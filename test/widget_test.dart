import 'package:flutter_test/flutter_test.dart';
import 'package:collabsme/data/models/user_model.dart';
import 'package:collabsme/data/models/notification_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': '123',
        'email': 'test@example.com',
        'first_name': 'Jean',
        'last_name': 'Dupont',
        'phone_number': '+33123456789',
        'company': '456',
        'role': 'ADMIN',
        'is_company_admin': true,
        'avatar_url': 'https://example.com/avatar.png',
        'bio': 'Développeur',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, '123');
      expect(user.email, 'test@example.com');
      expect(user.firstName, 'Jean');
      expect(user.lastName, 'Dupont');
      expect(user.fullName, 'Jean Dupont');
      expect(user.phoneNumber, '+33123456789');
      expect(user.companyId, '456');
      expect(user.role, 'ADMIN');
      expect(user.isCompanyAdmin, isTrue);
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.bio, 'Développeur');
      expect(user.displayRole, 'Admin');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': '123',
        'email': 'test@example.com',
        'first_name': '',
        'last_name': '',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, '123');
      expect(user.email, 'test@example.com');
      expect(user.fullName, 'test'); // split('@')[0] de l'email
      expect(user.phoneNumber, isNull);
      expect(user.companyId, isNull);
      expect(user.role, 'MEMBER');
      expect(user.isCompanyAdmin, isFalse);
      expect(user.avatarUrl, isNull);
      expect(user.bio, isNull);
    });

    test('toJson produces valid map', () {
      final user = UserModel(
        id: '1',
        email: 'a@b.com',
        firstName: 'Alice',
        lastName: 'Bob',
        role: 'LEAD',
        avatarUrl: 'https://pic.png',
        bio: 'Test',
      );

      final json = user.toJson();

      expect(json['id'], '1');
      expect(json['email'], 'a@b.com');
      expect(json['role'], 'LEAD');
      expect(json['avatar_url'], 'https://pic.png');
      expect(json['bio'], 'Test');
    });
  });

  group('NotificationModel', () {
    test('fromJson with related_id', () {
      final json = {
        'id': 'n1',
        'title': 'Tâche assignée',
        'message': 'Vous avez une nouvelle tâche',
        'notification_type': 'TASK_ASSIGNED',
        'is_read': false,
        'related_id': 'proj-123',
        'created_at': '2026-05-16T12:00:00Z',
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.id, 'n1');
      expect(notif.type, 'TASK_ASSIGNED');
      expect(notif.relatedId, 'proj-123');
      expect(notif.isRead, isFalse);
    });
  });
}
