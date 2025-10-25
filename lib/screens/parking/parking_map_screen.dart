// lib/screens/parking/parking_map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smart_parking_app/config/app_config.dart';
import 'package:smart_parking_app/providers/location_provider.dart';
import 'package:smart_parking_app/providers/parking_provider.dart';
import 'package:smart_parking_app/providers/traffic_provider.dart';
import 'package:smart_parking_app/models/parking_spot.dart';
import 'package:smart_parking_app/screens/parking/parking_spot_bottom_sheet.dart';
import 'package:smart_parking_app/screens/parking/add_parking_spot_dialog.dart';
import 'package:smart_parking_app/widgets/common/loading_indicator.dart';

class ParkingMapScreen extends StatefulWidget {
  @override
  _ParkingMapScreenState createState() => _ParkingMapScreenState();
}

class _ParkingMapScreenState extends State<ParkingMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _mapLoaded = false;
  bool _isAddingParkingSpot = false;
  LatLng? _selectedLocation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize traffic overlay safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final trafficProvider = Provider.of<TrafficProvider>(context, listen: false);
      trafficProvider.initializeTrafficOverlay();
      _loadParkingSpots();
    });
  }
  
  Future<void> _loadParkingSpots() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
    
    // Wait for location
    if (!locationProvider.hasLocation) {
      await locationProvider.getCurrentLocation();
    }
    
    // Get user location - using the separate latitude and longitude properties
    final userLatitude = locationProvider.currentLocation?.latitude ?? 0;
    final userLongitude = locationProvider.currentLocation?.longitude ?? 0;
    
    // Find parking spots - passing separate latitude and longitude
    await parkingProvider.findNearbyParkingSpots(
      userLatitude, 
      userLongitude,
      radius: AppConfig.defaultSearchRadius
    );
    
    // Move map to user location
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(userLatitude, userLongitude), 14.0
      ));
    }
    
    // Update UI
    _updateMarkers();
  }
  
  void _updateMarkers() {
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
    final spots = parkingProvider.nearbyParkingSpots;
    
    Set<Marker> markers = {};
    
    // Create marker for each parking spot
    for (final spot in spots) {
      markers.add(Marker(
        markerId: MarkerId(spot.id.toHexString()),
        position: LatLng(spot.latitude, spot.longitude),
        infoWindow: InfoWindow(
          title: spot.name,
          snippet: '${spot.availableSpots} spots • ${AppConfig.currencySymbol}${spot.pricePerHour.toStringAsFixed(2)}/hr',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          spot.availableSpots > 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed
        ),
        onTap: () => _onMarkerTapped(spot),
      ));
    }
    
    // Create marker for user location
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    if (locationProvider.hasLocation) {
      markers.add(Marker(
        markerId: MarkerId('user_location'),
        position: LatLng(
          locationProvider.currentLocation!.latitude,
          locationProvider.currentLocation!.longitude
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: 'Your Location',
        ),
      ));
    }
    
    // Add temporary marker for new parking spot if in adding mode
    if (_isAddingParkingSpot && _selectedLocation != null) {
      markers.add(Marker(
        markerId: MarkerId('new_parking_spot'),
        position: _selectedLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(
          title: 'New Parking Spot',
          snippet: 'Tap to add details',
        ),
        onTap: () => _showAddParkingDialog(_selectedLocation!),
      ));
    }
    
    setState(() {
      _markers = markers;
    });
  }
  
  void _onMarkerTapped(ParkingSpot spot) {
    // If in adding mode, ignore regular marker taps
    if (_isAddingParkingSpot) return;
    
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
    parkingProvider.selectParkingSpot(spot);
    
    // Show bottom sheet with details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ParkingSpotBottomSheet(),
    );
  }
  
  void _startAddingParkingSpot() {
    setState(() {
      _isAddingParkingSpot = true;
      _selectedLocation = null;
    });
    
    // Show a snackbar with instructions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tap on the map to place a new parking spot'),
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Cancel',
          onPressed: _cancelAddingParkingSpot,
        ),
      ),
    );
  }
  
  void _cancelAddingParkingSpot() {
    setState(() {
      _isAddingParkingSpot = false;
      _selectedLocation = null;
    });
    _updateMarkers();
  }
  
  void _showAddParkingDialog(LatLng location) {
    showDialog(
      context: context,
      builder: (context) => AddParkingSpotDialog(
        location: location,
        onSave: (newSpot) {
          _addNewParkingSpot(newSpot);
        },
      ),
    ).then((_) {
      _cancelAddingParkingSpot();
    });
  }
  
  Future<void> _addNewParkingSpot(ParkingSpot newSpot) async {
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
    await parkingProvider.addParkingSpot(newSpot);
    
    // Refresh the markers
    _updateMarkers();
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New parking spot added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final parkingProvider = Provider.of<ParkingProvider>(context);
    final trafficProvider = Provider.of<TrafficProvider>(context);
    
    // Ensure traffic overlay is set up (without notifying)
    if (!trafficProvider.isOverlaySetup) {
      trafficProvider.setupTrafficOverlay();
    }
    
    // Prepare tile overlays
    Set<TileOverlay> tileOverlays = {};
    if (trafficProvider.isOverlaySetup && 
        trafficProvider.trafficOverlay != null &&
        trafficProvider.showTrafficLayer) {
      tileOverlays = {trafficProvider.trafficOverlay!};
    }
    
    // Default camera position (will be updated with user's location)
    final initialCameraPosition = CameraPosition(
      target: LatLng(
        locationProvider.currentLocation?.latitude ?? 0,
        locationProvider.currentLocation?.longitude ?? 0
      ),
      zoom: 13.0,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Parking'),
        actions: [
          // Traffic toggle button
          IconButton(
            icon: Icon(
              trafficProvider.showTrafficLayer ? Icons.traffic : Icons.traffic_outlined,
              color: trafficProvider.showTrafficLayer ? Colors.amber : null,
            ),
            tooltip: 'Toggle traffic',
            onPressed: () {
              trafficProvider.toggleTrafficLayer();
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadParkingSpots,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () {
              if (locationProvider.hasLocation && _mapController != null) {
                _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
                  LatLng(
                    locationProvider.currentLocation!.latitude,
                    locationProvider.currentLocation!.longitude
                  ), 
                  15.0
                ));
              }
            },
            tooltip: 'My Location',
          ),
        ],
      ),
      body: Column(
        children: [
          // ParkingFilterBar(),
          Expanded(
            child: Stack(
              children: [
                // Map
                GoogleMap(
                  initialCameraPosition: initialCameraPosition,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: _markers,
                  tileOverlays: tileOverlays,
                  onMapCreated: (controller) {
                    setState(() {
                      _mapController = controller;
                      _mapLoaded = true;
                    });
                    
                    // Initial load if we have location
                    if (locationProvider.hasLocation) {
                      _updateMarkers();
                      
                      controller.animateCamera(CameraUpdate.newLatLngZoom(
                        LatLng(
                          locationProvider.currentLocation!.latitude,
                          locationProvider.currentLocation!.longitude
                        ), 
                        14.0
                      ));
                    }
                  },
                  onTap: (LatLng location) {
                    if (_isAddingParkingSpot) {
                      setState(() {
                        _selectedLocation = location;
                      });
                      _updateMarkers();
                      _showAddParkingDialog(location);
                    }
                  },
                ),
                
                // Loading indicator
                if (parkingProvider.isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: LoadingIndicator(),
                      ),
                    ),
                  ),
                  
                // Error message
                if (parkingProvider.error != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              parkingProvider.error!,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () => parkingProvider.clearError(),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Parking spots found indicator
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${parkingProvider.nearbyParkingSpots.length} parking spots found',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Add parking spot button (visible only when not in adding mode)
                if (!_isAddingParkingSpot)
                  Positioned(
                    bottom: 90,
                    right: 16,
                    child: FloatingActionButton(
                      onPressed: _startAddingParkingSpot,
                      child: Icon(Icons.add_location),
                      tooltip: 'Add Parking Space',
                      heroTag: 'add_parking',
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                
                // Cancel adding button (visible only when in adding mode)
                if (_isAddingParkingSpot)
                  Positioned(
                    bottom: 90,
                    right: 16,
                    child: FloatingActionButton(
                      onPressed: _cancelAddingParkingSpot,
                      child: Icon(Icons.close),
                      tooltip: 'Cancel',
                      heroTag: 'cancel_add_parking',
                      backgroundColor: Colors.red,
                    ),
                  ),
                
                // Traffic legend
                if (trafficProvider.showTrafficLayer)
                  Positioned(
                    left: 16,
                    bottom: 160,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Traffic:', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            _legendItem(Colors.green, 'Low'),
                            _legendItem(Colors.orange, 'Medium'),
                            _legendItem(Colors.red, 'High'),
                            _legendItem(Colors.purple, 'Severe'),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadParkingSpots,
        child: Icon(Icons.search),
        tooltip: 'Search Parking',
      ),
    );
  }
  
  // Create legend item widget
  Widget _legendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}