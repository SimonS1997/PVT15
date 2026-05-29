import 'package:flutter/material.dart';
import '../managers/saved_events_manager.dart';
import '../models/event_location.dart';
import '../utils/category_labels.dart';
import '../widgets/bottom_nav_bar.dart';

class MyPlanScreen extends StatelessWidget {
  const MyPlanScreen({super.key});

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
                "Min plan",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D0930),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF461458)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Din plan",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Här ser du dina sparade event inför kulturnatten.",
                      style: TextStyle(
                        color: Color(0xFFAE8ACF),
                      ),
                    ),
                  ],
                ),
              ),

              //Valda events
              Expanded(
                child: ListenableBuilder(
                  listenable: SavedEventsManager.instance,
                  builder: (context, child) {
                    final events = SavedEventsManager.instance.savedEvents;

                    if (SavedEventsManager.instance.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (events.isEmpty) {
                      return const Center(
                        child: Text(
                          "Du har inga sparade event än.",
                          style: TextStyle(color: Color(0xFFAE8ACF)),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return _PlanEventCard(
                          index: index + 1,
                          event: event,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              //Knapp
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final events = SavedEventsManager.instance.savedEvents;
                    Navigator.pushNamed(
                      context,
                      '/feasibility',
                      arguments: events,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC34F8),
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Hinner jag?",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/map');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/nearby');
              break;
            case 3:
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }
}

class _PlanEventCard extends StatelessWidget {
  final int index;
  final EventLocation event;

  const _PlanEventCard({
    required this.index,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D0930),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF461458)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 35,
                height: 35,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF461458),
                ),
                child: Text(
                  "$index.",
                  style: const TextStyle(
                    color: Color(0xFFEC34F8),
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                event.timeStart ?? "",
                style: const TextStyle(
                  color: Color(0xFFEC34F8),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  SavedEventsManager.instance.toggleSave(event.id);
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFAE8ACF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
              localizedCategoryLabel(event.category),
              style: const TextStyle(
                color: Color(0xFFAE8ACF),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            event.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xFFAD89CE),
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                event.venue,
                style: const TextStyle(
                  color: Color(0xFFAD89CE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/map',
                      arguments: true,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF861C91),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Visa på kartan",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
                    side: const BorderSide(
                      color: Color(0xFF861C91),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Detaljer",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
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
