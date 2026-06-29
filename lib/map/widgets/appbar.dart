import 'package:flutter/material.dart';

import 'package:biodivisio/core/theme/theme.dart';

class MapAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String serverName;
  final Map<String, String> baseMaps;
  final String currentBaseMap;
  final ValueChanged<String> onBaseMapChanged;
  final VoidCallback onUserLocation;
  final bool isLocating;
  final VoidCallback onFilter;
  final VoidCallback onAbout;
  final VoidCallback onLogout;

  const MapAppBar({
    super.key,
    required this.serverName,
    required this.baseMaps,
    required this.currentBaseMap,
    required this.onBaseMapChanged,
    required this.onUserLocation,
    required this.isLocating,
    required this.onFilter,
    required this.onAbout,
    required this.onLogout,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: "BiodiVisio\n",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            TextSpan(
              text: serverName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: "Rechercher des observations",
          onPressed: onFilter,
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
