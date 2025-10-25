// lib/providers/parking_provider.dart
import 'package:flutter/foundation.dart';
import 'package:smart_parking_app/models/parking_spot.dart';
import 'package:smart_parking_app/providers/parking_service.dart';
import 'package:smart_parking_app/screens/parking/id_generator.dart';

class ParkingProvider extends ChangeNotifier {
  final ParkingService _parkingService;
  
  List<ParkingSpot> _nearbyParkingSpots = [];
  ParkingSpot? _selectedParkingSpot;
  bool _isLoading = false;
  String? _error;
  
  // User created parking spots (local storage)
  List<ParkingSpot> _userCreatedSpots = [];
  
  ParkingProvider(this._parkingService);
  
  // Getters
  List<ParkingSpot> get nearbyParkingSpots => _nearbyParkingSpots;
  ParkingSpot? get selectedParkingSpot => _selectedParkingSpot;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Find nearby parking spots
  Future<void> findNearbyParkingSpots(
    double latitude, 
    double longitude, 
    {double radius = 1.0}
  ) async {
    _setLoading(true);
    clearError(); // Changed from _clearError to clearError
    
    try {
      // Get spots from API
      final spots = await _parkingService.findNearbyParkingSpots(
        latitude, 
        longitude, 
        radius: radius
      );
      
      // Merge with user created spots
      final allSpots = [...spots, ..._getUserCreatedSpotsNearby(latitude, longitude, radius)];
      
      _nearbyParkingSpots = allSpots;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load parking spots: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Select a parking spot
  void selectParkingSpot(ParkingSpot spot) {
    _selectedParkingSpot = spot;
    notifyListeners();
  }
  
  // Add a new parking spot (user created)
  Future<void> addParkingSpot(ParkingSpot spot) async {
    _setLoading(true);
    clearError(); // Changed from _clearError to clearError
    
    try {
      // Set an ID if not provided
      if (spot.id == null) {
        final updatedSpot = spot.copyWith(
          id: IdGenerator.generateObjectId(),
        );
        spot = updatedSpot;
      }
      
      // Store locally for now (in production, this would be sent to the server)
      _userCreatedSpots.add(spot);
      
      // Add to nearby spots if not already there
      if (!_nearbyParkingSpots.any((s) => s.id.toHexString() == spot.id.toHexString())) {
        _nearbyParkingSpots.add(spot);
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to add parking spot: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Book a parking spot
  Future<bool> bookParkingSpot(ParkingSpot spot, DateTime startTime, DateTime endTime) async {
    _setLoading(true);
    clearError(); // Changed from _clearError to clearError
    
    try {
      // If it's a user-created spot, handle it locally
      if (spot.isUserCreated == true) {
        // Update available spots locally
        _updateAvailableSpots(spot, -1); // decrease by 1
        
        // In a real app, this would also create a booking record
        _setLoading(false);
        return true;
      }
      
      // Otherwise, use the service
      final success = await _parkingService.bookParkingSpot(
        spot.id.toHexString(), 
        startTime, 
        endTime
      );
      
      if (success) {
        // Update available spots in our local list
        _updateAvailableSpots(spot, -1); // decrease by 1
      }
      
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Failed to book parking spot: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
  
  // Cancel a parking spot booking
  Future<bool> cancelBooking(String bookingId) async {
    _setLoading(true);
    clearError(); // Changed from _clearError to clearError
    
    try {
      // In a real app, you would get the spot ID from the booking
      // For now, we'll just assume it's for the selected spot
      
      if (_selectedParkingSpot != null) {
        // If it's a user-created spot, handle it locally
        if (_selectedParkingSpot!.isUserCreated == true) {
          // Update available spots locally
          _updateAvailableSpots(_selectedParkingSpot!, 1); // increase by 1
          
          _setLoading(false);
          return true;
        }
        
        // Otherwise, use the service
        final success = await _parkingService.cancelBooking(bookingId);
        
        if (success) {
          // Update available spots in our local list
          _updateAvailableSpots(_selectedParkingSpot!, 1); // increase by 1
        }
        
        _setLoading(false);
        return success;
      }
      
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to cancel booking: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
  
  // Helper to update available spots
  void _updateAvailableSpots(ParkingSpot spot, int change) {
    // Update in the nearby spots list
    final index = _nearbyParkingSpots.indexWhere(
      (s) => s.id.toHexString() == spot.id.toHexString()
    );
    
    if (index >= 0) {
      final updatedSpot = _nearbyParkingSpots[index].copyWith(
        availableSpots: _nearbyParkingSpots[index].availableSpots + change
      );
      
      _nearbyParkingSpots[index] = updatedSpot;
      
      // If this is the selected spot, update that too
      if (_selectedParkingSpot?.id.toHexString() == spot.id.toHexString()) {
        _selectedParkingSpot = updatedSpot;
      }
      
      // If it's a user-created spot, update in that list too
      if (spot.isUserCreated == true) {
        final userSpotIndex = _userCreatedSpots.indexWhere(
          (s) => s.id.toHexString() == spot.id.toHexString()
        );
        
        if (userSpotIndex >= 0) {
          _userCreatedSpots[userSpotIndex] = updatedSpot;
        }
      }
      
      notifyListeners();
    }
  }
  
  // Filter user created spots by distance
  List<ParkingSpot> _getUserCreatedSpotsNearby(
    double latitude, 
    double longitude, 
    double radiusKm
  ) {
    // In a real app, you would calculate actual distance
    // For now, we'll just return all user-created spots
    return _userCreatedSpots;
  }
  
  // Loading and error handling
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
  
  // This method was missing
  void clearError() {
    _error = null;
    notifyListeners();
  }
}