class UserEntity {
  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    this.coupleId,
    this.coupleStatus,
  });

  final String id;
  final String email;
  final String displayName;
  final String? coupleId;
  final String? coupleStatus;

  factory UserEntity.fromJson(Map<String, dynamic> json) => UserEntity(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        coupleId: json['coupleId'] as String?,
        coupleStatus: json['coupleStatus'] as String?,
      );

  UserEntity copyWith({String? coupleId, String? coupleStatus}) => UserEntity(
        id: id,
        email: email,
        displayName: displayName,
        coupleId: coupleId ?? this.coupleId,
        coupleStatus: coupleStatus ?? this.coupleStatus,
      );

  /// true si la pareja está activa (los dos miembros se han unido)
  bool get isCoupleActive => coupleStatus == 'ACTIVE';
}
