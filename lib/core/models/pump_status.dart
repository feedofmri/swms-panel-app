/// Model for pump status and control
class PumpStatus {
  final String pumpId;
  final bool isOn;
  final DateTime lastToggled;

  PumpStatus({
    required this.pumpId,
    required this.isOn,
    DateTime? lastToggled,
  }) : lastToggled = lastToggled ?? DateTime.now();

  /// Create a copy with updated status
  PumpStatus copyWith({
    String? pumpId,
    bool? isOn,
    DateTime? lastToggled,
  }) {
    return PumpStatus(
      pumpId: pumpId ?? this.pumpId,
      isOn: isOn ?? this.isOn,
      lastToggled: lastToggled ?? this.lastToggled,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'pumpId': pumpId,
      'isOn': isOn,
      'lastToggled': lastToggled.toIso8601String(),
    };
  }

  /// Create from JSON
  factory PumpStatus.fromJson(Map<String, dynamic> json) {
    return PumpStatus(
      pumpId: json['pumpId'],
      isOn: json['isOn'],
      lastToggled: DateTime.parse(json['lastToggled']),
    );
  }

  @override
  String toString() {
    return 'PumpStatus(id: $pumpId, isOn: $isOn, lastToggled: $lastToggled)';
  }
}
