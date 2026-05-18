import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';

class MyPlanScreen extends StatelessWidget {
  const MyPlanScreen({super.key});

  //fakedata tillfälligt
  final List<Map<String, String>> events = const [
    {
      "titel": "Museum Night",
      "plats" : "Stockholm City",
      "tid" : "18:00-22:00",
      "genre" : "Museum",
    },
    {
      "titel" : "Konsert",
      "plats" : "Globen",
      "tid" : "18:00-22:00",
      "genre" : "Musik",
    },
    {
      "titel" : "Utställning",
      "plats" : "Museet",
      "tid" : "18:00-22:00",
      "genre" : "Konst",
    },
  ];

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

              Row(
                children: [

                  IconButton(
                    onPressed: () {
                      //lägga till att gå tillbaka  
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(
                    width: 8),

                  const Text(
                    "Min plan",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(
                height: 20
                ),

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
                        "Lägga in rutt-info här (events • min • gång)",
                        style: TextStyle(
                          color: Color(0xFFAE8ACF),
                          ),
                      ),
                    ],
                    ),
                  ),
              

              //Valda events
              Expanded(
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];

                    return _PlanEventCard(
                      index: index + 1,
                      titel: event["titel"]!,
                      plats: event["plats"]!,
                      tid: event["tid"]!,
                      genre: event["genre"]!,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              //Knapp
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  //till optimeraplan sidan
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                  
                    backgroundColor: const Color(0xFFEC34F8),
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    )
                  ),
                  child: const Text(
                    "Optimera min plan",
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
            Navigator.pushReplacementNamed(context, '/profile');
            break;
          }
        }
      ),
    );
  }
}



//eventsen
class _PlanEventCard extends StatelessWidget {
  final int index;
  final String titel;
  final String plats;
  final String tid;
  final String genre;

  const _PlanEventCard({
    required this.index,
    required this.titel,
    required this.plats,
    required this.tid,
    required this.genre,
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

            //index
            Container(
              width: 35,
              height: 35,
              alignment: Alignment.center,
              decoration: BoxDecoration(
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

            //tid
              Text(
                tid,
                style: const TextStyle(
                  color: Color(0xFFEC34F8),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),

              IconButton(
            onPressed: () {},

            icon: const Icon(
              Icons.delete_outline,
              color: Color(0xFFAE8ACF),
            ),
          ),
            ],
          ),
          const SizedBox(height: 10),


        //genre
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
              genre,
              style: TextStyle(
                color: Color(0xFFAE8ACF),
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 16),
        

         //titeln
          Text(
            titel,
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
            plats,
            style: const TextStyle(
              color: Color(0xFFAD89CE),
            ),
          ),
        ],
       ),
       const SizedBox(height: 18),

       //Knapparna i eventsen
       Row(
        children: [

          Expanded(
            child: OutlinedButton(
              //till kartsida
              onPressed: () {},

              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: Color(0xFF861C91),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 14),
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
              onPressed: () {},

              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: Color(0xFF861C91),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  //till eventdetaljsida
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