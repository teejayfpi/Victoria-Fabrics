import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/admin/providers/admin_auth_provider.dart';
import 'package:fabric_haven/core/error/exceptions.dart';

AdminUser _admin(AdminRole role) => AdminUser(
      id: 'uid-1',
      email: 'staff@victoriafabrics.test',
      name: 'Test Staff',
      role: role,
    );

void main() {
  group('AdminRole.tryParse', () {
    test('parses every known role, including the snake_case super admin', () {
      expect(AdminRole.tryParse('viewer'), AdminRole.viewer);
      expect(AdminRole.tryParse('staff'), AdminRole.staff);
      expect(AdminRole.tryParse('admin'), AdminRole.admin);
      expect(AdminRole.tryParse('super_admin'), AdminRole.superAdmin);
      expect(AdminRole.tryParse('superAdmin'), AdminRole.superAdmin);
    });

    test('returns null for unknown or missing values', () {
      expect(AdminRole.tryParse('owner'), isNull);
      expect(AdminRole.tryParse(null), isNull);
    });

    test('canManage is false for viewers and true from staff upwards', () {
      expect(AdminRole.viewer.canManage, isFalse);
      expect(AdminRole.staff.canManage, isTrue);
      expect(AdminRole.admin.canManage, isTrue);
      expect(AdminRole.superAdmin.canManage, isTrue);
    });
  });

  group('requireAdmin', () {
    test('throws when no admin is signed in', () {
      expect(
        () => requireAdmin(null),
        throwsA(
          isA<AuthException>()
              .having((e) => e.code, 'code', 'admin-required'),
        ),
      );
    });

    test('rejects a role below the required minimum', () {
      expect(
        () => requireAdmin(_admin(AdminRole.viewer)),
        throwsA(
          isA<AuthException>()
              .having((e) => e.code, 'code', 'insufficient-role'),
        ),
      );
    });

    test('allows a role at or above the minimum', () {
      expect(requireAdmin(_admin(AdminRole.staff)).role, AdminRole.staff);
      expect(
        requireAdmin(_admin(AdminRole.admin), minimum: AdminRole.admin).role,
        AdminRole.admin,
      );
    });

    test('honours a raised minimum for destructive actions', () {
      expect(
        () => requireAdmin(_admin(AdminRole.staff), minimum: AdminRole.admin),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AdminUser equality', () {
    test('compares on id and role', () {
      expect(_admin(AdminRole.admin), _admin(AdminRole.admin));
      expect(
        _admin(AdminRole.admin).hashCode,
        _admin(AdminRole.admin).hashCode,
      );
      expect(_admin(AdminRole.admin), isNot(_admin(AdminRole.staff)));
    });
  });
}
