class RememberedSession {
  final String token;
  final Map<String, dynamic> loginData;
  final DateTime expiresAt;

  const RememberedSession({
    required this.token,
    required this.loginData,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}