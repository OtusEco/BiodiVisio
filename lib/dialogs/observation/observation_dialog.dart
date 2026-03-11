import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:map_launcher/map_launcher.dart';

import '../../services/api_service.dart';
import 'details_observation.dart';

class ObservationDialog extends StatelessWidget {
  final List observations;
  final double lat;
  final double lon;
  final ApiService api;

  const ObservationDialog({
    super.key,
    required this.observations,
    required this.lat,
    required this.lon,
    required this.api,
  });

  String formatDate(String? rawDate) {
    if (rawDate == null) return "Date inconnue";
    try {
      final date = DateTime.parse(rawDate);
      final timePart = rawDate.split('T').last;
      final hasTime = timePart != "00:00:00";
      return hasTime
          ? DateFormat('dd/MM/yyyy HH:mm').format(date)
          : DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return rawDate;
    }
  }

  Future<void> openInMaps(BuildContext context, double lat, double lon) async {
    final availableMaps = await MapLauncher.installedMaps;

    if (availableMaps.isEmpty) return;
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Text(
                  "Ouvrir dans une application de cartes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              // Liste des applis installées
              ...availableMaps.map((map) {
                return ListTile(
                  leading: const Icon(Icons.exit_to_app, size: 30),
                  title: Text(map.mapName),
                  onTap: () {
                    map.showMarker(
                      coords: Coords(lat, lon),
                      title: "Observation",
                    );
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
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Listes des observations",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: observations.isEmpty
                    ? const Center(
                        child: Text(
                          "Aucune observation",
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.separated(
                        itemCount: observations.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final obs = observations[index];

                          final species = (obs["lb_nom"] != null)
                              ? obs["lb_nom"]
                              : (obs["nom_vern_or_lb_nom"]?.contains(",") ??
                                    false)
                              ? obs["nom_vern_or_lb_nom"]!.split(',')[0]
                              : obs["nom_vern_or_lb_nom"] ?? "Aucune espèce";

                          final dateMin = formatDate(obs["date_min"]);

                          final subtitle =
                              (obs["lb_nom"] != null &&
                                  obs["nom_vern_or_lb_nom"] != null)
                              ? "${obs["nom_vern_or_lb_nom"]!.split(',')[0]} • $dateMin"
                              : dateMin;

                          final cdNom = obs["cd_nom"]?.toString() ?? "";

                          final isPolygon = obs["_isPolygon"] == true;

                          return Container(
                            decoration: BoxDecoration(
                              color: isPolygon
                                  ? Colors.grey.shade300
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 0,
                              ),
                              leading: const Icon(
                                Icons.info_outline,
                                size: 25,
                                color: Colors.green,
                              ),
                              title: Text(
                                species,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(subtitle),
                              trailing: isPolygon
                                  ? null
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.directions),
                                          onPressed: () =>
                                              openInMaps(context, lat, lon),
                                        ),
                                      ],
                                    ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => DetailObservationDialog(
                                    observationId: obs["_id"].toString(),
                                    cdNom: cdNom,
                                    api: api,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Fermer"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
