// lib/models/user.dart
import 'package:mongo_dart/mongo_dart.dart';

class User {
  final dynamic id; // Use dynamic to handle both ObjectId and String
  final String username;
  final String email;
  final String name;
  final String phoneNumber;
  final List<String> vehicleIds;
  final List<String> bookingIds;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.vehicleIds,
    required this.bookingIds,
    required this.createdAt,
  });

  // Factory constructor to create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    // Handle ID correctly - could be ObjectId or String
    var userId = json['_id'];
    
    return User(
      id: userId, // Store as is - don't convert to string yet
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      vehicleIds: (json['vehicleIds'] as List?)?.map((id) => id.toString()).toList() ?? [],
      bookingIds: (json['bookingIds'] as List?)?.map((id) => id.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id, // Keep as is - don't convert to string
      'username': username,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'vehicleIds': vehicleIds,
      'bookingIds': bookingIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Helper method to get ID as hex string safely
  String idToHexString() {
    if (id is ObjectId) {
      return (id as ObjectId).toHexString();
    } else if (id is String) {
      return id;
    } else {
      return id.toString();
    }
  }
}