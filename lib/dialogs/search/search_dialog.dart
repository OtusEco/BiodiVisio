import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/map_search.dart';

import 'widgets/taxon_filter.dart';
import 'widgets/location_filter.dart';
import 'widgets/date_filter.dart';

Future<MapFilters?> showFilterDialog({
  required BuildContext context,
  required ApiService apiService,
  required MapFilters currentFilters,
}) async {
  DateFilterMode dateMode = currentFilters.dateMode == DateMode.period
      ? DateFilterMode.period
      : DateFilterMode.betweenDates;

  DateTime? selectedDateMin = currentFilters.dateMin;
  DateTime? selectedDateMax = currentFilters.dateMax;

  // selectedTaxonLabels = List<Map<String,dynamic>>
  final selectedCdRefs = List<int>.from(currentFilters.selectedCdRefs);
  final selectedTaxonLabels = List<Map<String, dynamic>>.from(
    currentFilters.selectedTaxonLabels,
  );

  final selectedAreaComIds = List<int>.from(currentFilters.selectedAreaComIds);
  final selectedAreaComNames = List<String>.from(
    currentFilters.selectedAreaComNames,
  );

  final selectedAreaDepIds = List<int>.from(currentFilters.selectedAreaDepIds);
  final selectedAreaDepNames = List<String>.from(
    currentFilters.selectedAreaDepNames,
  );

  return showModalBottomSheet<MapFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
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
                      ),

                      const SizedBox(height: 15),

                      // Localisation
                      LocationFilterSection(
                        apiService: apiService,
                        selectedAreaComIds: selectedAreaComIds,
                        selectedAreaComNames: selectedAreaComNames,
                        selectedAreaDepIds: selectedAreaDepIds,
                        selectedAreaDepNames: selectedAreaDepNames,
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

                      // Boutons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setStateDialog(() {
                                selectedCdRefs.clear();
                                selectedTaxonLabels.clear();
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
                                color: Colors.red,
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
                                      selectedAreaComIds: selectedAreaComIds,
                                      selectedAreaComNames:
                                          selectedAreaComNames,
                                      selectedAreaDepIds: selectedAreaDepIds,
                                      selectedAreaDepNames:
                                          selectedAreaDepNames,
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
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}
