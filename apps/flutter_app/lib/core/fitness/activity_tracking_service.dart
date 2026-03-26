import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fitness_models.dart';
import 'health_connect_service.dart';

class ActivityTrackingService {
  ActivityTrackingService._();

  static final ActivityTrackingService instance = ActivityTrackingService._();
  static const MethodChannel _motionChannel = MethodChannel(
    'com.velorastudios.earndash/motion_tracking',
  );

  static const String _currentDayKey = 'fitness.current_day';
  static const String _baselineStepKey = 'fitness.baseline_steps';
  static const String _todayStepsKey = 'fitness.today_steps';
  static const String _walkMinutesKey = 'fitness.walk_minutes';
  static const String _runMinutesKey = 'fitness.run_minutes';
  static const String _activeMinutesKey = 'fitness.active_minutes';
  static const String _statusKey = 'fitness.status';
  static const String _lastActivityTypeKey = 'fitness.last_activity_type';
  static const String _lastActivityAtKey = 'fitness.last_activity_at';
  static const String _rawStepsKey = 'fitness.raw_steps';
  static const String _historyKey = 'fitness.history';
  static const String _messageKey = 'fitness.message';

  final StreamController<DeviceActivitySnapshot> _controller =
      StreamController<DeviceActivitySnapshot>.broadcast();
  final HealthConnectService _healthConnectService = HealthConnectService();

  SharedPreferences? _prefs;
  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;
  StreamSubscription<Activity>? _activitySubscription;
  bool _initialized = false;
  bool _supported = true;
  bool _permissionGranted = false;

  Future<DeviceActivitySnapshot> initialize() async {
    if (_initialized) {
      return getSnapshot();
    }

    _prefs = await SharedPreferences.getInstance();
    await _rolloverIfNeeded();

    if (kIsWeb) {
      _supported = false;
      await _writeMessage(
        'Move & Earn works on Android and iPhone devices, not on web.',
      );
      _initialized = true;
      return getSnapshot();
    }

    _permissionGranted = await _ensurePermission();
    if (!_permissionGranted) {
      _initialized = true;
      return getSnapshot();
    }

    _stepSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (Object error, StackTrace stackTrace) {
        _supported = false;
        unawaited(_writeMessage('Step sensor unavailable on this device.'));
        unawaited(_emitSnapshot());
      },
    );

    _statusSubscription = Pedometer.pedestrianStatusStream.listen(
      _onPedestrianStatus,
      onError: (Object error, StackTrace stackTrace) {
        unawaited(
          _writeMessage('Pedestrian status is not available on this device.'),
        );
        unawaited(_emitSnapshot());
      },
    );

    _activitySubscription =
        FlutterActivityRecognition.instance.activityStream.listen(
      _onActivity,
      onError: (Object error, StackTrace stackTrace) {
        unawaited(
          _writeMessage('Live activity classification is unavailable right now.'),
        );
        unawaited(_emitSnapshot());
      },
    );

    if (Platform.isAndroid) {
      await _startAndroidForegroundTracking();
    }

