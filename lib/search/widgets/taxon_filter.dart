import 'dart:async';

import 'package:flutter/material.dart';

import 'package:biodivisio/core/services/api_service.dart';
import 'package:biodivisio/core/theme/theme.dart';

import '../data/data.dart';

enum TaxonSearchType { taxon, ranks, group2 }

class TaxonFilterSection extends StatefulWidget {
  final ApiService apiService;
  final List<int> selectedCdRefs;
  final List<Map<String, dynamic>> selectedTaxonLabels;
  final List<String> selectedGroup2;

  const TaxonFilterSection({
    super.key,
    required this.apiService,
    required this.selectedCdRefs,
    required this.selectedTaxonLabels,
    required this.selectedGroup2,
  });

  @override
  State<TaxonFilterSection> createState() => _TaxonFilterSectionState();
}

class _TaxonFilterSectionState extends State<TaxonFilterSection> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> suggestions = [];
  Timer? _debounce;
  TaxonSearchType searchType = TaxonSearchType.taxon;

  List<String> group2Filtered = [];

  @override
  void initState() {
    super.initState();
    group2Filtered = List.from(group2Options);
  }

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
    final canSelectTaxonOrRank = widget.selectedGroup2.isEmpty;
    final canSelectGroup2 = widget.selectedTaxonLabels.isEmpty;

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
          items: [
            DropdownMenuItem(
              value: TaxonSearchType.taxon,
              enabled: canSelectTaxonOrRank,
              child: Text(
                "Taxon",
                style: TextStyle(
                  color: canSelectTaxonOrRank ? Colors.black : Colors.grey,
                ),
              ),
            ),
            DropdownMenuItem(
              value: TaxonSearchType.ranks,
              enabled: canSelectTaxonOrRank,
              child: Text(
                "Rang taxonomique",
                style: TextStyle(
                  color: canSelectTaxonOrRank ? Colors.black : Colors.grey,
                ),
              ),
            ),
            DropdownMenuItem(
              value: TaxonSearchType.group2,
              enabled: canSelectGroup2,
              child: Text(
                "Groupe 2 - INPN",
                style: TextStyle(
                  color: canSelectGroup2 ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ],
          onChanged: (value) {
            if ((value == TaxonSearchType.group2 &&
                    widget.selectedTaxonLabels.isNotEmpty) ||
                ((value == TaxonSearchType.taxon ||
                        value == TaxonSearchType.ranks) &&
                    widget.selectedGroup2.isNotEmpty)) {
              return;
            }

            if (value != null) {
              setState(() {
                searchType = value;
                suggestions = [];
                group2Filtered = List.from(group2Options);
              });
            }
          },
        ),
        const SizedBox(height: 10),

        // Taxons/Rangs
        if (searchType == TaxonSearchType.taxon ||
            searchType == TaxonSearchType.ranks) ...[
          TextField(
            controller: _controller,
            enabled: canSelectTaxonOrRank,
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
            final displayText = searchType == TaxonSearchType.ranks
                ? "$nomRang : ${lbNom ?? 'Inconnu'}"
                : (label != null &&
                        label.isNotEmpty &&
                        lbNom != null &&
                        label != lbNom)
                    ? "$label - $lbNom"
                    : lbNom ?? "Inconnu";

            return ListTile(
              dense: true,
              title: Text(displayText),
              onTap: () {
                final cdRef = taxon["cd_ref"];
                final alreadySelected =
                    widget.selectedTaxonLabels.any((t) => t["cd_ref"] == cdRef);

                if (!alreadySelected) {
                  setState(() {
                    final enrichedTaxon = Map<String, dynamic>.from(taxon);
                    enrichedTaxon["isRank"] =
                        searchType == TaxonSearchType.ranks;
                    widget.selectedTaxonLabels.add(enrichedTaxon);
                    suggestions = [];
                  });
                }
                _controller.clear();
              },
            );
          }),
        ] else ...[
          // Groupe 2
          TextField(
            decoration: InputDecoration(
              hintText: "Rechercher un groupe",
              border: const OutlineInputBorder(),
              isDense: true,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                group2Filtered = group2Options
                    .where((g) => g.toLowerCase().contains(value.toLowerCase()))
                    .toList();
              });
            },
          ),
          const SizedBox(height: 10),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                itemCount: group2Filtered.length,
                itemBuilder: (context, index) {
                  final group = group2Filtered[index];
                  final isSelected = widget.selectedGroup2.contains(group);

                  return ListTile(
                    dense: true,
                    title: Text(group),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
                        : const Icon(Icons.circle_outlined),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          widget.selectedGroup2.remove(group);
                        } else {
                          widget.selectedGroup2.add(group);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ],

        // Elements sélectionnés
        Wrap(
          spacing: 4,
          runSpacing: 2,
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
                });
              },
            );
          }).toList(),
        ),
        if (widget.selectedGroup2.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            runSpacing: 2,
            children: widget.selectedGroup2.map((group) {
              return Chip(
                label: Text("Groupe 2 : $group"),
                onDeleted: () {
                  setState(() {
                    widget.selectedGroup2.remove(group);
                  });
                },
              );
            }).toList(),
          ),
        ],
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
