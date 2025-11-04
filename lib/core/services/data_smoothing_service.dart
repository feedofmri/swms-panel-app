import '../models/sensor_data.dart';

/// Service for smoothing sensor data to handle temporary dropouts from low-power sensors
class DataSmoothingService {
  // Configuration for dropout detection and smoothing - Made more conservative
  static const Duration _validReadingWindow = Duration(seconds: 10); // Increased from 5
  static const double _dropoutThreshold = 3.0; // Reduced from 5.0 - more sensitive to dropouts
  static const int _maxConsecutiveDropouts = 5; // Increased from 3 - more tolerance
  static const double _maxChangePercentage = 15.0; // Reduced from 50% - less tolerance for sudden changes
  static const double _minChangeThreshold = 2.0; // New: ignore changes smaller than 2 units

  // Storage for last known good values
  SensorData? _lastValidReading;
  DateTime? _lastValidTimestamp;

  // Counters for consecutive dropouts per sensor
  final Map<String, int> _consecutiveDropouts = {};

  // Moving averages for trend analysis - Increased window
  final Map<String, List<double>> _recentReadings = {};
  static const int _trendWindowSize = 8; // Increased from 5 for more stability

  /// Process incoming sensor data and return smoothed/filtered data
  SensorData processSensorData(SensorData newData) {
    final now = DateTime.now();

    // If we don't have a previous reading, accept this one as baseline
    if (_lastValidReading == null) {
      _lastValidReading = newData;
      _lastValidTimestamp = now;
      _updateTrendData(newData);
      return newData;
    }

    // Check if too much time has passed since last valid reading
    if (_lastValidTimestamp != null &&
        now.difference(_lastValidTimestamp!) > _validReadingWindow) {
      // Accept new reading after timeout, but validate it's reasonable
      if (_isReadingReasonable(newData)) {
        _lastValidReading = newData;
        _lastValidTimestamp = now;
        _resetDropoutCounters();
        _updateTrendData(newData);
        return newData;
      }
    }

    // Create filtered data starting with the new reading
    SensorData filteredData = _createFilteredData(newData);

    // Update last valid reading if the filtered data is good
    if (_isReadingValid(filteredData)) {
      _lastValidReading = filteredData;
      _lastValidTimestamp = now;
      _resetDropoutCounters();
      _updateTrendData(filteredData);
    }

    return filteredData;
  }

  /// Create filtered sensor data by validating each field
  SensorData _createFilteredData(SensorData newData) {
    return SensorData(
      reservoirLevel: _filterSensorValue(
        'reservoir',
        newData.reservoirLevel,
        _lastValidReading?.reservoirLevel ?? 0,
      ),
      houseTankLevel: _filterSensorValue(
        'house_tank',
        newData.houseTankLevel,
        _lastValidReading?.houseTankLevel ?? 0,
      ),
      optionalTankLevel: _filterSensorValue(
        'optional_tank',
        newData.optionalTankLevel,
        _lastValidReading?.optionalTankLevel ?? 0,
      ),
      turbidity: _filterSensorValue(
        'turbidity',
        newData.turbidity,
        _lastValidReading?.turbidity ?? 0,
      ),
      battery: _filterSensorValue(
        'battery',
        newData.battery,
        _lastValidReading?.battery ?? 0,
      ),
      filterTank: newData.filterTank,
      pump1Status: newData.pump1Status,
      pump2Status: newData.pump2Status,
      pump3Status: newData.pump3Status,
      alert: newData.alert,
      timestamp: newData.timestamp,
    );
  }

  /// Filter individual sensor values
  double _filterSensorValue(String sensorName, double newValue, double lastValue) {
    // Ignore very small changes (noise reduction)
    if ((newValue - lastValue).abs() < _minChangeThreshold) {
      return lastValue; // Keep the previous value for small fluctuations
    }

    // Check for obvious dropout (value too low)
    if (newValue < _dropoutThreshold && lastValue > _dropoutThreshold) {
      _incrementDropoutCounter(sensorName);

      // If we've had too many consecutive dropouts, gradually decrease
      if (_getDropoutCount(sensorName) > _maxConsecutiveDropouts) {
        return _getSmoothedValue(sensorName, newValue, lastValue);
      }

      // Otherwise, maintain last valid value
      return lastValue;
    }

    // Check for unreasonable jumps
    if (lastValue > 0 && _isUnreasonableChange(newValue, lastValue)) {
      _incrementDropoutCounter(sensorName);

      // Return heavily smoothed transition instead of abrupt change
      return _getHeavilySmoothedValue(sensorName, newValue, lastValue);
    }

    // For all valid changes, still apply light smoothing to reduce noise
    final smoothedValue = _applyLightSmoothing(sensorName, newValue, lastValue);

    // Value seems valid, reset dropout counter
    _resetDropoutCounter(sensorName);
    return smoothedValue;
  }

