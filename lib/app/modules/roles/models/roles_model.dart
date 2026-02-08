class RolesModel {
  String? id;
  String? roleName;
  List<AssignedPages>? assignedPages;
  int? status; // 1 = Active, 0 = Inactive

  RolesModel({this.id, this.roleName, this.assignedPages, this.status});

  RolesModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    roleName = json['role_name'];
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
