import 'package:flutter/material.dart';

import 'package:biodivisio/core/theme/theme.dart';

class _SpeciesStat {
  final String cdNom;
  final String lbNom;
  final String? nomVern;
  final int count;

  _SpeciesStat({
    required this.cdNom,
    required this.lbNom,
    required this.nomVern,
    required this.count,
  });
}

// Liste d'espèces
List<_SpeciesStat> _buildSpeciesStats(List<Map<String, dynamic>> observations) {
  final Map<String, _SpeciesStatBuilder> byCdNom = {};

  for (final obs in observations) {
    final cdNom = obs["cd_nom"]?.toString();
    final lbNom = (obs["lb_nom"]?.toString().trim().isNotEmpty ?? false)
        ? obs["lb_nom"].toString().trim()
        : "Inconnu";

    final nomVernRaw = obs["nom_vern"]?.toString().trim();
    final nomVernOrLbRaw = obs["nom_vern_or_lb_nom"]?.toString().trim();

    String? nomVern;

// Priorité au vrai champ nom_vern
    if (nomVernRaw != null && nomVernRaw.isNotEmpty && nomVernRaw != lbNom) {
      nomVern = nomVernRaw.split(',').first.trim();
    }
// Sinon on utilise nom_vern_or_lb_nom s'il est différent du nom scientifique
    else if (nomVernOrLbRaw != null &&
        nomVernOrLbRaw.isNotEmpty &&
        nomVernOrLbRaw != lbNom) {
      nomVern = nomVernOrLbRaw.split(',').first.trim();
    }

    final key = (cdNom != null && cdNom.isNotEmpty) ? cdNom : lbNom;

    final existing = byCdNom[key];
    if (existing == null) {
      byCdNom[key] = _SpeciesStatBuilder(
        cdNom: cdNom ?? "",
        lbNom: lbNom,
        nomVern: nomVern,
        count: 1,
      );
    } else {
      existing.count++;
      existing.nomVern ??= nomVern;
    }
  }

  final stats = byCdNom.values
      .map((b) => _SpeciesStat(
            cdNom: b.cdNom,
            lbNom: b.lbNom,
            nomVern: b.nomVern,
            count: b.count,
          ))
      .toList();

  stats.sort(
    (a, b) => a.lbNom.toLowerCase().compareTo(b.lbNom.toLowerCase()),
  );

  return stats;
}

class _SpeciesStatBuilder {
  final String cdNom;
  final String lbNom;
  String? nomVern;
  int count;

  _SpeciesStatBuilder({
    required this.cdNom,
    required this.lbNom,
    required this.nomVern,
    required this.count,
  });
}

const _moisAbreges = [
  "Jan",
  "Fév",
  "Mar",
  "Avr",
  "Mai",
  "Juin",
  "Juil",
  "Août",
  "Sep",
  "Oct",
  "Nov",
  "Déc",
];

const _moisComplets = [
  "Janvier",
  "Février",
  "Mars",
  "Avril",
  "Mai",
  "Juin",
  "Juillet",
  "Août",
  "Septembre",
  "Octobre",
  "Novembre",
  "Décembre",
];

// Répartition du nombre d'observations par mois (date_min)
List<int> _buildMonthCounts(List<Map<String, dynamic>> observations) {
  final counts = List<int>.filled(12, 0);

  for (final obs in observations) {
    final dateMin = obs["date_min"]?.toString();
    if (dateMin == null || dateMin.isEmpty) continue;

    final date = DateTime.tryParse(dateMin);
    if (date == null) continue;

    counts[date.month - 1]++;
  }

  return counts;
}

Future<void> showStatisticsBottomSheet(
  BuildContext context, {
  required List<Map<String, dynamic>> observations,
}) async {
  final speciesStats = _buildSpeciesStats(observations);
  final monthCounts = _buildMonthCounts(observations);

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
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: _StatisticsSheet(
            speciesStats: speciesStats,
            monthCounts: monthCounts,
          ),
        ),
      );
    },
  );
}

class _StatisticsSheet extends StatelessWidget {
  final List<_SpeciesStat> speciesStats;
  final List<int> monthCounts;

  const _StatisticsSheet({
    required this.speciesStats,
    required this.monthCounts,
  });

