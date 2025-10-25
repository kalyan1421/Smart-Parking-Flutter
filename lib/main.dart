// lib/main.dart - Updated with BookingProvider
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_parking_app/config/routes.dart';
import 'package:smart_parking_app/config/theme.dart';
import 'package:smart_parking_app/core/database/database_service.dart';
import 'package:smart_parking_app/providers/auth_provider.dart';
import 'package:smart_parking_app/providers/booking_provider.dart';
import 'package:smart_parking_app/providers/location_provider.dart';
import 'package:smart_parking_app/providers/parking_provider.dart';
import 'package:smart_parking_app/providers/parking_service.dart';
import 'package:smart_parking_app/providers/traffic_provider.dart';
import 'package:smart_parking_app/providers/routing_provider.dart';
import 'package:smart_parking_app/repositories/booking_repository.dart';
import 'package:smart_parking_app/screens/auth/login_screen.dart';
import 'package:smart_parking_app/screens/home/home_screen.dart';
import 'package:smart_parking_app/widgets/common/loading_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize MongoDB connection
  await DatabaseService.init();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => TrafficProvider()),
        ChangeNotifierProvider(create: (_) => RoutingProvider()),
        
        // Initialize repositories
        Provider(create: (_) => BookingRepository()),
        
        // Initialize services
        Provider(create: (_) => ParkingService()),
        
        // Initialize providers that depend on services/repositories
        ChangeNotifierProxyProvider<ParkingService, ParkingProvider>(
          create: (context) => ParkingProvider(context.read<ParkingService>()),
          update: (context, service, previous) => previous ?? ParkingProvider(service),
        ),
        ChangeNotifierProxyProvider<BookingRepository, BookingProvider>(
          create: (context) => BookingProvider(context.read<BookingRepository>()),
          update: (context, repository, previous) => previous ?? BookingProvider(repository),
        ),
      ],
      child: MyAppContent(),
    );
  }
}

class MyAppContent extends StatefulWidget {
  @override
  _MyAppContentState createState() => _MyAppContentState();
}

class _MyAppContentState extends State<MyAppContent> {
  bool _initializing = true;
  bool _initialized = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    // We use Future.microtask to schedule the initialization after the current build phase
    Future.microtask(() => _initializeApp());
  }
  
  Future<void> _initializeApp() async {
    if (_initialized) return;
    
    try {
      setState(() {
        _initializing = true;
      });
      
      // Initialize auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();
      
      // Initialize location provider
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      await locationProvider.initialize();
      
      // Initialize traffic provider
      final trafficProvider = Provider.of<TrafficProvider>(context, listen: false);
      await Future.microtask(() => trafficProvider.initializeTrafficOverlay());
      
      setState(() {
        _initializing = false;
        _initialized = true;
        _error = null;
      });
    } catch (e) {
      print('Error initializing app: $e');
      setState(() {
        _initializing = false;
        _initialized = true;
        _error = e.toString();
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing
    if (_initializing) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Parking',
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LoadingIndicator(),
                SizedBox(height: 16),
                Text('Loading Smart Parking...'),
              ],
            ),
          ),
        ),
      );
    }
    
    // Show error screen if initialization failed
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Parking',
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text('Failed to initialize app:'),
                SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Colors.red)),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initializeApp,
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // App is initialized, show normal content
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Smart Parking',
          theme: AppTheme.lightTheme,
          routes: AppRoutes.routes,
          home: authProvider.isLoggedIn ? HomeScreen() : LoginScreen(),
        );
      },
    );
  }
}