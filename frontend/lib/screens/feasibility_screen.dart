import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../models/event_location.dart';
import '../services/transit_api_service.dart';

class FeasibilityScreen extends StatefulWidget {
  const FeasibilityScreen({super.key});

  @override
  State<FeasibilityScreen> createState() => _FeasibilityScreenState();
}

class _FeasibilityScreenState extends State<FeasibilityScreen> {
  final TransitApiService _api =
      TransitApiService(baseUrl: 'http://10.0.2.2:8083');

  List<EventLocation> _events = [];
  List<LegPlanLeg> _legs = [];
  bool _loading = true;
  String? _error;
  final Map<int, int> _dwellByIndex = {};

  int _dwellFor(int eventIndex) => _dwellByIndex[eventIndex] ?? 30;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_events.isEmpty) {
      final events =
          ModalRoute.of(context)!.settings.arguments as List<EventLocation>;
      _events = [...events]
        ..removeWhere((e) => e.timeStart == null || e.timeStart!.isEmpty)
        ..sort((a, b) => a.timeStart!.compareTo(b.timeStart!));
      _fetchLegs();
    }
  }

  Future<void> _fetchLegs() async {
    if (_events.length < 2) {
      setState(() => _loading = false);
      return;
    }
    try {
      final token = await AuthService.instance.validAccessToken();

      final stops = _events
          .map((e) => {
                'name': e.name,
                'lat': e.latitude,
                'lon': e.longitude,
                'startTime': e.timeStart,
              })
          .toList();

      final legs = await _api.planLegs(stops: stops, accessToken: token);
      if (!mounted) return;
      setState(() {
        _legs = legs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int _gapMinutes(int legIndex) {
    final a = _events[legIndex].timeStart!.split(':');
    final b = _events[legIndex + 1].timeStart!.split(':');
    return (int.parse(b[0]) * 60 + int.parse(b[1])) -
        (int.parse(a[0]) * 60 + int.parse(a[1]));
  }

  bool _isLegFeasible(int legIndex) =>
      _legs[legIndex].travelMinutes <=
          _gapMinutes(legIndex) - _dwellFor(legIndex);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120A1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF120A1E),
        foregroundColor: Colors.white,
        title: const Text('Hinner jag?'),
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFEC34F8)),
            SizedBox(height: 16),
            Text('Planerar din rutt…',
                style: TextStyle(color: Color(0xFFAE8ACF), fontSize: 16)),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              style: const TextStyle(color: Color(0xFFAE8ACF)),
              textAlign: TextAlign.center),
        ),
      );
    }
    if (_events.length < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'Lägg till minst två event i din plan för att kolla restider.',
              style: TextStyle(color: Color(0xFFAE8ACF)),
              textAlign: TextAlign.center),
        ),
      );
    }

    final allFeasible =
        List.generate(_legs.length, _isLegFeasible).every((v) => v);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _summary(allFeasible),
        const SizedBox(height: 20),
        ..._timeline(),
      ],
    );
  }

  List<Widget> _timeline() {
    final widgets = <Widget>[];
    for (var i = 0; i < _events.length; i++) {
      widgets.add(_eventCard(i));
      if (i < _events.length - 1) widgets.add(_legBlock(i));
    }
    return widgets;
  }

  Widget _summary(bool ok) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFF1B3320) : const Color(0xFF3A1212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: ok ? const Color(0xFF3D8C5A) : const Color(0xFFE45A5A)),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.warning_amber,
              color: ok ? const Color(0xFF7BE0A4) : const Color(0xFFE45A5A)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ok
                  ? 'Du hinner med hela din plan.'
                  : 'Vissa byten är för tighta.',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(int eventIndex) {
    final event = _events[eventIndex];
    final isLast = eventIndex == _events.length - 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1545),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEC34F8), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                event.timeStart ?? '',
                style: const TextStyle(
                    color: Color(0xFFEC34F8),
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    if (event.venue.isNotEmpty)
                      Text(event.venue,
                          style: const TextStyle(
                              color: Color(0xFFAE8ACF), fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: 10),
            const Divider(color: Color(0xFF461458), height: 1),
            const SizedBox(height: 4),
            _dwellStepper(eventIndex),
          ],
        ],
      ),
    );
  }

  Widget _dwellStepper(int eventIndex) {
    final value = _dwellFor(eventIndex);
    return Row(
      children: [
        const Expanded(
          child: Text('Tid här',
              style: TextStyle(color: Color(0xFFAE8ACF), fontSize: 13)),
        ),
        IconButton(
          onPressed: value > 5
              ? () => setState(() => _dwellByIndex[eventIndex] = value - 5)
              : null,
          icon:
              const Icon(Icons.remove_circle_outline, color: Color(0xFFEC34F8)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        SizedBox(
          width: 56,
          child: Text('$value min',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        IconButton(
          onPressed: () => setState(() => _dwellByIndex[eventIndex] = value + 5),
          icon: const Icon(Icons.add_circle_outline, color: Color(0xFFEC34F8)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _legBlock(int legIndex) {
    final leg = _legs[legIndex];
    final available = _gapMinutes(legIndex) - _dwellFor(legIndex);
    final ok = leg.travelMinutes <= available;
    final color = ok ? const Color(0xFF7BE0A4) : const Color(0xFFE45A5A);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.arrow_downward, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                'Restid ${leg.travelMinutes} min · $available min tills nästa event',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...leg.segments.map(_segmentRow),
        ],
      ),
    );
  }

  Widget _segmentRow(LegSegment seg) {
    final icon = seg.isWalk
        ? Icons.directions_walk
        : Icons.directions_transit_outlined;
    final duration =
        seg.durationMinutes != null ? ' (${seg.durationMinutes} min)' : '';

    final String text;
    if (seg.isWalk) {
      text = 'Gå från ${seg.fromName} till ${seg.toName}$duration';
    } else {
      final line = seg.line ?? 'Linje';
      final direction =
          seg.direction != null ? ' mot ${seg.direction}' : '';
      text =
          '$line$direction: ${seg.fromName} → ${seg.toName}$duration';
    }

    return Padding(
      padding: const EdgeInsets.only(left: 26, top: 2, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFAE8ACF), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Color(0xFFC7A4D8), fontSize: 13, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
