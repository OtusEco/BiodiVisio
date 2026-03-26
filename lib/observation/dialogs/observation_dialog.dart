import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/api_service.dart';
import '../widgets/share_position.dart';
import 'details_observation.dart';
import '../../core/theme/theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final hasPointObservation = observations.any(
      (obs) => obs["_isPolygon"] != true,
    );

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: AppColors.card,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Titre
                    const Expanded(
                      child: Text(
                        "Liste des observations",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Bouton à droite
                    Row(
                      children: [
                        if (hasPointObservation)
                          MapActionButton(lat: lat, lon: lon, isPolygon: false),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: observations.isEmpty
                    ? const Center(
                        child: Text(
                          "Aucune observation",
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: observations.length,
                        separatorBuilder: (context, index) =>
                            const Divider(color: AppColors.border),
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
                                color: AppColors.secondary,
                              ),
                              title: Text(
                                species,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(subtitle),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => DetailObservationDialog(
                                    observationId: obs["_id"].toString(),
                                    cdNom: cdNom,
                                    api: api,
                                    isPolygon: isPolygon,
                                    lat: obs["_lat"],
                                    lon: obs["_lon"],
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
