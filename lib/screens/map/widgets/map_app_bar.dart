import 'package:flutter/material.dart';

class MapAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String subtitle;
  final Map<String, String> baseMaps;
  final String currentBaseMap;
  final ValueChanged<String> onBaseMapChanged;
  final VoidCallback onUserLocation;
  final VoidCallback onFilter;
  final VoidCallback onAbout;
  final VoidCallback onLogout;

  const MapAppBar({
    super.key,
    required this.subtitle,
    required this.baseMaps,
    required this.currentBaseMap,
    required this.onBaseMapChanged,
    required this.onUserLocation,
    required this.onFilter,
    required this.onAbout,
    required this.onLogout,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

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
                color: Colors.black,
              ),
            ),
            const TextSpan(
              text: "Carte des observations",
              style: TextStyle(fontSize: 12, color: Colors.black),
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
          icon: const Icon(Icons.my_location),
          tooltip: "Afficher ma position",
          onPressed: onUserLocation,
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: Container(
          color: Colors.blue.shade100,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: onFilter,
            child: Text(
              subtitle,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
