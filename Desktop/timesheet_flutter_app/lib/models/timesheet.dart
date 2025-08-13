class Timesheet {
  final int id;
  final int siteId;
  final int planningId;
  final int timesheetTypeId;
  final String uniqueCode;
  final String? details;
  final DateTime createdAt;
  final String? status;

  Timesheet({
    required this.id,
    required this.siteId,
    required this.planningId,
    required this.timesheetTypeId,
    required this.uniqueCode,
    this.details,
    required this.createdAt,
    this.status,
  });

  factory Timesheet.fromJson(Map<String, dynamic> json) {
    return Timesheet(
      id: json['id'] ?? 0,
      siteId: json['site_id'] ?? 0,
      planningId: json['planning_id'] ?? 0,
      timesheetTypeId: json['timesheet_type_id'] ?? 0,
      uniqueCode: json['unique_code'] ?? '',
      details: json['details'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'planning_id': planningId,
      'timesheet_type_id': timesheetTypeId,
      'unique_code': uniqueCode,
      'details': details,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }

  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
           createdAt.month == now.month &&
           createdAt.day == now.day;
  }

  @override
  String toString() {
    return 'Timesheet(id: $id, code: $uniqueCode, date: $formattedDate)';
  }
}
