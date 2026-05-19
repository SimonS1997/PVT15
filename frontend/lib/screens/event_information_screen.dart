import 'package:flutter/material.dart';

class EventInformationScreen extends StatelessWidget {
  const EventInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF21012B),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: Colors.white,
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.favorite_border),
                      color: Colors.white,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A0755),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9A00B5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Kategori',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                const Text(
                  'Moderna museet:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Midnattsvisning',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 28),

                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.access_time, color: Color(0xFFE02BFF), size: 26),
                    SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '18.00 - 00.00',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '18 april 2026',
                          style: TextStyle(
                            color: Color(0xFFC7A4D8),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFFE02BFF),
                      size: 28,
                    ),
                    SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Moderna museet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Skeppsholmen',
                          style: TextStyle(
                            color: Color(0xFFC7A4D8),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.groups_2_outlined,
                      color: Color(0xFFE02BFF),
                      size: 28,
                    ),
                    SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hög aktivitet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Baserat på förra året',
                          style: TextStyle(
                            color: Color(0xFFC7A4D8),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.near_me_outlined,
                      color: Color(0xFFE02BFF),
                      size: 28,
                    ),
                    SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '12 min från din position',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Gång',
                          style: TextStyle(
                            color: Color(0xFFC7A4D8),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                const Text(
                  'Om eventet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'information',
                  style: TextStyle(
                    color: Color(0xFFC7A4D8),
                    fontSize: 18,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6A007A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Lägg till i min plan',
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C0138),
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                        color: Color(0xFF9A00B5)
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Visa på karta',
                    style: TextStyle(fontSize: 17,
                        fontWeight: FontWeight.w600
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
