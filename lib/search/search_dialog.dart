import 'package:flutter/material.dart';

import 'package:biodivisio/core/services/api_service.dart';
import 'package:biodivisio/core/theme/theme.dart';

import 'models/map_search.dart';
import 'widgets/date_filter.dart';
import 'widgets/location_filter.dart';
import 'widgets/taxon_filter.dart';

Future<MapFilters?> showFilterDialog({
  required BuildContext context,
  required ApiService apiService,
  required MapFilters currentFilters,
}) async {
  // Quoi ?
  final selectedCdRefs = List<int>.from(currentFilters.selectedCdRefs);
  final selectedTaxonLabels =
      List<Map<String, dynamic>>.from(currentFilters.selectedTaxonLabels);
  final selectedProtection =
      List<String>.from(currentFilters.selectedProtection);
  final selectedRegulation =
      List<String>.from(currentFilters.selectedRegulation);
  bool selectedZnief = currentFilters.selectedZnief;
  final selectedWorldwide = List<String>.from(currentFilters.selectedWorldwide);
  final selectedEuropean = List<String>.from(currentFilters.selectedEuropean);
  final selectedNational = List<String>.from(currentFilters.selectedNational);
  final selectedRegional = List<String>.from(currentFilters.selectedRegional);
  final selectedHabitat = List<String>.from(currentFilters.selectedHabitat);
  final selectedGroup2 = List<String>.from(currentFilters.selectedGroup2);
  final selectedGroup3 = List<String>.from(currentFilters.selectedGroup3);

  // Où ?
  final selectedAreaComIds = List<int>.from(currentFilters.selectedAreaComIds);
  final selectedAreaComNames =
      List<String>.from(currentFilters.selectedAreaComNames);
  final selectedAreaDepIds = List<int>.from(currentFilters.selectedAreaDepIds);
  final selectedAreaDepNames =
      List<String>.from(currentFilters.selectedAreaDepNames);

  SpatialFilterType spatialFilterType = currentFilters.spatialFilterType;
  String? geoIntersection = currentFilters.geoIntersection;
  double? radius = currentFilters.radius;

  // Quand ?
  DateFilterMode dateMode = currentFilters.dateMode == DateMode.period
      ? DateFilterMode.period
      : DateFilterMode.betweenDates;
  DateTime? selectedDateMin = currentFilters.dateMin;
  DateTime? selectedDateMax = currentFilters.dateMax;

  return showModalBottomSheet<MapFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Chercher des observations",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Taxon
                          TaxonFilterSection(
                            apiService: apiService,
                            selectedCdRefs: selectedCdRefs,
                            selectedTaxonLabels: selectedTaxonLabels,
                            selectedProtection: selectedProtection,
                            selectedRegulation: selectedRegulation,
                            selectedZnief: selectedZnief,
                            selectedWorldwide: selectedWorldwide,
                            selectedEuropean: selectedEuropean,
                            selectedNational: selectedNational,
                            selectedRegional: selectedRegional,
                            selectedHabitat: selectedHabitat,
                            selectedGroup2: selectedGroup2,
                            selectedGroup3: selectedGroup3,
                            onZniefChanged: (value) {
                              setStateDialog(() {
                                selectedZnief = value;
                              });
                            },
                          ),

                          const SizedBox(height: 15),

                          // Localisation
                          LocationFilterSection(
                            apiService: apiService,
                            selectedAreaComIds: selectedAreaComIds,
                            selectedAreaComNames: selectedAreaComNames,
                            selectedAreaDepIds: selectedAreaDepIds,
                            selectedAreaDepNames: selectedAreaDepNames,
                            spatialFilterType: spatialFilterType,
                            onSpatialTypeChanged: (value) {
                              setStateDialog(() {
                                spatialFilterType = value;
                              });
                            },
                          ),

                          const SizedBox(height: 15),

                          // Période
                          DateFilterSection(
                            dateMode: dateMode,
                            dateMin: selectedDateMin,
                            dateMax: selectedDateMax,
                            onModeChanged: (mode) {
                              setStateDialog(() => dateMode = mode);
                            },
                            onDateMinChanged: (date) {
                              setStateDialog(() => selectedDateMin = date);
                            },
                            onDateMaxChanged: (date) {
                              setStateDialog(() => selectedDateMax = date);
                            },
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Boutons
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        12 + MediaQuery.of(context).viewInsets.bottom,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.card,
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setStateDialog(() {
                                selectedCdRefs.clear();
                                selectedTaxonLabels.clear();
                                selectedProtection.clear();
                                selectedRegulation.clear();
                                selectedZnief = false;
                                selectedWorldwide.clear();
                                selectedEuropean.clear();
                                selectedNational.clear();
                                selectedRegional.clear();
                                selectedHabitat.clear();
                                selectedGroup2.clear();
                                selectedGroup3.clear();
                                selectedAreaComIds.clear();
                                selectedAreaComNames.clear();
                                selectedAreaDepIds.clear();
                                selectedAreaDepNames.clear();
                                selectedDateMin = null;
                                selectedDateMax = null;
                                dateMode = DateFilterMode.betweenDates;
                              });
                            },
                            child: const Text(
                              "Effacer",
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Annuler"),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                    MapFilters(
                                      selectedCdRefs: selectedCdRefs,
                                      selectedTaxonLabels: selectedTaxonLabels,
                                      selectedProtection: selectedProtection,
                                      selectedRegulation: selectedRegulation,
                                      selectedZnief: selectedZnief,
                                      selectedWorldwide: selectedWorldwide,
                                      selectedEuropean: selectedEuropean,
                                      selectedNational: selectedNational,
                                      selectedRegional: selectedRegional,
                                      selectedHabitat: selectedHabitat,
                                      selectedGroup2: selectedGroup2,
                                      selectedGroup3: selectedGroup3,
                                      selectedAreaComIds: selectedAreaComIds,
                                      selectedAreaComNames:
                                          selectedAreaComNames,
                                      selectedAreaDepIds: selectedAreaDepIds,
                                      selectedAreaDepNames:
                                          selectedAreaDepNames,
                                      spatialFilterType: spatialFilterType,
                                      geoIntersection: geoIntersection,
                                      radius: radius,
                                      dateMin: selectedDateMin,
                                      dateMax: selectedDateMax,
                                      dateMode:
                                          dateMode == DateFilterMode.period
                                              ? DateMode.period
                                              : DateMode.betweenDates,
                                    ),
                                  );
                                },
                                child: const Text("Appliquer"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}