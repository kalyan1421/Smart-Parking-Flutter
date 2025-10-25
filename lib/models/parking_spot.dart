// lib/models/parking_spot.dart
class ParkingSpot {
  final dynamic id; // Could be ObjectId, String, or our custom ObjectIdLike
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final int totalSpots;
  final int availableSpots;
  final double pricePerHour;
  final List<String> features;
  final bool? isUserCreated; // Flag to indicate if this spot was created by a user

  ParkingSpot({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.totalSpots,
    required this.availableSpots,
    required this.pricePerHour,
    required this.features,
    this.isUserCreated = false,
  });

  // Create a copy with updated values
  ParkingSpot copyWith({
    dynamic id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    int? totalSpots,
    int? availableSpots,
    double? pricePerHour,
    List<String>? features,
    bool? isUserCreated,
  }) {
    return ParkingSpot(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      totalSpots: totalSpots ?? this.totalSpots,
      availableSpots: availableSpots ?? this.availableSpots,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      features: features ?? this.features,
      isUserCreated: isUserCreated ?? this.isUserCreated,
    );
  }

  // Convert from JSON
  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      latitude: json['location']['coordinates'][1].toDouble(),
      longitude: json['location']['coordinates'][0].toDouble(),
      totalSpots: json['totalSpots'],
      availableSpots: json['availableSpots'],
      pricePerHour: json['pricePerHour'].toDouble(),
      features: List<String>.from(json['features'] ?? []),
      isUserCreated: json['isUserCreated'] ?? false,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id.toString(),
      'name': name,
      'description': description,
      'location': {
        'type': 'Point',
        'coordinates': [longitude, latitude], // GeoJSON format: [lng, lat]
      },
      'totalSpots': totalSpots,
      'availableSpots': availableSpots,
      'pricePerHour': pricePerHour,
      'features': features,
      'isUserCreated': isUserCreated ?? false,
    };
  }
}