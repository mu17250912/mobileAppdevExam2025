import 'package:flutter/material.dart';

class DailyWaterLogForm extends StatefulWidget {
  final String? initialLocation;
  final void Function(Map<String, dynamic> data)? onSubmit;
  const DailyWaterLogForm({Key? key, this.initialLocation, this.onSubmit}) : super(key: key);

  @override
  State<DailyWaterLogForm> createState() => _DailyWaterLogFormState();
}

class _DailyWaterLogFormState extends State<DailyWaterLogForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();

  // Showers
  double? _showerDuration;
  double? _showerLiters;
  String _showerType = 'Standard';

  // Toilet
  int? _toiletFlushes;
  String _toiletType = 'Standard';

  // Dishes
  String _dishesMethod = 'By hand';
  int? _dishesCount;
  double? _dishesDuration;
  bool _dishesBasin = false;

  // Laundry
  int? _laundryLoads;
  String _laundryType = 'Standard';

  // Drinking water
  int? _drinkingGlasses;
  double? _drinkingLiters;

  // Car washing
  String _carWashMethod = 'Hose';
  double? _carWashDuration;
  int? _carWashBuckets;

  // Gardening
  double? _gardenDuration;
  String _gardenMethod = 'Hose';

  // Optional
  double? _meterReading;
  String? _location;

  @override
  void initState() {
    super.initState();
    _location = widget.initialLocation;
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();
    // Estimate total usage (very basic for now)
    double totalLiters = 0;
    if (_showerLiters != null) {
      totalLiters += _showerLiters!;
    } else if (_showerDuration != null) {
      // Assume 9 liters/minute for standard, 6 for low-flow
      totalLiters += _showerDuration! * (_showerType == 'Low-flow' ? 6 : 9);
    }
    if (_toiletFlushes != null) {
      // Assume 9 liters/flush standard, 4 dual, 6 low-flow
      double perFlush = _toiletType == 'Dual flush' ? 4 : (_toiletType == 'Low-flow' ? 6 : 9);
      totalLiters += _toiletFlushes! * perFlush;
    }
    if (_dishesMethod == 'By hand') {
      if (_dishesDuration != null) {
        // Assume 6 liters/minute tap, 3 liters/minute basin
        double perMin = _dishesBasin ? 3 : 6;
        totalLiters += _dishesDuration! * perMin;
      }
    } else if (_dishesMethod == 'Using dishwasher' && _dishesCount != null) {
      // Assume 15 liters per dishwasher run
      totalLiters += _dishesCount! * 15;
    }
    if (_laundryLoads != null) {
      // Assume 90 liters/load standard, 50 high-efficiency
      totalLiters += _laundryLoads! * (_laundryType == 'High-efficiency' ? 50 : 90);
    }
    if (_drinkingLiters != null) {
      totalLiters += _drinkingLiters!;
    } else if (_drinkingGlasses != null) {
      totalLiters += _drinkingGlasses! * 0.25;
    }
    if (_carWashMethod == 'Hose' && _carWashDuration != null) {
      // Assume 10 liters/minute
      totalLiters += _carWashDuration! * 10;
    } else if (_carWashMethod == 'Bucket' && _carWashBuckets != null) {
      // Assume 10 liters/bucket
      totalLiters += _carWashBuckets! * 10;
    }
    if (_gardenDuration != null) {
      // Hose: 15 l/min, Drip: 4 l/min, Sprinkler: 18 l/min
      double perMin = 15;
      if (_gardenMethod == 'Drip irrigation') perMin = 4;
      if (_gardenMethod == 'Sprinkler') perMin = 18;
      totalLiters += _gardenDuration! * perMin;
    }
    // Generate a simple tip
    String tip = totalLiters > 300
        ? 'Your usage is high today. Consider ways to reduce water use!'
        : 'Good job! Your water usage is within a reasonable range.';
    final data = {
      'date': _selectedDate,
      'showerDuration': _showerDuration,
      'showerLiters': _showerLiters,
      'showerType': _showerType,
      'toiletFlushes': _toiletFlushes,
      'toiletType': _toiletType,
      'dishesMethod': _dishesMethod,
      'dishesCount': _dishesCount,
      'dishesDuration': _dishesDuration,
      'dishesBasin': _dishesBasin,
      'laundryLoads': _laundryLoads,
      'laundryType': _laundryType,
      'drinkingGlasses': _drinkingGlasses,
      'drinkingLiters': _drinkingLiters,
      'carWashMethod': _carWashMethod,
      'carWashDuration': _carWashDuration,
      'carWashBuckets': _carWashBuckets,
      'gardenDuration': _gardenDuration,
      'gardenMethod': _gardenMethod,
      'meterReading': _meterReading,
      'location': _location,
      'totalLiters': totalLiters,
      'tip': tip,
    };
    if (widget.onSubmit != null) widget.onSubmit!(data);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personalized Tip'),
        content: Text('Estimated total: ${totalLiters.toStringAsFixed(1)} liters\n\n$tip'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _pickDate,
                  child: Text('${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
                ),
              ],
            ),
            const Divider(),
            const Text('1. Showers', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Duration (min)'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _showerDuration = double.tryParse(v ?? ''),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Liters (if known)'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _showerLiters = double.tryParse(v ?? ''),
                  ),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              value: _showerType,
              items: const [
                DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                DropdownMenuItem(value: 'Low-flow', child: Text('Low-flow')),
              ],
              onChanged: (v) => setState(() => _showerType = v!),
              decoration: const InputDecoration(labelText: 'Showerhead Type'),
            ),
            const Divider(),
            const Text('2. Toilet Flushes', style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Number of flushes'),
              keyboardType: TextInputType.number,
              onSaved: (v) => _toiletFlushes = int.tryParse(v ?? ''),
            ),
            DropdownButtonFormField<String>(
              value: _toiletType,
              items: const [
                DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                DropdownMenuItem(value: 'Dual flush', child: Text('Dual flush')),
                DropdownMenuItem(value: 'Low-flow', child: Text('Low-flow')),
              ],
              onChanged: (v) => setState(() => _toiletType = v!),
              decoration: const InputDecoration(labelText: 'Toilet Type'),
            ),
            const Divider(),
            const Text('3. Washing Dishes', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: _dishesMethod,
              items: const [
                DropdownMenuItem(value: 'By hand', child: Text('By hand')),
                DropdownMenuItem(value: 'Using dishwasher', child: Text('Using dishwasher')),
              ],
              onChanged: (v) => setState(() => _dishesMethod = v!),
              decoration: const InputDecoration(labelText: 'Method'),
            ),
            if (_dishesMethod == 'By hand') ...[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Duration (min)'),
                keyboardType: TextInputType.number,
                onSaved: (v) => _dishesDuration = double.tryParse(v ?? ''),
              ),
              CheckboxListTile(
                value: _dishesBasin,
                onChanged: (v) => setState(() => _dishesBasin = v ?? false),
                title: const Text('Used basin (otherwise tap running)'),
              ),
            ] else ...[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Number of runs'),
                keyboardType: TextInputType.number,
                onSaved: (v) => _dishesCount = int.tryParse(v ?? ''),
              ),
            ],
            const Divider(),
            const Text('4. Laundry', style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Number of loads'),
              keyboardType: TextInputType.number,
              onSaved: (v) => _laundryLoads = int.tryParse(v ?? ''),
            ),
            DropdownButtonFormField<String>(
              value: _laundryType,
              items: const [
                DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                DropdownMenuItem(value: 'High-efficiency', child: Text('High-efficiency')),
              ],
              onChanged: (v) => setState(() => _laundryType = v!),
              decoration: const InputDecoration(labelText: 'Machine Type'),
            ),
            const Divider(),
            const Text('5. Drinking Water', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Glasses'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _drinkingGlasses = int.tryParse(v ?? ''),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Liters'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _drinkingLiters = double.tryParse(v ?? ''),
                  ),
                ),
              ],
            ),
            const Divider(),
            const Text('6. Car Washing', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: _carWashMethod,
              items: const [
                DropdownMenuItem(value: 'Hose', child: Text('Hose')),
                DropdownMenuItem(value: 'Bucket', child: Text('Bucket')),
              ],
              onChanged: (v) => setState(() => _carWashMethod = v!),
              decoration: const InputDecoration(labelText: 'Method'),
            ),
            if (_carWashMethod == 'Hose')
              TextFormField(
                decoration: const InputDecoration(labelText: 'Duration (min)'),
                keyboardType: TextInputType.number,
                onSaved: (v) => _carWashDuration = double.tryParse(v ?? ''),
              ),
            if (_carWashMethod == 'Bucket')
              TextFormField(
                decoration: const InputDecoration(labelText: 'Number of buckets'),
                keyboardType: TextInputType.number,
                onSaved: (v) => _carWashBuckets = int.tryParse(v ?? ''),
              ),
            const Divider(),
            const Text('7. Gardening/Outdoor Watering', style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Duration (min)'),
              keyboardType: TextInputType.number,
              onSaved: (v) => _gardenDuration = double.tryParse(v ?? ''),
            ),
            DropdownButtonFormField<String>(
              value: _gardenMethod,
              items: const [
                DropdownMenuItem(value: 'Hose', child: Text('Hose')),
                DropdownMenuItem(value: 'Drip irrigation', child: Text('Drip irrigation')),
                DropdownMenuItem(value: 'Sprinkler', child: Text('Sprinkler')),
              ],
              onChanged: (v) => setState(() => _gardenMethod = v!),
              decoration: const InputDecoration(labelText: 'Method'),
            ),
            const Divider(),
            const Text('Optional Inputs', style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Water Meter Reading'),
              keyboardType: TextInputType.number,
              onSaved: (v) => _meterReading = double.tryParse(v ?? ''),
            ),
            TextFormField(
              initialValue: _location,
              decoration: const InputDecoration(labelText: 'Location/Region (optional)'),
              onSaved: (v) => _location = v,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 