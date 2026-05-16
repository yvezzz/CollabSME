import logging

from django.core.mail import send_mail
from django.template.loader import render_to_string
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from notifications.models import Notification
from .models import Invitation
from .serializers import InvitationSerializer

logger = logging.getLogger(__name__)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def invitation_list(request):
    if request.method == 'GET':
        invitations = Invitation.objects.filter(company=request.user.company)
        return Response(InvitationSerializer(invitations, many=True).data)

    if request.method == 'POST':
        if not request.user.is_company_admin:
            return Response({'error': 'Action non autorisée.'}, status=403)
        serializer = InvitationSerializer(data=request.data)
        if serializer.is_valid():
            invitation = serializer.save(
                company=request.user.company,
                invited_by=request.user,
            )

            try:
                context = {
                    'company_name': request.user.company.name,
                    'inviter_name': f'{request.user.first_name} {request.user.last_name}',
                    'token': str(invitation.token),
                }
                html_message = render_to_string('emails/invitation.html', context)
                text_message = render_to_string('emails/invitation.txt', context)
                send_mail(
                    subject=f'Invitation à rejoindre {request.user.company.name}',
                    message=text_message,
                    from_email=None,
                    recipient_list=[invitation.email],
                    html_message=html_message,
                )
                logger.info(f'Invitation email sent to {invitation.email}')
            except Exception as e:
                logger.error(f'Failed to send invitation email: {e}')

            return Response(
                InvitationSerializer(invitation).data,
                status=status.HTTP_201_CREATED,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def cancel_invitation(request, pk):
    try:
        invitation = Invitation.objects.get(id=pk, company=request.user.company)
    except Invitation.DoesNotExist:
        return Response({'error': 'Invitation introuvable.'}, status=404)

    invitation.delete()
    return Response(status=204)


@api_view(['GET'])
@permission_classes([AllowAny])
def validate_invitation(request, token):
    try:
        invitation = Invitation.objects.get(token=token, status='PENDING')
    except Invitation.DoesNotExist:
        return Response(
            {'error': 'Lien d\'invitation invalide ou expiré.'},
            status=404,
        )

    return Response({
        'email': invitation.email,
        'company': invitation.company.name,
        'role': invitation.role,
        'token': str(invitation.token),
    })


@api_view(['POST'])
@permission_classes([AllowAny])
def accept_invitation(request, token):
    try:
        invitation = Invitation.objects.get(token=token, status='PENDING')
    except Invitation.DoesNotExist:
        return Response(
            {'error': 'Lien d\'invitation invalide ou expiré.'},
            status=404,
        )

    from authentication.serializers import RegisterSerializer
    reg_serializer = RegisterSerializer(data={
        **request.data,
        'email': invitation.email,
        'company_name': invitation.company.name,
    })
    if reg_serializer.is_valid():
        user = reg_serializer.save()
        user.company = invitation.company
        user.role = invitation.role
        user.is_company_admin = (invitation.role == 'ADMIN')
        user.save()

        invitation.status = 'ACCEPTED'
        invitation.save()

        from rest_framework_simplejwt.tokens import RefreshToken
        refresh = RefreshToken.for_user(user)
        return Response({
            'tokens': {
                'access': str(refresh.access_token),
                'refresh': str(refresh),
            }
        }, status=status.HTTP_201_CREATED)

    return Response(reg_serializer.errors, status=400)


@api_view(['POST'])
@permission_classes([AllowAny])
def decline_invitation(request, token):
    try:
        invitation = Invitation.objects.get(token=token, status='PENDING')
    except Invitation.DoesNotExist:
        return Response(
            {'error': 'Lien d\'invitation invalide ou expiré.'},
            status=404,
        )

    invitation.status = 'DECLINED'
    invitation.save()
    return Response({'message': 'Invitation refusée.'})
