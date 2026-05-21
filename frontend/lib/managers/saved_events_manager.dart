import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/event_location.dart';
import '../services/event_api_service.dart';
import '../services/plan_api_service.dart';
import '../auth_service.dart';

class SavedEventsManager extends ChangeNotifier {
  SavedEventsManager._();
  static final SavedEventsManager instance = SavedEventsManager._();

  final PlanApiService _planApi = PlanApiService(baseUrl: 'http://10.0.2.2:8084');
  final EventApiService _eventApi = EventApiService(baseUrl: 'http://10.0.2.2:8082');

  List<int> _savedEventIds = [];
  List<EventLocation> _allEvents = [];
  bool _isLoading = false;

  List<int> get savedEventIds => _savedEventIds;
  bool get isLoading => _isLoading;

  List<EventLocation> get savedEvents {
    return _allEvents.where((e) => _savedEventIds.contains(e.id)).toList();
  }

  bool isSaved(int eventId) => _savedEventIds.contains(eventId);

  Future<void> init() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final token = await AuthService.instance.validAccessToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Hämta alla events för att kunna visa detaljer i "Min plan"
      _allEvents = await _eventApi.fetchEvents(accessToken: token);

      // Hämta sparade IDs från backend
      final prefs = await _planApi.fetchAll(token);

      if (prefs.containsKey('saved_events')) {
        final savedData = prefs['saved_events'];
        if (savedData is List) {
          _savedEventIds = savedData.map((e) => e as int).toList();
        } else if (savedData is String) {
          final decoded = jsonDecode(savedData) as List<dynamic>;
          _savedEventIds = decoded.map((e) => e as int).toList();
        }
      }
    } catch (e) {
      // Logga fel internt eller via ett dedikerat loggningssystem om tillgängligt
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleSave(int eventId) async {
    if (_savedEventIds.contains(eventId)) {
      _savedEventIds.remove(eventId);
    } else {
      _savedEventIds.add(eventId);
    }
    notifyListeners();

    try {
      final token = await AuthService.instance.validAccessToken();
      if (token != null) {
        await _planApi.put(token, 'saved_events', _savedEventIds);
      }
    } catch (e) {
      // Hantera ev. nätverksfel här
    }
  }

  void clear() {
    _savedEventIds = [];
    _allEvents = [];
    notifyListeners();
  }
}
