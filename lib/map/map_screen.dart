import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
import 'widgets/view.dart';


class MapScreen extends StatefulWidget {
  final ApiService apiService;
  final bool skipInitialLoad;

  const MapScreen({
    super.key,
    required this.apiService,
    this.skipInitialLoad = false,
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

  MapFilters _filters = const MapFilters();

  String _currentBaseMap = "OSM";

  final Map<String, String> _baseMaps = {
    "OSM": "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
    "Satellite":
        "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
  };

  bool _osmExpanded = false;

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

    // Taxons (seulement lb_nom pas de nom_rang)
    if (_filters.selectedTaxonLabels.isNotEmpty) {
      final cleaned = _filters.selectedTaxonLabels.map((taxon) {
        return taxon["lb_nom"] ?? "Inconnu";
      }).toList();

      parts.add(cleaned.join(", "));
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
      String endpoint = "/synthese/for_web";

      final body = _filters.toApiPayload(isFirstLoad: _isFirstLoad);

      if (_isFirstLoad) {
        endpoint += "?limit=100"; // pour serveurs classiques
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
        _loading = false;
        _isFirstLoad = false;
      });
    } on ApiException catch (e) {
      setState(() => _loading = false);

      if (!mounted) return;

      if (e.statusCode == 401) {
        widget.apiService.logout();
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

    if (_filters.isEmpty) {
      if (widget.skipInitialLoad) {
        setState(() {
          _markers = [];
          _polygons = [];
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

  void _logout() {
    widget.apiService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // Géolocalisation

  Future<void> _showUserLocation() async {
    final result = await LocationService.getUserLocation();

    if (!mounted) return;

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
            color: _currentBaseMap == "OSM" ? Colors.black : Colors.white,
            size: 35,
          ),
        ),
      ];
    });

    _mapController.move(userLatLng, 10);
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MapAppBar(
        subtitle: _subtitle,
        baseMaps: _baseMaps,
        currentBaseMap: _currentBaseMap,
        onBaseMapChanged: (value) {
          setState(() => _currentBaseMap = value);
        },
        onUserLocation: _showUserLocation,
        onFilter: _openFilterDialog,
        onAbout: () => showAboutBottomSheet(context),
        onLogout: _logout,
      ),
      body: _loading
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
              ],
            ),
    );
  }
}
