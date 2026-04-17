import 'package:flutter/material.dart';

class LogbookScreen extends StatefulWidget {
  const LogbookScreen({super.key});

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  // Här kommer vi lagra kunna lagra fågelobservationer
  // t.ex. List<BirdObservation> _observations = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mina Observationer',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D5A27), // Nice Skogsgrön
              ),
            ),
            const SizedBox(height: 20),

            // Placeholder för loggboken
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_stories,
                      size: 100,
                      color: const Color(0xFF2D5A27).withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Inga loggar ännu.\nDags att ge sig ut i skogen!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Knapp för loggboken (t.ex. för att lägga till ett nytt fynd)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Här kan vi trigga kameran
          debugPrint('Här ska vi lägga till en ny fågel!');
        },
        backgroundColor: const Color(0xFF2D5A27),
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }
}