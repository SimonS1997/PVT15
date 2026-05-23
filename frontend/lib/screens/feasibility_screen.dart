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
  int _dwellMinutes = 30;

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
      if (token == null) throw Exception('Du behöver vara inloggad.');

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

  int _minutesBetween(String a, String b) {
    final pa = a.split(':');
    final pb = b.split(':');
    final ma = int.parse(pa[0]) * 60 + int.parse(pa[1]);
    final mb = int.parse(pb[0]) * 60 + int.parse(pb[1]);
    return mb - ma;
  }

  List<_LegVerdict> _verdicts() {
    final out = <_LegVerdict>[];
    for (var i = 0; i < _legs.length; i++) {
      final gap = _minutesBetween(_events[i].timeStart!, _events[i + 1].timeStart!);
      final available = gap - _dwellMinutes;
      out.add(_LegVerdict(
        leg: _legs[i],
        availableMinutes: available,
        feasible: _legs[i].travelMinutes <= available,
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120A1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF120A1E),
        foregroundColor: Colors.white,
        title: const Text('Hinner jag?'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFEC34F8)),
                    SizedBox(height: 16),
                    Text(
                      'Planerar din rutt…',
                      style: TextStyle(
                        color: Color(0xFFAE8ACF),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFFAE8ACF)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _events.length < 2
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Lägg till minst två event i din plan för att kolla restider.',
                            style: TextStyle(color: Color(0xFFAE8ACF)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final verdicts = _verdicts();
    final allFeasible = verdicts.every((v) => v.feasible);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: allFeasible
                ? const Color(0xFF1B3320)
                : const Color(0xFF3A1212),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: allFeasible
                  ? const Color(0xFF3D8C5A)
                  : const Color(0xFFE45A5A),
            ),
          ),
          child: Row(
            children: [
              Icon(
                allFeasible ? Icons.check_circle : Icons.warning_amber,
                color: allFeasible
                    ? const Color(0xFF7BE0A4)
                    : const Color(0xFFE45A5A),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  allFeasible
                      ? 'Du hinner med hela din plan.'
                      : 'Vissa byten är för tighta.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildDwellRow(),
        const SizedBox(height: 20),
        ...verdicts.map(_buildLegCard),
      ],
    );
  }

  Widget _buildDwellRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A1F5C)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Rekommenderad tid per event',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          IconButton(
            onPressed: _dwellMinutes > 5
                ? () => setState(() => _dwellMinutes -= 5)
                : null,
            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFEC34F8)),
          ),
          SizedBox(
            width: 64,
            child: Text(
              '$_dwellMinutes min',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _dwellMinutes += 5),
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFEC34F8)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegCard(_LegVerdict v) {
    final color = v.feasible ? const Color(0xFF7BE0A4) : const Color(0xFFE45A5A);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A1F5C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                v.feasible ? Icons.check : Icons.warning_amber,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${v.leg.from} → ${v.leg.to}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Restid ${v.leg.travelMinutes} min · Tillgängligt ${v.availableMinutes} min',
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }
}

class _LegVerdict {
  _LegVerdict({
    required this.leg,
    required this.availableMinutes,
    required this.feasible,
  });

  final LegPlanLeg leg;
  final int availableMinutes;
  final bool feasible;
}
