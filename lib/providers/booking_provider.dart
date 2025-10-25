// lib/providers/booking_provider.dart
import 'package:flutter/foundation.dart';
import 'package:smart_parking_app/models/booking.dart';
import 'package:smart_parking_app/models/parking_spot.dart';
import 'package:smart_parking_app/repositories/booking_repository.dart';

class BookingProvider with ChangeNotifier {
  final BookingRepository _bookingRepository;
  
  List<Booking> _activeBookings = [];
  List<Booking> _bookingHistory = [];
  bool _isLoading = false;
  String? _error;
  
  BookingProvider(this._bookingRepository);
  
  // Getters
  List<Booking> get activeBookings => _activeBookings;
  List<Booking> get bookingHistory => _bookingHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Create a new booking
  Future<Booking?> createBooking(
    String userId,
    ParkingSpot parkingSpot,
    DateTime startTime,
    DateTime endTime,
    double totalPrice
  ) async {
    _setLoading(true);
    clearError();
    
    try {
      final booking = await _bookingRepository.createBooking(
        userId,
        parkingSpot,
        startTime,
        endTime,
        totalPrice,
      );
      
      // Add to active bookings
      _activeBookings = [booking, ..._activeBookings];
      notifyListeners();
      
      return booking;
    } catch (e) {
      _setError('Failed to create booking: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Load user's active bookings
  Future<void> loadActiveBookings(String userId) async {
    _setLoading(true);
    clearError();
    
    try {
      final bookings = await _bookingRepository.getActiveBookings(userId);
      _activeBookings = bookings;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load active bookings: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Load user's booking history
  Future<void> loadBookingHistory(String userId) async {
    _setLoading(true);
    clearError();
    
    try {
      final bookings = await _bookingRepository.getBookingHistory(userId);
      _bookingHistory = bookings;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load booking history: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    _setLoading(true);
    clearError();
    
    try {
      final success = await _bookingRepository.cancelBooking(bookingId);
      
      if (success) {
        // Update booking status in local lists
        final activeIndex = _activeBookings.indexWhere((b) => b.id.toHexString() == bookingId);
        if (activeIndex >= 0) {
          final updatedBooking = _activeBookings[activeIndex].copyWith(
            status: 'cancelled',
            updatedAt: DateTime.now(),
          );
          
          // Remove from active bookings
          _activeBookings.removeAt(activeIndex);
          
          // Add to booking history
          _bookingHistory = [updatedBooking, ..._bookingHistory];
          
          notifyListeners();
        }
      }
      
      return success;
    } catch (e) {
      _setError('Failed to cancel booking: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Complete a booking
  Future<bool> completeBooking(String bookingId) async {
    _setLoading(true);
    clearError();
    
    try {
      final success = await _bookingRepository.completeBooking(bookingId);
      
      if (success) {
        // Update booking status in local lists
        final activeIndex = _activeBookings.indexWhere((b) => b.id.toHexString() == bookingId);
        if (activeIndex >= 0) {
          final updatedBooking = _activeBookings[activeIndex].copyWith(
            status: 'completed',
            updatedAt: DateTime.now(),
          );
          
          // Remove from active bookings
          _activeBookings.removeAt(activeIndex);
          
          // Add to booking history
          _bookingHistory = [updatedBooking, ..._bookingHistory];
          
          notifyListeners();
        }
      }
      
      return success;
    } catch (e) {
      _setError('Failed to complete booking: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Get a booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    _setLoading(true);
    clearError();
    
    try {
      return await _bookingRepository.getBookingById(bookingId);
    } catch (e) {
      _setError('Failed to get booking: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Error and loading helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}