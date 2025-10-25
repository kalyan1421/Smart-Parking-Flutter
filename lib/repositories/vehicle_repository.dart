
// lib/repositories/vehicle_repository.dart - Vehicle repository
import 'package:mongo_dart/mongo_dart.dart';
import 'package:smart_parking_app/config/constants.dart';
import 'package:smart_parking_app/core/database/database_service.dart';
import 'package:smart_parking_app/models/vehicle.dart';

class VehicleRepository {
  final DbCollection _vehicleCollection = DatabaseService.collection('vehicles');
  final DbCollection _userCollection = DatabaseService.collection(AppConstants.usersCollection);
  
  // Get user's vehicles
  Future<List<Vehicle>> getUserVehicles(ObjectId userId) async {
    final vehicleDocs = await _vehicleCollection.find(
      where.eq('userId', userId)
    ).toList();
    
    return vehicleDocs.map((doc) => Vehicle.fromJson(doc)).toList();
  }
  
  // Get vehicle by ID
  Future<Vehicle> getVehicleById(ObjectId vehicleId) async {
    final vehicleDoc = await _vehicleCollection.findOne(where.id(vehicleId));
    if (vehicleDoc == null) {
      throw Exception('Vehicle not found');
    }
    
    return Vehicle.fromJson(vehicleDoc);
  }
  
  // Add vehicle
  Future<Vehicle> addVehicle(
    ObjectId userId,
    String licensePlate,
    String make,
    String model,
    String color,
    String type,
    {bool isDefault = false}
  ) async {
    // Check if this is the first vehicle
    final existingVehicles = await getUserVehicles(userId);
    if (existingVehicles.isEmpty) {
      isDefault = true;
    } else if (isDefault) {
      // Clear existing default vehicles
      await _clearDefaultVehicles(userId);
    }
    
    final vehicleId = ObjectId();
    final vehicleDoc = {
      '_id': vehicleId,
      'userId': userId,
      'licensePlate': licensePlate,
      'make': make,
      'model': model,
      'color': color,
      'type': type,
      'isDefault': isDefault,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    await _vehicleCollection.insert(vehicleDoc);
    
    // Update user's vehicle IDs
    await _userCollection.update(
      where.id(userId),
      {r'$push': {'vehicleIds': vehicleId}}
    );
    
    return Vehicle.fromJson(vehicleDoc);
  }Future<Vehicle> updateVehicle(
    ObjectId vehicleId,
    {
      String? licensePlate,
      String? make,
      String? model,
      String? color,
      String? type,
      bool? isDefault
    }
  ) async {
    final update = {
      r'$set': {
        if (licensePlate != null) 'licensePlate': licensePlate,
        if (make != null) 'make': make,
        if (model != null) 'model': model,
        if (color != null) 'color': color,
        if (type != null) 'type': type,
        if (isDefault != null) 'isDefault': isDefault,
      }
    };
    
    // If setting as default, clear other defaults
    final vehicle = await getVehicleById(vehicleId);
    // if (isDefault == true) {
    //   await _clearDefaultVehicles(vehicle.userId);
    // }
    
    await _vehicleCollection.update(where.id(vehicleId), update);
    
    final updatedVehicleDoc = await _vehicleCollection.findOne(where.id(vehicleId));
    return Vehicle.fromJson(updatedVehicleDoc!);
  }
  
  // Delete vehicle
  Future<void> deleteVehicle(ObjectId vehicleId) async {
    final vehicle = await getVehicleById(vehicleId);
    
    await _vehicleCollection.remove(where.id(vehicleId));
    
    // Update user's vehicle IDs
    // await _userCollection.update(
    //   where.id(vehicle.userId),
    //   {r'$pull': {'vehicleIds': vehicleId}}
    // );
    
    // If this was the default vehicle, set another as default
    if (vehicle.isDefault) {
      // final remainingVehicles = await getUserVehicles(vehicle.userId);
      // if (remainingVehicles.isNotEmpty) {
      //   await updateVehicle(remainingVehicles.first.id, isDefault: true);
      // }
    }
  }
  
  // Clear default vehicles
  Future<void> _clearDefaultVehicles(ObjectId userId) async {
    await _vehicleCollection.update(
      where.eq('userId', userId).eq('isDefault', true),
      {r'$set': {'isDefault': false}}
    );
  }
}