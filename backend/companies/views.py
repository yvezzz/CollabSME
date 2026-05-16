from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response

from authentication.models import User
from authentication.serializers import UserSerializer
from .models import Company
from .serializers import CompanySerializer


@api_view(['GET', 'PATCH'])
def company_detail(request):
    company = request.user.company
    if not company:
        return Response(
            {'error': 'Aucune entreprise associée.'},
            status=status.HTTP_404_NOT_FOUND,
        )

    if request.method == 'GET':
        return Response(CompanySerializer(company).data)

    if request.method == 'PATCH':
        serializer = CompanySerializer(company, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(
            {'error': 'Erreur de validation.'},
            status=status.HTTP_400_BAD_REQUEST,
        )


@api_view(['GET'])
def company_members(request):
    company = request.user.company
    if not company:
        return Response({'error': 'Aucune entreprise associée.'}, status=404)
    users = User.objects.filter(company=company).order_by('email')
    return Response(UserSerializer(users, many=True).data)


@api_view(['DELETE'])
def remove_member(request, user_id):
    company = request.user.company
    if not company:
        return Response({'error': 'Aucune entreprise associée.'}, status=404)

    if not request.user.is_company_admin:
        return Response({'error': 'Action non autorisée.'}, status=403)

    try:
        user = User.objects.get(id=user_id, company=company)
    except User.DoesNotExist:
        return Response({'error': 'Utilisateur introuvable.'}, status=404)

    if user == request.user:
        return Response(
            {'error': 'Vous ne pouvez pas vous retirer vous-même.'}, status=400
        )

    user.company = None
    user.role = 'MEMBER'
    user.is_company_admin = False
    user.save()
    return Response({'message': 'Membre retiré avec succès.'})


@api_view(['PATCH'])
def change_member_role(request, user_id):
    company = request.user.company
    if not company:
        return Response({'error': 'Aucune entreprise associée.'}, status=404)

    if not request.user.is_company_admin:
        return Response({'error': 'Action non autorisée.'}, status=403)

    try:
        user = User.objects.get(id=user_id, company=company)
    except User.DoesNotExist:
        return Response({'error': 'Utilisateur introuvable.'}, status=404)

    role = request.data.get('role')
    valid_roles = ['ADMIN', 'LEAD', 'MEMBER']
    if role not in valid_roles:
        return Response({'error': 'Rôle invalide.'}, status=400)

    user.role = role
    user.is_company_admin = (role == 'ADMIN')
    user.save()
    return Response(UserSerializer(user).data)
