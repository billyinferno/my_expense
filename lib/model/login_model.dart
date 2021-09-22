class LoginModel {
  final String jwt;
  final LoginUserModel user;

  LoginModel(this.jwt, this.user);

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    LoginUserModel _user = LoginUserModel.fromJson(json['user']);
    return LoginModel(json['jwt'], _user);
  }

  Map<String, dynamic> toJson() => {
    'jwt': jwt,
    'user': user.toJson()
  };
}

class LoginUserModel {
  final int id;
  final String username;
  final String email;
  final bool confirmed;
  final bool blocked;

  LoginUserModel(this.id, this.username, this.email, this.confirmed, this.blocked);

  factory LoginUserModel.fromJson(Map<String, dynamic> json) {
    return LoginUserModel(
        json['id'],
        json['username'],
        json['email'],
        json['confirmed'],
        json['blocked']
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'confirmed': confirmed,
    'blocked': blocked
  };
}