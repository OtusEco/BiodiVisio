import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

class MapView extends StatelessWidget {
  final List<Marker> markers;
  final List<Polygon> polygons;
  final MapController mapController;
  final List<Marker> userLocationMarker;
  final Map<String, String> baseMaps;
  final String currentBaseMap;
  final Function(double zoom)? onZoomChanged;
  final VoidCallback? onMapReady;

  // Dessin polygone/cercle
  final bool drawPolygonMode;
  final bool drawCircleMode;
  final List<LatLng> polygonPoints;
  final LatLng? circleCenter;
  final double? circleRadius;
  final ValueChanged<LatLng>? onMapTap;

  const MapView({
    super.key,
    required this.markers,
    required this.polygons,
    required this.mapController,
    required this.userLocationMarker,
    required this.baseMaps,
    required this.currentBaseMap,
    this.onZoomChanged,
    this.onMapReady,

    // Dessin polygone/cercle
    this.drawPolygonMode = false,
    this.drawCircleMode = false,
    this.polygonPoints = const [],
    this.circleCenter,
    this.circleRadius,
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: const LatLng(46.6, 2.4),
        initialZoom: 6,
        interactionOptions: const InteractionOptions(
          flags: ~InteractiveFlag.rotate,
        ),
        onTap: (_, point) {
          onMapTap?.call(point);
        },
        onPositionChanged: (position, hasGesture) {
          onZoomChanged?.call(position.zoom);
        },
        onMapReady: () {
          onMapReady?.call();
        },
      ),
      children: [
        TileLayer(
          urlTemplate: baseMaps[currentBaseMap]!,
          userAgentPackageName: 'fr.otuseco.biodivisio/1.2.0',
        ),

        // Layer - Position utilisateur
        MarkerLayer(
          markers: userLocationMarker,
        ),

        // Layer - recherche par polygone
        PolygonLayer(
          polygons: [
            ...polygons,

            // Dessin du polygone
            if (drawPolygonMode && polygonPoints.length >= 2)
              Polygon(
                points: polygonPoints,
                color: Colors.blue.withValues(alpha: 0.25),
                borderColor: Colors.blue,
                borderStrokeWidth: 3,
              ),
          ],
        ),

        // Sommets du polygone
        if (drawPolygonMode && polygonPoints.isNotEmpty)
          MarkerLayer(
            markers: polygonPoints.map((point) {
              return Marker(
                point: point,
                width: 12,
                height: 12,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                ),
              );
            }).toList(),
          ),

        // Dessin du cercle
        if (drawCircleMode && circleCenter != null && circleRadius != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: circleCenter!,
                radius: circleRadius!,
                useRadiusInMeter: true,
                color: Colors.blue.withValues(alpha: 0.25),
                borderColor: Colors.blue,
                borderStrokeWidth: 3,
              ),
            ],
          ),

        // Centre du cercle
        if (drawCircleMode && circleCenter != null)
          MarkerLayer(
            markers: [
              Marker(
                point: circleCenter!,
                width: 20,
                height: 20,
                child: const Icon(
                  Icons.radio_button_checked,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
            ],
          ),

        // Layer - Clusters observations
        if (markers.isNotEmpty)
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 45,
              size: const Size(40, 40),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(50),
              maxZoom: 15,
              markers: markers,
              builder: (context, markers) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.blue,
                  ),
                  child: Center(
                    child: Text(
                      markers.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // Barre d'échelle
        Scalebar(
          textStyle: const TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
          padding: EdgeInsets.only(
            right: 10,
            left: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          alignment: Alignment.bottomRight,
          length: ScalebarLength.l,
        ),
      ],
    );
  }
}