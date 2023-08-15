class Users {
  String fullName;
  bool driver;
  bool owner;
  bool admin;
  String id;
  String userName;
  String normalizedUserName;
  String email;
  String normalizedEmail;
  bool emailConfirmed;
  String passwordHash;
  String securityStamp;
  String concurrencyStamp;
  String phoneNumber;
  bool phoneNumberConfirmed;
  bool twoFactorEnabled;
  DateTime? lockoutEnd;
  bool lockoutEnabled;
  int accessFailedCount;

  Users({
    required this.fullName,
    required this.driver,
    required this.owner,
    required this.admin,
    required this.id,
    required this.userName,
    required this.normalizedUserName,
    required this.email,
    required this.normalizedEmail,
    required this.emailConfirmed,
    required this.passwordHash,
    required this.securityStamp,
    required this.concurrencyStamp,
    required this.phoneNumber,
    required this.phoneNumberConfirmed,
    required this.twoFactorEnabled,
    this.lockoutEnd,
    required this.lockoutEnabled,
    required this.accessFailedCount,
  });

  factory Users.fromObject(Map<String, dynamic> map) {
    return Users(
      fullName: map['fullName'] ?? '',
      driver: map['driver'] ?? false,
      owner: map['owner'] ?? false,
      admin: map['admin'] ?? false,
      id: map['id'] ?? '',
      userName: map['userName'] ?? '',
      normalizedUserName: map['normalizedUserName'] ?? '',
      email: map['email'] ?? '',
      normalizedEmail: map['normalizedEmail'] ?? '',
      emailConfirmed: map['emailConfirmed'] ?? false,
      passwordHash: map['passwordHash'] ?? '',
      securityStamp: map['securityStamp'] ?? '',
      concurrencyStamp: map['concurrencyStamp'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      phoneNumberConfirmed: map['phoneNumberConfirmed'] ?? false,
      twoFactorEnabled: map['twoFactorEnabled'] ?? false,
      lockoutEnd: map['lockoutEnd'] != null ? DateTime.parse(map['lockoutEnd']) : null,
      lockoutEnabled: map['lockoutEnabled'] ?? false,
      accessFailedCount: map['accessFailedCount'] ?? 0,
    );
  }
}