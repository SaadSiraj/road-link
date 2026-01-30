class UserModel {
  final String uid;
  final String phoneNumber;
  final bool isVerified;
  final bool isAdmin;
  final String? name;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.phoneNumber,
    required this.isVerified,
    this.isAdmin = false,
    this.name,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'isVerified': isVerified,
      'isAdmin': isAdmin,
      'name': name,
      'photoUrl': photoUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      phoneNumber: map['phoneNumber'] as String,
      isVerified: map['isVerified'] as bool,
      isAdmin: (map['isAdmin'] as bool?) ?? false,
      name: map['name'] as String?,
      photoUrl: map['photoUrl'] as String?,
    );
  }
}
