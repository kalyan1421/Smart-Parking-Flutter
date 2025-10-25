// lib/repositories/booking_repository.dart
import 'package:mongo_dart/mongo_dart.dart';
import 'package:smart_parking_app/config/constants.dart';
import 'package:smart_parking_app/core/database/database_service.dart';
import 'package:smart_parking_app/models/booking.dart';
import 'package:smart_parking_app/models/parking_spot.dart';

class BookingRepository {
  final DbCollection _collection = DatabaseService.collection(AppConstants.bookingsCollection);
  final DbCollection _usersCollection = DatabaseService.collection(AppConstants.usersCollection);

  // Create a new booking
  Future<Booking> createBooking(
    String userId,
    ParkingSpot parkingSpot,
    DateTime startTime,
    DateTime endTime,
    double totalPrice
  ) async {
    // Create booking document
    final bookingId = ObjectId();
    
    // Handle userId correctly - parse as ObjectId if possible
    dynamic userIdObj;
    try {
      userIdObj = ObjectId.parse(userId);
    } catch (e) {
      // If parsing fails, use as string
      userIdObj = userId;
    }
    
    final bookingDoc = {
      '_id': bookingId,
      'userId': userIdObj,
      'parkingSpotId': parkingSpot.id.toString(),
      'parkingSpotName': parkingSpot.name,
      'location': {
        'type': 'Point',
        'coordinates': [parkingSpot.longitude, parkingSpot.latitude],
      },
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalPrice': totalPrice,
      'status': 'active', // active, completed, cancelled
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    // Insert booking into database
    await _collection.insert(bookingDoc);
    
    // Add booking ID to user's bookings list
    await _usersCollection.update(
      userIdObj is ObjectId ? where.id(userIdObj) : where.eq('_id', userIdObj),
      {
        r'$push': {
          'bookingIds': bookingId.toHexString(),
        }
      }
    );
    
    // Return booking object
    return Booking.fromJson(bookingDoc);
  }
  
  // Get all bookings for a user
  Future<List<Booking>> getUserBookings(String userId) async {
    // Parse userId as ObjectId if possible
    dynamic userIdObj;
    try {
      userIdObj = ObjectId.parse(userId);
    } catch (e) {
      userIdObj = userId;
    }
    
    final bookings = await _collection.find(
      userIdObj is ObjectId ? where.eq('userId', userIdObj) : where.eq('userId', userIdObj)
    ).toList();
    
    return bookings.map((doc) => Booking.fromJson(doc)).toList();
  }
  
  // Get a specific booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    // Parse bookingId as ObjectId if possible
    dynamic bookingIdObj;
    try {
      bookingIdObj = ObjectId.parse(bookingId);
    } catch (e) {
      bookingIdObj = bookingId;
    }
    
    final bookingDoc = await _collection.findOne(
      bookingIdObj is ObjectId ? where.id(bookingIdObj) : where.eq('_id', bookingIdObj)
    );
    
    if (bookingDoc == null) {
      return null;
    }
    
    return Booking.fromJson(bookingDoc);
  }
  
  // Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    // Parse bookingId as ObjectId if possible
    dynamic bookingIdObj;
    try {
      bookingIdObj = ObjectId.parse(bookingId);
    } catch (e) {
      bookingIdObj = bookingId;
    }
    
    final result = await _collection.update(
      bookingIdObj is ObjectId ? where.id(bookingIdObj) : where.eq('_id', bookingIdObj),
      {
        r'$set': {
          'status': 'cancelled',
          'updatedAt': DateTime.now().toIso8601String(),
        }
      }
    );
    
    return result['nModified'] > 0;
  }
  
  // Mark a booking as completed
  Future<bool> completeBooking(String bookingId) async {
    // Parse bookingId as ObjectId if possible
    dynamic bookingIdObj;
    try {
      bookingIdObj = ObjectId.parse(bookingId);
    } catch (e) {
      bookingIdObj = bookingId;
    }
    
    final result = await _collection.update(
      bookingIdObj is ObjectId ? where.id(bookingIdObj) : where.eq('_id', bookingIdObj),
      {
        r'$set': {
          'status': 'completed',
          'updatedAt': DateTime.now().toIso8601String(),
        }
      }
    );
    
    return result['nModified'] > 0;
  }
  
  // Get active bookings for a user
  Future<List<Booking>> getActiveBookings(String userId) async {
    // Parse userId as ObjectId if possible
    dynamic userIdObj;
    try {
      userIdObj = ObjectId.parse(userId);
    } catch (e) {
      userIdObj = userId;
    }
    
    final bookings = await _collection.find(
      userIdObj is ObjectId 
          ? where.eq('userId', userIdObj).eq('status', 'active')
          : where.eq('userId', userIdObj).eq('status', 'active')
    ).toList();
    
    return bookings.map((doc) => Booking.fromJson(doc)).toList();
  }
  
  // Get booking history for a user (completed and cancelled bookings)
  Future<List<Booking>> getBookingHistory(String userId) async {
    // Parse userId as ObjectId if possible
    dynamic userIdObj;
    try {
      userIdObj = ObjectId.parse(userId);
    } catch (e) {
      userIdObj = userId;
    }
    
    final bookings = await _collection.find(
      userIdObj is ObjectId
          ? where.eq('userId', userIdObj).oneFrom('status', ['completed', 'cancelled'])
          : where.eq('userId', userIdObj).oneFrom('status', ['completed', 'cancelled'])
    ).toList();
    
    return bookings.map((doc) => Booking.fromJson(doc)).toList();
  }
}