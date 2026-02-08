import 'package:cloud_firestore/cloud_firestore.dart';

class ContactModel {
  final String id;
  final String? fName;
  final String? lName;
  final String phoneNumber;
  final String countryCode;
  final String? email;
  final String? company;
  final List<String> tags;
  final int? status; // 0 = opted-out, 1 = opted-in, null = none
  final String? notes;
  final DateTime? lastContacted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? clientId;

  // New fields with default values
  final String? profilePhoto;
  final DateTime? birthdate;
  final DateTime? anniversaryDt;
  final DateTime? workAnniversaryDt;

  // Month fields for easier querying
  final String? birthdateMonth;
  final String? anniversaryDateMonth;
  final String? workAnniversaryDateMonth;

  // Active status for milestones
  final bool isBirthdateActive;
  final bool isAnniversaryActive;
  final bool isWorkAnniversaryActive;
  final Map<String, dynamic> customAttributes;

  ContactModel({
    required this.id,
    required this.fName,
    required this.lName,
    required this.phoneNumber,
    required this.countryCode,
    this.email,
    this.company,
    required this.tags,
    this.status,
    this.notes,
    this.lastContacted,
    required this.createdAt,
    required this.updatedAt,
    this.clientId,
    this.profilePhoto,
    this.birthdate,
    this.anniversaryDt,
    this.workAnniversaryDt,
    this.birthdateMonth,
    this.anniversaryDateMonth,
    this.workAnniversaryDateMonth,
    this.isBirthdateActive = true,
    this.isAnniversaryActive = true,
    this.isWorkAnniversaryActive = true,
    this.customAttributes = const {},
  });

