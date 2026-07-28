import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:biodivisio/core/services/api_service.dart';
import 'package:biodivisio/core/services/location_service.dart';
import 'package:biodivisio/core/theme/theme.dart';
import 'package:biodivisio/login/login_screen.dart';
import 'package:biodivisio/observation/dialogs/observation_dialog.dart';
import 'package:biodivisio/observation/dialogs/details_dialog.dart';
import 'package:biodivisio/search/models/map_search.dart';
import 'package:biodivisio/search/search_dialog.dart';

import 'utils/geometry_utils.dart';
import 'widgets/about.dart';
import 'widgets/appbar.dart';
import 'widgets/attribution.dart';
import 'widgets/statistics.dart';
import 'widgets/view.dart';

class MapScreen extends StatefulWidget {
  final ApiService apiService;
  final bool skipInitialLoad;

  // WKT si ancien serveur
  final bool useWktGeometry;

  const MapScreen({
    super.key,
    required this.apiService,
    this.skipInitialLoad = false,
    this.useWktGeometry = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isFirstLoad = true;
  bool _loading = true;

  List<Marker> _markers = [];
  List<Polygon> _polygons = [];
  List<Marker> _userLocationMarker = [];

  // Observations brutes actuellement affichées (stats)
  List<Map<String, dynamic>> _allObservations = [];

  MapFilters _filters = const MapFilters();

  String _currentBaseMap = "OpenStreetMap";

  final Map<String, String> _baseMaps = {
    "OpenStreetMap": "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
    "Plan IGN":
        "https://data.geopf.fr/wmts?SERVICE=WMTS&VERSION=1.0.0&REQUEST=GetTile&LAYER=GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2&TILEMATRIXSET=PM&TILEMATRIX={z}&TILEROW={y}&TILECOL={x}&FORMAT=image/png&STYLE=normal",
    "Ortho IGN":
        "https://data.geopf.fr/wmts?SERVICE=WMTS&VERSION=1.0.0&REQUEST=GetTile&LAYER=ORTHOIMAGERY.ORTHOPHOTOS&TILEMATRIXSET=PM&TILEMATRIX={z}&TILEROW={y}&TILECOL={x}&FORMAT=image/jpeg&STYLE=normal",
    "OpenTopoMap": "https://tile.opentopomap.org/{z}/{x}/{y}.png",
  };

  double _currentZoom = 10;
  bool _isLocating = false;
  bool _osmExpanded = false;

  Timer? _locationTimer;

  // Dessin polygone/cercle
  bool _drawPolygonMode = false;
  bool _drawCircleMode = false;
  final List<LatLng> _polygonPoints = [];
  LatLng? _circleCenter;
  double? _circleRadius;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    if (!widget.skipInitialLoad) {
      loadData();
    } else {
      _isFirstLoad = false;
      _loading = false;
    }
  }

  // Sous titre
  String get _subtitle {
    if (_filters.isEmpty) {
      return widget.skipInitialLoad
          ? "Recherchez des observations pour les afficher"
          : "Affichage des 100 dernières observations du serveur";
    }

    final parts = <String>[];

    if (_filters.selectedTaxonLabels.isEmpty) {
      parts.add("Toutes les espèces");
    }

    // Taxons (seulement lb_nom pas de nom_rang)
    if (_filters.selectedTaxonLabels.isNotEmpty) {
      final cleaned = _filters.selectedTaxonLabels.map((taxon) {
        return taxon["lb_nom"] ?? "Inconnu";
      }).toList();

      parts.add(cleaned.join(", "));
    }

    final filterMap = {
      "Protection": _filters.selectedProtection,
      "Réglementation": _filters.selectedRegulation,
      "Liste rouge mondiale": _filters.selectedWorldwide,
      "Liste rouge européenne": _filters.selectedEuropean,
      "Liste rouge nationale": _filters.selectedNational,
      "Liste rouge régionale": _filters.selectedRegional,
      "Habitat": _filters.selectedHabitat,
      "Groupe 2 - INPN": _filters.selectedGroup2,
      "Groupe 3 - INPN": _filters.selectedGroup3,
    };

    filterMap.forEach((label, list) {
      if (list.isNotEmpty) parts.add("$label (${list.length})");
    });

    if (_filters.selectedZnief) {
      parts.add("Espèces ZNIEFF");
    }

    // Dates
    if (_filters.dateMin != null || _filters.dateMax != null) {
      String format(DateTime? d) {
        if (d == null) return "...";
        return "${d.day.toString().padLeft(2, '0')}/"
            "${d.month.toString().padLeft(2, '0')}/"
            "${d.year}";
      }

      parts.add("${format(_filters.dateMin)} ➔ ${format(_filters.dateMax)}");
    }

    // Localisation
    if (_filters.selectedAreaComNames.isNotEmpty) {
      parts.add(_filters.selectedAreaComNames.join(", "));
    }

    if (_filters.selectedAreaDepNames.isNotEmpty) {
      parts.add(_filters.selectedAreaDepNames.join(", "));
    }

    // Zone dessinée
    if (_filters.spatialFilterType == SpatialFilterType.polygon) {
      parts.add("Zone : polygone");
    } else if (_filters.spatialFilterType == SpatialFilterType.circle) {
      parts.add("Zone : cercle");
    }

    return parts.join(" • ");
  }

  // Emprise des points

  LatLngBounds? _computeBounds() {
    final allPoints = <LatLng>[];

    // Ajouter les markers
    allPoints.addAll(_markers.map((m) => m.point));

    // Ajouter les sommets des polygones dans l'emprise
    for (var poly in _polygons) {
      allPoints.addAll(poly.points);
    }

    // Filtrer les points invalides
    allPoints.removeWhere((p) => !p.latitude.isFinite || !p.longitude.isFinite);

    if (allPoints.isEmpty) return null;

    // un seul point dans la recherche
    if (allPoints.length == 1) {
      final p = allPoints.first;
      return LatLngBounds(
        LatLng(p.latitude - 0.01, p.longitude - 0.01),
        LatLng(p.latitude + 0.01, p.longitude + 0.01),
      );
    }

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (var p in allPoints) {
      if (!p.latitude.isFinite || !p.longitude.isFinite) continue;

      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    // Si les points sont au même endroit
    if (minLat == maxLat && minLng == maxLng) {
      return LatLngBounds(
        LatLng(minLat - 0.01, minLng - 0.01),
        LatLng(maxLat + 0.01, maxLng + 0.01),
      );
    }

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  void _fitBoundsIfNeeded() {
    if (_markers.isEmpty && _polygons.isEmpty) return;

    final bounds = _computeBounds();
    if (bounds == null) return;

// Protection contre zoom invalide
    final latDiff = (bounds.north - bounds.south).abs();
    final lngDiff = (bounds.east - bounds.west).abs();

    if (!latDiff.isFinite || !lngDiff.isFinite) return;
    if (latDiff == 0 && lngDiff == 0) return;

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  // Load data

  Future<void> loadData() async {
    setState(() => _loading = true);

    try {
      String endpoint = "/synthese/for_web?format=grouped_geom";

      final body = _filters.toApiPayload(isFirstLoad: _isFirstLoad);

      if (_isFirstLoad) {
        endpoint += "&limit=100"; // pour serveurs classiques
        body["limit"] = 100; // pour serveurs qui attendent dans le body
      }

      final data = await widget.apiService.postForWeb(endpoint, body: body);

      List features;

      if (data["features"] != null) {
        // format GeoNature classique
        features = List.from(data["features"]);
      } else if (data["data"]?["features"] != null) {
        // format serveur alternatif
        features = (data["data"]["features"] as List).map((f) {
          return {
            "type": "Feature",
            "geometry": {"type": f["type"], "coordinates": f["coordinates"]},
            "properties": f["properties"] ?? {},
          };
        }).toList();
      } else {
        throw Exception("Format GeoJSON inconnu");
      }

      final result = GeoJsonParser.parse(features);

      if (!mounted) return;

      setState(() {
        _markers = result.markers.map((data) {
          return Marker(
            width: 40,
            height: 40,
            point: data.position,
            child: GestureDetector(
              onTap: () {
                final observations = data.observations;

                if (observations.length == 1) {
                  final obs = observations.first;
                  final cdNom = obs["cd_nom"]?.toString() ?? "";

                  showDialog(
                    context: context,
                    builder: (_) => DetailObservationDialog(
                      observationId: obs["_id"].toString(),
                      cdNom: cdNom,
                      api: widget.apiService,
                      isPolygon: obs["_isPolygon"] == true,
                      lat: obs["_lat"],
                      lon: obs["_lon"],
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => ObservationDialog(
                      observations: observations,
                      lat: data.position.latitude,
                      lon: data.position.longitude,
                      api: widget.apiService,
                    ),
                  );
                }
              },
              child: Icon(
                _iconForType(data.type),
                color: _colorForType(data.type),
                size: 35,
              ),
            ),
          );
        }).toList();

        _polygons = result.polygons;
        _allObservations =
            result.markers.expand((m) => m.observations).toList();
        _loading = false;
        _isFirstLoad = false;
      });
    } on ApiException catch (e) {
      setState(() => _loading = false);

      if (!mounted) return;

      if (e.statusCode == 401) {
        widget.apiService.logout();

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove("session");

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text("⚠️ ${e.message}"),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      setState(() => _loading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("⚠️ Erreur inattendue"),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // Icônes fonctions du type de "précision"

  IconData _iconForType(MarkerType type) {
    switch (type) {
      case MarkerType.point:
        return Icons.location_on;
      case MarkerType.line:
        return Icons.wrong_location;
      case MarkerType.polygon:
        return Icons.location_off;
    }
  }

  Color _colorForType(MarkerType type) {
    switch (type) {
      case MarkerType.point:
        return AppColors.mapPoint;
      case MarkerType.line:
        return AppColors.mapLine;
      case MarkerType.polygon:
        return AppColors.mapPolygon;
    }
  }

  // Recherche

  Future<void> _openFilterDialog() async {
    final result = await showFilterDialog(
      context: context,
      apiService: widget.apiService,
      currentFilters: _filters,
    );

    if (result == null) return;

    setState(() => _filters = result);

    if (_filters.spatialFilterType == SpatialFilterType.polygon) {
      setState(() {
        _drawPolygonMode = true;
        _drawCircleMode = false;

        _polygonPoints.clear();
        _circleCenter = null;
        _circleRadius = null;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Cliquez sur la carte pour dessiner le polygone",
          ),
        ),
      );

      return;
    }

    if (_filters.spatialFilterType == SpatialFilterType.circle) {
      setState(() {
        _drawCircleMode = true;
        _drawPolygonMode = false;

        _polygonPoints.clear();
        _circleCenter = null;
        _circleRadius = null;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Premier clic = centre, deuxième clic = rayon",
          ),
        ),
      );

      return;
    }

    if (_filters.isEmpty) {
      if (widget.skipInitialLoad) {
        setState(() {
          _markers = [];
          _polygons = [];
          _allObservations = [];
          _loading = false;
        });
      } else {
        _isFirstLoad = true;
        loadData();
      }
    } else {
      _isFirstLoad = false;
      loadData();
    }
  }

  // Déconnexion

  void _logout() async {
    widget.apiService.logout();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("session");

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // Géolocalisation

  Future<void> _showUserLocation() async {
    _locationTimer?.cancel();
    setState(() => _isLocating = true);

    final double targetZoom = _currentZoom < 10 ? 10 : _currentZoom;

    final result = await LocationService.getUserLocation(
      onRefined: (refinedPosition) {
        if (!mounted) return;

        setState(() {
          _userLocationMarker = [
            Marker(
              width: 40,
              height: 40,
              point: refinedPosition,
              child: Icon(
                Icons.my_location,
                color: (_currentBaseMap == "OpenStreetMap" ||
                        _currentBaseMap == "Plan IGN" ||
                        _currentBaseMap == "OpenTopoMap")
                    ? Colors.black
                    : Colors.white,
                size: 35,
              ),
            ),
          ];
        });

        _startLocationTimer();
        _mapController.move(refinedPosition, targetZoom);
      },
      gpsError: () {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text("⚠️ Impossible d'obtenir une position GPS précise"),
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
    );

    if (!mounted) return;

    setState(() => _isLocating = false);

    if (!result.isSuccess) {
      String message;
      switch (result.error) {
        case LocationErrorType.serviceDisabled:
          message = "Service de localisation désactivé";
          break;
        case LocationErrorType.permissionDenied:
          message = "Permission de localisation refusée";
          break;
        case LocationErrorType.permissionDeniedForever:
          message = "Permission refusée définitivement (paramètres requis)";
          break;
        default:
          message = "Erreur lors de la récupération de la position";
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );

      return;
    }

    final userLatLng = result.position!;

    setState(() {
      _userLocationMarker = [
        Marker(
          width: 40,
          height: 40,
          point: userLatLng,
          child: Icon(
            Icons.my_location,
            color: (_currentBaseMap == "OpenStreetMap" ||
                    _currentBaseMap == "Plan IGN" ||
                    _currentBaseMap == "OpenTopoMap")
                ? Colors.black
                : Colors.white,
            size: 35,
          ),
        ),
      ];
    });

    _startLocationTimer();

    _mapController.move(userLatLng, targetZoom);
  }

  void _startLocationTimer() {
    _locationTimer?.cancel();

    _locationTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted) return;

      setState(() {
        _userLocationMarker = [];
      });
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _onMapTap(LatLng point) {
    if (_drawPolygonMode) {
      setState(() {
        _polygonPoints.add(point);
      });
      return;
    }

    if (_drawCircleMode) {
      if (_circleCenter == null) {
        setState(() {
          _circleCenter = point;
        });
      } else {
        final distance = const Distance();

        setState(() {
          _circleRadius = distance.as(
            LengthUnit.Meter,
            _circleCenter!,
            point,
          );
        });
      }
    }
  }

  void _validatePolygon() {
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Le polygone doit contenir au moins 3 sommets"),
        ),
      );
      return;
    }

    setState(() {
      _drawPolygonMode = false;

      _filters = _filters.copyWith(
        spatialFilterType: SpatialFilterType.polygon,
        geoIntersection: widget.useWktGeometry
            ? polygonToWkt(_polygonPoints)
            : polygonToGeoJson(_polygonPoints),
        radius: null,
      );
    });

    _isFirstLoad = false;
    loadData();
  }

  void _validateCircle() {
    if (_circleCenter == null || _circleRadius == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Définissez le centre et le rayon du cercle"),
        ),
      );
      return;
    }

    setState(() {
      _drawCircleMode = false;

      _filters = _filters.copyWith(
        spatialFilterType: SpatialFilterType.circle,
        geoIntersection: widget.useWktGeometry
            ? pointToWkt(_circleCenter!)
            : circleToGeoJson(_circleCenter!, _circleRadius!),
        radius: _circleRadius,
      );
    });

    _isFirstLoad = false;
    loadData();
  }

  void _cancelDrawing() {
    setState(() {
      // Quitte le mode dessin
      _drawPolygonMode = false;
      _drawCircleMode = false;

      // Efface le dessin en cours
      _polygonPoints.clear();
      _circleCenter = null;
      _circleRadius = null;

      // Supprime le filtre spatial
      _filters = _filters.copyWith(
        spatialFilterType: null,
        geoIntersection: null,
        radius: null,
      );
    });
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MapAppBar(
        baseMaps: _baseMaps,
        currentBaseMap: _currentBaseMap,
        onBaseMapChanged: (value) {
          setState(() => _currentBaseMap = value);
        },
        onUserLocation: _showUserLocation,
        isLocating: _isLocating,
        onFilter: _openFilterDialog,
        onStatistics: () => showStatisticsBottomSheet(
          context,
          observations: _allObservations,
        ),
        hasResults: _allObservations.isNotEmpty,
        onAbout: () => showAboutBottomSheet(
          context,
          serverName: Uri.parse(widget.apiService.baseUrl).host,
        ),
        onLogout: _logout,
      ),
      body: Column(
        children: [
          // Bandeau sous-titre
          InkWell(
            onTap: _openFilterDialog,
            child: Container(
              color: Colors.blue.shade100,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                _subtitle,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Carte
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      MapView(
                        mapController: _mapController,
                        markers: _markers,
                        polygons: _polygons,
                        userLocationMarker: _userLocationMarker,
                        baseMaps: _baseMaps,
                        currentBaseMap: _currentBaseMap,
                        drawPolygonMode: _drawPolygonMode,
                        drawCircleMode: _drawCircleMode,
                        polygonPoints: _polygonPoints,
                        circleCenter: _circleCenter,
                        circleRadius: _circleRadius,
                        onMapTap: _onMapTap,
                        onZoomChanged: (zoom) {
                          if ((zoom - _currentZoom).abs() > 0.01) {
                            _currentZoom = zoom;
                          }
                        },
                        onMapReady: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Future.microtask(_fitBoundsIfNeeded);
                          });
                        },
                      ),
                      MapAttribution(
                        baseMapType: _currentBaseMap,
                        expanded: _osmExpanded,
                        onTap: () {
                          setState(() {
                            _osmExpanded = !_osmExpanded;
                          });
                        },
                      ),
                      if (_drawPolygonMode || _drawCircleMode)
                        Positioned(
                          bottom: MediaQuery.of(context).padding.bottom + 60,
                          right: 20,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Quitter le mode dessin
                              FloatingActionButton(
                                heroTag: "cancel_draw",
                                backgroundColor: Colors.grey.shade700,
                                tooltip: "Annuler",
                                onPressed: _cancelDrawing,
                                child: const Icon(Icons.close),
                              ),

                              const SizedBox(height: 10),

                              // Effacer le dessin
                              FloatingActionButton(
                                heroTag: "delete_draw",
                                backgroundColor: Colors.red,
                                tooltip: "Effacer",
                                onPressed: () {
                                  setState(() {
                                    if (_drawPolygonMode) {
                                      if (_polygonPoints.isNotEmpty) {
                                        _polygonPoints.removeLast();
                                      }
                                    }

                                    if (_drawCircleMode) {
                                      if (_circleRadius != null) {
                                        _circleRadius = null;
                                      } else if (_circleCenter != null) {
                                        _circleCenter = null;
                                      }
                                    }
                                  });
                                },
                                child: const Icon(Icons.delete),
                              ),

                              const SizedBox(height: 10),

                              // Appliquer
                              FloatingActionButton(
                                heroTag: "search_draw",
                                tooltip: "Appliquer",
                                onPressed: () {
                                  if (_drawPolygonMode) {
                                    _validatePolygon();
                                  } else {
                                    _validateCircle();
                                  }
                                },
                                child: const Icon(Icons.search),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
