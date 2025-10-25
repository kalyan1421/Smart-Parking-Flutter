
// lib/repositories/traffic_repository.dart - Fixed Traffic repository
import 'package:mongo_dart/mongo_dart.dart';
import 'package:smart_parking_app/config/constants.dart';
import 'package:smart_parking_app/core/database/database_service.dart';
import 'package:smart_parking_app/models/traffic_data.dart';
// import 'dart:math' as dart;
import 'package:smart_parking_app/core/utils/math_extensions.dart';


class TrafficRepository {
  final DbCollection _trafficCollection = DatabaseService.collection(AppConstants.trafficDataCollection);
  
  // Get traffic data near a location using a simplified approach
  Future<List<TrafficData>> getTrafficDataNearLocation(double latitude, double longitude, double maxDistanceInKm) async {
    // First, fetch all traffic data
    final trafficDocs = await _trafficCollection.find().toList();
    final List<TrafficData> allTrafficData = trafficDocs.map((doc) => TrafficData.fromJson(doc)).toList();
    
    // Manual distance filtering logic (simplified approach)
    List<TrafficData> nearbyTraffic = [];
    
    for (final traffic in allTrafficData) {
      // Calculate distance using Haversine formula
      double distance = _calculateDistance(
        latitude, longitude, 
        traffic.latitude, traffic.longitude
      );
      
      // If within max distance, add to nearby list
      if (distance <= maxDistanceInKm) {
        nearbyTraffic.add(traffic);
      }
    }
    
    // Sort by distance (closest first)
    nearbyTraffic.sort((a, b) {
      double distA = _calculateDistance(latitude, longitude, a.latitude, a.longitude);
      double distB = _calculateDistance(latitude, longitude, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });
    
    return nearbyTraffic;
  }
  
  // Helper method to calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0; // in kilometers
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = 
      (dLat / 2).sin() * (dLat / 2).sin() +
      (dLon / 2).sin() * (dLon / 2).sin() * lat1.cos() * lat2.cos();
    double c = 2 * a.sqrt().atan2((1 - a).sqrt());
    
    return earthRadius * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }
  
  // Get recent traffic data
  Future<List<TrafficData>> getRecentTrafficData() async {
    final thirtyMinutesAgo = DateTime.now().subtract(Duration(minutes: 30));
    
    final trafficDocs = await _trafficCollection.find(
      where.gt('timestamp', thirtyMinutesAgo.toIso8601String())
    ).toList();
    
    return trafficDocs.map((doc) => TrafficData.fromJson(doc)).toList();
  }
  
  // Submit traffic report
  Future<TrafficData> submitTrafficReport(
    double latitude,
    double longitude,
    String locationName,
    int vehicleCount,
    CongestionLevel congestionLevel,
    {String? imageUrl}
  ) async {
    final id = ObjectId();
    final now = DateTime.now();
    
    final trafficDoc = {
      '_id': id,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'vehicleCount': vehicleCount,
      'congestionLevel': congestionLevel.toString().split('.').last,
      'timestamp': now.toIso8601String(),
      'isLive': true,
    };
    
    await _trafficCollection.insert(trafficDoc);
    
    return TrafficData.fromJson(trafficDoc);
  }
  
  // Get traffic data by ID
  Future<TrafficData> getTrafficDataById(ObjectId id) async {
    final trafficDoc = await _trafficCollection.findOne(where.id(id));
    if (trafficDoc == null) {
      throw Exception('Traffic data not found');
    }
    
    return TrafficData.fromJson(trafficDoc);
  }
}