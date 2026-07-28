import 'package:flutter/material.dart';

class MapAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Map<String, String> baseMaps;
  final String currentBaseMap;
  final ValueChanged<String> onBaseMapChanged;
  final VoidCallback onUserLocation;
  final bool isLocating;
  final VoidCallback onFilter;
  final VoidCallback onStatistics;
  final bool hasResults;
  final VoidCallback onAbout;
  final VoidCallback onLogout;

  const MapAppBar({
    super.key,
    required this.baseMaps,
    required this.currentBaseMap,
    required this.onBaseMapChanged,
    required this.onUserLocation,
    required this.isLocating,
    required this.onFilter,
    required this.onStatistics,
    required this.hasResults,
    required this.onAbout,
    required this.onLogout,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // Hauteur du logo selon la largeur d'écran disponible.
  double? _logoHeight(double screenWidth) {
    if (screenWidth < 360) return null; // écran trop petit : pas de logo
    if (screenWidth < 400) return 24;
    if (screenWidth < 600) return 30;
    return 36;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoHeight = _logoHeight(screenWidth);

    return AppBar(
      titleSpacing: 12,
      centerTitle: false,
      title: logoHeight == null
          ? null
          : Image.asset(
              'assets/images/logo.png',
              height: logoHeight,
              fit: BoxFit.contain,
            ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: "Rechercher des observations",
          onPressed: onFilter,
        ),
        if (hasResults)
          IconButton(
            icon: const Icon(Icons.query_stats),
            tooltip: "Statistiques",
            onPressed: onStatistics,
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.layers),
          tooltip: "Changer le fond de carte",
          onSelected: onBaseMapChanged,
          itemBuilder: (context) {
            return baseMaps.keys.map((name) {
              return PopupMenuItem(value: name, child: Text(name));
            }).toList();
          },
        ),
        IconButton(
          icon: isLocating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          tooltip: "Afficher ma position",
          onPressed: isLocating ? null : onUserLocation,
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: "À propos",
          onPressed: onAbout,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: "Déconnexion",
          onPressed: onLogout,
        ),
      ],
    );
  }
}
