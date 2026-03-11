enum DateMode { betweenDates, period }

class MapFilters {
  final List<int> selectedCdRefs;
  final List<Map<String, dynamic>> selectedTaxonLabels;
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
      if (selectedCdRefs.isNotEmpty) {
        filters["cd_ref"] = selectedCdRefs;
      }

      if (selectedTaxonLabels.isNotEmpty) {
        final cdRefParents = selectedTaxonLabels
            .where((taxon) => taxon["nom_rang"] != null)
            .map((taxon) => taxon["cd_ref"])
            .toList();

        if (cdRefParents.isNotEmpty) {
          filters["cd_ref_parent"] = cdRefParents;
        }
      }

      if (selectedAreaComIds.isNotEmpty) {
        filters["area_COM"] = selectedAreaComIds;
      }

      if (selectedAreaDepIds.isNotEmpty) {
        filters["area_DEP"] = selectedAreaDepIds;
      }

      if (dateMin != null && dateMax != null) {
        if (dateMode == DateMode.period) {
          filters["period_start"] =
              "${dateMin!.day.toString().padLeft(2, '0')}/${dateMin!.month.toString().padLeft(2, '0')}";
          filters["period_end"] =
              "${dateMax!.day.toString().padLeft(2, '0')}/${dateMax!.month.toString().padLeft(2, '0')}";
        } else {
          filters["date_min"] =
              "${dateMin!.year}-${dateMin!.month.toString().padLeft(2, '0')}-${dateMin!.day.toString().padLeft(2, '0')}";
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
      selectedAreaComIds.isEmpty &&
      selectedAreaDepIds.isEmpty &&
      dateMin == null &&
      dateMax == null;
}
