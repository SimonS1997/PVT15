import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../auth_service.dart';
import '../models/event_location.dart';
import '../services/event_api_service.dart';
import '../utils/category_labels.dart';
import '../widgets/bottom_nav_bar.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final EventApiService _api =
  EventApiService(baseUrl: 'http://10.0.2.2:8082');

  List<_EventWithDistance> _events = [];
  bool _loading = true;
  String? _error;
  bool _isLocationError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _isLocationError = false;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _loading = false;
          _error = 'Aktivera platstjänster i enhetsinställningarna';
          _isLocationError = true;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _loading = false;
          _error = 'Tillåt platsåtkomst för att se nära event';
          _isLocationError = true;
        });
        return;
      }

      final results = await Future.wait([
        Geolocator.getCurrentPosition(),
        AuthService.instance
            .validAccessToken()
            .then((token) => _api.fetchEvents(accessToken: token)),
      ]);

      final position = results[0] as Position;
      final allEvents = results[1] as List<EventLocation>;

      final withDistance = allEvents.map((e) {
        final distanceM = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          e.latitude,
          e.longitude,
        );
        return _EventWithDistance(event: e, distanceM: distanceM);
      }).toList()
        ..sort((a, b) => a.distanceM.compareTo(b.distanceM));

      if (!mounted) return;
      setState(() {
        _events = withDistance.take(10).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Kunde inte hämta event: $e';
      });
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nära mig',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              if (!_loading && _error == null)
                Text(
                  'Din position hittad · Visar ${_events.length} närmaste',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFAE8ACF),
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/map');
              break;
            case 2:
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/plan');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFEC34F8)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLocationError)
              const Icon(
                Icons.location_off,
                color: Color(0xFFAE8ACF),
                size: 48,
              ),
            if (_isLocationError) const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFAE8ACF)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_events.isEmpty) {
      return const Center(
        child: Text(
          'Inga event hittades',
          style: TextStyle(color: Color(0xFFAE8ACF)),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final item = _events[index];
        return _NearbyEventCard(
          event: item.event,
          distance: _formatDistance(item.distanceM),
        );
      },
    );
  }
}

class _EventWithDistance {
  const _EventWithDistance({
    required this.event,
    required this.distanceM,
  });

  final EventLocation event;
  final double distanceM;
}

class _NearbyEventCard extends StatelessWidget {
  const _NearbyEventCard({
    required this.event,
    required this.distance,
  });

  final EventLocation event;
  final String distance;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D0930),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF461458),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                event.timeStart ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFEC34F8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                event.venue,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFAD89CE),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '📍 $distance',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFAE8ACF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF320E45),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                localizedCategoryLabel(event.category, fallback: 'Övrigt'),
                style: const TextStyle(
                  color: Color(0xFFAE8ACF),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/map',
                      arguments: event,
                    );
                  },
                  icon: const Icon(Icons.location_on_outlined, size: 18),
                  label: const Text(
                    'Visa på kartan',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF861C91)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/event-information',
                      arguments: event,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF861C91)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Detaljer',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
