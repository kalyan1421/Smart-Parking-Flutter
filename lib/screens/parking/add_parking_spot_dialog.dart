// lib/screens/parking/add_parking_spot_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_parking_app/models/parking_spot.dart';
import 'package:smart_parking_app/screens/parking/id_generator.dart';

class AddParkingSpotDialog extends StatefulWidget {
  final LatLng location;
  final Function(ParkingSpot) onSave;

  const AddParkingSpotDialog({
    Key? key,
    required this.location,
    required this.onSave,
  }) : super(key: key);

  @override
  _AddParkingSpotDialogState createState() => _AddParkingSpotDialogState();
}

class _AddParkingSpotDialogState extends State<AddParkingSpotDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalSpotsController = TextEditingController(text: '1');
  final _pricePerHourController = TextEditingController(text: '2.00');
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _totalSpotsController.dispose();
    _pricePerHourController.dispose();
    super.dispose();
  }
  
  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      // Create a new parking spot
      final newSpot = ParkingSpot(
        id: IdGenerator.generate(), // You would need to implement this or use a UUID package
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        totalSpots: int.parse(_totalSpotsController.text),
        availableSpots: int.parse(_totalSpotsController.text), // Initially all spots are available
        pricePerHour: double.parse(_pricePerHourController.text),
        features: [], // Basic features
        isUserCreated: true, // Flag to indicate this is user-created
      );
      
      widget.onSave(newSpot);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Parking Space'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location: ${widget.location.latitude.toStringAsFixed(5)}, ${widget.location.longitude.toStringAsFixed(5)}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. My Driveway Parking',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g. Private parking space available for booking',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalSpotsController,
                      decoration: InputDecoration(
                        labelText: 'Total Spots',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        int? spots = int.tryParse(value);
                        if (spots == null || spots < 1) {
                          return 'Min 1';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _pricePerHourController,
                      decoration: InputDecoration(
                        labelText: 'Price/Hour',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        double? price = double.tryParse(value);
                        if (price == null || price < 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          child: Text('SAVE'),
        ),
      ],
    );
  }
}