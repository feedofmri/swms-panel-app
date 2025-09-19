 /// Core model for sensor data received from ESP8266
class SensorData {
  final double reservoirLevel;
  final double houseTankLevel;
  final String filterTank;
  final double turbidity;
  final String pump1Status;
  final String pump2Status;
  final double battery;
  final String? alert;
  final DateTime timestamp;

  SensorData({
    required this.reservoirLevel,
    required this.houseTankLevel,
    required this.filterTank,
    required this.turbidity,
    required this.pump1Status,
    required this.pump2Status,
    required this.battery,
    this.alert,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Factory constructor to create SensorData from JSON
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      reservoirLevel: (json['reservoir_level'] ?? 0).toDouble(),
      houseTankLevel: (json['house_tank_level'] ?? 0).toDouble(),
      filterTank: json['filter_tank'] ?? 'unknown',
      turbidity: (json['turbidity'] ?? 0).toDouble(),
      pump1Status: json['pump1'] ?? 'OFF',
      pump2Status: json['pump2'] ?? 'OFF',
      battery: (json['battery'] ?? 0).toDouble(),
      alert: json['alert'],
    );
  }

  /// Convert SensorData to JSON
  Map<String, dynamic> toJson() {
    return {
      'reservoir_level': reservoirLevel,
      'house_tank_level': houseTankLevel,
      'filter_tank': filterTank,
      'turbidity': turbidity,
      'pump1': pump1Status,
      'pump2': pump2Status,
      'battery': battery,
      'alert': alert,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create a copy with updated values
  SensorData copyWith({
    double? reservoirLevel,
    double? houseTankLevel,
    String? filterTank,
    double? turbidity,
    String? pump1Status,
    String? pump2Status,
    double? battery,
    String? alert,
    DateTime? timestamp,
  }) {
    return SensorData(
      reservoirLevel: reservoirLevel ?? this.reservoirLevel,
      houseTankLevel: houseTankLevel ?? this.houseTankLevel,
      filterTank: filterTank ?? this.filterTank,
      turbidity: turbidity ?? this.turbidity,
      pump1Status: pump1Status ?? this.pump1Status,
      pump2Status: pump2Status ?? this.pump2Status,
      battery: battery ?? this.battery,
      alert: alert ?? this.alert,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Check if turbidity is in good range
  bool get isTurbidityGood => turbidity <= 10;

  /// Check if any pump is currently running
  bool get isAnyPumpRunning => pump1Status == 'ON' || pump2Status == 'ON';

  /// Check if filter tank is wet
  bool get isFilterWet => filterTank.toLowerCase() == 'wet';

  @override
  String toString() {
    return 'SensorData(reservoir: $reservoirLevel%, house: $houseTankLevel%, filter: $filterTank, turbidity: $turbidity, pump1: $pump1Status, pump2: $pump2Status, battery: ${battery}V, alert: $alert)';
  }
}
