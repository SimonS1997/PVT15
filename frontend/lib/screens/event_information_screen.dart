import 'package:flutter/material.dart';

import '../models/event_location.dart';
import '../utils/category_labels.dart';

class EventInformationScreen extends StatelessWidget {
  const EventInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final event = ModalRoute.of(context)!.settings.arguments as EventLocation;
    final timeRange = [event.timeStart, event.timeEnd]
        .where((t) => t != null && t.isNotEmpty)
        .join(' – ');

    return Scaffold(
      backgroundColor: const Color(0xFF21012B),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new),
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9A00B5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    localizedCategoryLabel(event.category),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  event.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 28),
                if (timeRange.isNotEmpty)
                  _DetailRow(
                    icon: Icons.access_time,
                    title: timeRange,
                    subtitle: '18 april 2026',
                  ),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  title: event.venue,
                  subtitle: event.address,
                ),
                if (event.nearestStation != null && event.nearestStation!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.directions_transit_outlined,
                    title: 'Närmaste hållplats',
                    subtitle: event.nearestStation!,
                  ),
                if (event.bookingRequired)
                  _DetailRow(
                    icon: Icons.event_available_outlined,
                    title: 'Bokning krävs',
                    subtitle: null,
                  ),
                const SizedBox(height: 20),
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const Text(
                    'Om eventet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description!,
                    style: const TextStyle(
                      color: Color(0xFFC7A4D8),
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFE02BFF), size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Color(0xFFC7A4D8),
                      fontSize: 15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
