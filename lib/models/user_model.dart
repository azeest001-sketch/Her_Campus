/// User role chosen on the role-select screen.
enum UserRole {
  student,
  admin,
}

/// App user — friend can expand fields when wiring Supabase/auth.
class UserModel {
  const UserModel({
    this.id,
    this.email,
    this.displayName,
    this.role,
  });

  final String? id;
  final String? email;
  final String? displayName;
  final UserRole? role;
}
