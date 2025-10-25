
// lib/core/database/database_service.dart - MongoDB connection service
import 'package:mongo_dart/mongo_dart.dart';
import 'package:smart_parking_app/config/constants.dart';

class DatabaseService {
  static Db? _db;
  
  static Future<void> init() async {
    if (_db == null) {
      try {
        _db = await Db.create(AppConstants.mongoDbUrl);
        await _db!.open();
        print('Connected to MongoDB');
      } catch (e) {
        print('Error connecting to MongoDB: $e');
        rethrow;
      }
    }
  }
  
  static Db get db {
    if (_db == null) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _db!;
  }
  
  static DbCollection collection(String name) {
    return db.collection(name);
  }
  
  static Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      print('Disconnected from MongoDB');
    }
  }
}
