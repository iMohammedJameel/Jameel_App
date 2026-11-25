class JameelUserModel {
  final String? uId;
  final String? userName;
  final String? userEmail;
  final String? userDepartment;
  final DateTime? userJoinDate;
  final String? photoUrl;
  final String role;
  final int annualLeaveBalance;
  final String? assignedSiteName;
  final double? assignedSiteLat;
  final double? assignedSiteLng;
  final double? assignedSiteRadiusMeters;

  const JameelUserModel({
    this.uId,
    this.userName,
    this.userEmail,
    this.userDepartment,
    this.userJoinDate,
    this.photoUrl,
    this.role = 'employee',
    this.annualLeaveBalance = 21,
    this.assignedSiteName,
    this.assignedSiteLat,
    this.assignedSiteLng,
    this.assignedSiteRadiusMeters,
  });

  bool get isManagerOrHr => role == 'manager' || role == 'hr';

  bool get hasAssignedSite =>
      assignedSiteLat != null &&
      assignedSiteLng != null &&
      assignedSiteRadiusMeters != null &&
      assignedSiteRadiusMeters! > 0;

  JameelUserModel copyWith({
    String? uId,
    String? userName,
    String? userEmail,
    String? userDepartment,
    DateTime? userJoinDate,
    String? photoUrl,
    String? role,
    int? annualLeaveBalance,
    String? assignedSiteName,
    double? assignedSiteLat,
    double? assignedSiteLng,
    double? assignedSiteRadiusMeters,
  }) {
    return JameelUserModel(
      uId: uId ?? this.uId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userDepartment: userDepartment ?? this.userDepartment,
      userJoinDate: userJoinDate ?? this.userJoinDate,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      annualLeaveBalance: annualLeaveBalance ?? this.annualLeaveBalance,
      assignedSiteName: assignedSiteName ?? this.assignedSiteName,
      assignedSiteLat: assignedSiteLat ?? this.assignedSiteLat,
      assignedSiteLng: assignedSiteLng ?? this.assignedSiteLng,
      assignedSiteRadiusMeters:
          assignedSiteRadiusMeters ?? this.assignedSiteRadiusMeters,
    );
  }

  factory JameelUserModel.fromMap(Map<String, dynamic> map) {
    return JameelUserModel(
      uId: map['uId'] as String?,
      userName: map['userName'] as String?,
      userEmail: map['userEmail'] as String?,
      userDepartment: map['userDepartment'] as String?,
      userJoinDate: map['userJoinDate'] is String
          ? DateTime.tryParse(map['userJoinDate'] as String)
          : null,
      photoUrl: map['photoUrl'] as String?,
      role: (map['role'] as String?) ?? 'employee',
      annualLeaveBalance: (map['annualLeaveBalance'] as num?)?.toInt() ?? 21,
      assignedSiteName: map['assignedSiteName'] as String?,
      assignedSiteLat: (map['assignedSiteLat'] as num?)?.toDouble(),
      assignedSiteLng: (map['assignedSiteLng'] as num?)?.toDouble(),
      assignedSiteRadiusMeters:
          (map['assignedSiteRadiusMeters'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uId': uId,
        'userName': userName,
        'userEmail': userEmail,
        'userDepartment': userDepartment,
        'userJoinDate': userJoinDate?.toIso8601String(),
        if (photoUrl != null) 'photoUrl': photoUrl,
        'role': role,
        'annualLeaveBalance': annualLeaveBalance,
        if (assignedSiteName != null) 'assignedSiteName': assignedSiteName,
        if (assignedSiteLat != null) 'assignedSiteLat': assignedSiteLat,
        if (assignedSiteLng != null) 'assignedSiteLng': assignedSiteLng,
        if (assignedSiteRadiusMeters != null)
          'assignedSiteRadiusMeters': assignedSiteRadiusMeters,
      };
}
