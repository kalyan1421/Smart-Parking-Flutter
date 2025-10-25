// lib/services/parking_service.dart
import 'dart:async';
import 'dart:math';
import 'package:smart_parking_app/models/parking_spot.dart';
import 'package:smart_parking_app/screens/parking/id_generator.dart';

class ParkingService {
  // Mock data for demo purposes
  final List<ParkingSpot> _mockParkingSpots = [];
  final Random _random = Random();

  ParkingService() {
    // Initialize with some mock data
    _initializeMockData();
  }

  void _initializeMockData() {
    // Add some mock parking spots in various locations
    // These would normally come from an API
    
    // Clear existing mock data
    _mockParkingSpots.clear();
    
    // Helper to create mock ObjectId
    dynamic createMockId(String value) {
      return ObjectIdLike(value);
    }
    
    _mockParkingSpots.addAll([
      ParkingSpot(
        id: createMockId('spot001'),
        name: 'Downtown Parking Garage',
        description: 'Covered parking in the heart of downtown',
        latitude: 37.7749, // Sample coordinates - would be adjusted based on user location
        longitude: -122.4194,
        totalSpots: 150,
        availableSpots: 42,
        pricePerHour: 4.50,
        features: ['Covered', 'Security', 'EV Charging'],
      ),
      ParkingSpot(
        id: createMockId('spot002'),
        name: 'Main Street Lot',
        description: 'Convenient open-air parking near shopping',
        latitude: 37.7750, // Sample coordinates - would be adjusted based on user location
        longitude: -122.4180,
        totalSpots: 80,
        availableSpots: 15,
        pricePerHour: 3.00,
        features: ['Open 24/7', 'Surveillance'],
      ),
      ParkingSpot(
        id: createMockId('spot003'),
        name: 'City Center Parking',
        description: 'Premium parking with valet service',
        latitude: 37.7760, // Sample coordinates - would be adjusted based on user location
        longitude: -122.4190,
        totalSpots: 200,
        availableSpots: 75,
        pricePerHour: 6.00,
        features: ['Valet', 'Covered', 'Security', 'Car Wash'],
      ),
      ParkingSpot(
        id: createMockId('spot004'),
        name: 'North Side Parking',
        description: 'Budget friendly parking option',
        latitude: 37.7770, // Sample coordinates - would be adjusted based on user location
        longitude: -122.4175,
        totalSpots: 60,
        availableSpots: 0, // Full - no spots available
        pricePerHour: 2.50,
        features: ['Open 24/7'],
      ),
      ParkingSpot(
        id: createMockId('spot005'),
        name: 'Waterfront Parking',
        description: 'Scenic parking near the bay',
        latitude: 37.7780, // Sample coordinates - would be adjusted based on user location
        longitude: -122.4160,
        totalSpots: 100,
        availableSpots: 30,
        pricePerHour: 5.00,
        features: ['Security', 'Scenic View'],
      ),
    ]);
  }

  // Find nearby parking spots with a given radius in kilometers
  Future<List<ParkingSpot>> findNearbyParkingSpots(
    double latitude, 
    double longitude, 
    {double radius = 1.0}
  ) async {
    // In a real app, this would make an API call
    // For now, we'll simulate network delay and return mock data
    
    await Future.delayed(Duration(milliseconds: 800)); // Simulate network delay
    
    // Adjust the mock data to be near the user's location
    for (var spot in _mockParkingSpots) {
      // Create new coordinates based on user location plus some random offset
      // This ensures the spots are always near the user for demo purposes
      final latOffset = (_random.nextDouble() * 0.01) * (_random.nextBool() ? 1 : -1);
      final lngOffset = (_random.nextDouble() * 0.01) * (_random.nextBool() ? 1 : -1);
      
      final updatedSpot = spot.copyWith(
        latitude: latitude + latOffset,
        longitude: longitude + lngOffset,
      );
      
      // Update the spot in the list
      final index = _mockParkingSpots.indexOf(spot);
      _mockParkingSpots[index] = updatedSpot;
    }
    
    // Return spots within radius (for mock, we'll return all)
    return _mockParkingSpots;
  }

