class AdminsModel {
  String? id;
  String? firstName;
  String? lastName;
  String? username; // Keep for backward compatibility
  String? email;
  String? role;
  String? clientId;
  String? clientName;
  int? status; // 1 = Active, 0 = Inactive
  DateTime? lastLoggedIn;

  AdminsModel(
    this.id,
    this.firstName,
    this.lastName,
    this.username,
    this.email,
    this.role,
    this.clientId,
    this.clientName,
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
    id = json['id']?.toString();
    firstName = json['first_name'] ?? json['firstName'];
    lastName = json['last_name'] ?? json['lastName'];
    username = json['username'];
    email = json['email'];
    role = json['role'];
    clientId = json['client_id'] ?? json['clientId'];
    clientName =
        json['client_name'] ??
        json['clientName'] ??
        (json['client'] != null ? json['client']['name'] : null);
    status = json['status'] ?? 1;
    lastLoggedIn =
        json["last_logged_in"] == null ||
            json["last_logged_in"] == "null" ||
            json["last_logged_in"].toString().isEmpty
        ? null
        : DateTime.tryParse(json["last_logged_in"].toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'role': role,
      'client_id': clientId,
      'client_name': clientName,
      'status': status,
      'last_logged_in': lastLoggedIn?.toIso8601String(),
    };
  }
}
