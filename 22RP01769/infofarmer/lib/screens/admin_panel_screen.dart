import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:infofarmer/screens/login_screen.dart'; // Added import for LoginScreen
import 'package:infofarmer/screens/tips_screen.dart'; // Import TipsScreen directly

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with TickerProviderStateMixin {
  TabController? _tabController;

  // Price Entry Controllers
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _unitController = TextEditingController();
  final _marketNameController = TextEditingController();
  final _priceMinController = TextEditingController();
  final _priceMaxController = TextEditingController();
  final _priceAvgController = TextEditingController();
  final _sourceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSavingPrice = false;

  // Disease Management
  final _diseaseNameController = TextEditingController();
  final _diseaseSymptomsController = TextEditingController();
  final _organicControlController = TextEditingController();
  final _chemicalControlController = TextEditingController();
  final _affectedCropsController = TextEditingController();
  final _weatherTriggersController = TextEditingController();

  // Tips Management
  final _tipTitleController = TextEditingController();
  final _tipDescriptionController = TextEditingController();
  final _tipCropController = TextEditingController();
  String _selectedTipCategory = 'Planting';
  final List<String> _tipCategories = [
    'Planting',
    'Watering & Irrigation',
    'Fertilization',
    'Harvesting',
    'Storage',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Prices, Tips, Diseases
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _itemNameController.dispose();
    _unitController.dispose();
    _marketNameController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    _priceAvgController.dispose();
    _sourceController.dispose();
    _diseaseNameController.dispose();
    _diseaseSymptomsController.dispose();
    _organicControlController.dispose();
    _chemicalControlController.dispose();
    _affectedCropsController.dispose();
    _weatherTriggersController.dispose();
    _tipTitleController.dispose();
    _tipDescriptionController.dispose();
    _tipCropController.dispose();
    super.dispose();
  }

  Future<void> _savePriceEntry() async {
    setState(() { _isSavingPrice = true; });
    if (_formKey.currentState!.validate()) {
      await Hive.openBox('prices_box');
      final box = Hive.box('prices_box');
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      await box.put(id, {
        'id': id,
        'itemName': _itemNameController.text,
        'unit': _unitController.text,
        'marketName': _marketNameController.text,
        'priceMin': double.parse(_priceMinController.text),
        'priceMax': double.parse(_priceMaxController.text),
        'priceAvg': double.parse(_priceAvgController.text),
        'date': _selectedDate.toIso8601String(),
        'source': _sourceController.text.isNotEmpty ? _sourceController.text : null,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price entry saved!')),
      );
      _formKey.currentState!.reset();
      setState(() {
        _selectedDate = DateTime.now();
      });
    }
    setState(() { _isSavingPrice = false; });
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildPriceManagementTab() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = screenWidth < 400 ? 8.0 : 16.0;
    return Padding(
      padding: EdgeInsets.all(padding),
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add New Price Entry',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _itemNameController,
                            decoration: const InputDecoration(labelText: 'Item Name', hintText: 'e.g. Maize'),
                            validator: (value) => value == null || value.isEmpty ? 'Enter item name' : null,
                          ),
                          TextFormField(
                            controller: _unitController,
                            decoration: const InputDecoration(labelText: 'Unit (e.g. per kg)', hintText: 'e.g. per kg'),
                            validator: (value) => value == null || value.isEmpty ? 'Enter unit' : null,
                          ),
                          TextFormField(
                            controller: _marketNameController,
                            decoration: const InputDecoration(labelText: 'Market Name/Location', hintText: 'e.g. Kigali'),
                            validator: (value) => value == null || value.isEmpty ? 'Enter market name/location' : null,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _priceMinController,
                                  decoration: const InputDecoration(labelText: 'Price Min', hintText: 'e.g. 100'),
                                  keyboardType: TextInputType.number,
                                  validator: (value) => value == null || value.isEmpty ? 'Enter min price' : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _priceMaxController,
                                  decoration: const InputDecoration(labelText: 'Price Max', hintText: 'e.g. 200'),
                                  keyboardType: TextInputType.number,
                                  validator: (value) => value == null || value.isEmpty ? 'Enter max price' : null,
                                ),
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: _priceAvgController,
                            decoration: const InputDecoration(labelText: 'Price Average', hintText: 'e.g. 150'),
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null || value.isEmpty ? 'Enter average price' : null,
                          ),
                          ListTile(
                            title: Text('Date: ${_selectedDate.toLocal()}'.split(' ')[0]),
                            trailing: Tooltip(
                              message: 'Pick date',
                              child: const Icon(Icons.calendar_today, semanticLabel: 'Pick date'),
                            ),
                            onTap: () => _pickDate(context),
                          ),
                          TextFormField(
                            controller: _sourceController,
                            decoration: const InputDecoration(labelText: 'Source (optional)', hintText: 'e.g. MINAGRI'),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: _isSavingPrice
                              ? const CircularProgressIndicator(semanticsLabel: 'Saving price entry...')
                              : ElevatedButton(
                                  onPressed: _savePriceEntry,
                                  child: const Text('Save Price Entry', semanticsLabel: 'Save Price Entry button'),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Price Entries',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<Box>(
                          future: Hive.openBox('prices_box'),
                          builder: (BuildContext context, AsyncSnapshot<Box> snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final box = snapshot.data!;
                            return ValueListenableBuilder(
                              valueListenable: box.listenable(),
                              builder: (BuildContext context, Box box, Widget? child) {
                                final entries = box.values.toList();
                                if (entries.isEmpty) {
                                  return const Center(child: Text('No price entries available.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));
                                }
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: entries.length > 5 ? 5 : entries.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final entry = entries[entries.length - 1 - index];
                                    return ListTile(
                                      leading: const Icon(Icons.shopping_basket, size: 28, semanticLabel: 'Market item'),
                                      title: Text('${entry['itemName']} (${entry['unit']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      subtitle: Text('${entry['marketName']} - Avg: ${entry['priceAvg']}', style: const TextStyle(fontSize: 15)),
                                      trailing: IconButton(
                                        icon: Tooltip(
                                          message: 'Delete entry',
                                          child: const Icon(Icons.delete, semanticLabel: 'Delete entry'),
                                        ),
                                        onPressed: () async {
                                          await Hive.openBox('prices_box');
                                          final box = Hive.box('prices_box');
                                          await box.delete(entry['id']);
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiseaseManagementTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Disease Information',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _diseaseNameController,
                      decoration: const InputDecoration(labelText: 'Disease Name'),
                    ),
                    TextField(
                      controller: _diseaseSymptomsController,
                      decoration: const InputDecoration(labelText: 'Symptoms'),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: _organicControlController,
                      decoration: const InputDecoration(labelText: 'Organic Control Methods'),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: _chemicalControlController,
                      decoration: const InputDecoration(labelText: 'Chemical Control Methods'),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: _affectedCropsController,
                      decoration: const InputDecoration(labelText: 'Affected Crops (comma separated)'),
                    ),
                    TextField(
                      controller: _weatherTriggersController,
                      decoration: const InputDecoration(labelText: 'Weather Triggers (comma separated)'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Validate input
                          if (_diseaseNameController.text.isEmpty ||
                              _diseaseSymptomsController.text.isEmpty ||
                              _organicControlController.text.isEmpty ||
                              _chemicalControlController.text.isEmpty ||
                              _affectedCropsController.text.isEmpty ||
                              _weatherTriggersController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill in all fields.')),
                            );
                            return;
                          }
                          await Hive.openBox('diseases_box');
                          final box = Hive.box('diseases_box');
                          final id = DateTime.now().millisecondsSinceEpoch.toString();
                          await box.put(id, {
                            'id': id,
                            'name': _diseaseNameController.text,
                            'symptoms': _diseaseSymptomsController.text,
                            'organicControl': _organicControlController.text,
                            'chemicalControl': _chemicalControlController.text,
                            'affectedCrops': _affectedCropsController.text.split(',').map((e) => e.trim()).toList(),
                            'weatherTriggers': _weatherTriggersController.text.split(',').map((e) => e.trim()).toList(),
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Disease info saved!')),
                          );
                          _diseaseNameController.clear();
                          _diseaseSymptomsController.clear();
                          _organicControlController.clear();
                          _chemicalControlController.clear();
                          _affectedCropsController.clear();
                          _weatherTriggersController.clear();
                          setState(() {});
                        },
                        child: const Text('Save Disease Info'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Existing Diseases',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<Box>(
                      future: Hive.openBox('diseases_box'),
                      builder: (BuildContext context, AsyncSnapshot<Box> snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final box = snapshot.data!;
                        return ValueListenableBuilder(
                          valueListenable: box.listenable(),
                          builder: (BuildContext context, Box box, Widget? child) {
                            final diseases = box.values.toList();
                            if (diseases.isEmpty) {
                              return const Center(child: Text('No diseases found.'));
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: diseases.length,
                              itemBuilder: (BuildContext context, int index) {
                                final disease = diseases[index];
                                return ListTile(
                                  title: Text(disease['name'] ?? ''),
                                  subtitle: Text(disease['symptoms'] ?? ''),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      await Hive.openBox('diseases_box');
                                      final box = Hive.box('diseases_box');
                                      await box.delete(disease['id']);
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addTipDialog() async {
    _tipTitleController.clear();
    _tipDescriptionController.clear();
    _tipCropController.clear();
    _selectedTipCategory = _tipCategories.first;
    final _formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tip'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tipCropController,
                decoration: const InputDecoration(
                  labelText: 'Crop (type any crop)',
                  hintText: 'e.g. Maize, Beans',
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Crop is required' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedTipCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _tipCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (String? v) => setState(() => _selectedTipCategory = v!),
                validator: (value) => value == null || value.isEmpty ? 'Category is required' : null,
              ),
              TextFormField(
                controller: _tipTitleController,
                decoration: const InputDecoration(
                  labelText: 'Tip Title',
                  hintText: 'Enter a short, descriptive title',
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Title is required' : null,
              ),
              TextFormField(
                controller: _tipDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Tip Description',
                  hintText: 'Provide detailed advice or instructions',
                ),
                maxLines: 3,
                validator: (value) => value == null || value.trim().isEmpty ? 'Description is required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() != true) return;
              await Hive.openBox('tips_box');
              final box = Hive.box('tips_box');
              final id = DateTime.now().millisecondsSinceEpoch.toString();
              await box.put(id, {
                'id': id,
                'crop': _tipCropController.text,
                'category': _selectedTipCategory,
                'title': _tipTitleController.text,
                'description': _tipDescriptionController.text,
                'status': 'pending', // New field for status
                'submittedBy': 'user', // New field for who submitted
                'timestamp': DateTime.now().toIso8601String(), // New field for timestamp
              });
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsManagementTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pending Tips Approval Section
                Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FutureBuilder<Box>(
                      future: Hive.openBox('tips_box'),
                      builder: (BuildContext context, AsyncSnapshot<Box> snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final box = snapshot.data!;
                        final pendingTips = box.values.where((tip) => tip['status'] == 'pending').toList();
                        if (pendingTips.isEmpty) {
                          return const Text('No pending tips for approval.', style: TextStyle(fontWeight: FontWeight.bold));
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pending User Tips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 300, // or any reasonable height
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: pendingTips.length,
                                itemBuilder: (BuildContext context, int idx) {
                                  final tip = pendingTips[idx];
                                  return Card(
                                    color: Colors.white,
                                    child: ListTile(
                                      title: Text(tip['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(tip['description'] ?? ''),
                                          const SizedBox(height: 4),
                                          Text('Crop: ${tip['crop']} - ${tip['category']}', style: const TextStyle(fontSize: 12)),
                                          Text('Submitted by: ${tip['submittedBy'] ?? tip['author']}', style: const TextStyle(fontSize: 12)),
                                          Text('Date: ${tip['timestamp']?.toString().split('T').first ?? ''}', style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.check, color: Colors.green),
                                            tooltip: 'Approve',
                                            onPressed: () async {
                                              await box.put(tip['id'], {
                                                ...tip,
                                                'status': 'approved',
                                                'approvedBy': 'admin',
                                                'approvedAt': DateTime.now().toIso8601String(),
                                              });
                                              setState(() {});
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tip approved!'), backgroundColor: Colors.green));
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, color: Colors.red),
                                            tooltip: 'Reject',
                                            onPressed: () async {
                                              await box.delete(tip['id']);
                                              setState(() {});
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tip rejected and removed.'), backgroundColor: Colors.red));
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tipCropController,
                            decoration: const InputDecoration(labelText: 'Crop (type any crop)'),
                            onChanged: (String _) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedTipCategory,
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: _tipCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                            onChanged: (String? v) => setState(() => _selectedTipCategory = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          fit: FlexFit.tight,
                          child: ElevatedButton.icon(
                            onPressed: _addTipDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Tip'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(0, 48),
                              padding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FutureBuilder<Box>(
                      future: Hive.openBox('tips_box'),
                      builder: (BuildContext context, AsyncSnapshot<Box> snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final box = snapshot.data!;
                        final tips = box.values.toList();
                        final filteredTips = tips.where((tip) =>
                          tip['crop'].toString().toLowerCase() == _tipCropController.text.toLowerCase() &&
                          tip['category'] == _selectedTipCategory
                        ).toList();
                        if (filteredTips.isEmpty) {
                          return const Center(child: Text('No tips for this crop and category.'));
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredTips.length,
                          itemBuilder: (BuildContext context, int idx) {
                            final tip = filteredTips[idx];
                            return Card(
                              child: ListTile(
                                title: Text(tip['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(tip['description'] ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    await Hive.openBox('tips_box');
                                    final box = Hive.box('tips_box');
                                    await box.delete(tip['id']);
                                    setState(() {});
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Back to App',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController!,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.attach_money), text: 'Prices'),
            Tab(icon: Icon(Icons.tips_and_updates), text: 'Tips'),
            Tab(icon: Icon(Icons.sick), text: 'Diseases'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Analytics section
          FutureBuilder(
            future: _getAnalyticsData(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              );
              final data = snapshot.data as Map<String, dynamic>;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 24,
                          runSpacing: 12,
                          children: [
                            _analyticsTile('Users', data['users'].toString(), Icons.people),
                            _analyticsTile('Tips (Approved)', data['tipsApproved'].toString(), Icons.check_circle),
                            _analyticsTile('Tips (Pending)', data['tipsPending'].toString(), Icons.hourglass_empty),
                            _analyticsTile('Price Entries', data['prices'].toString(), Icons.attach_money),
                            _analyticsTile('Diseases', data['diseases'].toString(), Icons.sick),
                            _analyticsTile('Popular Crop', data['popularCrop'] ?? '-', Icons.local_florist),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // User subscription status summary
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text('User Subscriptions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Wrap(
                      spacing: 16,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.star, color: Colors.amber),
                          label: Text('Premium Users: ${data['premiumCount']}'),
                          backgroundColor: Colors.white,
                        ),
                        Chip(
                          avatar: const Icon(Icons.person, color: Colors.grey),
                          label: Text('Free Users: ${data['freeCount']}'),
                          backgroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          // Expanded TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController!,
              children: [
                _buildPriceManagementTab(),
                _buildTipsManagementTab(),
                _buildDiseaseManagementTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for analytics tiles
  Widget _analyticsTile(String label, String value, IconData icon) {
    return Chip(
      avatar: Icon(icon, color: Colors.blue[700]),
      label: Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  // Gather analytics data from Hive
  Future<Map<String, dynamic>> _getAnalyticsData() async {
    final usersBox = await Hive.openBox('users');
    final tipsBox = await Hive.openBox('tips_box');
    final pricesBox = await Hive.openBox('prices_box');
    final diseasesBox = await Hive.openBox('diseases_box');
    final settingsBox = await Hive.openBox('settings');
    final users = usersBox.length;
    final tips = tipsBox.values.toList();
    final tipsApproved = tips.where((t) => t['status'] == 'approved').length;
    final tipsPending = tips.where((t) => t['status'] == 'pending').length;
    final prices = pricesBox.length;
    final diseases = diseasesBox.length;
    // Most popular crop by number of tips
    final cropCounts = <String, int>{};
    for (final t in tips) {
      final crop = t['crop'] ?? 'Unknown';
      cropCounts[crop] = (cropCounts[crop] ?? 0) + 1;
    }
    String? popularCrop;
    if (cropCounts.isNotEmpty) {
      popularCrop = cropCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }
    // User list with subscription status
    int premiumCount = 0;
    int freeCount = 0;
    for (final u in usersBox.values) {
      final username = u['username'] ?? u['email'] ?? u.toString();
      final isPremium = settingsBox.get('isPremium_${username}', defaultValue: false);
      if (isPremium) {
        premiumCount++;
      } else {
        freeCount++;
      }
    }
    return {
      'users': users,
      'tipsApproved': tipsApproved,
      'tipsPending': tipsPending,
      'prices': prices,
      'diseases': diseases,
      'popularCrop': popularCrop,
      'premiumCount': premiumCount,
      'freeCount': freeCount,
    };
  }
} 