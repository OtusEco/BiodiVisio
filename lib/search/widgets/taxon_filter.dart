import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/theme.dart';

enum TaxonSearchType { taxon, ranks }

class TaxonFilterSection extends StatefulWidget {
  final ApiService apiService;
  final List<int> selectedCdRefs;
  final List<Map<String, dynamic>> selectedTaxonLabels;

  const TaxonFilterSection({
    super.key,
    required this.apiService,
    required this.selectedCdRefs,
    required this.selectedTaxonLabels,
  });

  @override
  State<TaxonFilterSection> createState() => _TaxonFilterSectionState();
}

class _TaxonFilterSectionState extends State<TaxonFilterSection> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> suggestions = [];
  Timer? _debounce;
  TaxonSearchType searchType = TaxonSearchType.taxon;

  String get fieldHint {
    return searchType == TaxonSearchType.taxon
        ? "Rechercher un taxon"
        : "Rechercher un rang";
  }

  Future<void> _search(String value) async {
    if (value.length < 3) {
      setState(() => suggestions = []);
      return;
    }

    try {
      final results = await widget.apiService.searchTaxons(
        value,
        useRanks: searchType == TaxonSearchType.ranks,
      );
      if (!mounted) return;
      setState(() => suggestions = results);
    } catch (_) {
      if (!mounted) return;
      setState(() => suggestions = []);
    }
  }

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      title: "Quoi ?",
      icon: Icons.travel_explore,
      children: [
        const Text(
          "Type de recherche",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        DropdownButton<TaxonSearchType>(
          value: searchType,
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: TaxonSearchType.taxon,
              child: Text("Taxon"),
            ),
            DropdownMenuItem(
              value: TaxonSearchType.ranks,
              child: Text("Rang taxonomique"),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                searchType = value;
                suggestions = [];
              });
            }
          },
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: fieldHint,
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: _onChanged,
        ),
        const SizedBox(height: 10),

        // Suggestions
        ...suggestions.map((taxon) {
          final lbNom = taxon["lb_nom"];
          final label = taxon["nom_vern"];
          final nomRang = taxon["nom_rang"];

          // Affichage selon le type de recherche (taxon/rang taxo)
          final displayText = searchType == TaxonSearchType.ranks
              ? "$nomRang : ${lbNom ?? 'Inconnu'}"
              : (label != null &&
                    label.isNotEmpty &&
                    lbNom != null &&
                    label != lbNom)
              ? "$label - $lbNom"
              : lbNom ?? "Inconnu";

          final cdRef = taxon["cd_ref"];

          return ListTile(
            dense: true,
            title: Text(displayText),
            onTap: () {
              if (!widget.selectedCdRefs.contains(cdRef)) {
                setState(() {
                  widget.selectedCdRefs.add(cdRef);
                  widget.selectedTaxonLabels.add(taxon);
                  suggestions = [];
                });
              }
              _controller.clear();
            },
          );
        }),

        // affichage nom_rang : lb_nom
        Wrap(
          spacing: 6,
          children: widget.selectedTaxonLabels.map((taxon) {
            final lbNom = taxon["lb_nom"] ?? "Inconnu";
            final nomRang = taxon["nom_rang"] ?? "Taxon";
            final displayText = "$nomRang : $lbNom";
            final index = widget.selectedTaxonLabels.indexOf(taxon);

            return Chip(
              label: Text(displayText),
              onDeleted: () {
                setState(() {
                  widget.selectedTaxonLabels.removeAt(index);
                  widget.selectedCdRefs.removeAt(index);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}
