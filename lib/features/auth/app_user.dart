class AppUser {
  final String email;
  final String uid;
  final String? displayName;

  const AppUser({
    required this.email,
    required this.uid,
    this.displayName,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'uid': uid,
      'displayName': displayName,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      email: map['email'] as String,
      uid: map['uid'] as String,
      displayName: map['displayName'] as String?,
    );
  }
}
