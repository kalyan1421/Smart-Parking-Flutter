// lib/screens/parking/parking_spot_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_parking_app/config/app_config.dart';
import 'package:smart_parking_app/models/parking_spot.dart' hide TimeOfDay;
import 'package:smart_parking_app/providers/parking_provider.dart';
import 'package:smart_parking_app/screens/parking/booking_confirmation_screen.dart';
import 'package:smart_parking_app/widgets/common/loading_indicator.dart';

class ParkingSpotBottomSheet extends StatefulWidget {
  @override
  _ParkingSpotBottomSheetState createState() => _ParkingSpotBottomSheetState();
}

class _ParkingSpotBottomSheetState extends State<ParkingSpotBottomSheet> {
  DateTime _startTime = DateTime.now().add(Duration(minutes: 15));
  DateTime _endTime = DateTime.now().add(Duration(hours: 1, minutes: 15));
  bool _isBooking = false;

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStartTime ? _startTime : _endTime),
    );
    
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        final selectedDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        
        if (isStartTime) {
          _startTime = selectedDateTime;
          // Make sure end time is at least 30 minutes after start time
          if (_endTime.difference(_startTime).inMinutes < 30) {
            _endTime = _startTime.add(Duration(minutes: 30));
          }
        } else {
          _endTime = selectedDateTime;
          // Make sure end time is after start time
          if (_endTime.isBefore(_startTime)) {
            _endTime = _startTime.add(Duration(minutes: 30));
          }
        }
      });
    }
  }

  double _calculateTotalPrice() {
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
    final spot = parkingProvider.selectedParkingSpot;
    
    if (spot == null) return 0;
    
    // Calculate hours (partial hours count as full hours)
    final durationMinutes = _endTime.difference(_startTime).inMinutes;
    final durationHours = (durationMinutes / 60).ceil();
    
    return spot.pricePerHour * durationHours;
  }

  Future<void> _bookParkingSpot() async {
    setState(() {
      _isBooking = true;
    });
    
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
    final spot = parkingProvider.selectedParkingSpot;
    
    if (spot == null) {
      setState(() {
        _isBooking = false;
      });
      return;
    }
    
    // Book the spot
    final success = await parkingProvider.bookParkingSpot(
      spot,
      _startTime,
      _endTime,
    );
    
    setState(() {
      _isBooking = false;
    });
    
    if (success) {
      // Close bottom sheet
      Navigator.of(context).pop();
      
      // Navigate to confirmation screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BookingConfirmationScreen(
            parkingSpot: spot,
            startTime: _startTime,
            endTime: _endTime,
            totalPrice: _calculateTotalPrice(),
            bookingId: 'booking_${DateTime.now().millisecondsSinceEpoch}', // Placeholder ID
          ),
        ),
      );
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book parking spot'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final parkingProvider = Provider.of<ParkingProvider>(context);
    final spot = parkingProvider.selectedParkingSpot;
    
    if (spot == null) {
      return Container(
        height: 200,
        child: Center(
          child: Text('No parking spot selected'),
        ),
      );
    }
    
    final totalPrice = _calculateTotalPrice();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: !spot.isVerified 
                      ? Colors.orange.shade100 
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  !spot.isVerified ? 'UNVERIFIED' : 'VERIFIED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: !spot.isVerified 
                        ? Colors.orange.shade800 
                        : Colors.green.shade800,
                  ),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: spot.availableSpots > 0 
                      ? Colors.green.shade100 
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  spot.availableSpots > 0 
                      ? '${spot.availableSpots} AVAILABLE' 
                      : 'FULL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: spot.availableSpots > 0 
                        ? Colors.green.shade800 
                        : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            spot.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 4),
          Text(
            spot.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.attach_money, size: 16),
              SizedBox(width: 4),
              Text(
                '${AppConfig.currencySymbol}${spot.pricePerHour.toStringAsFixed(2)}/hr',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (spot.amenities.isNotEmpty) ...[
                SizedBox(width: 16),
                ...spot.amenities.take(2).map((amenity) => 
                  Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      amenity,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                if (spot.amenities.length > 2) 
                  Text('+${spot.amenities.length - 2} more'),
              ],
            ],
          ),
          SizedBox(height: 24),
          Text(
            'Select Parking Duration',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectTime(context, true),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'START TIME',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectTime(context, false),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'END TIME',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Price:'),
                Text(
                  '${AppConfig.currencySymbol}${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: spot.availableSpots > 0 && !_isBooking
                  ? _bookParkingSpot
                  : null,
              child: _isBooking
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: LoadingIndicator(size: 24),
                    )
                  : Text('BOOK NOW'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}