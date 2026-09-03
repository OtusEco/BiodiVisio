import 'package:flutter/material.dart';

import 'package:map_launcher/map_launcher.dart';

class MapActionButton extends StatelessWidget {
  final double? lat;
  final double? lon;
  final bool isPolygon;
  final String title;

  const MapActionButton({
    super.key,
    required this.lat,
    required this.lon,
    required this.isPolygon,
    required this.title,
  });

  static const List<MapApp> _supportedMaps = [
    MapApp.apple,
    MapApp.google,
    MapApp.waze,
    MapApp.osmand,
    MapApp.osmandplus,
  ];

  Future<void> openInMaps(BuildContext context) async {
    if (lat == null || lon == null) return;

    final request = MapLauncher.marker(
      LocationCoords(lat!, lon!, title: title),
    );
    final availableMaps = await request.getSupportedMaps(_supportedMaps);

    if (availableMaps.isEmpty) return;
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Text(
                  "Ouvrir dans une application de cartes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              ...availableMaps.map((map) {
                return ListTile(
                  leading: Image.memory(map.iconBytes, height: 30, width: 30),
                  title: Text(map.name),
                  onTap: () {
                    map.show();
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isPolygon || lat == null || lon == null) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.directions),
      tooltip: "Ouvrir dans une application de cartes",
      onPressed: () => openInMaps(context),
    );
  }
}