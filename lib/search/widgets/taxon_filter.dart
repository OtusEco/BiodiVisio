import 'dart:async';

import 'package:flutter/material.dart';

import 'package:biodivisio/core/services/api_service.dart';
import 'package:biodivisio/core/theme/theme.dart';

import '../data/data.dart';

enum TaxonSearchType {
  taxon,
  ranks,
  protection,
  regulation,
  worldwideRedList,
  europeanRedList,
  nationalRedList,
  regionalRedList,
  habitat,
  group2,
  group3,
}

enum _SelectionGroup {
  taxon,
  protection,
  regulation,
  worldwide,
  european,
  national,
  regional,
  habitat,
  group2,
  group3,
}

class TaxonFilterSection extends StatefulWidget {
  final ApiService apiService;
  final List<int> selectedCdRefs;
  final List<Map<String, dynamic>> selectedTaxonLabels;
  final List<String> selectedProtection;
  final List<String> selectedRegulation;
  final List<String> selectedWorldwide;
  final List<String> selectedEuropean;
  final List<String> selectedNational;
  final List<String> selectedRegional;
  final List<String> selectedHabitat;
  final List<String> selectedGroup2;
  final List<String> selectedGroup3;

  const TaxonFilterSection({
    super.key,
    required this.apiService,
    required this.selectedCdRefs,
    required this.selectedTaxonLabels,
    required this.selectedProtection,
    required this.selectedRegulation,
    required this.selectedWorldwide,
    required this.selectedEuropean,
    required this.selectedNational,
    required this.selectedRegional,
    required this.selectedHabitat,
    required this.selectedGroup2,
    required this.selectedGroup3,
  });

  @override
  State<TaxonFilterSection> createState() => _TaxonFilterSectionState();
}

