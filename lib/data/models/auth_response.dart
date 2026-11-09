import 'user.dart';

class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RefreshTokenRequest {
  const RefreshTokenRequest({required this.refreshToken});

  final String refreshToken;

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}

class AuthResponse {
  const AuthResponse({
    required this.tokenType,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresInSeconds,
    required this.refreshTokenExpiresInSeconds,
    required this.user,
  });

  final String tokenType;
  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresInSeconds;
  final int refreshTokenExpiresInSeconds;
  final UserResponse user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    tokenType: json['tokenType'] as String,
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    accessTokenExpiresInSeconds: (json['accessTokenExpiresInSeconds'] as num)
        .toInt(),
    refreshTokenExpiresInSeconds: (json['refreshTokenExpiresInSeconds'] as num)
        .toInt(),
    user: UserResponse.fromJson(json['user'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'tokenType': tokenType,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'accessTokenExpiresInSeconds': accessTokenExpiresInSeconds,
    'refreshTokenExpiresInSeconds': refreshTokenExpiresInSeconds,
    'user': user.toJson(),
  };
}
