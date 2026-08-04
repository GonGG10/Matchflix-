class UserEntity {
  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    this.coupleId,
  });

  final String id;
  final String email;
  final String displayName;
  final String? coupleId;

  factory UserEntity.fromJson(Map<String, dynamic> json) => UserEntity(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        coupleId: json['coupleId'] as String?,
      );

  UserEntity copyWith({String? coupleId}) => UserEntity(
        id: id,
        email: email,
        displayName: displayName,
        coupleId: coupleId ?? this.coupleId,
      );
}
