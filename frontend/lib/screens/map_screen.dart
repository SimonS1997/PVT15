import 'dart:async';

import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../managers/saved_events_manager.dart';
import '../models/event_location.dart';
import '../services/event_api_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'event_map_view.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final EventApiService _service = EventApiService(
    baseUrl: 'http://10.0.2.2:8082',
  );

  List<EventLocation> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(SavedEventsManager.instance.init());
    unawaited(_loadEvents());
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService.instance.validAccessToken();
      final events = await _service.fetchEvents(accessToken: token);
      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Kunde inte hämta events: $e';
      });
    }
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/plan');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12001F),
      body: EventMapView(
        events: _events,
        isLoading: _isLoading,
        error: _error,
        onRetry: _loadEvents,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: _onBottomNavTap,
      ),
    );
  }
}
