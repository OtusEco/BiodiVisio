import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/theme.dart';

Future<void> showAboutBottomSheet(BuildContext context) async {
  // Récupération de PackageInfo pour avoir la version
  final packageInfo = await PackageInfo.fromPlatform();
  final appVersion = packageInfo.version;
  final String developerName = "Développé par OtusEco (GPLv3)";

  if (!context.mounted) return;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: MediaQuery.of(context).size.width * 0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                RichText(
                  textAlign: TextAlign.justify,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    children: [
                      const TextSpan(
                        text: "BiodiVisio",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const TextSpan(
                        text:
                            " est une application mobile open-source permettant de visualiser, explorer et consulter "
                            "les données naturalistes issues des plateformes ",
                      ),
                      TextSpan(
                        text: "GeoNature",
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final Uri url = Uri.parse("https://geonature.fr");
                            if (!await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            )) {
                              debugPrint("Impossible d'ouvrir GeoNature");
                            }
                          },
                      ),
                      const TextSpan(
                        text:
                            ".\n\nElle offre une interface cartographique fluide, des outils de recherche avancés (taxonomie, espace, "
                            "période) et un accès rapide aux informations d'observation pour les naturalistes, gestionnaires d'espaces naturels et chercheurs.\n\n"
                            "Conçue pour une utilisation sur le terrain, ",
                      ),
                      const TextSpan(
                        text: "BiodiVisio",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const TextSpan(
                        text:
                            " facilite l'accès et la diffusion de la connaissance sur la biodiversité.",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Légende
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Légende :",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blue),
                          SizedBox(width: 8),
                          Text("Position précise"),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.wrong_location, color: Colors.orange),
                          SizedBox(width: 8),
                          Text("Position approximative"),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_off, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Position non diffusée"),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Boutons
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final Uri url = Uri.parse(
                                "https://github.com/OtusEco/BiodiVisio/issues/new",
                              );
                              if (!await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              )) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Impossible d'ouvrir la page de signalement",
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.bug_report),
                            label: const Text("Problème"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final Uri url = Uri.parse(
                                "https://github.com/OtusEco/BiodiVisio/issues/new",
                              );
                              if (!await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              )) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Impossible d'ouvrir la page de suggestion",
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.lightbulb),
                            label: const Text("Suggestion"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final Uri url = Uri.parse(
                                "https://github.com/OtusEco/BiodiVisio",
                              );
                              if (!await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              )) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Impossible d'ouvrir le dépôt GitHub",
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.code),
                            label: const Text("Code source"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final body = Uri.encodeComponent(
                                "\r\n#####\nApplication BiodiVisio\n- version $appVersion\n- depuis à propos\n#####",
                              );
                              final Uri emailLaunchUri = Uri(
                                scheme: 'mailto',
                                path: 'biodivisio@outlook.fr',
                                query:
                                    "subject=BiodiVisio - Message depuis l'application&body=$body",
                              );

                              if (!await launchUrl(emailLaunchUri)) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Impossible d'ouvrir l'application mail",
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.email),
                            label: const Text("Contact"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Version
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Version $appVersion",
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      developerName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
