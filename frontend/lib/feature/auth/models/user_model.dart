class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final Map<String, dynamic>? activePlan;
  final int streak;
  final DateTime? lastCheckIn;
  final bool isOnboardingComplete;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.activePlan,
    this.streak = 0,
    this.lastCheckIn,
    this.isOnboardingComplete = false,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    Map<String, dynamic>? activePlan,
    int? streak,
    DateTime? lastCheckIn,
    bool? isOnboardingComplete,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      activePlan: activePlan ?? this.activePlan,
      streak: streak ?? this.streak,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'activePlan': activePlan,
      'streak': streak,
      'lastCheckIn': lastCheckIn?.toIso8601String(),
      'isOnboardingComplete': isOnboardingComplete,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      activePlan: map['activePlan'] as Map<String, dynamic>?,
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      lastCheckIn: map['lastCheckIn'] != null
          ? DateTime.tryParse(map['lastCheckIn'] as String)
          : null,
      isOnboardingComplete: map['isOnboardingComplete'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, streak: $streak, lastCheckIn: $lastCheckIn, activePlan: ${activePlan != null}, isOnboardingComplete: $isOnboardingComplete)';
  }
}
