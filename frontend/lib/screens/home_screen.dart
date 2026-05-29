import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../managers/saved_events_manager.dart';
import '../models/event_location.dart';
import '../services/event_api_service.dart';
import '../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EventApiService _api =
      EventApiService(baseUrl: 'http://10.0.2.2:8082');

  static const List<String> _categoryLabels = [
    "Alla",
    "Musik",
    "Konst",
    "Teater",
    "Film",
    "Dans",
    "Guidad tur",
    "Historia",
    "Litteratur",
    "Wellness",
    "Workshop",
    "Övrigt",
  ];

  List<EventLocation> _events = [];
  bool _loading = true;
  String? _error;
  String _selectedLabel = "Alla";
  String _searchTerm = "";
  bool _sortByStartTime = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // Översätter UI-label till backend-kategori
  String? _toCategory(String label) {
    switch (label) {
      case "Musik":
        return "MUSIC";
      case "Konst":
        return "ART";
      case "Teater":
        return "THEATRE";
      case "Film":
        return "FILM";
      case "Dans":
        return "DANCE";
      case "Guidad tur":
        return "GUIDED_TOUR";
      case "Historia":
        return "HISTORY";
      case "Litteratur":
        return "LITERATURE";
      case "Wellness":
        return "WELLNESS";
      case "Workshop":
        return "WORKSHOP";
      case "Övrigt":
        return "OTHER";
      default:
        return null;
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await AuthService.instance.validAccessToken();
      final events = await _api.fetchEvents(
        accessToken: token,
        category: _toCategory(_selectedLabel),
        search: _searchTerm,
      );

      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "Kunde inte hämta event: $e";
      });
    }
  }

  void _onCategoryTap(String label) {
    setState(() => _selectedLabel = label);
    _loadEvents();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchTerm = value);
    _loadEvents();
  }

  List<EventLocation> get _visibleEvents {
    final events = [..._events];
    if (!_sortByStartTime) return events;

    events.sort((a, b) {
      final aMinutes = _startMinutes(a.timeStart);
      final bMinutes = _startMinutes(b.timeStart);
      if (aMinutes == null && bMinutes == null) {
        return a.name.compareTo(b.name);
      }
      if (aMinutes == null) return 1;
      if (bMinutes == null) return -1;
      final timeCompare = aMinutes.compareTo(bMinutes);
      if (timeCompare != 0) return timeCompare;
      return a.name.compareTo(b.name);
    });

    return events;
  }

  int? _startMinutes(String? value) {
    if (value == null || value.isEmpty) return null;
    final match = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(value);
    if (match == null) return null;

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
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

              // Rubrik
              const Text(
                "Stockholms Kulturnatt",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 4),

              // Underrubrik
              const Text(
                "18 April 2026",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFAE8ACF),
                ),
              ),

              const SizedBox(height: 16),

              // Sökfält
              TextField(
                style: const TextStyle(
                  color: Colors.white,
                ),

                cursorColor: const Color(0xFFAE8ACF),

                onChanged: _onSearchChanged,

                decoration: InputDecoration(
                  hintText: "Sök event...",

                  hintStyle: const TextStyle(
                    color: Color(0XFFAE8ACF),
                  ),

                  prefixIcon: const Icon(
                    Icons.search,
                    size: 30,
                    color: Color(0XFFAE8ACF),
                  ),

                  filled: true,
                  fillColor: const Color(0xFF1D0930),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),

                    borderSide: const BorderSide(
                      color: Color(0xFF461458),
                      width: 2,
                    ),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),

                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 102, 48, 122),
                      width: 2,
                    ),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),

                    borderSide: const BorderSide(
                      color: Color(0xFF461458),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Filterbubblor
              SizedBox(
                height: 50,
                width: double.infinity,

                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 16),
                  children: [
                    for (final label in _categoryLabels)
                      _FilterBubbla(
                        label: label,
                        selected: _selectedLabel == label,
                        onTap: () => _onCategoryTap(label),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // Events
              Expanded(
                child: _buildEventList(),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,

        onTap: (index) {
          switch (index) {

            case 0:
              break;

            case 1:
              Navigator.pushReplacementNamed(context, '/map');
              break;

            case 2:
              Navigator.pushReplacementNamed(context, '/nearby');
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

  Widget _buildEventList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFEC34F8),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Color(0xFFAE8ACF)),
          textAlign: TextAlign.center,
        ),
      );
    }

    final events = _visibleEvents;

    if (events.isEmpty) {
      return const Center(
        child: Text(
          "Inga event matchade.",
          style: TextStyle(color: Color(0xFFAE8ACF)),
        ),
      );
    }

    return ListenableBuilder(
      listenable: SavedEventsManager.instance,
      builder: (context, child) {
        return ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Event",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                _SortButton(
                  sortByStartTime: _sortByStartTime,
                  onChanged: (value) {
                    setState(() => _sortByStartTime = value);
                  },
                ),
              ],
            ),
            if (_sortByStartTime) ...[
              const SizedBox(height: 6),
              const Text(
                "Sorterad efter starttid",
                style: TextStyle(
                  color: Color(0xFFAE8ACF),
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 12),
            for (var event in events) _EventCard(event: event),
          ],
        );
      },
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.sortByStartTime,
    required this.onChanged,
  });

  final bool sortByStartTime;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<bool>(
      tooltip: "Sortera",
      color: const Color(0xFF1D0930),
      onSelected: onChanged,
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: false,
          checked: !sortByStartTime,
          child: const Text(
            "Standard",
            style: TextStyle(color: Colors.white),
          ),
        ),
        CheckedPopupMenuItem(
          value: true,
          checked: sortByStartTime,
          child: const Text(
            "Starttid",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1D0930),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF861C91)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sort,
              color: Color(0xFFAE8ACF),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              sortByStartTime ? "Starttid" : "Sortera",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Filterbubblor
class _FilterBubbla extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterBubbla({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        margin: const EdgeInsets.only(right: 16),

        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF861C91)
              : const Color(0xFF420D4D),

          borderRadius: BorderRadius.circular(30),

          border: Border.all(
            color: const Color(0xFF861C91),
            width: 2,
          ),
        ),

        child: Center(
          child: Text(
            label,

            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// Eventkort
class _EventCard extends StatelessWidget {
  final EventLocation event;

  const _EventCard({
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final isSaved = SavedEventsManager.instance.isSaved(event.id);

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
          // Titel och tid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  SavedEventsManager.instance.toggleSave(event.id);
                },
                icon: Icon(
                  isSaved ? Icons.favorite : Icons.favorite_border,
                  color: const Color(0xFFEC34F8),
                ),
              ),
              Text(
                event.timeStart ?? "",
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFEC34F8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Plats
          Text(
            event.venue,

            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFFAD89CE),
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              // Kategori
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF320E45),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  event.category ?? "Övrigt",
                  style: const TextStyle(
                    color: Color(0xFFAE8ACF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/event-information',
                    arguments: event,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF861C91)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Detaljer",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