  // Book a parking spot
  Future<bool> bookParkingSpot(
    String spotId, 
    DateTime startTime, 
    DateTime endTime
  ) async {
    // In a real app, this would make an API call
    // For now, we'll simulate network delay and update mock data
    
    await Future.delayed(Duration(milliseconds: 700)); // Simulate network delay
    
    // Find the spot by ID
    final spotIndex = _mockParkingSpots.indexWhere(
      (spot) => spot.id.toHexString() == spotId
    );
    
    if (spotIndex >= 0) {
      final spot = _mockParkingSpots[spotIndex];
      
      // Check if there are spots available
      if (spot.availableSpots <= 0) {
        return false; // No spots available
      }
      
      // Update available spots
      final updatedSpot = spot.copyWith(
        availableSpots: spot.availableSpots - 1
      );
      
      _mockParkingSpots[spotIndex] = updatedSpot;
      
      // In a real app, this would also create a booking record
      
      return true; // Booking successful
    }
    
    return false; // Spot not found
  }

  // Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    // In a real app, this would make an API call to cancel the booking
    // and update the available spots for the associated parking spot
    // For now, we'll simulate network delay and return success
    
    await Future.delayed(Duration(milliseconds: 600)); // Simulate network delay
    
    // In a real app, you would get the spot ID from the booking
    // For now, we'll assume the booking is successful
    
    return true; // Cancellation successful
  }
  
  // Get user's booking history
  Future<List<Map<String, dynamic>>> getUserBookingHistory() async {
    // In a real app, this would make an API call to get the user's booking history
    // For now, we'll simulate network delay and return mock data
    
    await Future.delayed(Duration(milliseconds: 900)); // Simulate network delay
    
    // Return mock booking history
    return [
      {
        'id': 'booking123',
        'spotId': 'spot001',
        'spotName': 'Downtown Parking Garage',
        'startTime': DateTime.now().subtract(Duration(days: 2)),
        'endTime': DateTime.now().subtract(Duration(days: 2, hours: 2)),
        'price': 9.00,
        'status': 'completed',
      },
      {
        'id': 'booking456',
        'spotId': 'spot003',
        'spotName': 'City Center Parking',
        'startTime': DateTime.now().subtract(Duration(days: 1)),
        'endTime': DateTime.now().subtract(Duration(days: 1, hours: 3)),
        'price': 18.00,
        'status': 'completed',
      },
    ];
  }
  
  // Search for parking spots by name or location
  Future<List<ParkingSpot>> searchParkingSpots(String query) async {
    // In a real app, this would make an API call to search for parking spots
    // For now, we'll simulate network delay and filter mock data
    
    await Future.delayed(Duration(milliseconds: 700)); // Simulate network delay
    
    // Filter spots by name or description
    final filteredSpots = _mockParkingSpots.where((spot) {
      return spot.name.toLowerCase().contains(query.toLowerCase()) ||
             spot.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
    
    return filteredSpots;
  }
  
  // Get parking spot details by ID
  Future<ParkingSpot?> getParkingSpotById(String spotId) async {
    // In a real app, this would make an API call to get spot details
    // For now, we'll simulate network delay and return from mock data
    
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
    
    // Find the spot by ID
    final spot = _mockParkingSpots.firstWhere(
      (spot) => spot.id.toHexString() == spotId,
      orElse: () => null as ParkingSpot, // This will throw an error if not found
    );
    
    return spot;
  }
  
  // Rate a parking spot
  Future<bool> rateParkingSpot(String spotId, int rating, String? comment) async {
    // In a real app, this would make an API call to rate the spot
    // For now, we'll simulate network delay and return success
    
    await Future.delayed(Duration(milliseconds: 600)); // Simulate network delay
    
    // In a real app, you would store the rating and comment
    // For now, we'll just return success
    
    return true; // Rating successful
  }
}