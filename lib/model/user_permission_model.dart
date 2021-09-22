class UserPermissionModel {
  final int id;
  final String username;
  final String email;

  UserPermissionModel(this.id, this.username, this.email);

  factory UserPermissionModel.fromJson(Map<String, dynamic> json) {
    return UserPermissionModel(json['id'], json['username'], json['email']);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
  };
}