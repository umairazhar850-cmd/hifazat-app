enum UserRole { consumer, vendor, admin }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.consumer:
        return 'Consumer';
      case UserRole.vendor:
        return 'Vendor / Shop Owner';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get homeGreetingSubtitle {
    switch (this) {
      case UserRole.consumer:
        return 'What would you like to test today?';
      case UserRole.vendor:
        return 'Verify your shop\'s quality before you sell';
      case UserRole.admin:
        return 'Manage users and monitor community data';
    }
  }

  static UserRole fromName(String? name) {
    return UserRole.values.firstWhere((e) => e.name == name, orElse: () => UserRole.consumer);
  }
}
