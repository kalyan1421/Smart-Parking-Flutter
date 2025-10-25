// lib/repositories/auth_repository.dart - Authentication repository with fixed ID handling
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_parking_app/config/constants.dart';
import 'package:smart_parking_app/core/database/database_service.dart';
import 'package:smart_parking_app/models/user.dart';

class AuthRepository {
  final DbCollection _collection = DatabaseService.collection(AppConstants.usersCollection);
  
  // Register a new user
  Future<User> register(String username, String email, String password, String name, String phoneNumber) async {
    // Check if email is already registered
    final existingUser = await _collection.findOne(where.eq('email', email));
    if (existingUser != null) {
      throw Exception('Email already registered');
    }
    
    // Check if username is already taken
    final existingUsername = await _collection.findOne(where.eq('username', username));
    if (existingUsername != null) {
      throw Exception('Username already taken');
    }
    
    // Hash password
    final hashedPassword = _hashPassword(password);
    
    // Create user document
    final userId = ObjectId();
    final userDoc = {
      '_id': userId,
      'username': username,
      'email': email,
      'password': hashedPassword,
      'name': name,
      'phoneNumber': phoneNumber,
      'vehicleIds': [],
      'bookingIds': [],
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    // Insert user into database
    await _collection.insert(userDoc);
    
    // Save user ID in shared preferences - store as hex string
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId.toHexString());
    
    // Return user object
    return User.fromJson(userDoc);
  }
  
  // Login user
  Future<User> login(String email, String password) async {
    // Find user by email
    final userDoc = await _collection.findOne(where.eq('email', email));
    if (userDoc == null) {
      throw Exception('User not found');
    }
    
    // Verify password
    final hashedPassword = userDoc['password'];
    if (hashedPassword != _hashPassword(password)) {
      throw Exception('Invalid password');
    }
    
    // Get user ID in the correct format
    final userId = userDoc['_id'];
    if (userId == null) {
      throw Exception('Invalid user data (missing ID)');
    }
    
    // Save user ID in shared preferences
    final prefs = await SharedPreferences.getInstance();
    if (userId is ObjectId) {
      await prefs.setString('userId', userId.toHexString());
    } else {
      await prefs.setString('userId', userId.toString());
    }
    
    // Return user object
    return User.fromJson(userDoc);
  }
  
  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }
  
  // Get current user
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdString = prefs.getString('userId');
    
    if (userIdString == null) {
      return null;
    }
    
    try {
      // Try to parse as ObjectId
      final userId = ObjectId.parse(userIdString);
      final userDoc = await _collection.findOne(where.id(userId));
      
      if (userDoc == null) {
        await prefs.remove('userId');
        return null;
      }
      
      return User.fromJson(userDoc);
    } catch (e) {
      // If it fails to parse as ObjectId, try as string
      final userDoc = await _collection.findOne(where.eq('_id', userIdString));
      
      if (userDoc == null) {
        await prefs.remove('userId');
        return null;
      }
      
      return User.fromJson(userDoc);
    }
  }
  
  // Update user profile
  Future<User> updateProfile(User user, {String? name, String? phoneNumber}) async {
    dynamic userId;
    
    // Determine the correct ID format
    if (user.id is ObjectId) {
      userId = user.id;
    } else if (user.id is String) {
      try {
        userId = ObjectId.parse(user.id);
      } catch (e) {
        userId = user.id;
      }
    } else {
      userId = user.id;
    }
    
    final update = {
      r'$set': {
        if (name != null) 'name': name,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
      }
    };
    
    await _collection.update(
      userId is ObjectId ? where.id(userId) : where.eq('_id', userId),
      update
    );
    
    final updatedUserDoc = await _collection.findOne(
      userId is ObjectId ? where.id(userId) : where.eq('_id', userId)
    );
    
    if (updatedUserDoc == null) {
      throw Exception('Failed to retrieve updated user');
    }
    
    return User.fromJson(updatedUserDoc);
  }
  
  // Change password
  Future<void> changePassword(User user, String currentPassword, String newPassword) async {
    dynamic userId;
    
    // Determine the correct ID format
    if (user.id is ObjectId) {
      userId = user.id;
    } else if (user.id is String) {
      try {
        userId = ObjectId.parse(user.id);
      } catch (e) {
        userId = user.id;
      }
    } else {
      userId = user.id;
    }
    
    final userDoc = await _collection.findOne(
      userId is ObjectId ? where.id(userId) : where.eq('_id', userId)
    );
    
    if (userDoc == null) {
      throw Exception('User not found');
    }
    
    final hashedPassword = userDoc['password'];
    if (hashedPassword != _hashPassword(currentPassword)) {
      throw Exception('Current password is incorrect');
    }
    
    final newHashedPassword = _hashPassword(newPassword);
    await _collection.update(
      userId is ObjectId ? where.id(userId) : where.eq('_id', userId),
      {r'$set': {'password': newHashedPassword}}
    );
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    final userDoc = await _collection.findOne(where.eq('email', email));
    if (userDoc == null) {
      throw Exception('User not found');
    }
    
    // In a real app, send a password reset email
    // For demo purposes, set a temp password
    final tempPassword = 'resetpass123';
    final hashedPassword = _hashPassword(tempPassword);
    
    await _collection.update(
      where.eq('email', email),
      {r'$set': {'password': hashedPassword}}
    );
    
    // In a real app, email the temp password to the user
    print('Password reset for $email. Temp password: $tempPassword');
  }
  
  // Hash password
  String _hashPassword(String password) {
    // In a real app, use a secure hashing library
    // For demo purposes, using simple hashing
    return password.hashCode.toString();
  }
}