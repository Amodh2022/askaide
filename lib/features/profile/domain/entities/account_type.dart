/// Roles that gate routes and sidebar items. The backend sends a free-form
/// string, so [fromApi] tolerates casing/spelling variants.
enum AccountType {
  student,
  parent,
  teacher,
  superAdmin;

  static AccountType fromApi(String? raw) {
    switch (raw?.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '')) {
      case 'parent':
        return AccountType.parent;
      case 'teacher':
        return AccountType.teacher;
      case 'superadmin':
      case 'admin':
        return AccountType.superAdmin;
      case 'student':
      default:
        return AccountType.student;
    }
  }

  String get apiValue => switch (this) {
        AccountType.student => 'Student',
        AccountType.parent => 'Parent',
        AccountType.teacher => 'Teacher',
        AccountType.superAdmin => 'SuperAdmin',
      };

  String get label => apiValue;

  bool get isStudent => this == AccountType.student;
  bool get isParent => this == AccountType.parent;
  bool get isTeacher => this == AccountType.teacher;
  bool get isSuperAdmin => this == AccountType.superAdmin;
}