  /// Check if the change between readings is unreasonably large
  bool _isUnreasonableChange(double newValue, double oldValue) {
    if (oldValue == 0) return false; // No baseline to compare

    final changePercentage = ((newValue - oldValue).abs() / oldValue) * 100;
    return changePercentage > _maxChangePercentage;
  }

  /// Get smoothed value using simple moving average or interpolation
  double _getSmoothedValue(String sensorName, double newValue, double lastValue) {
    final recentReadings = _recentReadings[sensorName] ?? [];

    if (recentReadings.isNotEmpty) {
      // Use moving average of recent valid readings
      final sum = recentReadings.reduce((a, b) => a + b);
      final average = sum / recentReadings.length;

      // Weighted blend: 70% recent average, 30% new reading
      return (average * 0.7) + (newValue * 0.3);
    }

    // Fallback: simple interpolation between last and new
    return (lastValue * 0.8) + (newValue * 0.2);
  }

  /// Get heavily smoothed value for large transitions
  double _getHeavilySmoothedValue(String sensorName, double newValue, double lastValue) {
    final recentReadings = _recentReadings[sensorName] ?? [];

    if (recentReadings.isNotEmpty) {
      // Use moving average of recent valid readings
      final sum = recentReadings.reduce((a, b) => a + b);
      final average = sum / recentReadings.length;

      // Weighted blend: 90% recent average, 10% new reading (more damping)
      return (average * 0.9) + (newValue * 0.1);
    }

    // Fallback: simple interpolation between last and new
    return (lastValue * 0.8) + (newValue * 0.2);
  }

  /// Apply light smoothing to reduce noise for valid changes
  double _applyLightSmoothing(String sensorName, double newValue, double lastValue) {
    final recentReadings = _recentReadings[sensorName] ?? [];

    if (recentReadings.isNotEmpty) {
      // Use moving average of recent valid readings
      final sum = recentReadings.reduce((a, b) => a + b);
      final average = sum / recentReadings.length;

      // Weighted blend: 80% recent average, 20% new reading
      return (average * 0.8) + (newValue * 0.2);
    }

    // Fallback: no smoothing if no recent data
    return newValue;
  }

  /// Check if overall reading is reasonable
  bool _isReadingReasonable(SensorData data) {
    // Basic sanity checks
    if (data.reservoirLevel < 0 || data.reservoirLevel > 100) return false;
    if (data.houseTankLevel < 0 || data.houseTankLevel > 100) return false;
    if (data.optionalTankLevel < 0 || data.optionalTankLevel > 100) return false;
    if (data.turbidity < 0) return false;
    if (data.battery < 0 || data.battery > 15) return false; // Assuming 12V system

    return true;
  }

  /// Check if reading is valid (not a dropout)
  bool _isReadingValid(SensorData data) {
    return data.reservoirLevel >= _dropoutThreshold ||
           data.houseTankLevel >= _dropoutThreshold ||
           data.optionalTankLevel >= _dropoutThreshold;
  }

  /// Update trend data for moving average calculations
  void _updateTrendData(SensorData data) {
    _addToTrendWindow('reservoir', data.reservoirLevel);
    _addToTrendWindow('house_tank', data.houseTankLevel);
    _addToTrendWindow('optional_tank', data.optionalTankLevel);
    _addToTrendWindow('turbidity', data.turbidity);
    _addToTrendWindow('battery', data.battery);
  }

  /// Add value to trend window (sliding window)
  void _addToTrendWindow(String sensor, double value) {
    _recentReadings[sensor] ??= [];
    _recentReadings[sensor]!.add(value);

    // Keep only recent readings
    if (_recentReadings[sensor]!.length > _trendWindowSize) {
      _recentReadings[sensor]!.removeAt(0);
    }
  }

  /// Increment dropout counter for specific sensor
  void _incrementDropoutCounter(String sensorName) {
    _consecutiveDropouts[sensorName] = (_consecutiveDropouts[sensorName] ?? 0) + 1;
  }

  /// Reset dropout counter for specific sensor
  void _resetDropoutCounter(String sensorName) {
    _consecutiveDropouts[sensorName] = 0;
  }

  /// Reset all dropout counters
  void _resetDropoutCounters() {
    _consecutiveDropouts.clear();
  }

  /// Get current dropout count for sensor
  int _getDropoutCount(String sensorName) {
    return _consecutiveDropouts[sensorName] ?? 0;
  }

  /// Get the last valid reading
  SensorData? get lastValidReading => _lastValidReading;

  /// Reset the service (useful for reconnection scenarios)
  void reset() {
    _lastValidReading = null;
    _lastValidTimestamp = null;
    _consecutiveDropouts.clear();
    _recentReadings.clear();
  }
}
