import '../../../core/models/pump_status.dart';

/// Controls-specific model for pump and system controls
class ControlsModel {
  final PumpStatus pump1Status;
  final PumpStatus pump2Status;
  final bool isConnected;
  final bool isBuzzerActive;
  final DateTime? lastCommandSent;
  final String? lastCommandResult;

  ControlsModel({
    required this.pump1Status,
    required this.pump2Status,
    this.isConnected = false,
    this.isBuzzerActive = false,
    this.lastCommandSent,
    this.lastCommandResult,
  });

  /// Create a copy with updated values
  ControlsModel copyWith({
    PumpStatus? pump1Status,
    PumpStatus? pump2Status,
    bool? isConnected,
    bool? isBuzzerActive,
    DateTime? lastCommandSent,
    String? lastCommandResult,
  }) {
    return ControlsModel(
      pump1Status: pump1Status ?? this.pump1Status,
      pump2Status: pump2Status ?? this.pump2Status,
      isConnected: isConnected ?? this.isConnected,
      isBuzzerActive: isBuzzerActive ?? this.isBuzzerActive,
      lastCommandSent: lastCommandSent ?? this.lastCommandSent,
      lastCommandResult: lastCommandResult ?? this.lastCommandResult,
    );
  }

  /// Check if any pump is currently running
  bool get isAnyPumpRunning => pump1Status.isOn || pump2Status.isOn;

  /// Check if both pumps are running
  bool get areBothPumpsRunning => pump1Status.isOn && pump2Status.isOn;

  /// Get total number of running pumps
  int get runningPumpsCount {
    int count = 0;
    if (pump1Status.isOn) count++;
    if (pump2Status.isOn) count++;
    return count;
  }

  /// Check if commands can be sent (connected and not waiting for response)
  bool get canSendCommands {
    if (!isConnected) return false;
    if (lastCommandSent == null) return true;

    // Allow new commands after 2 seconds
    final timeSinceLastCommand = DateTime.now().difference(lastCommandSent!);
    return timeSinceLastCommand.inSeconds >= 2;
  }

  /// Get status summary
  String get statusSummary {
    if (!isConnected) return 'Disconnected';
    if (runningPumpsCount == 0) return 'All pumps stopped';
    if (runningPumpsCount == 1) return '1 pump running';
    return '$runningPumpsCount pumps running';
  }
}
