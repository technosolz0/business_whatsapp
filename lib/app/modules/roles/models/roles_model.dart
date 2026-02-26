class RolesModel {
  String? id;
  String? roleName;
  String? clientId;
  String? clientName;
  List<AssignedPages>? assignedPages;
  int? status; // 1 = Active, 0 = Inactive

  RolesModel({
    this.id,
    this.roleName,
    this.clientId,
    this.clientName,
    this.assignedPages,
    this.status,
  });

  RolesModel.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    roleName = json['role_name'] ?? json['roleName'] ?? json['name'];
    clientId = json['client_id'] ?? json['clientId'];
    clientName =
        json['client_name'] ??
        json['clientName'] ??
        (json['client'] != null ? json['client']['name'] : null);
    status = json['status'] ?? 1; // Default to active
    assignedPages = json['assigned_pages'] == null
        ? []
        : (json['assigned_pages'] as List)
              .map((e) => AssignedPages.fromJson(e))
              .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_name': roleName,
      'client_id': clientId,
      'client_name': clientName,
      'status': status,
      'assigned_pages': assignedPages == null
          ? []
          : assignedPages!.map((e) => e.toJson()).toList(),
    };
  }
}

class AssignedPages {
  int? ax;
  String? route;
  String? routeName;

  AssignedPages({this.ax, this.route, this.routeName});

  AssignedPages.fromJson(Map<String, dynamic> json) {
    ax = int.parse(json['ax'].toString());
    route = json['route'];
    routeName = json['name'];
  }

  Map<String, dynamic> toJson() {
    return {'ax': ax, 'route': route, 'name': routeName};
  }
}