    _initialized = true;
    await _emitSnapshot();
    return getSnapshot();
  }

  Future<DeviceActivitySnapshot> refresh() async {
    await initialize();
    await _rolloverIfNeeded();
    if (Platform.isAndroid && _permissionGranted) {
      await _startAndroidForegroundTracking();
    }
    return getSnapshot();
  }

  Future<DeviceActivitySnapshot> getSnapshot() async {
    if (!_initialized) {
      return initialize();
    }

    final prefs = _prefs!;
    final todayDateKey =
        prefs.getString(_currentDayKey) ?? _dateKey(DateTime.now());
    final localTodaySteps = prefs.getInt(_todayStepsKey) ?? 0;
    final localWalkMinutes = prefs.getInt(_walkMinutesKey) ?? 0;
    final localRunMinutes = prefs.getInt(_runMinutesKey) ?? 0;
    final localActiveMinutesStored = prefs.getInt(_activeMinutesKey) ?? 0;
    final localActiveMinutes = max(
      localActiveMinutesStored,
      (localTodaySteps / 100).round(),
    );
    final localDistanceKm = localTodaySteps * 0.00078;
    final localCalories = (localTodaySteps * 0.04).round();

    var mergedTodaySteps = localTodaySteps;
    var mergedDistanceKm = localDistanceKm;
    var mergedActiveMinutes = localActiveMinutes;
    var mergedWalkMinutes = max(
      localWalkMinutes,
      max(0, localActiveMinutes - localRunMinutes),
    );
    var mergedRunMinutes = min(localRunMinutes, localActiveMinutes);
    var mergedCalories = localCalories;
    var status = prefs.getString(_statusKey) ?? 'unknown';
    var message = prefs.getString(_messageKey);
    var supported = _supported;
    var permissionGranted = _permissionGranted;
    var source = 'device_sensor';

    var weeklyHistory = _buildWeeklyHistory(
      todayDateKey: todayDateKey,
      todaySteps: mergedTodaySteps,
      walkMinutes: mergedWalkMinutes,
      runMinutes: mergedRunMinutes,
      activeMinutes: mergedActiveMinutes,
      distanceKm: mergedDistanceKm,
      calories: mergedCalories,
    );

    if (Platform.isAndroid) {
      final foregroundSnapshot = await _readAndroidForegroundSnapshot();
      if (foregroundSnapshot != null) {
        supported = supported && foregroundSnapshot.supported;
        mergedTodaySteps = max(mergedTodaySteps, foregroundSnapshot.todaySteps);
        mergedDistanceKm = max(mergedDistanceKm, mergedTodaySteps * 0.00078);
        mergedCalories = max(mergedCalories, (mergedTodaySteps * 0.04).round());
        if (foregroundSnapshot.running && status == 'unknown') {
          status = 'tracking';
        }
        source = '$source + ${foregroundSnapshot.source}';
      }

      final healthSnapshot = await _healthConnectService.syncWeeklyHistory();
      if (healthSnapshot != null) {
        source = '$source + ${healthSnapshot.source}';
        if (healthSnapshot.available &&
            healthSnapshot.permissionsGranted &&
            healthSnapshot.weeklyHistory.isNotEmpty) {
          weeklyHistory = List<DeviceActivityDay>.from(healthSnapshot.weeklyHistory);
          mergedTodaySteps = max(mergedTodaySteps, healthSnapshot.todaySteps);
          mergedDistanceKm =
              max(mergedDistanceKm, healthSnapshot.todayDistanceKm);
          mergedActiveMinutes =
              max(mergedActiveMinutes, healthSnapshot.todayActiveMinutes);
          mergedWalkMinutes = max(mergedWalkMinutes, mergedActiveMinutes);
          mergedCalories = max(mergedCalories, healthSnapshot.todayCalories);
          permissionGranted = true;
        } else if (healthSnapshot.message != null && message == null) {
          message = healthSnapshot.message;
        }
      }
    }

    if (weeklyHistory.isNotEmpty) {
      weeklyHistory[weeklyHistory.length - 1] = DeviceActivityDay(
        dateKey: todayDateKey,
        label: weeklyHistory.last.label,
        steps: mergedTodaySteps,
        distanceKm: mergedDistanceKm,
        activeMinutes: mergedActiveMinutes,
        walkMinutes: mergedWalkMinutes,
        runMinutes: mergedRunMinutes,
        calories: mergedCalories,
      );
    }

    return DeviceActivitySnapshot(
      supported: supported,
      permissionGranted: permissionGranted,
      status: status,
      source: source,
      todayDateKey: todayDateKey,
      todaySteps: mergedTodaySteps,
      distanceKm: mergedDistanceKm,
      activeMinutes: mergedActiveMinutes,
      walkMinutes: mergedWalkMinutes,
      runMinutes: mergedRunMinutes,
      calories: mergedCalories,
      weeklyHistory: weeklyHistory,
      message: message,
    );
  }

  Stream<DeviceActivitySnapshot> watchSnapshots() async* {
    yield await initialize();
    yield* _controller.stream;
  }

  Future<void> dispose() async {
    await _stepSubscription?.cancel();
    await _statusSubscription?.cancel();
    await _activitySubscription?.cancel();
  }

  Future<bool> _ensurePermission() async {
    final recognition = FlutterActivityRecognition.instance;
    var permission = await recognition.checkPermission();
    if (permission == PermissionRequestResult.PERMANENTLY_DENIED) {
      await _writeMessage(
        'Activity permission is permanently denied. Enable motion access in system settings.',
      );
      return false;
    }
    if (permission == PermissionRequestResult.DENIED) {
      permission = await recognition.requestPermission();
    }

    final granted = permission == PermissionRequestResult.GRANTED;
    if (!granted) {
      await _writeMessage(
        'Move & Earn needs activity permission to read your real step count.',
      );
    } else {
      await _writeMessage(null);
    }
    return granted;
  }

  Future<void> _onStepCount(StepCount event) async {
    final prefs = _prefs!;
    await _rolloverIfNeeded(rawSteps: event.steps);

    var baseline = prefs.getInt(_baselineStepKey);
    baseline ??= event.steps;
    await prefs.setInt(_baselineStepKey, baseline);
    await prefs.setInt(_rawStepsKey, event.steps);

    final steps = max(0, event.steps - baseline);
    await prefs.setInt(_todayStepsKey, steps);
    await _writeMessage(null);
    await _emitSnapshot();
  }

  Future<void> _onPedestrianStatus(PedestrianStatus event) async {
    await _prefs!.setString(_statusKey, event.status.trim().toLowerCase());
    await _emitSnapshot();
  }

  Future<void> _onActivity(Activity activity) async {
    final prefs = _prefs!;
    final normalizedType = _normalizeActivityType(activity.type);
    final currentTime = DateTime.now();
    final previousTimeMillis = prefs.getInt(_lastActivityAtKey);
    final previousType = prefs.getString(_lastActivityTypeKey);

    if (previousTimeMillis != null && previousType != null) {
      final previousTime = DateTime.fromMillisecondsSinceEpoch(
        previousTimeMillis,
      );
      final deltaMinutes = currentTime.difference(previousTime).inMinutes;
      if (deltaMinutes > 0 && deltaMinutes < 240) {
        if (previousType == 'walking') {
          await prefs.setInt(
            _walkMinutesKey,
            (prefs.getInt(_walkMinutesKey) ?? 0) + deltaMinutes,
          );
          await prefs.setInt(
            _activeMinutesKey,
            (prefs.getInt(_activeMinutesKey) ?? 0) + deltaMinutes,
          );
        } else if (previousType == 'running') {
          await prefs.setInt(
            _runMinutesKey,
            (prefs.getInt(_runMinutesKey) ?? 0) + deltaMinutes,
          );
          await prefs.setInt(
            _activeMinutesKey,
            (prefs.getInt(_activeMinutesKey) ?? 0) + deltaMinutes,
          );
        }
      }
    }

    await prefs.setString(_lastActivityTypeKey, normalizedType);
    await prefs.setInt(_lastActivityAtKey, currentTime.millisecondsSinceEpoch);
    await prefs.setString(_statusKey, normalizedType);
    await _emitSnapshot();
  }

  Future<void> _rolloverIfNeeded({int? rawSteps}) async {
    final prefs = _prefs!;
    final today = _dateKey(DateTime.now());
    final stored = prefs.getString(_currentDayKey);
    if (stored == null) {
      await prefs.setString(_currentDayKey, today);
      if (rawSteps != null) {
        await prefs.setInt(_baselineStepKey, rawSteps);
        await prefs.setInt(_rawStepsKey, rawSteps);
      }
      return;
    }

    if (stored == today) {
      return;
    }

    await _archiveCurrentDay(stored);
    await prefs.setString(_currentDayKey, today);
    await prefs.setInt(_todayStepsKey, 0);
    await prefs.setInt(_walkMinutesKey, 0);
    await prefs.setInt(_runMinutesKey, 0);
    await prefs.setInt(_activeMinutesKey, 0);
    await prefs.remove(_lastActivityAtKey);
    await prefs.remove(_lastActivityTypeKey);
    await prefs.setString(_statusKey, 'unknown');
    if (rawSteps != null) {
      await prefs.setInt(_baselineStepKey, rawSteps);
      await prefs.setInt(_rawStepsKey, rawSteps);
    } else {
      await prefs.remove(_baselineStepKey);
    }
  }

  Future<void> _archiveCurrentDay(String dateKey) async {
    final prefs = _prefs!;
    final history = _readHistory();
    history.removeWhere((item) => item.dateKey == dateKey);

    final steps = prefs.getInt(_todayStepsKey) ?? 0;
    final walkMinutes = prefs.getInt(_walkMinutesKey) ?? 0;
    final runMinutes = prefs.getInt(_runMinutesKey) ?? 0;
    final activeMinutes = max(
      prefs.getInt(_activeMinutesKey) ?? 0,
      (steps / 100).round(),
    );

    history.add(
      DeviceActivityDay(
        dateKey: dateKey,
        label: _weekdayLabel(DateTime.parse(dateKey)),
        steps: steps,
        distanceKm: steps * 0.00078,
        activeMinutes: activeMinutes,
        walkMinutes: max(walkMinutes, max(0, activeMinutes - runMinutes)),
        runMinutes: min(runMinutes, activeMinutes),
        calories: (steps * 0.04).round(),
      ),
    );

    history.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    final trimmed =
        history.length > 6 ? history.sublist(history.length - 6) : history;
    await prefs.setString(
      _historyKey,
      jsonEncode(trimmed.map((item) => item.toJson()).toList()),
    );
  }

  List<DeviceActivityDay> _buildWeeklyHistory({
    required String todayDateKey,
    required int todaySteps,
    required int walkMinutes,
    required int runMinutes,
    required int activeMinutes,
    required double distanceKm,
    required int calories,
  }) {
    final archived = <String, DeviceActivityDay>{
      for (final item in _readHistory()) item.dateKey: item,
    };
    final today = DateTime.parse(todayDateKey);
    final items = <DeviceActivityDay>[];

    for (var offset = 6; offset >= 0; offset -= 1) {
      final date = today.subtract(Duration(days: offset));
      final dateKey = _dateKey(date);
      if (offset == 0) {
        items.add(
          DeviceActivityDay(
            dateKey: dateKey,
            label: _weekdayLabel(date),
            steps: todaySteps,
            distanceKm: distanceKm,
            activeMinutes: activeMinutes,
            walkMinutes: walkMinutes,
            runMinutes: runMinutes,
            calories: calories,
          ),
        );
      } else {
        items.add(
          archived[dateKey] ??
              DeviceActivityDay(
                dateKey: dateKey,
                label: _weekdayLabel(date),
                steps: 0,
                distanceKm: 0,
                activeMinutes: 0,
                walkMinutes: 0,
                runMinutes: 0,
                calories: 0,
              ),
        );
      }
    }

    return items;
  }

  List<DeviceActivityDay> _readHistory() {
    final raw = _prefs!.getString(_historyKey);
    if (raw == null || raw.isEmpty) {
      return <DeviceActivityDay>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) => DeviceActivityDay.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> _emitSnapshot() async {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(await getSnapshot());
  }

  Future<void> _writeMessage(String? value) async {
    if (value == null || value.isEmpty) {
      await _prefs?.remove(_messageKey);
      return;
    }
    await _prefs?.setString(_messageKey, value);
  }

  Future<void> _startAndroidForegroundTracking() async {
    try {
      await _motionChannel.invokeMethod<void>('startForegroundTracking');
    } on MissingPluginException {
      // Ignore on non-Android or when the channel is unavailable.
    } on PlatformException {
      // Ignore and fall back to foreground-only sensor updates.
    }
  }

  Future<_AndroidMotionSnapshot?> _readAndroidForegroundSnapshot() async {
    try {
      final raw = await _motionChannel.invokeMapMethod<String, dynamic>(
        'getTrackingSnapshot',
      );
      if (raw == null) {
        return null;
      }
      return _AndroidMotionSnapshot.fromJson(raw);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  String _normalizeActivityType(ActivityType type) {
    switch (type) {
      case ActivityType.RUNNING:
        return 'running';
      case ActivityType.WALKING:
        return 'walking';
      case ActivityType.STILL:
        return 'stopped';
      default:
        return 'unknown';
    }
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

class _AndroidMotionSnapshot {
  _AndroidMotionSnapshot({
    required this.supported,
    required this.running,
    required this.todaySteps,
    required this.source,
  });

  final bool supported;
  final bool running;
  final int todaySteps;
  final String source;

  factory _AndroidMotionSnapshot.fromJson(Map<String, dynamic> json) {
    return _AndroidMotionSnapshot(
      supported: json['supported'] as bool? ?? true,
      running: json['running'] as bool? ?? false,
      todaySteps: json['todaySteps'] as int? ?? 0,
      source: json['source'] as String? ?? 'android_foreground_service',
    );
  }
}
