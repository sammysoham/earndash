import 'dart:io';
import 'package:health/health.dart';
import '../models/fitness_models.dart';

class HealthConnectSyncResult {
  HealthConnectSyncResult({
    required this.available,
    required this.permissionsGranted,
    required this.source,
    required this.weeklyHistory,
    this.message,
  });

  final bool available;
  final bool permissionsGranted;
  final String source;
  final String? message;
  final List<DeviceActivityDay> weeklyHistory;

  int get todaySteps => weeklyHistory.isEmpty ? 0 : weeklyHistory.last.steps;
  double get todayDistanceKm =>
      weeklyHistory.isEmpty ? 0 : weeklyHistory.last.distanceKm;
  int get todayActiveMinutes =>
      weeklyHistory.isEmpty ? 0 : weeklyHistory.last.activeMinutes;
  int get todayCalories => weeklyHistory.isEmpty ? 0 : weeklyHistory.last.calories;
}

class HealthConnectService {
  final Health _health = Health();
  bool _configured = false;

  Future<HealthConnectSyncResult?> syncWeeklyHistory() async {
    if (!Platform.isAndroid) {
      return null;
    }

    await _ensureConfigured();

    if (!await _health.isHealthConnectAvailable()) {
      return HealthConnectSyncResult(
        available: false,
        permissionsGranted: false,
        source: 'health_connect',
        message: 'Install Health Connect for more accurate movement history.',
        weeklyHistory: <DeviceActivityDay>[],
      );
    }

    final types = <HealthDataType>[
      HealthDataType.STEPS,
      HealthDataType.DISTANCE_WALKING_RUNNING,
      HealthDataType.EXERCISE_TIME,
      HealthDataType.ACTIVE_ENERGY_BURNED,
    ];
    final permissions = List<HealthDataAccess>.filled(
      types.length,
      HealthDataAccess.READ,
    );

    final hasPermissions =
        await _health.hasPermissions(types, permissions: permissions) ?? false;
    final isAuthorized = hasPermissions ||
        await _health.requestAuthorization(types, permissions: permissions);
    if (!isAuthorized) {
      return HealthConnectSyncResult(
        available: true,
        permissionsGranted: false,
        source: 'health_connect',
        message: 'Health Connect access was not granted.',
        weeklyHistory: <DeviceActivityDay>[],
      );
    }

    if (await _health.isHealthDataHistoryAvailable() &&
        !await _health.isHealthDataHistoryAuthorized()) {
      await _health.requestHealthDataHistoryAuthorization();
    }

    final today = DateTime.now();
    final weeklyHistory = <DeviceActivityDay>[];

    for (var offset = 6; offset >= 0; offset -= 1) {
      final date = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: offset));
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));

      final steps =
          await _health.getTotalStepsInInterval(start, end, includeManualEntry: false) ?? 0;
      final points = await _health.getHealthDataFromTypes(
        types: <HealthDataType>[
          HealthDataType.DISTANCE_WALKING_RUNNING,
          HealthDataType.EXERCISE_TIME,
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ],
        startTime: start,
        endTime: end,
        recordingMethodsToFilter: const <RecordingMethod>[RecordingMethod.manual],
      );

      double distanceMeters = 0;
      int exerciseMinutes = 0;
      int calories = 0;

      for (final point in points) {
        final value = point.value;
        if (value is! NumericHealthValue) {
          continue;
        }

        switch (point.type) {
          case HealthDataType.DISTANCE_WALKING_RUNNING:
            distanceMeters += value.numericValue.toDouble();
            break;
          case HealthDataType.EXERCISE_TIME:
            exerciseMinutes += value.numericValue.round();
            break;
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            calories += value.numericValue.round();
            break;
          default:
            break;
        }
      }

      final activeMinutes = exerciseMinutes > 0
          ? exerciseMinutes
          : (steps / 100).round();
      weeklyHistory.add(
        DeviceActivityDay(
          dateKey: _dateKey(start),
          label: _weekdayLabel(start),
          steps: steps,
          distanceKm: distanceMeters / 1000,
          activeMinutes: activeMinutes,
          walkMinutes: activeMinutes,
          runMinutes: 0,
          calories: calories > 0 ? calories : (steps * 0.04).round(),
        ),
      );
    }

    return HealthConnectSyncResult(
      available: true,
      permissionsGranted: true,
      source: 'health_connect',
      weeklyHistory: weeklyHistory,
    );
  }

  Future<void> _ensureConfigured() async {
    if (_configured) {
      return;
    }
    await _health.configure();
    _configured = true;
  }

  String _dateKey(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _weekdayLabel(DateTime value) {
    const labels = <int, String>{
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };
    return labels[value.weekday] ?? 'Day';
  }
}
