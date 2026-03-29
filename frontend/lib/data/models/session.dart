import 'user.dart';

class Session {
  const Session({
    required this.token,
    required this.user,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      token: json['token']?.toString() ?? '',
      user: User.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    );
  }

  final String token;
  final User user;

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }
}
