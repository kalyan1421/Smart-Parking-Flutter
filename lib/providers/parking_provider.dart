// lib/providers/parking_provider.dart - Firebase-based parking management
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../core/database/database_service.dart';
import '../models/parking_spot.dart';

class ParkingProvider extends ChangeNotifier {
  List<ParkingSpot> _parkingSpots = [];
  List<ParkingSpot> _filteredSpots = [];
  ParkingSpot? _selectedParkingSpot;
  bool _isLoading = false;
  String? _error;
  Position? _currentLocation;
  
  // Filter properties
  double _maxPrice = 100.0;
  double _minPrice = 0.0;
  List<String> _selectedAmenities = [];
  List<String> _selectedVehicleTypes = [];
  double _searchRadius = 2000; // in meters
  String _sortBy = 'distance'; // distance, price, rating
  bool _showAvailableOnly = true;
  
  
  // Getters
  List<ParkingSpot> get parkingSpots => _filteredSpots;
  List<ParkingSpot> get nearbyParkingSpots => _filteredSpots; // For backward compatibility
  List<ParkingSpot> get allParkingSpots => _parkingSpots;
  ParkingSpot? get selectedParkingSpot => _selectedParkingSpot;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Position? get currentLocation => _currentLocation;
  double get maxPrice => _maxPrice;
  double get minPrice => _minPrice;
  List<String> get selectedAmenities => _selectedAmenities;
  List<String> get selectedVehicleTypes => _selectedVehicleTypes;
  double get searchRadius => _searchRadius;
  String get sortBy => _sortBy;
  bool get showAvailableOnly => _showAvailableOnly;
  
