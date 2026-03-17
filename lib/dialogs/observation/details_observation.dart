import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import './widget/share_position.dart';

const Map<String, String> nomenclatureFieldLabels = {
  // Caractéristiques biologiques
  "id_nomenclature_sex": "Sexe",
  "id_nomenclature_life_stage": "Stade de vie",
  "id_nomenclature_bio_condition": "Etat biologique",
  "id_nomenclature_bio_status": "Statut biologique",
  "id_nomenclature_naturalness": "Naturalité",
  "id_nomenclature_sensitivity": "Sensibilité",
  "id_nomenclature_behaviour": "Comportement",

  // Observation et validation
  "id_nomenclature_obs_technique": "Technique d'observation",
  "id_nomenclature_determination_method": "Méthode de détermination",
  "id_nomenclature_observation_status": "Statut d'observation",
  "id_nomenclature_source_status": "Statut source",
  "id_nomenclature_valid_status": "Statut de validation",

  // Géographie et environnement
  "id_nomenclature_geo_object_nature": "Nature de l'objet géographique",
  "id_nomenclature_info_geo_type": "Type d'information géographique",
  "id_nomenclature_biogeo_status": "Statut biogéographique",
  "id_nomenclature_diffusion_level": "Niveau de diffusion",
  "id_nomenclature_blurring": "Floutage",

  // Regroupements et dénombrements
  "id_nomenclature_grp_typ": "Type de regroupement",
  "id_nomenclature_obj_count": "Objet du dénombrement",
  "id_nomenclature_type_count": "Type de dénombrement",
  "id_nomenclature_exist_proof": "Preuve d'existence",
};

// Définition des catégories
final Map<String, List<String>> categories = {
  "Caractéristiques biologiques": [
    "id_nomenclature_sex",
    "id_nomenclature_life_stage",
    "id_nomenclature_bio_condition",
    "id_nomenclature_bio_status",
    "id_nomenclature_naturalness",
    "id_nomenclature_sensitivity",
    "id_nomenclature_behaviour",
  ],
  "Observation": [
    "id_nomenclature_obs_technique",
    "id_nomenclature_determination_method",
    "id_nomenclature_observation_status",
    "id_nomenclature_source_status",
    //"id_nomenclature_valid_status",
  ],
  "Localisation et diffusion": [
    "id_nomenclature_geo_object_nature",
    "id_nomenclature_info_geo_type",
    "id_nomenclature_biogeo_status",
    "id_nomenclature_diffusion_level",
    "id_nomenclature_blurring",
  ],
  "Dénombrement": [
    "id_nomenclature_grp_typ",
    "id_nomenclature_obj_count",
    "id_nomenclature_type_count",
    "id_nomenclature_exist_proof",
  ],
};

class DetailObservationDialog extends StatefulWidget {
  final String observationId;
  final String cdNom;
  final ApiService api;
  final double? lat;
  final double? lon;
  final bool isPolygon;

  const DetailObservationDialog({
    super.key,
    required this.observationId,
    required this.cdNom,
    required this.api,
    this.lat,
    this.lon,
    required this.isPolygon,
  });

  @override
  State<DetailObservationDialog> createState() =>
      _DetailObservationDialogState();
}

class _DetailObservationDialogState extends State<DetailObservationDialog> {
  late Future<Map<String, dynamic>> _futureObservation;
  late Future<Map<String, dynamic>> _futureTaxRef;
  String get baseUrlClean =>
      widget.api.baseUrl.replaceAll(RegExp(r'/api/?$'), '');

  @override
  void initState() {
    super.initState();

    _futureObservation = widget.api.fetchObservationDetail(
      widget.observationId,
    );

    _futureTaxRef = widget.cdNom.isNotEmpty
        ? widget.api.fetchTaxRef(widget.cdNom)
        : Future.value({});
  }

  String formatObservationDate(String? dateMin, String? dateMax) {
    if (dateMin == null) return "Date inconnue";

    DateTime min = DateTime.parse(dateMin);
    DateTime? max = dateMax != null ? DateTime.tryParse(dateMax) : null;

    String formatDay(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);
    String formatTime(DateTime dt) => DateFormat('HH:mm').format(dt);

    if (max == null || min.isAtSameMomentAs(max)) {
      return min.hour == 0 && min.minute == 0
          ? formatDay(min)
          : DateFormat('dd/MM/yyyy HH:mm').format(min);
    }

    if (min.year == max.year && min.month == max.month && min.day == max.day) {
      String dayPart = formatDay(min);
      String startTime = min.hour != 0 || min.minute != 0
          ? formatTime(min)
          : "";
      String endTime = formatTime(max);

      return startTime.isNotEmpty
          ? "$dayPart $startTime - $endTime"
          : "$dayPart - $endTime";
    }

    String formattedMin = min.hour == 0 && min.minute == 0
        ? formatDay(min)
        : DateFormat('dd/MM/yyyy HH:mm').format(min);

    String formattedMax = max.hour == 0 && max.minute == 0
        ? formatDay(max)
        : DateFormat('dd/MM/yyyy HH:mm').format(max);

    return "$formattedMin - $formattedMax";
  }

