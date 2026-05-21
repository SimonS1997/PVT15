import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/event_location.dart';
import '../services/event_api_service.dart';
import '../services/plan_api_service.dart';
import '../auth_service.dart';

class SavedEventsManager extends ChangeNotifier {
  SavedEventsManager._();
  static final SavedEventsManager instance = SavedEventsManager._();

  final PlanApiService _planApi = PlanApiService(
    baseUrl: 'http://10.0.2.2:8084',
  );
  final EventApiService _eventApi = EventApiService(
    baseUrl: 'http://10.0.2.2:8082',
  );

  List<int> _savedEventIds = [];
  List<EventLocation> _savedEventDetails = [];
  bool _isLoading = false;
  bool _hasInitialized = false;

  List<int> get savedEventIds => _savedEventIds;
  bool get isLoading => _isLoading;

  List<EventLocation> get savedEvents {
    final eventsById = {
      for (final event in _savedEventDetails) event.id: event,
    };
    return [
      for (final id in _savedEventIds)
        if (eventsById[id] != null) eventsById[id]!,
    ];
  }

  bool isSaved(int eventId) => _savedEventIds.contains(eventId);

  Future<void> init({bool forceRefresh = false}) async {
    if (_isLoading || (_hasInitialized && !forceRefresh)) return;
    _isLoading = true;
    notifyListeners();

    try {
      final token = await AuthService.instance.validAccessToken();
      if (token == null) {
        _hasInitialized = true;
        return;
      }

      final prefs = await _planApi.fetchAll(token);
      _savedEventIds = _parseSavedEventIds(prefs['saved_events']);

      _savedEventDetails = _savedEventIds.isEmpty
          ? []
          : await _eventApi.fetchEvents(
              accessToken: token,
              ids: _savedEventIds,
            );

      _hasInitialized = true;
    } catch (e) {
      // TODO: show a non-blocking sync error in the UI.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleSave(int eventId) async {
    final wasSaved = _savedEventIds.contains(eventId);
    if (wasSaved) {
      _savedEventIds.remove(eventId);
      _savedEventDetails.removeWhere((event) => event.id == eventId);
    } else {
      _savedEventIds.add(eventId);
    }
    notifyListeners();

    try {
      final token = await AuthService.instance.validAccessToken();
      if (token != null) {
        await _planApi.put(token, 'saved_events', _savedEventIds);
        if (!wasSaved &&
            !_savedEventDetails.any((event) => event.id == eventId)) {
          final event = await _eventApi.fetchById(eventId, accessToken: token);
          if (event != null) {
            _savedEventDetails.add(event);
            notifyListeners();
          }
        }
      }
    } catch (e) {
      // TODO: restore local state if the save request fails.
    }
  }

  void clear() {
    _savedEventIds = [];
    _savedEventDetails = [];
    _hasInitialized = false;
    notifyListeners();
  }

  List<int> _parseSavedEventIds(dynamic savedData) {
    final dynamic decoded = savedData is String
        ? jsonDecode(savedData)
        : savedData;
    if (decoded is! List) return [];

    return decoded
        .map((value) {
          if (value is int) return value;
          if (value is num) return value.toInt();
          if (value is String) return int.tryParse(value);
          return null;
        })
        .whereType<int>()
        .toList();
  }
}
