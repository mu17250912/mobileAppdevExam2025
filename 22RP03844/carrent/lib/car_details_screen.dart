import 'package:flutter/material.dart';
import 'booking_screen.dart';
import 'car_store.dart';

class CarDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> car;
  const CarDetailsScreen({Key? key, required this.car}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final carId = car['id'] as String?;
    final carObj = carId != null ? CarStore.getCarById(carId) : null;
    final isAvailable = car['available'] ?? true;
    
    return Scaffold(
      appBar: AppBar(title: Text('${car['brand']} ${car['model']}')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (car['image'] != null && car['image'].toString().isNotEmpty)
              Image.network(
                car['image'],
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey.withOpacity(0.2),
                  child: const Icon(Icons.directions_car, size: 80, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${car['brand']} ${car['model']}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Price: ${car['price']} RWF/day',
                    style: const TextStyle(fontSize: 18, color: Color(0xFF667eea), fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isAvailable ? Icons.check_circle : Icons.cancel,
                        color: isAvailable ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAvailable ? 'Available' : 'Not Available',
                        style: TextStyle(
                          color: isAvailable ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A reliable ${car['brand']} ${car['model']} perfect for city and upcountry travel. This vehicle offers comfort, safety, and excellent fuel efficiency for your journey.',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isAvailable
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingScreen(car: car),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isAvailable ? 'Book Now' : 'Not Available',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 