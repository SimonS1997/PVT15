import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/event_location.dart';

class EventMapView extends StatefulWidget {
  const EventMapView({
    super.key,
    required this.events,
  });

  final List<EventLocation> events;

  @override
  State<EventMapView> createState() => _EventMapViewState();
}

class _EventMapViewState extends State<EventMapView> {
  static const LatLng stockholm = LatLng(59.3293, 18.0686);

  EventLocation? selectedEvent;

  Set<Marker> get markers {
    return widget.events.map((event) {
      final bool isSelected = selectedEvent?.id == event.id;

      return Marker(
        markerId: MarkerId(event.id.toString()),
        position: event.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected
              ? BitmapDescriptor.hueViolet
              : BitmapDescriptor.hueMagenta,
        ),
        onTap: () {
          setState(() {
            selectedEvent = event;
          });
        },
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12001F),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _MapHeader(
                  onBack: () => Navigator.maybePop(context),
                ),
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: stockholm,
                      zoom: 12,
                    ),
                    markers: markers,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),
              ],
            ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 88,
              child: _FilterBar(),
            ),

            if (selectedEvent != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _EventInfoCard(
                  event: selectedEvent!,
                  onClose: () {
                    setState(() {
                      selectedEvent = null;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1B0030),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new),
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Text(
                'Karta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B0A57),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {},
                child: const Text('Filtrera'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF662080)),
                  ),
                  child: const Text(
                    'Södermalm, Stockholm',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF662080)),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.near_me_outlined),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(label: 'Alla', selected: true),
        const SizedBox(width: 8),
        _FilterChip(label: 'Min plan', selected: false),
        const SizedBox(width: 8),
        _FilterChip(label: 'I närheten', selected: false),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFD84DFF) : const Color(0xFF1B0030),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF662080)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EventInfoCard extends StatelessWidget {
  const _EventInfoCard({
    required this.event,
    required this.onClose,
  });

  final EventLocation event;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1B0030),
        border: Border(
          top: BorderSide(color: Color(0xFF662080)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _CategoryBadge(label: 'Event'),
              const SizedBox(width: 10),
              const Text(
                '18:00',
                style: TextStyle(
                  color: Color(0xFFD84DFF),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xFFD4A4FF),
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.venue,
                  style: const TextStyle(
                    color: Color(0xFFD4A4FF),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (event.address.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              event.address,
              style: const TextStyle(
                color: Color(0xFFBFA6D9),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF3B0A57),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}