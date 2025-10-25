
// lib/config/constants.dart - App constants
class AppConstants {
  // MongoDB connection
  static const String mongoDbUrl = 'mongodb+srv://kalyan91333:N0K0tSsQLTV7D093@cluster0.x5ivq.mongodb.net/trafficdb'; // Use environment variables in production
  static const String googleMapsApiKey  ='AIzaSyA3TG94CbG-lUzrgusZggVrOPEaZ9DD3D0';
  // Collection names
  static const String usersCollection = 'users';
  static const String parkingAreasCollection = 'parking_areas';
  static const String parkingSlotsCollection = 'parking_slots';
  static const String bookingsCollection = 'bookings';
  static const String trafficDataCollection = 'traffic_data';
  
  // Map settings
  static const double defaultZoom = 14.0;
  static const double defaultLat = 37.7749; // Default latitude
  static const double defaultLng = -122.4194; // Default longitude
  
  // Parking status
  static const String statusAvailable = 'available';
  static const String statusReserved = 'reserved';
  static const String statusOccupied = 'occupied';
  
  // Booking status
  static const String bookingPending = 'pending';
  static const String bookingConfirmed = 'confirmed';
  static const String bookingCheckedIn = 'checked_in';
  static const String bookingCompleted = 'completed';
  static const String bookingCancelled = 'cancelled';
}