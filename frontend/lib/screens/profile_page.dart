import 'package:flutter/material.dart';
import '../widgets/profile_stat_card.dart';

// TILLFÄLLIG DUMMY FIL
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Min Profil"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundImage: NetworkImage(
                "https://i.pravatar.cc/150?img=12",
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Adam Svensson",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Text(
              "adam@email.com",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                ProfileStatCard(
                  title: "Favoriter",
                  value: "8",
                  icon: Icons.favorite,
                ),
                ProfileStatCard(
                  title: "Planerade",
                  value: "5",
                  icon: Icons.event,
                ),
                ProfileStatCard(
                  title: "Rutter",
                  value: "3",
                  icon: Icons.route,
                ),
              ],
            ),

            const SizedBox(height: 30),

            FilledButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/map');
              },
              icon: const Icon(Icons.map),
              label: const Text("Öppna karta"),
            ),

            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Inställningar"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logga ut"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}