// lib/models/booking.dart
import 'package:mongo_dart/mongo_dart.dart';

class Booking {
  final dynamic id; // Can be ObjectId or String
  final String userId;
  final String parkingSpotId;
  final String parkingSpotName;
  final double latitude;
  final double longitude;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final String status; // active, completed, cancelled
  final DateTime createdAt;
  final DateTime? updatedAt;

  Booking({
    required this.id,
    required this.userId,
    required this.parkingSpotId,
    required this.parkingSpotName,
    required this.latitude,
    required this.longitude,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  // Create a copy with updated values
  Booking copyWith({
    dynamic id,
    String? userId,
    String? parkingSpotId,
    String? parkingSpotName,
    double? latitude,
    double? longitude,
    DateTime? startTime,
    DateTime? endTime,
    double? totalPrice,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      parkingSpotId: parkingSpotId ?? this.parkingSpotId,
      parkingSpotName: parkingSpotName ?? this.parkingSpotName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert from JSON
  factory Booking.fromJson(Map<String, dynamic> json) {
    // Extract coordinates from location object
    double latitude = 0.0;
    double longitude = 0.0;
    
    if (json.containsKey('location') && json['location'] is Map) {
      final location = json['location'] as Map;
      if (location.containsKey('coordinates') && location['coordinates'] is List) {
        final coordinates = location['coordinates'] as List;
        if (coordinates.length >= 2) {
          longitude = (coordinates[0] as num).toDouble();
          latitude = (coordinates[1] as num).toDouble();
        }
      }
    }

    // Process userId - leave as it is, don't try to convert
    String userIdStr = '';
    if (json['userId'] is ObjectId) {
      userIdStr = json['userId'].toHexString();
    } else if (json['userId'] is String) {
      userIdStr = json['userId'];
    } else {
      userIdStr = json['userId'].toString();
    }

    return Booking(
      id: json['_id'], // Keep as is (ObjectId or String)
      userId: userIdStr,
      parkingSpotId: json['parkingSpotId'],
      parkingSpotName: json['parkingSpotName'],
      latitude: latitude,
      longitude: longitude,
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json.containsKey('updatedAt') && json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id, // Keep as is (ObjectId or String)
      'userId': userId,
      'parkingSpotId': parkingSpotId,
      'parkingSpotName': parkingSpotName,
      'location': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
  
  // Helper method to get ID as hex string safely
  String idToHexString() {
    if (id is ObjectId) {
      return (id as ObjectId).toHexString();
    } else if (id is String) {
      return id as String;
    } else {
      return id.toString();
    }
  }
  
  // Get duration in hours and minutes
  String get durationText {
    final durationMinutes = endTime.difference(startTime).inMinutes;
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes > 0 ? '${minutes}m' : ''}';
    } else {
      return '${minutes}m';
    }
  }
  
  // Get formatted date
  String get dateText {
    return '${startTime.day}/${startTime.month}/${startTime.year}';
  }
  
  // Get formatted time range
  String get timeText {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - '
           '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }
  
  // Is the booking active?
  bool get isActive => status == 'active';
  
  // Is the booking completed?
  bool get isCompleted => status == 'completed';
  
  // Is the booking cancelled?
  bool get isCancelled => status == 'cancelled';
}