import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
//import '../design_system/atoms/app_text.dart';

class SingleImageScreen extends StatefulWidget {
  final String imageUrl;
  final String birdSpecies; // För att visa namnet i titeln om vi vill

  const SingleImageScreen({
    super.key,
    required this.imageUrl,
    required this.birdSpecies,
  });

  @override
  State<SingleImageScreen> createState() => _SingleImageScreenState();
}

class _SingleImageScreenState extends State<SingleImageScreen> {
  // Variabel för att hålla reda på om vi ska visa tillbaka-knappen
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sätter bakgrunden till svart för att ge en "biograf-känsla" på bilden
      backgroundColor: Colors.black,

      // Vi använder en Stack för att lägga tillbaka-knappen ovanpå bilden
      body: Stack(
        children: [

          // 1. SJÄLVA BILDEN (med Zoom-funktion)
          // GestureDetector känner av tryck på hela skärmen
          GestureDetector(
            onTap: () {
              // När användaren trycker, vänd på sant/falskt för att visa/dölja knappen
              setState(() {
                _showControls = !_showControls;
              });
            },

            // InteractiveViewer är Flutters inbyggda widget för pinch-to-zoom och panorering!
            child: InteractiveViewer(
              minScale: 0.5, // Hur mycket man kan zooma ut (hälften)
              maxScale: 4.0, // Hur mycket man kan zooma in (4 gånger)
              boundaryMargin: const EdgeInsets.all(20.0), // Marginal när man panerar

              // Centrera bilden på skärmen
              child: Center(
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain, // Se till att hela bilden syns utan att beskäras
                  loadingBuilder: (context, child, loadingProgress) {
                    // Enkel laddningsindikator medans bilden hämtas
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: AppColors.surface));
                  },
                ),
              ),
            ),
          ),

          // 2. TILLBAKA-KNAPPEN (Överst till vänster)
          // AnimatedOpacity gör att knappen tonar in/ut snyggt när vi trycker
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm, // Justera för skärmens flärp (notch)
            left: AppSpacing.sm,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0, // Visa (1.0) eller dölj (0.0)
              duration: const Duration(milliseconds: 300), // Hur snabbt animationen ska gå

              // Om knappen ska döljas, inaktivera klick-funktionen helt
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54, // Halvgenomskinlig svart bakgrund
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      // Gå tillbaka till mapp-vyn
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}