  String getFirstPart(String nomVern) {
    int commaIndex = nomVern.indexOf(',');
    if (commaIndex != -1) {
      return nomVern.substring(0, commaIndex).trim();
    }
    return nomVern;
  }

  List<Widget> buildMediaSection(List medias) {
    if (medias.isEmpty) return [];

    return [
      ExpansionTile(
        title: const Text(
          "Média(s)",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
        children: medias.map<Widget>((media) {
          final path = media["media_path"];
          if (path == null) return const SizedBox();

          const specialServers = ["https://reensauvagerlaferme.fr/geonature"];
          final bool isSpecialServer = specialServers.contains(baseUrlClean);

          final url = isSpecialServer
              ? "$baseUrlClean/api/$path"
              : "$baseUrlClean/api/media/attachments/$path";

          final isImage =
              path.toLowerCase().endsWith(".jpg") ||
              path.toLowerCase().endsWith(".jpeg") ||
              path.toLowerCase().endsWith(".png") ||
              path.toLowerCase().endsWith(".gif") ||
              path.toLowerCase().endsWith(".webp");

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isImage)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.play_circle_outline),
                          const SizedBox(width: 8),
                          Expanded(child: Text(url.split("/").last)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    ];
  }

  String? getNomenclatureLabel(Map props, String idField) {
    final suffix = idField.replaceFirst("id_", "");
    final nomenclature = props[suffix];

    if (nomenclature != null) {
      return nomenclature["label_default"] ?? nomenclature["label_fr"];
    }

    return null;
  }

  List<Widget> buildNomenclatureFields(Map props) {
    List<Widget> widgets = [];

    categories.forEach((categoryTitle, keys) {
      List<Widget> categoryWidgets = [];

      for (var key in keys) {
        if (key == "id_nomenclature_valid_status") continue;

        final value = getNomenclatureLabel(props, key);

        if (value != null &&
            value.isNotEmpty &&
            value != "Non renseigné" &&
            value != "Inconnu" &&
            value != "NSP" &&
            value != "Ne Sait Pas" &&
            value != "Ne sait pas") {
          categoryWidgets.add(const SizedBox(height: 4));
          categoryWidgets.add(Text("${nomenclatureFieldLabels[key]} : $value"));
        }
      }

      if (categoryWidgets.isNotEmpty) {
        // Ajouter le titre de catégorie uniquement si elle contient des champs
        widgets.add(const SizedBox(height: 8));
        widgets.add(
          Text(
            categoryTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );
        widgets.addAll(categoryWidgets);
        widgets.add(const SizedBox(height: 12));
      }
    });

    return widgets;
  }

  Color getValidationStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case "certain - très probable":
        return Colors.green;
      case "en attente de validation":
      case "probable":
        return Colors.orange;
      case "douteux":
      case "invalide":
        return Colors.red;
      case "inconnu":
      case "non réalisable":
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _futureObservation,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return const SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    "Erreur lors du chargement de l'observation",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            final observation = snapshot.data!;
            final props = observation["properties"] ?? {};

            final observer = props["observers"] ?? "Aucun observateur";

            final date = formatObservationDate(
              props["date_min"],
              props["date_max"],
            );

            final comObs = props["comment_description"];
            final comContext = props["comment_context"];

            final countMin = props["count_min"];
            final countMax = props["count_max"];

            String count = "";

            if (countMin != null && countMax != null) {
              count = countMin == countMax
                  ? "$countMin"
                  : "entre $countMin et $countMax";
            } else if (countMin != null) {
              count = "$countMin";
            } else if (countMax != null) {
              count = "$countMax";
            }

            final medias = props["medias"] ?? [];

            final datasetName = props['dataset']?['dataset_name'] ?? 'Inconnu';
            final acquisitionName =
                props['dataset']?['acquisition_framework']?['acquisition_framework_name'] ??
                'Inconnu';

            final validationLabel = getNomenclatureLabel(
              props,
              "id_nomenclature_valid_status",
            );
            final validationColor = getValidationStatusColor(validationLabel);

            return FutureBuilder<Map<String, dynamic>>(
              future: _futureTaxRef,
              builder: (context, taxSnapshot) {
                if (taxSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (taxSnapshot.hasError) {
                  return const SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        "Erreur lors du chargement des informations taxonomiques.",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Détails de l'observation",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.link, size: 20),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Row(
                                          children: const [
                                            Icon(
                                              Icons.warning,
                                              color: Colors.orange,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Attention'),
                                          ],
                                        ),
                                        content: Text(
                                          "Connexion nécessaire pour accèder à l'observation sur internet.\n\n"
                                          "La page internet peut ne pas s'ouvrir -et donner une erreur- sur certains serveurs mal configurés.\n\n"
                                          "Identifiant de l'observation : ${widget.observationId}",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.of(context).pop();

                                              final url = Uri.parse(
                                                "$baseUrlClean/#/synthese/occurrence/${widget.observationId}/details",
                                              );

                                              final messenger =
                                                  ScaffoldMessenger.of(context);

                                              if (await canLaunchUrl(url)) {
                                                await launchUrl(
                                                  url,
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                              } else {
                                                messenger.showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Impossible d'ouvrir le lien",
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Text('Ouvrir la page'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text('Annuler'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              MapActionButton(
                                lat: widget.lat,
                                lon: widget.lon,
                                isPolygon: widget.isPolygon,
                              ),
                            ],
                          ),
                        ],
                      ),

                      Text.rich(
                        TextSpan(
                          children: [
                            if (taxSnapshot.hasData &&
                                taxSnapshot.data!.isNotEmpty) ...[
                              if (getFirstPart(
                                taxSnapshot.data?["nom_vern"] ?? "",
                              ).isNotEmpty)
                                TextSpan(
                                  text: getFirstPart(
                                    taxSnapshot.data?["nom_vern"] ?? "",
                                  ),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF28A745),
                                  ),
                                ),

                              if ((getFirstPart(
                                    taxSnapshot.data?["nom_vern"] ?? "",
                                  ).isNotEmpty) &&
                                  ((taxSnapshot.data?["nom_valide"] ?? "")
                                      .isNotEmpty))
                                const TextSpan(text: "\n"),

                              // nomValide en italique
                              if ((taxSnapshot.data?["nom_valide"] ?? "")
                                  .isNotEmpty)
                                TextSpan(
                                  text: taxSnapshot.data?["nom_valide"] ?? "",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF28A745),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text: "Observateur(s) : ",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: "$observer"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),

                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text: "Date : ",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: date),
                          ],
                        ),
                      ),

                      if (count.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                            children: [
                              const TextSpan(
                                text: "Effectif : ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: count),
                            ],
                          ),
                        ),
                      ],

                      if (comObs != null && comObs.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                            children: [
                              const TextSpan(
                                text: "Commentaire : ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: "$comObs"),
                            ],
                          ),
                        ),
                      ],

                      if (comContext != null && comContext.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                            children: [
                              const TextSpan(
                                text: "Commentaire du relevé : ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: "$comContext"),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      ...buildMediaSection(medias),

                      ExpansionTile(
                        title: const Text(
                          "Plus de détails",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        childrenPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                        ),
                        tilePadding: EdgeInsets.zero,
                        children: [
                          // Les widgets existants
                          ...buildNomenclatureFields(props).map(
                            (widget) => Align(
                              alignment: Alignment.centerLeft,
                              child: widget,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.grey.shade100,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Jeu de données
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: "Jeu de données : ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: datasetName,
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () async {
                                            final url = Uri.parse(
                                              "$baseUrlClean/#/metadata/dataset_detail/${props['dataset']?['id_dataset'] ?? ''}",
                                            );
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(
                                                url,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            } else {
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Impossible d'ouvrir le lien",
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 4),

                                // Cadre d'acquisition
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: "Cadre d'acquisition : ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: acquisitionName,
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () async {
                                            final url = Uri.parse(
                                              "$baseUrlClean/#/metadata/af_detail/${props['dataset']?['acquisition_framework']?['id_acquisition_framework'] ?? ''}",
                                            );
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(
                                                url,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            } else {
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Impossible d'ouvrir le lien",
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (validationLabel != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: validationColor.withValues(alpha: .2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                validationLabel,
                                style: TextStyle(
                                  color: validationColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Fermer"),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
