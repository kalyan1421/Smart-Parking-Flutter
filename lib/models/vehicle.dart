// lib/models/vehicle.dart
import 'package:mongo_dart/mongo_dart.dart';

enum VehicleType {
  sedan,
  suv,
  truck,
  van,
  motorcycle,
  electric
}

class Vehicle {
  final ObjectId id;
  final String userId;
  final String licensePlate; 
  final String make;
  final String model;
  final VehicleType type;
  final String color;
  final bool isElectric;
  final bool isDefault;
  
  Vehicle({
    required this.id,
    required this.userId,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.type,
    required this.color,
    this.isElectric = false,
    this.isDefault = false,
  });
  
  // Create from JSON (MongoDB document)
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['_id'],
      userId: json['userId'],
      licensePlate: json['licensePlate'],
      make: json['make'],
      model: json['model'],
      type: VehicleType.values[json['type'] ?? 0],
      color: json['color'],
      isElectric: json['isElectric'] ?? false,
      isDefault: json['isDefault'] ?? false,
    );
  }
  
  // Convert to JSON (for MongoDB)
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'licensePlate': licensePlate,
      'make': make,
      'model': model,
      'type': type.index,
      'color': color,
      'isElectric': isElectric,
      'isDefault': isDefault,
    };
  }
  
  // Create a copy with updated fields
  Vehicle copyWith({
    ObjectId? id,
    String? userId,
    String? licensePlate,
    String? make,
    String? model,
    VehicleType? type,
    String? color,
    bool? isElectric,
    bool? isDefault,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      licensePlate: licensePlate ?? this.licensePlate,
      make: make ?? this.make,
      model: model ?? this.model,
      type: type ?? this.type,
      color: color ?? this.color,
      isElectric: isElectric ?? this.isElectric,
      isDefault: isDefault ?? this.isDefault,
    );
  }
  
  // Formatted display of vehicle info
  String get displayName {
    return '$color $make $model (${licensePlate.toUpperCase()})';
  }
}