  // Liste des onglets
  static const _tabs = [
    Tab(icon: Icon(Icons.pets), text: "Espèces"),
    Tab(icon: Icon(Icons.bar_chart), text: "Phénologie"),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.query_stats, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Statistiques",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: "Fermer",
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          TabBar(
            tabs: _tabs,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
          ),

          const Divider(height: 1),

          Expanded(
            child: TabBarView(
              children: [
                _SpeciesTab(speciesStats: speciesStats),
                _PhenologyTab(monthCounts: monthCounts),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeciesTab extends StatefulWidget {
  final List<_SpeciesStat> speciesStats;

  const _SpeciesTab({required this.speciesStats});

  @override
  State<_SpeciesTab> createState() => _SpeciesTabState();
}

enum SpeciesSort {
  alphabetical,
  observationsDesc,
}

class _SpeciesTabState extends State<_SpeciesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = "";
  SpeciesSort _sort = SpeciesSort.observationsDesc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_SpeciesStat> get _filtered {
    List<_SpeciesStat> result = List.from(widget.speciesStats);

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();

      result = result.where((s) {
        final lbMatch = s.lbNom.toLowerCase().contains(q);
        final vernMatch = s.nomVern?.toLowerCase().contains(q) ?? false;
        return lbMatch || vernMatch;
      }).toList();
    }

    switch (_sort) {
      case SpeciesSort.alphabetical:
        result.sort(
          (a, b) => a.lbNom.toLowerCase().compareTo(b.lbNom.toLowerCase()),
        );
        break;

      case SpeciesSort.observationsDesc:
        result.sort((a, b) {
          final cmp = b.count.compareTo(a.count);
          if (cmp != 0) return cmp;
          return a.lbNom.toLowerCase().compareTo(b.lbNom.toLowerCase());
        });
        break;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totalObservations =
        filtered.fold<int>(0, (sum, species) => sum + species.count);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Rechercher une espèce...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: _sort == SpeciesSort.observationsDesc
                        ? "Tri : nombre d'observations"
                        : "Tri : A → Z",
                    icon: Icon(
                      _sort == SpeciesSort.observationsDesc
                          ? Icons.bar_chart
                          : Icons.sort_by_alpha,
                    ),
                    onPressed: () {
                      setState(() {
                        _sort = _sort == SpeciesSort.observationsDesc
                            ? SpeciesSort.alphabetical
                            : SpeciesSort.observationsDesc;
                      });
                    },
                  ),
                  if (_query.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _query = "";
                        });
                      },
                    ),
                ],
              ),
              isDense: true,
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                "${filtered.length} espèce${filtered.length > 1 ? 's' : ''} "
                "($totalObservations observation${totalObservations > 1 ? 's' : ''})",
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: widget.speciesStats.isEmpty
              ? const Center(
                  child: Text(
                    "Aucune espèce à afficher",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : filtered.isEmpty
                  ? const Center(
                      child: Text(
                        "Aucune espèce ne correspond à la recherche",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: AppColors.border, height: 1),
                      itemBuilder: (context, index) {
                        final species = filtered[index];

                        return ListTile(
                          leading: const Icon(
                            Icons.eco,
                            color: AppColors.secondary,
                          ),
                          title: Text(
                            species.lbNom,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          subtitle: species.nomVern != null
                              ? Text(species.nomVern!)
                              : null,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              "${species.count}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _PhenologyTab extends StatelessWidget {
  final List<int> monthCounts;

  const _PhenologyTab({required this.monthCounts});

  @override
  Widget build(BuildContext context) {
    final total = monthCounts.fold<int>(0, (sum, c) => sum + c);
    final maxCount = monthCounts.fold<int>(0, (m, c) => c > m ? c : m);

    if (total == 0) {
      return const Center(
        child: Text(
          "Aucune observation datée à afficher",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                "Répartition des observations par mois",
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (index) {
                final count = monthCounts[index];
                final ratio = maxCount == 0 ? 0.0 : count / maxCount;
                final isMax = maxCount > 0 && count == maxCount;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          count > 0 ? "$count" : "",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Tooltip(
                              message:
                                  "${_moisComplets[index]} : $count observation${count > 1 ? 's' : ''}",
                              child: FractionallySizedBox(
                                heightFactor: ratio.clamp(0.02, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isMax
                                        ? AppColors.primary
                                        : AppColors.secondary,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _moisAbreges[index],
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}