  // FROM FIRESTORE - Handle missing fields gracefully
  factory ContactModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    return ContactModel(
      id: doc.id,
      fName: data['fName'] as String? ?? '',
      lName: data['lName'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      countryCode: data['countryCode'] as String? ?? '+91',
      email: data['email'] as String?,
      clientId: data['clientId'] as String?,
      company: data['company'] as String?,
      tags:
          (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      status: data['status'] as int?,
      notes: data['notes'] as String?,
      lastContacted: data['lastContacted'] != null
          ? (data['lastContacted'] is String
                ? DateTime.parse(data['lastContacted'] as String)
                : (data['lastContacted'] as Timestamp).toDate())
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is String
                ? DateTime.parse(data['createdAt'] as String)
                : (data['createdAt'] as Timestamp).toDate())
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is String
                ? DateTime.parse(data['updatedAt'] as String)
                : (data['updatedAt'] as Timestamp).toDate())
          : DateTime.now(),
      // New fields - handle missing data gracefully
      profilePhoto: data['profilePhoto'] as String?,
      birthdate: data['birthdate'] != null
          ? (data['birthdate'] is String
                ? DateTime.parse(data['birthdate'] as String)
                : (data['birthdate'] as Timestamp).toDate())
          : null,
      anniversaryDt: data['anniversaryDt'] != null
          ? (data['anniversaryDt'] is String
                ? DateTime.parse(data['anniversaryDt'] as String)
                : (data['anniversaryDt'] as Timestamp).toDate())
          : null,
      workAnniversaryDt: data['workAnniversaryDt'] != null
          ? (data['workAnniversaryDt'] is String
                ? DateTime.parse(data['workAnniversaryDt'] as String)
                : (data['workAnniversaryDt'] as Timestamp).toDate())
          : null,
      // Month fields
      birthdateMonth: data['birthdateMonth'] as String?,
      anniversaryDateMonth: data['anniversaryDateMonth'] as String?,
      workAnniversaryDateMonth: data['workAnniversaryDateMonth'] as String?,
      isBirthdateActive: data['isBirthdateActive'] as bool? ?? false,
      isAnniversaryActive: data['isAnniversaryActive'] as bool? ?? false,
      isWorkAnniversaryActive:
          data['isWorkAnniversaryActive'] as bool? ?? false,
      customAttributes: data['customAttributes'] as Map<String, dynamic>? ?? {},
    );
  }

  // FROM JSON - Handle missing fields gracefully
  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String? ?? '',
      fName: json['fName'] as String? ?? '',
      lName: json['lName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '+91',
      email: json['email'] as String?,
      clientId: json['clientId'] as String?,
      company: json['company'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      status: json['status'] as int?,
      notes: json['notes'] as String?,
      lastContacted: json['lastContacted'] != null
          ? DateTime.parse(json['lastContacted'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      // New fields - handle missing data gracefully
      profilePhoto: json['profilePhoto'] as String?,
      birthdate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'] as String)
          : null,
      anniversaryDt: json['anniversaryDt'] != null
          ? DateTime.parse(json['anniversaryDt'] as String)
          : null,
      workAnniversaryDt: json['workAnniversaryDt'] != null
          ? DateTime.parse(json['workAnniversaryDt'] as String)
          : null,
      // Month fields
      birthdateMonth: json['birthdateMonth'] as String?,
      anniversaryDateMonth: json['anniversaryDateMonth'] as String?,
      workAnniversaryDateMonth: json['workAnniversaryDateMonth'] as String?,
      isBirthdateActive: json['isBirthdateActive'] as bool? ?? false,
      isAnniversaryActive: json['isAnniversaryActive'] as bool? ?? false,
      isWorkAnniversaryActive:
          json['isWorkAnniversaryActive'] as bool? ?? false,
      customAttributes: json['customAttributes'] as Map<String, dynamic>? ?? {},
    );
  }

  // TO JSON - Include all fields
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fName': fName,
      'lName': lName,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'email': email,
      'clientId': clientId,
      'company': company,
      'tags': tags,
      'status': status,
      'notes': notes,
      'lastContacted': lastContacted?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // New fields
      'profilePhoto': profilePhoto,
      'birthdate': birthdate?.toIso8601String(),
      'anniversaryDt': anniversaryDt?.toIso8601String(),
      'workAnniversaryDt': workAnniversaryDt?.toIso8601String(),
      // Month fields
      'birthdateMonth': birthdateMonth,
      'anniversaryDateMonth': anniversaryDateMonth,
      'workAnniversaryDateMonth': workAnniversaryDateMonth,
      'isBirthdateActive': isBirthdateActive,
      'isAnniversaryActive': isAnniversaryActive,
      'isWorkAnniversaryActive': isWorkAnniversaryActive,
      'customAttributes': customAttributes,
    };
  }

  // TO FIRESTORE - For saving to Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'fName': fName,
      'lName': lName,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'email': email,
      'company': company,
      'tags': tags,
      'status': status,
      'notes': notes,
      'lastContacted': lastContacted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      // New fields
      'profilePhoto': profilePhoto,
      'birthdate': birthdate,
      'anniversaryDt': anniversaryDt,
      'workAnniversaryDt': workAnniversaryDt,
      // Month fields
      'birthdateMonth': birthdateMonth,
      'anniversaryDateMonth': anniversaryDateMonth,
      'workAnniversaryDateMonth': workAnniversaryDateMonth,
      'isBirthdateActive': isBirthdateActive,
      'isAnniversaryActive': isAnniversaryActive,
      'isWorkAnniversaryActive': isWorkAnniversaryActive,
      'customAttributes': customAttributes,
    };
  }

  // COPY WITH - For updating contacts
  ContactModel copyWith({
    String? id,
    String? fName,
    String? lName,
    String? phoneNumber,
    String? countryCode,
    String? email,
    String? clientId,
    String? company,
    List<String>? tags,
    int? status,
    String? notes,
    DateTime? lastContacted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profilePhoto,
    DateTime? birthdate,
    DateTime? anniversaryDt,
    DateTime? workAnniversaryDt,
    String? birthdateMonth,
    String? anniversaryDateMonth,
    String? workAnniversaryDateMonth,
    bool? isBirthdateActive,
    bool? isAnniversaryActive,

    bool? isWorkAnniversaryActive,
    Map<String, dynamic>? customAttributes,
  }) {
    return ContactModel(
      id: id ?? this.id,
      fName: fName ?? this.fName,
      lName: lName ?? this.lName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      email: email ?? this.email,
      clientId: clientId ?? this.clientId,
      company: company ?? this.company,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      lastContacted: lastContacted ?? this.lastContacted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      birthdate: birthdate ?? this.birthdate,
      anniversaryDt: anniversaryDt ?? this.anniversaryDt,
      workAnniversaryDt: workAnniversaryDt ?? this.workAnniversaryDt,
      birthdateMonth: birthdateMonth ?? this.birthdateMonth,
      anniversaryDateMonth: anniversaryDateMonth ?? this.anniversaryDateMonth,
      workAnniversaryDateMonth:
          workAnniversaryDateMonth ?? this.workAnniversaryDateMonth,
      isBirthdateActive: isBirthdateActive ?? this.isBirthdateActive,
      isAnniversaryActive: isAnniversaryActive ?? this.isAnniversaryActive,
      isWorkAnniversaryActive:
          isWorkAnniversaryActive ?? this.isWorkAnniversaryActive,
      customAttributes: customAttributes ?? this.customAttributes,
    );
  }

  @override
  String toString() {
    return 'ContactModel(id: $id, fName: $fName, lName: $lName, phoneNumber: $phoneNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Don't forget to import these:
// import 'package:cloud_firestore/cloud_firestore.dart';
