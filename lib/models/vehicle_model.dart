class BusVehicle {
  final String id;
  final String busNumber; // e.g. 'KA06F8558'
  final String model;
  final int capacity;
  final String depotName;
  final String status; // 'ACTIVE', 'MAINTENANCE', 'OUT_OF_SERVICE'
  final bool isActive;

  const BusVehicle({
    required this.id,
    required this.busNumber,
    this.model = 'Tata Starbus Ultra EV',
    this.capacity = 42,
    this.depotName = 'Tumakuru Central City Depot #1 (Ashoka Road)',
    this.status = 'ACTIVE',
    this.isActive = true,
  });

  factory BusVehicle.fromJson(Map<String, dynamic> json) {
    return BusVehicle(
      id: json['id']?.toString() ?? '',
      busNumber: json['bus_number']?.toString() ?? json['busNumber']?.toString() ?? '',
      model: json['model']?.toString() ?? 'Tata Starbus Ultra EV',
      capacity: (json['capacity'] as num?)?.toInt() ?? 42,
      depotName: json['depot_name']?.toString() ?? json['depotName']?.toString() ?? 'Tumakuru Central Depot #1',
      status: json['status']?.toString() ?? 'ACTIVE',
      isActive: json['is_active'] as bool? ?? (json['status'] == 'ACTIVE'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bus_number': busNumber,
        'model': model,
        'capacity': capacity,
        'depot_name': depotName,
        'status': status,
        'is_active': isActive,
      };
}
