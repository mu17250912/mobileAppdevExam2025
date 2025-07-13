import 'package:flutter/material.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  // Mock data
  List<Map<String, dynamic>> cars = [
    {'brand': 'Toyota', 'model': 'Corolla', 'price': 50000},
    {'brand': 'Honda', 'model': 'Civic', 'price': 60000},
  ];
  List<Map<String, dynamic>> bookings = [
    {'car': 'Toyota Corolla', 'user': 'Emmanuel NIYONKURU', 'status': 'Pending'},
    {'car': 'Honda Civic', 'user': 'Emmy Niyonkuru', 'status': 'Approved'},
  ];
  List<Map<String, dynamic>> users = [
    {'name': 'Emmanuel NIYONKURU', 'email': 'niyoemm25@gmail.com'},
    {'name': 'Emmy Niyonkuru', 'email': 'emmy@gmail.com'},
  ];
  bool showCars = false;
  bool showBookings = false;
  bool showUsers = false;
  bool showAnalytics = false;

  void _addCar() async {
    String brand = '';
    String model = '';
    String price = '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Car'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Brand'),
              onChanged: (v) => brand = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Model'),
              onChanged: (v) => model = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              onChanged: (v) => price = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (brand.isNotEmpty && model.isNotEmpty && price.isNotEmpty) {
                setState(() {
                  cars.add({'brand': brand, 'model': model, 'price': int.tryParse(price) ?? 0});
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editCar(int index) async {
    String brand = cars[index]['brand'];
    String model = cars[index]['model'];
    String price = cars[index]['price'].toString();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Car'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Brand'),
              controller: TextEditingController(text: brand),
              onChanged: (v) => brand = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Model'),
              controller: TextEditingController(text: model),
              onChanged: (v) => model = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: price),
              onChanged: (v) => price = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (brand.isNotEmpty && model.isNotEmpty && price.isNotEmpty) {
                setState(() {
                  cars[index] = {'brand': brand, 'model': model, 'price': int.tryParse(price) ?? 0};
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteCar(int index) {
    setState(() {
      cars.removeAt(index);
    });
  }

  void _approveBooking(int index) {
    setState(() {
      bookings[index]['status'] = 'Approved';
    });
  }

  void _rejectBooking(int index) {
    setState(() {
      bookings[index]['status'] = 'Rejected';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        children: [
          ExpansionTile(
            title: const Text('View/Add/Edit/Delete Cars'),
            initiallyExpanded: showCars,
            onExpansionChanged: (v) => setState(() => showCars = v),
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cars.length,
                itemBuilder: (context, index) {
                  final car = cars[index];
                  return ListTile(
                    title: Text('${car['brand']} ${car['model']}'),
                    subtitle: Text('Price: ${car['price']} RWF/day'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editCar(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteCar(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: _addCar,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Car'),
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('Approve/Reject Bookings'),
            initiallyExpanded: showBookings,
            onExpansionChanged: (v) => setState(() => showBookings = v),
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return ListTile(
                    title: Text('${booking['car']} - ${booking['user']}'),
                    subtitle: Text('Status: ${booking['status']}'),
                    trailing: booking['status'] == 'Pending'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _approveBooking(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _rejectBooking(index),
                              ),
                            ],
                          )
                        : null,
                  );
                },
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('View Users'),
            initiallyExpanded: showUsers,
            onExpansionChanged: (v) => setState(() => showUsers = v),
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    title: Text(user['name']),
                    subtitle: Text(user['email']),
                  );
                },
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('View Analytics'),
            initiallyExpanded: showAnalytics,
            onExpansionChanged: (v) => setState(() => showAnalytics = v),
            children: const [
              ListTile(
                title: Text('Total Cars: 2'),
              ),
              ListTile(
                title: Text('Total Bookings: 2'),
              ),
              ListTile(
                title: Text('Total Users: 2'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 