  // Initialize current location
  Future<void> initializeLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      
      _currentLocation = await Geolocator.getCurrentPosition();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to get location: $e';
      notifyListeners();
    }
  }

  // Find nearby parking spots - Updated for Firebase
  Future<void> findNearbyParkingSpots(
    double latitude, 
    double longitude, 
    {double radius = 1.0}
  ) async {
    await loadParkingSpotsNear(latitude, longitude, radius: radius * 1000); // Convert to meters
  }
  
  // Load parking spots near location
  Future<void> loadParkingSpotsNear(double latitude, double longitude, {double? radius}) async {
    _setLoading(true);
    try {
      final searchRadius = radius ?? _searchRadius;
      final center = GeoFirePoint(GeoPoint(latitude, longitude));
      
      // Query Firestore using GeoFlutterFirePlus
      final collectionRef = DatabaseService.collection('parkingSpots');
      final geoCollectionReference = GeoCollectionReference(collectionRef);
      
      try {
        // Try geoflutterfire_plus geospatial query
        final querySnapshot = await geoCollectionReference.fetchWithin(
          center: center,
          radiusInKm: searchRadius / 1000,
          field: 'position',
          geopointFrom: (data) {
            final dataMap = data as Map<String, dynamic>?;
            final position = dataMap?['position'] as Map<String, dynamic>?;
            return position?['geopoint'] as GeoPoint? ?? const GeoPoint(0, 0);
          },
        );
        
        _parkingSpots = querySnapshot
            .map((doc) => ParkingSpot.fromFirestore(doc))
            .toList();
      } catch (geoError) {
        // Fallback to simple query without geo filtering
        final querySnapshot = await collectionRef.limit(20).get();
        
        _parkingSpots = querySnapshot.docs
            .map((doc) => ParkingSpot.fromFirestore(doc))
            .toList();
      }
      
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = 'Failed to load parking spots: $e';
      _parkingSpots = [];
      _filteredSpots = [];
    } finally {
      _setLoading(false);
    }
  }
  
  // Select a parking spot
  void selectParkingSpot(ParkingSpot spot) {
    _selectedParkingSpot = spot;
    notifyListeners();
  }
  
  // Apply filters to parking spots
  void _applyFilters() {
    _filteredSpots = _parkingSpots.where((spot) {
      // Availability filter
      if (_showAvailableOnly && !spot.isAvailableForBooking()) return false;
      
      // Price filter
      if (spot.pricePerHour < _minPrice || spot.pricePerHour > _maxPrice) return false;
      
      // Amenities filter
      if (_selectedAmenities.isNotEmpty) {
        bool hasSelectedAmenities = _selectedAmenities.every(
          (amenity) => spot.amenities.contains(amenity)
        );
        if (!hasSelectedAmenities) return false;
      }
      
      // Vehicle type filter
      if (_selectedVehicleTypes.isNotEmpty) {
        bool supportsVehicleType = _selectedVehicleTypes.any(
          (vehicleType) => spot.vehicleTypes.contains(vehicleType)
        );
        if (!supportsVehicleType) return false;
      }
      
      return true;
    }).toList();
    
    // Apply sorting
    _sortSpots();
    
    notifyListeners();
  }
  
  // Sort spots based on selected criteria
  void _sortSpots() {
    switch (_sortBy) {
      case 'price':
        _filteredSpots.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
        break;
      case 'rating':
        _filteredSpots.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'distance':
        if (_currentLocation != null) {
          _filteredSpots.sort((a, b) {
            final distanceA = Geolocator.distanceBetween(
              _currentLocation!.latitude, _currentLocation!.longitude,
              a.latitude, a.longitude
            );
            final distanceB = Geolocator.distanceBetween(
              _currentLocation!.latitude, _currentLocation!.longitude,
              b.latitude, b.longitude
            );
            return distanceA.compareTo(distanceB);
          });
        }
        break;
    }
  }
  
  // NOTE: Parking spot creation is now handled by admin app only
  // Users can only view and book existing parking spots
  
  // Update spot availability
  Future<bool> updateSpotAvailability(String spotId, int availableSpots) async {
    try {
      await DatabaseService.collection('parkingSpots').doc(spotId).update({
        'availableSpots': availableSpots,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update local list
      final index = _parkingSpots.indexWhere((s) => s.id == spotId);
      if (index != -1) {
        _parkingSpots[index] = _parkingSpots[index].copyWith(
          availableSpots: availableSpots,
          updatedAt: DateTime.now(),
        );
        _applyFilters();
      }
      
      return true;
    } catch (e) {
      _error = 'Failed to update availability: $e';
      notifyListeners();
      return false;
    }
  }

  // Book a parking spot (simplified - actual booking logic in BookingProvider)
  Future<bool> bookParkingSpot(ParkingSpot spot, DateTime startTime, DateTime endTime) async {
    // This method now just updates availability
    // The actual booking creation is handled by BookingProvider
    return await updateSpotAvailability(spot.id, spot.availableSpots - 1);
  }
  
  // Filter and search methods
  void updatePriceRange(double minPrice, double maxPrice) {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _applyFilters();
  }
  
  void updateSelectedAmenities(List<String> amenities) {
    _selectedAmenities = amenities;
    _applyFilters();
  }
  
  void updateSelectedVehicleTypes(List<String> vehicleTypes) {
    _selectedVehicleTypes = vehicleTypes;
    _applyFilters();
  }
  
  void updateSearchRadius(double radius) {
    _searchRadius = radius;
    notifyListeners();
  }
  
  void updateSortBy(String sortBy) {
    _sortBy = sortBy;
    _applyFilters();
  }
  
  void toggleAvailabilityFilter() {
    _showAvailableOnly = !_showAvailableOnly;
    _applyFilters();
  }
  
  void clearFilters() {
    _maxPrice = 100.0;
    _minPrice = 0.0;
    _selectedAmenities = [];
    _selectedVehicleTypes = [];
    _showAvailableOnly = true;
    _sortBy = 'distance';
    _applyFilters();
  }
  

  // Get parking spot by ID
  Future<ParkingSpot?> getParkingSpotById(String id) async {
    try {
      // First check if it's in our loaded spots
      final localSpot = _parkingSpots.where((spot) => spot.id == id).firstOrNull;
      if (localSpot != null) return localSpot;
      
      // If not found locally, fetch from Firestore
      final doc = await DatabaseService.collection('parkingSpots').doc(id).get();
      if (doc.exists) {
        return ParkingSpot.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _error = 'Failed to get parking spot: $e';
      notifyListeners();
      return null;
    }
  }
  
  // Load all parking spots from Firebase
  Future<void> loadAllParkingSpots() async {
    _setLoading(true);
    try {
      final querySnapshot = await DatabaseService.collection('parkingSpots')
          .orderBy('createdAt', descending: true)
          .get();
      
      _parkingSpots = querySnapshot.docs
          .map((doc) => ParkingSpot.fromFirestore(doc))
          .toList();
      
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = 'Failed to load parking spots: $e';
      _parkingSpots = [];
      _filteredSpots = [];
    } finally {
      _setLoading(false);
    }
  }

  // Search parking spots by query
  Future<void> searchParkingSpots(String query) async {
    _setLoading(true);
    try {
      final querySnapshot = await DatabaseService.collection('parkingSpots')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();
      
      _parkingSpots = querySnapshot.docs
          .map((doc) => ParkingSpot.fromFirestore(doc))
          .toList();
      
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = 'Failed to search parking spots: $e';
      _parkingSpots = [];
      _filteredSpots = [];
    } finally {
      _setLoading(false);
    }
  }
  
  // NOTE: Parking spot updates and deletions are handled by admin app only
  // Users can only view parking spots and update availability through bookings
  
  // Get spots owned by user
  Future<void> loadUserOwnedSpots(String userId) async {
    _setLoading(true);
    try {
      final querySnapshot = await DatabaseService.collection('parkingSpots')
          .where('ownerId', isEqualTo: userId)
          .get();
      
      _parkingSpots = querySnapshot.docs
          .map((doc) => ParkingSpot.fromFirestore(doc))
          .toList();
      
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = 'Failed to load owned spots: $e';
      _parkingSpots = [];
      _filteredSpots = [];
    } finally {
      _setLoading(false);
    }
  }
  
  // Get distance to parking spot
  double? getDistanceToSpot(ParkingSpot spot) {
    if (_currentLocation == null) return null;
    
    return Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      spot.latitude,
      spot.longitude,
    );
  }
  
  // Stream parking spots in real-time
  Stream<List<ParkingSpot>> streamParkingSpotsNear(double latitude, double longitude) {
    final center = GeoFirePoint(GeoPoint(latitude, longitude));
    final collectionRef = DatabaseService.collection('parkingSpots');
    final geoCollectionReference = GeoCollectionReference(collectionRef);
    
    return geoCollectionReference.subscribeWithin(
      center: center,
      radiusInKm: _searchRadius / 1000,
      field: 'position',
      geopointFrom: (data) {
        final dataMap = data as Map<String, dynamic>?;
        final position = dataMap?['position'] as Map<String, dynamic>?;
        return position?['geopoint'] as GeoPoint? ?? const GeoPoint(0, 0);
      },
    ).map((querySnapshot) => querySnapshot
        .map((doc) => ParkingSpot.fromFirestore(doc))
        .toList());
  }
  
  // Cancel booking (simplified - actual logic in BookingProvider)
  Future<bool> cancelBooking(String bookingId) async {
    // This is now handled by BookingProvider
    // Just return true for backward compatibility
    return true;
  }
  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}