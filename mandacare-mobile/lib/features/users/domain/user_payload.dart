class CreateTeamUserPayload {
  const CreateTeamUserPayload({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.password,
    required this.roleCode,
    this.phone,
    this.email,
  });

  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String username;
  final String password;
  final String roleCode;

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'username': username,
      'password': password,
      'roleCode': roleCode,
    };
  }
}

class UpdateTeamUserPayload {
  const UpdateTeamUserPayload({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.roleCode,
    required this.status,
    this.phone,
    this.email,
    this.password,
  });

  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String username;
  final String? password;
  final String roleCode;
  final String status;

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'username': username,
      if (password != null && password!.trim().isNotEmpty) 'password': password,
      'roleCode': roleCode,
      'status': status,
    };
  }
}
