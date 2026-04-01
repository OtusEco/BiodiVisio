enum DateMode { betweenDates, period }

class MapFilters {
  final List<int> selectedCdRefs;
  final List<Map<String, dynamic>> selectedTaxonLabels;
  final List<String> selectedHabitat;
  final List<String> selectedGroup2;
  final List<String> selectedGroup3;
  final List<int> selectedAreaComIds;
  final List<String> selectedAreaComNames;
  final List<int> selectedAreaDepIds;
  final List<String> selectedAreaDepNames;
  final DateTime? dateMin;
  final DateTime? dateMax;
  final DateMode dateMode;

  const MapFilters({
    this.selectedCdRefs = const [],
    this.selectedTaxonLabels = const [],
    this.selectedHabitat = const [],
    this.selectedGroup2 = const [],
    this.selectedGroup3 = const [],
    this.selectedAreaComIds = const [],
    this.selectedAreaComNames = const [],
    this.selectedAreaDepIds = const [],
    this.selectedAreaDepNames = const [],
    this.dateMin,
    this.dateMax,
    this.dateMode = DateMode.betweenDates,
  });

  Map<String, dynamic> toApiPayload({required bool isFirstLoad}) {
    final Map<String, dynamic> filters = {};

    if (!isFirstLoad) {
      // Taxons
      final cdRefs = selectedTaxonLabels
          .where((t) => t["isRank"] != true)
          .map((t) => t["cd_ref"])
          .toList();
      if (cdRefs.isNotEmpty) filters["cd_ref"] = cdRefs;

      // Rangs
      final cdRefParents = selectedTaxonLabels
          .where((t) => t["isRank"] == true)
          .map((t) => t["cd_ref"])
          .toList();
      if (cdRefParents.isNotEmpty) {
        filters["cd_ref_parent"] = cdRefParents;
      }

      // Habitat
      if (selectedHabitat.isNotEmpty) {
        filters["taxonomy_id_hab"] =
            selectedHabitat.map((e) => int.parse(e)).toList();
      }

      // Groupe 2
      if (selectedGroup2.isNotEmpty) {
        filters["taxonomy_group2_inpn"] = selectedGroup2;
      }

      // Groupe 3
      if (selectedGroup3.isNotEmpty) {
        filters["taxonomy_group3_inpn"] = selectedGroup3;
      }

      // Localisation
      if (selectedAreaComIds.isNotEmpty) {
        filters["area_COM"] = selectedAreaComIds;
      }
      if (selectedAreaDepIds.isNotEmpty) {
        filters["area_DEP"] = selectedAreaDepIds;
      }

      // Dates
      if (dateMode == DateMode.period) {
        if (dateMin != null && dateMax != null) {
          filters["period_start"] =
              "${dateMin!.day.toString().padLeft(2, '0')}/${dateMin!.month.toString().padLeft(2, '0')}";
          filters["period_end"] =
              "${dateMax!.day.toString().padLeft(2, '0')}/${dateMax!.month.toString().padLeft(2, '0')}";
        }
      } else {
        if (dateMin != null) {
          filters["date_min"] =
              "${dateMin!.year}-${dateMin!.month.toString().padLeft(2, '0')}-${dateMin!.day.toString().padLeft(2, '0')}";
        }

        if (dateMax != null) {
          filters["date_max"] =
              "${dateMax!.year}-${dateMax!.month.toString().padLeft(2, '0')}-${dateMax!.day.toString().padLeft(2, '0')}";
        }
      }
    }

    return filters;
  }

  bool get isEmpty =>
      selectedCdRefs.isEmpty &&
      selectedTaxonLabels.isEmpty &&
      selectedHabitat.isEmpty &&
      selectedGroup2.isEmpty &&
      selectedGroup3.isEmpty &&
      selectedAreaComIds.isEmpty &&
      selectedAreaDepIds.isEmpty &&
      dateMin == null &&
      dateMax == null;
}
