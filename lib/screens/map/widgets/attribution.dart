import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class MapAttribution extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;
  final String baseMapType;

  const MapAttribution({
    super.key,
    required this.expanded,
    required this.onTap,
    required this.baseMapType,
  });

  static const Map<String, String> _attributions = {
    "OSM": "© les contributeurs d'OpenStreetMap",
    "Satellite":
        "© Esri - Source : Esri, Maxar, Earthstar Geographics, and the GIS User Community",
  };

  String get attributionText =>
      _attributions[baseMapType] ?? "© Map data providers";

  @override
  Widget build(BuildContext context) {
    final text = expanded ? attributionText : baseMapType;

    return Positioned(
      left: 0,
      bottom: 0,
      child: SafeArea(
        minimum: EdgeInsets.only(
          left: 8,
          bottom: 8 + MediaQuery.of(context).padding.bottom,
        ),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: expanded
                  ? ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      child: _buildRow(text, allowWrap: true),
                    )
                  : IntrinsicWidth(child: _buildRow(text, allowWrap: false)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String text, {required bool allowWrap}) {
    // Gestion spéciale pour OpenStreetMap (avec lien)
    if (text.contains("OpenStreetMap")) {
      final parts = text.split("OpenStreetMap");
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.2,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(text: parts[0]),
                  TextSpan(
                    text: "OpenStreetMap",
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final Uri url = Uri.parse(
                          "https://www.openstreetmap.org/",
                        );
                        if (!await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        )) {
                          debugPrint("Impossible d'ouvrir OpenStreetMap");
                        }
                      },
                  ),
                  if (parts.length > 1) TextSpan(text: parts[1]),
                ],
              ),
              softWrap: allowWrap,
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              softWrap: allowWrap,
              overflow: allowWrap ? TextOverflow.visible : TextOverflow.clip,
              style: const TextStyle(
                fontSize: 12,
                height: 1.2,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      );
    }
  }
}
