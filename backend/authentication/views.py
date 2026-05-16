import logging
import secrets

from django.contrib.auth.tokens import default_token_generator
from django.contrib.auth.password_validation import validate_password
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import AnonRateThrottle
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import User
from .serializers import (
    UserSerializer,
    RegisterSerializer,
    PasswordResetRequestSerializer,
    PasswordResetConfirmSerializer,
)

logger = logging.getLogger(__name__)


class LoginView(TokenObtainPairView):
    throttle_classes = [AnonRateThrottle]
    throttle_scope = 'login'

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        try:
            serializer.is_valid(raise_exception=True)
        except Exception:
            return Response(
                {'error': 'Email ou mot de passe incorrect.'},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        return Response(serializer.validated_data, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    serializer = RegisterSerializer(data=request.data)
    if not serializer.is_valid():
        errors = serializer.errors
        if 'email' in errors:
            return Response(
                {'error': 'Un compte avec cet email existe déjà.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        first_error = None
        for field, errs in errors.items():
            if errs:
                first_error = str(errs[0])
                break
        return Response(
            {'error': first_error or 'Erreur de validation.'},
            status=status.HTTP_400_BAD_REQUEST,
        )
    user = serializer.save()
    refresh = RefreshToken.for_user(user)
    return Response({
        'user': UserSerializer(user).data,
        'tokens': {
            'access': str(refresh.access_token),
            'refresh': str(refresh),
        },
    }, status=status.HTTP_201_CREATED)


@api_view(['GET', 'PATCH', 'DELETE'])
def me(request):
    if request.method == 'GET':
        return Response(UserSerializer(request.user).data)

    if request.method == 'PATCH':
        serializer = UserSerializer(
            request.user, data=request.data, partial=True
        )
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(
            {'error': 'Erreur de validation.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if request.method == 'DELETE':
        user = request.user
        user.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(['POST'])
@permission_classes([AllowAny])
def password_reset_request(request):
    serializer = PasswordResetRequestSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(
            {'error': 'Email invalide.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    email = serializer.validated_data['email']
    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response(
            {'message': 'Si un compte existe avec cet email, '
             'vous recevrez un lien de réinitialisation.'},
            status=status.HTTP_200_OK,
        )

    token = default_token_generator.make_token(user)
    uid = urlsafe_base64_encode(force_bytes(user.pk))

    context = {
        'user': user,
        'token': token,
        'uid': uid,
    }
    html_message = render_to_string('emails/password_reset.html', context)
    text_message = render_to_string('emails/password_reset.txt', context)

    try:
        send_mail(
            subject='Réinitialisation de votre mot de passe',
            message=text_message,
            from_email=None,
            recipient_list=[email],
            html_message=html_message,
        )
        logger.info(f'Password reset email sent to {email}')
    except Exception as e:
        logger.error(f'Failed to send password reset email: {e}')

    return Response(
        {'message': 'Si un compte existe avec cet email, '
         'vous recevrez un lien de réinitialisation.'},
        status=status.HTTP_200_OK,
    )


@api_view(['POST'])
@permission_classes([AllowAny])
def password_reset_confirm(request):
    serializer = PasswordResetConfirmSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(
            {'error': 'Données invalides.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    email = serializer.validated_data['email']
    token = serializer.validated_data['token']
    new_password = serializer.validated_data['new_password']

    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response(
            {'error': 'Lien invalide ou expiré.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if not default_token_generator.check_token(user, token):
        return Response(
            {'error': 'Lien invalide ou expiré.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    user.set_password(new_password)
    user.save()
    return Response(
        {'message': 'Mot de passe réinitialisé avec succès.'},
        status=status.HTTP_200_OK,
    )


@api_view(['POST'])
def logout(request):
    try:
        refresh_token = request.data.get('refresh')
        if refresh_token:
            token = RefreshToken(refresh_token)
            token.blacklist()
    except Exception as e:
        logger.warning(f'Logout token blacklist error: {e}')
    return Response(status=status.HTTP_200_OK)


@api_view(['GET'])
def company_users(request):
    company = request.user.company
    if not company:
        return Response([])
    users = User.objects.filter(company=company)
    return Response(UserSerializer(users, many=True).data)
