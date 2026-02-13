import 'package:cloud_firestore/cloud_firestore.dart';

class AdminsModel {
  String? id;
  String? firstName;
  String? lastName;
  String? username; // Keep for backward compatibility
  String? email;
  String? role;
  int? status; // 1 = Active, 0 = Inactive
  DateTime? lastLoggedIn;

  AdminsModel(
    this.id,
    this.firstName,
    this.lastName,
    this.username,
    this.email,
    this.role,
    this.status,
    this.lastLoggedIn,
  );

  // Getter for full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '${firstName!.trim()} ${lastName!.trim()}'.trim();
    } else if (firstName != null) {
      return firstName!.trim();
    } else if (lastName != null) {
      return lastName!.trim();
    } else if (username != null) {
      return username!.trim();
    }
    return 'Unknown';
  }

  AdminsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    username = json['username']; // Keep for backward compatibility
    email = json['email'];
    role = json['role'];
    status = json['status'] ?? 1; // Default to active
    lastLoggedIn =
        json["last_logged_in"] == null ||
            json["last_logged_in"] == "null" ||
            (json['last_logged_in'] as String).isEmpty
        ? null
        : DateTime.parse(json["last_logged_in"].toString());
  }

  factory AdminsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminsModel.fromJson({'id': doc.id, ...data});
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'status': status,
      'last_logged_in': lastLoggedIn.toString(),
    };
  }
}