class _TaxonFilterSectionState extends State<TaxonFilterSection> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> suggestions = [];
  Timer? _debounce;
  TaxonSearchType searchType = TaxonSearchType.taxon;

  List<FilterOption<String>> protectionFiltered = [];
  List<FilterOption<String>> regulationFiltered = [];
  List<FilterOption<String>> worldwideFiltered = [];
  List<FilterOption<String>> europeanFiltered = [];
  List<FilterOption<String>> nationalFiltered = [];
  List<FilterOption<String>> regionalFiltered = [];
  List<FilterOption<String>> habitatFiltered = [];
  List<FilterOption<String>> group2Filtered = [];
  List<FilterOption<String>> group3Filtered = [];

  @override
  void initState() {
    super.initState();

    protectionFiltered = List.from(protectionStatusOptions);
    regulationFiltered = List.from(regulationStatusOptions);
    worldwideFiltered = List.from(worldwideRedListOptions);
    europeanFiltered = List.from(europeanRedListOptions);
    nationalFiltered = List.from(nationalRedListOptions);
    regionalFiltered = List.from(regionalRedListOptions);
    habitatFiltered = List.from(habitatOptions);
    group2Filtered = List.from(group2Options);
    group3Filtered = List.from(group3Options);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String get fieldHint {
    return searchType == TaxonSearchType.taxon
        ? "Rechercher un taxon"
        : "Rechercher un rang";
  }

  _SelectionGroup _groupForType(TaxonSearchType type) {
    switch (type) {
      case TaxonSearchType.taxon:
      case TaxonSearchType.ranks:
        return _SelectionGroup.taxon;
      case TaxonSearchType.protection:
        return _SelectionGroup.protection;
      case TaxonSearchType.regulation:
        return _SelectionGroup.regulation;
      case TaxonSearchType.worldwideRedList:
        return _SelectionGroup.worldwide;
      case TaxonSearchType.europeanRedList:
        return _SelectionGroup.european;
      case TaxonSearchType.nationalRedList:
        return _SelectionGroup.national;
      case TaxonSearchType.regionalRedList:
        return _SelectionGroup.regional;
      case TaxonSearchType.habitat:
        return _SelectionGroup.habitat;
      case TaxonSearchType.group2:
        return _SelectionGroup.group2;
      case TaxonSearchType.group3:
        return _SelectionGroup.group3;
    }
  }

  bool _hasAnySelection() {
    return widget.selectedTaxonLabels.isNotEmpty ||
        widget.selectedProtection.isNotEmpty ||
        widget.selectedRegulation.isNotEmpty ||
        widget.selectedWorldwide.isNotEmpty ||
        widget.selectedEuropean.isNotEmpty ||
        widget.selectedNational.isNotEmpty ||
        widget.selectedRegional.isNotEmpty ||
        widget.selectedHabitat.isNotEmpty ||
        widget.selectedGroup2.isNotEmpty ||
        widget.selectedGroup3.isNotEmpty;
  }

  bool _hasSelectionOutsideGroup(_SelectionGroup group) {
    return (group != _SelectionGroup.taxon &&
            widget.selectedTaxonLabels.isNotEmpty) ||
        (group != _SelectionGroup.protection &&
            widget.selectedProtection.isNotEmpty) ||
        (group != _SelectionGroup.regulation &&
            widget.selectedRegulation.isNotEmpty) ||
        (group != _SelectionGroup.worldwide &&
            widget.selectedWorldwide.isNotEmpty) ||
        (group != _SelectionGroup.european &&
            widget.selectedEuropean.isNotEmpty) ||
        (group != _SelectionGroup.national &&
            widget.selectedNational.isNotEmpty) ||
        (group != _SelectionGroup.regional &&
            widget.selectedRegional.isNotEmpty) ||
        (group != _SelectionGroup.habitat &&
            widget.selectedHabitat.isNotEmpty) ||
        (group != _SelectionGroup.group2 && widget.selectedGroup2.isNotEmpty) ||
        (group != _SelectionGroup.group3 && widget.selectedGroup3.isNotEmpty);
  }

  bool _canSelectType(TaxonSearchType type) {
    final group = _groupForType(type);
    if (!_hasAnySelection()) return true;
    return !_hasSelectionOutsideGroup(group);
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

  List<FilterOption<String>> _filterOptions(
    List<FilterOption<String>> options,
    String query,
  ) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return List.from(options);
    return options
        .where((option) => option.label.toLowerCase().contains(q))
        .toList();
  }

  FilterOption<String> _findOptionOrUnknown(
    List<FilterOption<String>> options,
    String value,
  ) {
    return options.firstWhere(
      (o) => o.value == value,
      orElse: () => FilterOption(label: "Inconnu", value: value),
    );
  }

  Widget _buildSelectableFilterList({
    required List<FilterOption<String>> filteredOptions,
    required String hint,
    required ValueChanged<String> onSearch,
    required List<String> selectedValues,
    required ValueChanged<String> onToggle,
    required String emptyText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            isDense: true,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: onSearch,
        ),
        const SizedBox(height: 10),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: filteredOptions.isEmpty
              ? Center(
                  child: Text(
                    emptyText,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    itemCount: filteredOptions.length,
                    itemBuilder: (context, index) {
                      final option = filteredOptions[index];
                      final isSelected = selectedValues.contains(option.value);

                      return ListTile(
                        dense: true,
                        title: Text(option.label),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                              )
                            : const Icon(Icons.circle_outlined),
                        onTap: () => onToggle(option.value),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildChipsFromValues({
    required List<String> selectedValues,
    required List<FilterOption<String>> options,
    required String prefix,
    required void Function(String value) onDelete,
  }) {
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: selectedValues.map((value) {
        final option = _findOptionOrUnknown(options, value);
        return Chip(
          label: Text("$prefix${option.label}"),
          onDeleted: () => onDelete(value),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSelectTaxonOrRank = _canSelectType(TaxonSearchType.taxon);
    final canSelectProtection = _canSelectType(TaxonSearchType.protection);
    final canSelectRegulation = _canSelectType(TaxonSearchType.regulation);
    final canSelectWorldwide = _canSelectType(TaxonSearchType.worldwideRedList);
    final canSelectEuropean = _canSelectType(TaxonSearchType.europeanRedList);
    final canSelectNational = _canSelectType(TaxonSearchType.nationalRedList);
    final canSelectRegional = _canSelectType(TaxonSearchType.regionalRedList);
    final canSelectHabitat = _canSelectType(TaxonSearchType.habitat);
    final canSelectGroup2 = _canSelectType(TaxonSearchType.group2);
    final canSelectGroup3 = _canSelectType(TaxonSearchType.group3);

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
              value: TaxonSearchType.protection,
              enabled: canSelectProtection,
              child: Text(
                "Protection",
                style: TextStyle(
                  color: canSelectProtection ? Colors.black : Colors.grey,
                ),
              ),
            ),
            DropdownMenuItem(
              value: TaxonSearchType.regulation,
              enabled: canSelectRegulation,
              child: Text(
                "Réglementation",
                style: TextStyle(
                  color: canSelectRegulation ? Colors.black : Colors.grey,
                ),
              ),
            ),
            DropdownMenuItem(
              value: TaxonSearchType.worldwideRedList,
              enabled: canSelectWorldwide,
              child: Text(
                "Liste rouge mondiale",
                style: TextStyle(
                  color: canSelectWorldwide ? Colors.black : Colors.grey,
                ),
              ),
            ),
            DropdownMenuItem(
              value: TaxonSearchType.europeanRedList,
              enabled: canSelectEuropean,
              child: Text(
                "Liste rouge européenne",
                style: TextStyle(
                  color: canSelectEuropean ? Colors.black : Colors.grey,
                ),
              ),
            ),
            DropdownMenuItem(
              value: TaxonSearchType.nationalRedList,
              enabled: canSelectNational,
              child: Text(
                "Liste rouge nationale",
                style: TextStyle(
                  color: canSelectNational ? Colors.black : Colors.grey,
                ),
              ),
            ),
            DropdownMenuItem(
              value: TaxonSearchType.regionalRedList,
              enabled: canSelectRegional,
              child: Text(
                "Liste rouge régionale",
                style: TextStyle(
                  color: canSelectRegional ? Colors.black : Colors.grey,
                ),
              ),
            ),
            DropdownMenuItem(
              value: TaxonSearchType.habitat,
              enabled: canSelectHabitat,
              child: Text(
                "Habitat",
                style: TextStyle(
                  color: canSelectHabitat ? Colors.black : Colors.grey,
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
            DropdownMenuItem(
              value: TaxonSearchType.group3,
              enabled: canSelectGroup3,
              child: Text(
                "Groupe 3 - INPN",
                style: TextStyle(
                  color: canSelectGroup3 ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            if (!_canSelectType(value)) return;

            setState(() {
              searchType = value;
              suggestions = [];
              _controller.clear();
              protectionFiltered = List.from(protectionStatusOptions);
              regulationFiltered = List.from(regulationStatusOptions);
              worldwideFiltered = List.from(worldwideRedListOptions);
              europeanFiltered = List.from(europeanRedListOptions);
              nationalFiltered = List.from(nationalRedListOptions);
              regionalFiltered = List.from(regionalRedListOptions);
              habitatFiltered = List.from(habitatOptions);
              group2Filtered = List.from(group2Options);
              group3Filtered = List.from(group3Options);
            });
          },
        ),
        const SizedBox(height: 10),
        if (searchType == TaxonSearchType.taxon ||
            searchType == TaxonSearchType.ranks) ...[
          TextField(
            controller: _controller,
            enabled: canSelectTaxonOrRank,
            decoration: InputDecoration(
              hintText: fieldHint,
              border: const OutlineInputBorder(),
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
        ] else if (searchType == TaxonSearchType.protection) ...[
          _buildSelectableFilterList(
            filteredOptions: protectionFiltered,
            hint: "Rechercher une protection",
            emptyText: "Aucune protection trouvée",
            selectedValues: widget.selectedProtection,
            onSearch: (value) {
              setState(() {
                protectionFiltered =
                    _filterOptions(protectionStatusOptions, value);
              });
            },
            onToggle: (value) {
              setState(() {
                if (widget.selectedProtection.contains(value)) {
                  widget.selectedProtection.remove(value);
                } else {
                  widget.selectedProtection.add(value);
                }
              });
            },
          ),
        ] else if (searchType == TaxonSearchType.regulation) ...[
          _buildSelectableFilterList(
            filteredOptions: regulationFiltered,
            hint: "Rechercher une réglementation",
            emptyText: "Aucune réglementation trouvée",
            selectedValues: widget.selectedRegulation,
            onSearch: (value) {
              setState(() {
                regulationFiltered =
                    _filterOptions(regulationStatusOptions, value);
              });
            },
            onToggle: (value) {
              setState(() {
                if (widget.selectedRegulation.contains(value)) {
                  widget.selectedRegulation.remove(value);
                } else {
                  widget.selectedRegulation.add(value);
                }
              });
            },
          ),
        ] else if (searchType == TaxonSearchType.worldwideRedList) ...[
          _buildSelectableFilterList(
            filteredOptions: worldwideFiltered,
            hint: "Rechercher dans la liste rouge mondiale",
            emptyText: "Aucune valeur trouvée",
            selectedValues: widget.selectedWorldwide,
            onSearch: (value) {
              setState(() {
                worldwideFiltered =
                    _filterOptions(worldwideRedListOptions, value);
              });
            },
            onToggle: (value) {
              setState(() {
                if (widget.selectedWorldwide.contains(value)) {
                  widget.selectedWorldwide.remove(value);
                } else {
                  widget.selectedWorldwide.add(value);
                }
              });
            },
          ),
        ] else if (searchType == TaxonSearchType.europeanRedList) ...[
          _buildSelectableFilterList(
            filteredOptions: europeanFiltered,
            hint: "Rechercher dans la liste rouge européenne",
            emptyText: "Aucune valeur trouvée",
            selectedValues: widget.selectedEuropean,
            onSearch: (value) {
              setState(() {
                europeanFiltered =
                    _filterOptions(europeanRedListOptions, value);
              });
            },
            onToggle: (value) {
              setState(() {
                if (widget.selectedEuropean.contains(value)) {
                  widget.selectedEuropean.remove(value);
                } else {
                  widget.selectedEuropean.add(value);
                }
              });
            },
          ),
        ] else if (searchType == TaxonSearchType.nationalRedList) ...[
          _buildSelectableFilterList(
            filteredOptions: nationalFiltered,
            hint: "Rechercher dans la liste rouge nationale",
            emptyText: "Aucune valeur trouvée",
            selectedValues: widget.selectedNational,
            onSearch: (value) {
              setState(() {
                nationalFiltered =
                    _filterOptions(nationalRedListOptions, value);
              });
            },
            onToggle: (value) {
              setState(() {
                if (widget.selectedNational.contains(value)) {
                  widget.selectedNational.remove(value);
                } else {
                  widget.selectedNational.add(value);
                }
              });
            },
          ),
        ] else if (searchType == TaxonSearchType.regionalRedList) ...[
          _buildSelectableFilterList(
            filteredOptions: regionalFiltered,
            hint: "Rechercher dans la liste rouge régionale",
            emptyText: "Aucune valeur trouvée",
            selectedValues: widget.selectedRegional,
            onSearch: (value) {
              setState(() {
                regionalFiltered =
                    _filterOptions(regionalRedListOptions, value);
              });
            },
            onToggle: (value) {
              setState(() {
                if (widget.selectedRegional.contains(value)) {
                  widget.selectedRegional.remove(value);
                } else {
                  widget.selectedRegional.add(value);
                }
              });
            },
          ),
        ] else if (searchType == TaxonSearchType.habitat) ...[
          _buildSelectableFilterList(
            filteredOptions: habitatFiltered,
            hint: "Rechercher un habitat",
            emptyText: "Aucun habitat trouvé",
            selectedValues: widget.selectedHabitat,
            onSearch: (value) {
              setState(() {
                habitatFiltered = _filterOptions(habitatOptions, value);
              });
            },
            onToggle: (value) {
              setState(() {
                if (widget.selectedHabitat.contains(value)) {
                  widget.selectedHabitat.remove(value);
                } else {
                  widget.selectedHabitat.add(value);
                }
              });
            },
          ),
        ] else if (searchType == TaxonSearchType.group2) ...[
          _buildSelectableFilterList(
            filteredOptions: group2Filtered,
            hint: "Rechercher un groupe",
            emptyText: "Aucun groupe trouvé",
            selectedValues: widget.selectedGroup2,
            onSearch: (value) {
              setState(() {
                group2Filtered = _filterOptions(group2Options, value);
              });
            },
            onToggle: (value) {
              setState(() {
                if (widget.selectedGroup2.contains(value)) {
                  widget.selectedGroup2.remove(value);
                } else {
                  widget.selectedGroup2.add(value);
                }
              });
            },
          ),
        ] else if (searchType == TaxonSearchType.group3) ...[
          _buildSelectableFilterList(
            filteredOptions: group3Filtered,
            hint: "Rechercher un groupe",
            emptyText: "Aucun groupe trouvé",
            selectedValues: widget.selectedGroup3,
            onSearch: (value) {
              setState(() {
                group3Filtered = _filterOptions(group3Options, value);
              });
            },
            onToggle: (value) {
              setState(() {
                if (widget.selectedGroup3.contains(value)) {
                  widget.selectedGroup3.remove(value);
                } else {
                  widget.selectedGroup3.add(value);
                }
              });
            },
          ),
        ],
        
        // Elements sélectionnés
        if (widget.selectedTaxonLabels.isNotEmpty) ...[
          const SizedBox(height: 10),
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
        ],
        if (widget.selectedProtection.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildChipsFromValues(
            selectedValues: widget.selectedProtection,
            options: protectionStatusOptions,
            prefix: "Protection : ",
            onDelete: (value) {
              setState(() {
                widget.selectedProtection.remove(value);
              });
            },
          ),
        ],
        if (widget.selectedRegulation.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildChipsFromValues(
            selectedValues: widget.selectedRegulation,
            options: regulationStatusOptions,
            prefix: "Réglementation : ",
            onDelete: (value) {
              setState(() {
                widget.selectedRegulation.remove(value);
              });
            },
          ),
        ],
        if (widget.selectedWorldwide.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildChipsFromValues(
            selectedValues: widget.selectedWorldwide,
            options: worldwideRedListOptions,
            prefix: "Liste rouge mondiale : ",
            onDelete: (value) {
              setState(() {
                widget.selectedWorldwide.remove(value);
              });
            },
          ),
        ],
        if (widget.selectedEuropean.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildChipsFromValues(
            selectedValues: widget.selectedEuropean,
            options: europeanRedListOptions,
            prefix: "Liste rouge européenne : ",
            onDelete: (value) {
              setState(() {
                widget.selectedEuropean.remove(value);
              });
            },
          ),
        ],
        if (widget.selectedNational.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildChipsFromValues(
            selectedValues: widget.selectedNational,
            options: nationalRedListOptions,
            prefix: "Liste rouge nationale : ",
            onDelete: (value) {
              setState(() {
                widget.selectedNational.remove(value);
              });
            },
          ),
        ],
        if (widget.selectedRegional.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildChipsFromValues(
            selectedValues: widget.selectedRegional,
            options: regionalRedListOptions,
            prefix: "Liste rouge régionale : ",
            onDelete: (value) {
              setState(() {
                widget.selectedRegional.remove(value);
              });
            },
          ),
        ],
        if (widget.selectedHabitat.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildChipsFromValues(
            selectedValues: widget.selectedHabitat,
            options: habitatOptions,
            prefix: "Habitat : ",
            onDelete: (value) {
              setState(() {
                widget.selectedHabitat.remove(value);
              });
            },
          ),
        ],
        if (widget.selectedGroup2.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildChipsFromValues(
            selectedValues: widget.selectedGroup2,
            options: group2Options,
            prefix: "Groupe 2 : ",
            onDelete: (value) {
              setState(() {
                widget.selectedGroup2.remove(value);
              });
            },
          ),
        ],
        if (widget.selectedGroup3.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildChipsFromValues(
            selectedValues: widget.selectedGroup3,
            options: group3Options,
            prefix: "Groupe 3 : ",
            onDelete: (value) {
              setState(() {
                widget.selectedGroup3.remove(value);
              });
            },
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
