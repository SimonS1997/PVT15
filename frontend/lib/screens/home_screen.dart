import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});


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

              //Rubrik
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Stockholms Kulturnatt",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.favorite_border,
                      color: Color(0xFFEC34F8),
                      size: 30,
                      ),
                    onPressed: () {},
                  )
                ],
              ),
              const SizedBox(height: 4),



            //Underrubrik
              const Text(
                "18 April 2026",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFAE8ACF),
                ),
              ),
              const SizedBox(height: 16),


              //sökfält
              TextField(
                style: const TextStyle(
                  color: Colors.white,
                ),
                cursorColor: Color(0xFFAE8ACF),
                
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
                  fillColor: Color(0xFF1D0930),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
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

              //filterbubblor
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 16),
                  children: const [
                    _FilterBubbla(label: "Alla"),
                    _FilterBubbla(label: "Musik"),
                    _FilterBubbla(label: "Konst"),
                    _FilterBubbla(label: "Teater"),
                    _FilterBubbla(label: "Film"),
                    _FilterBubbla(label: "Dans"),
                    _FilterBubbla(label: "Mat"),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              //eventsen
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [

                    const Text(
                      "Börjar snart",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    //låtsasdata
                    _EventCard(title: "Museum Night"),
                    _EventCard(title: "Konsert"),
                    _EventCard(title: "Konstutatällning"),
                    const SizedBox(height: 24),

                    const Text(
                      "I närheten",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    //låtsasdata
                    _EventCard(title: "musik"),
                    _EventCard(title: "utställning"),
                    _EventCard(title: "Konstutatällning"),

                  ],
                ),
              ),
             ],
            ),
          ),
         ),
    );
  }
}

//filterbubblor klass
class _FilterBubbla extends StatelessWidget {
                final String label;

                const _FilterBubbla({required this.label});

                @override
                Widget build(BuildContext context) {
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF420D4D),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Color(0xFF861C91),
                        width: 2,
                      )
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
                  );
                }
              }



//eventkortet
class _EventCard extends StatelessWidget {
  final String title;

  const _EventCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1D0930),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF461458),
          width: 2,
        )
      ),
      
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [

          //titel och tid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold, 
                  color: Colors.white,
                ),
              ),

              const Text(
                "Tid", //Ändra senare
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFFEC34F8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),


          //plats
          const Text(
            "Plats", //Ändra till riktig data
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFFAD89CE),
            ),
          ),
          const SizedBox(height: 15),

          //genre
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color:Color(0xFF320E45),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              "Genre", //Ändra till riktig data
              style: TextStyle(
                color: Color(0xFFAE8ACF),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            )
          )
        ]
      ),
    );
  }
}
    

  
      

            
            
        