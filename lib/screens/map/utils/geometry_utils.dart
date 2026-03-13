import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum MarkerType { point, line, polygon }

class MapMarkerData {
  final LatLng position;
  final List<Map<String, dynamic>> observations;
  final MarkerType type;

  MapMarkerData({
    required this.position,
    required this.observations,
    required this.type,
  });
}

// Résultat du parsing GeoJSON
class MapDataResult {
  final List<MapMarkerData> markers;
  final List<Polygon> polygons;

  MapDataResult({required this.markers, required this.polygons});
}

// Parser GeoJSON
class GeoJsonParser {
  // Parse la liste des features GeoJSON
  static MapDataResult parse(List features) {
    final List<MapMarkerData> markers = [];
    final List<Polygon> polygons = [];

    for (var feature in features) {
      final geometry = feature["geometry"];
      if (geometry == null) continue;

      final type = geometry["type"];
      final properties = feature["properties"] ?? {};
      // observations : si "observations" existe, on prend la liste, sinon que properties
      final rawObservations = properties["observations"] ?? [properties];

      // normaliser chaque observation : ajouter _id pour faciliter l'accès
      final observations = rawObservations.map<Map<String, dynamic>>((obs) {
        final copy = Map<String, dynamic>.from(obs);
        copy["_id"] = obs["id_synthese"] ?? obs["id"];
        return copy;
      }).toList();

      switch (type) {
        case "Point":
          _handlePoint(geometry, observations, markers);
          break;
        case "LineString":
          _handleLineString(geometry, observations, markers);
          break;
        case "MultiPolygon":
          _handleMultiPolygon(geometry, observations, markers, polygons);
          break;
      }
    }

    return MapDataResult(markers: markers, polygons: polygons);
  }

  // POINT

  static void _handlePoint(
    Map geometry,
    List<Map<String, dynamic>> observations,
    List<MapMarkerData> markers,
  ) {
    final coords = geometry["coordinates"];
    final lat = coords[1].toDouble();
    final lon = coords[0].toDouble();

    // enrichir observations
    for (var obs in observations) {
      obs["_lat"] = lat;
      obs["_lon"] = lon;
      obs["_isPolygon"] = false;
    }

    markers.add(
      MapMarkerData(
        position: LatLng(lat, lon),
        observations: observations,
        type: MarkerType.point,
      ),
    );
  }

  // LINESTRING

  static void _handleLineString(
    Map geometry,
    List<Map<String, dynamic>> observations,
    List<MapMarkerData> markers,
  ) {
    final coords = geometry["coordinates"];

    double sumLat = 0;
    double sumLon = 0;

    for (var coord in coords) {
      sumLat += coord[1].toDouble();
      sumLon += coord[0].toDouble();
    }

    final lat = sumLat / coords.length;
    final lon = sumLon / coords.length;

    for (var obs in observations) {
      obs["_lat"] = lat;
      obs["_lon"] = lon;
      obs["_isPolygon"] = false;
    }

    markers.add(
      MapMarkerData(
        position: LatLng(lat, lon),
        observations: observations,
        type: MarkerType.line,
      ),
    );
  }

  // MULTIPOLYGON

  static void _handleMultiPolygon(
    Map geometry,
    List<Map<String, dynamic>> observations,
    List<MapMarkerData> markers,
    List<Polygon> polygons,
  ) {
    final coords = geometry["coordinates"];

    for (var polygon in coords) {
      for (var ring in polygon) {
        final points = ring
            .map<LatLng>(
              (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()),
            )
            .toList();

        polygons.add(
          Polygon(
            points: points,
            color: Colors.red.withValues(alpha: 0.3),
            borderColor: Colors.red,
            borderStrokeWidth: 2,
          ),
        );

        // Calcul du centroïde pour afficher un marker cliquable
        final centroid = calculatePolygonCentroid(points);

        // Marquer les observations comme polygone + ajout des coordonnées
        for (var obs in observations) {
          obs["_lat"] = centroid.latitude;
          obs["_lon"] = centroid.longitude;
          obs["_isPolygon"] = true;
        }

        markers.add(
          MapMarkerData(
            position: centroid,
            observations: observations,
            type: MarkerType.polygon,
          ),
        );
      }
    }
  }

  // CENTROIDE POLYGONE

  static LatLng calculatePolygonCentroid(List<LatLng> points) {
    double area = 0.0;
    double cx = 0.0;
    double cy = 0.0;

    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;

      final factor =
          (points[i].latitude * points[j].longitude -
          points[j].latitude * points[i].longitude);

      area += factor;
      cx += (points[i].latitude + points[j].latitude) * factor;
      cy += (points[i].longitude + points[j].longitude) * factor;
    }

    area /= 2;

    if (area == 0) return points.first;

    cx /= (6 * area);
    cy /= (6 * area);

    return LatLng(cx, cy);
  }
}
