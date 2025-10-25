// lib/core/config/app_config.dart
class AppConfig {
  // API Keys
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  
  // Database Configuration
  static const String mongoDbUri = 'YOUR_MONGODB_URI';
  static const String dbName = 'smart_parking';
  
  // App Settings
  static const int bookingCancellationTimeLimit = 60; // Minutes before start time
  static const double defaultSearchRadius = 2000; // In meters
  static const int maxBookingDurationHours = 24;
  
  // Payment Settings
  static const bool enabledPayments = false; // Toggle payment functionality
  static const String currencySymbol = 'K';
  
  // Notifications
  static const bool enablePushNotifications = true;
  
  // Feature Flags
  static const bool enableElectricVehicleFiltering = true;
  static const bool enableAccessibilityFeatures = true;
  static const bool enableRealTimeUpdates = true;
}