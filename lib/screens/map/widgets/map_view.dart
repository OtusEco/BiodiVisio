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
  final VoidCallback? onMapReady;

  const MapView({
    super.key,
    required this.markers,
    required this.polygons,
    required this.mapController,
    required this.userLocationMarker,
    required this.baseMaps,
    required this.currentBaseMap,
    this.onMapReady,
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
        onMapReady: () {
          onMapReady?.call();
        },
      ),
      children: [
        TileLayer(
          urlTemplate: baseMaps[currentBaseMap]!,
          userAgentPackageName: 'fr.otuseco.biodivisio/1.0.0',
        ),

        MarkerLayer(markers: userLocationMarker),

        PolygonLayer(polygons: polygons),

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
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          // Ajout de l'échelle géographique avec Scalebar
        const Scalebar(
            textStyle: TextStyle(color: Colors.black, fontSize: 14),
            padding: EdgeInsets.only(right: 10, left: 10, bottom: 10),
            alignment: Alignment.bottomRight,
            length: ScalebarLength.l,
          ),
      ],
    );
  }
}
