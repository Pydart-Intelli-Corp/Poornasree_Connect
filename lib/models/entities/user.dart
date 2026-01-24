class UserModel {
  final String id;
  final String email;
  final String role; // admin, dairy, bmc, society, farmer
  final String name;
  final String? token;
  final String? refreshToken;
  
  // Additional entity-specific fields
  final String? type; // society, farmer, bmc, dairy
  final String? location;
  final String? contactPhone;
  final String? phone;
  
  // Society-specific
  final String? societyId;
  final String? societyIdentifier;
  final String? societyName;
  final String? presidentName;
  
  // Farmer-specific
  final String? farmerId;
  final String? address;
  final String? bankName;
  final String? bankAccountNumber;
  final String? ifscCode;
  
  // BMC-specific
  final String? bmcId;
  final String? bmcName;
  
  // Dairy-specific
  final String? dairyId;
  final String? dairyName;
  final String? dairyIdentifier;
  
  // Admin/Schema info
  final String? adminName;
  final String? adminEmail;
  final String? schema;
  final String? status;
  
  // Statistics (Last 30 days)
  final double? totalRevenue30Days;
  final double? totalCollection30Days;
  final double? avgFat;
  final double? avgSnf;
  final double? avgClr;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.token,
    this.refreshToken,
    this.type,
    this.location,
    this.contactPhone,
    this.phone,
    this.societyId,
    this.societyIdentifier,
    this.societyName,
    this.presidentName,
    this.farmerId,
    this.address,
    this.bankName,
    this.bankAccountNumber,
    this.ifscCode,
    this.bmcId,
    this.bmcName,
    this.dairyId,
    this.dairyName,
    this.dairyIdentifier,
    this.adminName,
    this.adminEmail,
    this.schema,
    this.status,
    this.totalRevenue30Days,
    this.totalCollection30Days,
    this.avgFat,
    this.avgSnf,
    this.avgClr,
  });

  // Factory constructor to create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? json['type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      token: json['token']?.toString(),
      refreshToken: json['refreshToken']?.toString(),
      type: json['type']?.toString(),
      location: json['location']?.toString(),
      contactPhone: (json['contactPhone'] ?? json['contact_phone'])?.toString(),
      phone: json['phone']?.toString(),
      societyId: (json['societyId'] ?? json['society_id'])?.toString(),
      societyIdentifier: (json['societyIdentifier'] ?? json['society_identifier'])?.toString(),
      societyName: (json['societyName'] ?? json['society_name'])?.toString(),
      presidentName: (json['presidentName'] ?? json['president_name'])?.toString(),
      farmerId: (json['farmerId'] ?? json['farmer_id'])?.toString(),
      address: json['address']?.toString(),
      bankName: (json['bankName'] ?? json['bank_name'])?.toString(),
      bankAccountNumber: (json['bankAccountNumber'] ?? json['bank_account_number'])?.toString(),
      ifscCode: (json['ifscCode'] ?? json['ifsc_code'])?.toString(),
      bmcId: (json['bmcId'] ?? json['bmc_id'])?.toString(),
      bmcName: (json['bmcName'] ?? json['bmc_name'])?.toString(),
      dairyId: (json['dairyId'] ?? json['dairy_id'])?.toString(),
      dairyName: (json['dairyName'] ?? json['dairy_name'])?.toString(),
      dairyIdentifier: (json['dairyIdentifier'] ?? json['dairy_identifier'])?.toString(),
      adminName: (json['adminName'] ?? json['admin_name'])?.toString(),
      adminEmail: (json['adminEmail'] ?? json['admin_email'])?.toString(),
      schema: json['schema']?.toString(),
      status: json['status']?.toString(),
      totalRevenue30Days: json['totalRevenue30Days'] != null ? double.tryParse(json['totalRevenue30Days'].toString()) : null,
      totalCollection30Days: json['totalCollection30Days'] != null ? double.tryParse(json['totalCollection30Days'].toString()) : null,
      avgFat: json['avgFat'] != null ? double.tryParse(json['avgFat'].toString()) : null,
      avgSnf: json['avgSnf'] != null ? double.tryParse(json['avgSnf'].toString()) : null,
      avgClr: json['avgClr'] != null ? double.tryParse(json['avgClr'].toString()) : null,
    );
  }

  // Method to convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
      'token': token,
      'refreshToken': refreshToken,
      'type': type,
      'location': location,
      'contactPhone': contactPhone,
      'phone': phone,
      'societyId': societyId,
      'societyIdentifier': societyIdentifier,
      'societyName': societyName,
      'presidentName': presidentName,
      'farmerId': farmerId,
      'address': address,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'ifscCode': ifscCode,
      'bmcId': bmcId,
      'bmcName': bmcName,
      'dairyId': dairyId,
      'dairyName': dairyName,
      'dairyIdentifier': dairyIdentifier,
      'adminName': adminName,
      'adminEmail': adminEmail,
      'schema': schema,
      'status': status,
      'totalRevenue30Days': totalRevenue30Days,
      'totalCollection30Days': totalCollection30Days,
      'avgFat': avgFat,
      'avgSnf': avgSnf,
      'avgClr': avgClr,
    };
  }

  // CopyWith method for creating modified copies
  UserModel copyWith({
    String? id,
    String? email,
    String? role,
    String? name,
    String? token,
    String? refreshToken,
    String? type,
    String? location,
    String? contactPhone,
    String? phone,
    String? societyId,
    String? societyIdentifier,
    String? societyName,
    String? presidentName,
    String? farmerId,
    String? address,
    String? bankName,
    String? bankAccountNumber,
    String? ifscCode,
    String? bmcId,
    String? bmcName,
    String? dairyId,
    String? dairyName,
    String? dairyIdentifier,
    String? adminName,
    String? adminEmail,
    String? schema,
    String? status,
    double? totalRevenue30Days,
    double? totalCollection30Days,
    double? avgFat,
    double? avgSnf,
    double? avgClr,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      type: type ?? this.type,
      location: location ?? this.location,
      contactPhone: contactPhone ?? this.contactPhone,
      phone: phone ?? this.phone,
      societyId: societyId ?? this.societyId,
      societyIdentifier: societyIdentifier ?? this.societyIdentifier,
      societyName: societyName ?? this.societyName,
      presidentName: presidentName ?? this.presidentName,
      farmerId: farmerId ?? this.farmerId,
      address: address ?? this.address,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      bmcId: bmcId ?? this.bmcId,
      bmcName: bmcName ?? this.bmcName,
      dairyId: dairyId ?? this.dairyId,
      dairyName: dairyName ?? this.dairyName,
      dairyIdentifier: dairyIdentifier ?? this.dairyIdentifier,
      adminName: adminName ?? this.adminName,
      adminEmail: adminEmail ?? this.adminEmail,
      schema: schema ?? this.schema,
      status: status ?? this.status,
      totalRevenue30Days: totalRevenue30Days ?? this.totalRevenue30Days,
      totalCollection30Days: totalCollection30Days ?? this.totalCollection30Days,
      avgFat: avgFat ?? this.avgFat,
      avgSnf: avgSnf ?? this.avgSnf,
      avgClr: avgClr ?? this.avgClr,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, role: $role, name: $name, type: $type)';
  }
}
