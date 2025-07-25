import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:hive/hive.dart';
import 'package:infofarmer/screens/login_screen.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart' as material;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/subscription_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// DiseaseScreen shows crop‑specific diseases, allows admins to add / delete.
/// 
/// Pass the **signed‑in username / email** to toggle admin‑only widgets.
class DiseaseScreen extends StatefulWidget {
  const DiseaseScreen({super.key, required this.username});
  final String username;

  @override
  State<DiseaseScreen> createState() => _DiseaseScreenState();
}

class _DiseaseScreenState extends State<DiseaseScreen> {
  // ───────────────────────────────── Crop filter
  final _crops = <String>[
    'Tomato',
    'Beans',
    'Maize',
    'Potato',
    'Cabbage',
    'Carrot',
    'Onion',
    'Other',
  ];
  String _selectedCrop = 'Tomato';
  String _searchQuery = '';
  String _severity = 'Medium';
  final List<String> _severityLevels = ['Low', 'Medium', 'High'];

  // ───────────────────────────────── Text‑editing controllers
  final _diseaseNameCtl       = TextEditingController();
  final _symptomsCtl          = TextEditingController();
  final _organicCtl           = TextEditingController();
  final _chemicalCtl          = TextEditingController();
  final _affectedCropsCtl     = TextEditingController();
  final _weatherTriggersCtl   = TextEditingController();
  final _preventionTipsCtl = TextEditingController();
  final _resourcesCtl = TextEditingController();
  final _reportNameCtl = TextEditingController();
  final _reportSymptomsCtl = TextEditingController();
  String? _reportPhotoPath;

  // Convenience getter — are we admin?
  bool get _isAdmin => widget.username.toLowerCase() == 'admin@infofarmer.com';
  bool _isPremium = false;

  final InAppPurchase _iap = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  final String _kPremiumId = 'premium_subscription'; // TODO: Replace with your real product ID

  Future<void> _initIAP() async {
    final bool available = await _iap.isAvailable();
    if (!available) return;
    final ProductDetailsResponse response = await _iap.queryProductDetails({_kPremiumId});
    if (response.notFoundIDs.isEmpty) {
      setState(() {
        _products = response.productDetails;
      });
    }
  }

  Future<void> _loadPremium() async {
    _isPremium = await SubscriptionService.isPremium(widget.username);
    if (mounted) setState(() {});
  }

  Future<void> _setPremium(bool value) async {
    if (value) {
      await SubscriptionService.activatePremium(widget.username, 'manual_premium');
    } else {
      await SubscriptionService.removePremium(widget.username);
    }
  }

  @override
  void dispose() {
    for (final ctl in [
      _diseaseNameCtl,
      _symptomsCtl,
      _organicCtl,
      _chemicalCtl,
      _affectedCropsCtl,
      _weatherTriggersCtl,
      _preventionTipsCtl,
      _resourcesCtl,
      _reportNameCtl,
      _reportSymptomsCtl,
    ]) ctl.dispose();
    super.dispose();
  }

  // ───────────────────────────────── Helpers
  Future<void> _saveDisease() async {
    final emptyFields = [
      _diseaseNameCtl,
      _symptomsCtl,
      _organicCtl,
      _chemicalCtl,
      _affectedCropsCtl,
      _weatherTriggersCtl,
      _preventionTipsCtl,
      _resourcesCtl,
    ].any((c) => c.text.trim().isEmpty);

    if (emptyFields) {
      _showSnack('Please fill in all fields.');
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    var box = await Hive.openBox('diseases_box');
    await box.put(id, {
      'id': id,
      'name': _diseaseNameCtl.text.trim(),
      'symptoms': _symptomsCtl.text.trim(),
      'organicControl': _organicCtl.text.trim(),
      'chemicalControl': _chemicalCtl.text.trim(),
      'affectedCrops': _affectedCropsCtl.text.split(',').map((e) => e.trim()).toList(),
      'weatherTriggers': _weatherTriggersCtl.text.split(',').map((e) => e.trim()).toList(),
      'severity': _severity,
      'preventionTips': _preventionTipsCtl.text.trim(),
      'resources': _resourcesCtl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'lastUpdated': DateTime.now().toIso8601String(),
    });

    _showSnack('Disease info saved!');
    _clearForm();
    setState(() {});
  }

  Future<void> _saveDiseaseReport() async {
    var box = await Hive.openBox('disease_reports');
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, {
      'id': id,
      'name': _reportNameCtl.text.trim(),
      'symptoms': _reportSymptomsCtl.text.trim(),
      'photo': _reportPhotoPath,
      'timestamp': DateTime.now().toIso8601String(),
    });
    _reportNameCtl.clear();
    _reportSymptomsCtl.clear();
    _reportPhotoPath = null;
  }

  void _clearForm() {
    for (final ctl in [
      _diseaseNameCtl,
      _symptomsCtl,
      _organicCtl,
      _chemicalCtl,
      _affectedCropsCtl,
      _weatherTriggersCtl,
      _preventionTipsCtl,
      _resourcesCtl,
    ]) ctl.clear();
    _severity = 'Medium';
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<List<String>> _getNotes(String diseaseId) async {
    var notesBox = await Hive.openBox('disease_notes');
    return List<String>.from(notesBox.get(diseaseId, defaultValue: []));
  }

  Future<void> _addNote(String diseaseId, String note) async {
    var notesBox = await Hive.openBox('disease_notes');
    final notes = List<String>.from(notesBox.get(diseaseId, defaultValue: []));
    notes.add(note);
    await notesBox.put(diseaseId, notes);
    setState(() {});
  }

  void _showDiseaseDetails(Map disease) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(disease['name'] ?? ''),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (disease['symptoms'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Symptoms:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                if (disease['symptoms'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(disease['symptoms']),
                  ),
                if (disease['organicControl'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Organic Control:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                if (disease['organicControl'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(disease['organicControl']),
                  ),
                if (disease['chemicalControl'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Chemical Control:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                if (disease['chemicalControl'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(disease['chemicalControl']),
                  ),
                if (disease['affectedCrops'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Affected Crops:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                if (disease['affectedCrops'] != null)
                  Wrap(
                    spacing: 6,
                    children: List<Widget>.from((disease['affectedCrops'] as List).map((c) => Chip(label: Text(c)))),
                  ),
                if (disease['weatherTriggers'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text('Weather Triggers:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                if (disease['weatherTriggers'] != null)
                  Wrap(
                    spacing: 6,
                    children: List<Widget>.from((disease['weatherTriggers'] as List).map((w) => Chip(label: Text(w)))),
                  ),
                if (disease['severity'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text('Severity:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                if (disease['severity'] != null)
                  Chip(label: Text(disease['severity'])),
                if (disease['preventionTips'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text('Prevention Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                if (disease['preventionTips'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(disease['preventionTips']),
                  ),
                if (disease['resources'] != null && disease['resources']!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text('Resources:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                if (disease['resources'] != null && disease['resources']!.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: List<Widget>.from((disease['resources'] as List).map((r) => Chip(label: Text(r)))),
                  ),
                if (disease['lastUpdated'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text('Last Updated:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                if (disease['lastUpdated'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(DateTime.parse(disease['lastUpdated']!).toLocal().toString()),
                  ),
                const SizedBox(height: 16),
                Text('User Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                FutureBuilder<List<String>>(
                  future: _getNotes(disease['id']),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final notes = snapshot.data!;
                    if (notes.isEmpty) return const Text('No notes yet.');
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: notes.map((n) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('- $n'),
                      )).toList(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Add a note',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 3,
                  onSubmitted: (value) async {
                    if (value.trim().isNotEmpty) {
                      await _addNote(disease['id'], value.trim());
                      setStateDialog(() {});
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDiseaseDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Report New Disease'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _reportNameCtl,
                  decoration: const InputDecoration(labelText: 'Disease name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reportSymptomsCtl,
                  decoration: const InputDecoration(labelText: 'Symptoms'),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Add Photo'),
                      onPressed: () {
                        // Simulate photo upload by setting a dummy path
                        setStateDialog(() => _reportPhotoPath = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
                      },
                    ),
                    if (_reportPhotoPath != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text('Photo attached', style: TextStyle(color: Colors.green)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveDiseaseReport();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disease report submitted!')));
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _populateSampleDiseases() async {
    var box = await Hive.openBox('diseases_box');
    if (box.isEmpty) {
      final now = DateTime.now().toIso8601String();
      final List<Map<String, dynamic>> samples = [
        {
          'id': '1',
          'name': 'Late Blight',
          'symptoms': 'Dark spots on leaves and stems, white mold under leaves.',
          'description': 'A serious disease of tomato and potato caused by Phytophthora infestans.',
          'organicControl': 'Remove infected plants, use copper-based sprays.',
          'chemicalControl': 'Apply fungicides containing mancozeb or chlorothalonil.',
          'affectedCrops': ['Tomato', 'Potato'],
          'weatherTriggers': ['High humidity', 'Cool temperatures'],
          'severity': 'High',
          'preventionTips': 'Rotate crops, avoid overhead watering, use resistant varieties.',
          'resources': ['https://en.wikipedia.org/wiki/Phytophthora_infestans'],
          'lastUpdated': now,
        },
        {
          'id': '2',
          'name': 'Powdery Mildew',
          'symptoms': 'White powdery spots on leaves and stems.',
          'description': 'A fungal disease affecting many crops, especially cucurbits.',
          'organicControl': 'Spray with neem oil or potassium bicarbonate.',
          'chemicalControl': 'Use sulfur-based fungicides.',
          'affectedCrops': ['Cucumber', 'Squash', 'Pumpkin', 'Tomato'],
          'weatherTriggers': ['Dry, warm days', 'Cool nights'],
          'severity': 'Medium',
          'preventionTips': 'Ensure good air circulation, avoid overhead irrigation.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/powdery-mildew-homemade-and-organic-remedies.htm'],
          'lastUpdated': now,
        },
        {
          'id': '3',
          'name': 'Bacterial Wilt',
          'symptoms': 'Sudden wilting of leaves, brown discoloration in stems.',
          'description': 'A bacterial disease that blocks water transport in plants.',
          'organicControl': 'Remove and destroy infected plants.',
          'chemicalControl': 'No effective chemical control.',
          'affectedCrops': ['Tomato', 'Potato', 'Eggplant'],
          'weatherTriggers': ['Warm, wet conditions'],
          'severity': 'High',
          'preventionTips': 'Use resistant varieties, rotate crops.',
          'resources': ['https://www.apsnet.org/edcenter/disandpath/bacterial/pdlessons/Pages/BacterialWilt.aspx'],
          'lastUpdated': now,
        },
        {
          'id': '4',
          'name': 'Early Blight',
          'symptoms': 'Brown concentric spots on lower leaves.',
          'description': 'A common fungal disease of tomato and potato caused by Alternaria solani.',
          'organicControl': 'Remove infected leaves, use compost tea sprays.',
          'chemicalControl': 'Apply fungicides with chlorothalonil.',
          'affectedCrops': ['Tomato', 'Potato'],
          'weatherTriggers': ['Warm, humid weather'],
          'severity': 'Medium',
          'preventionTips': 'Mulch soil, avoid wetting foliage.',
          'resources': ['https://extension.umn.edu/diseases/early-blight-tomato'],
          'lastUpdated': now,
        },
        {
          'id': '5',
          'name': 'Downy Mildew',
          'symptoms': 'Yellow patches on upper leaf surface, gray mold underneath.',
          'description': 'A fungal-like disease affecting cucurbits and other crops.',
          'organicControl': 'Remove infected leaves, improve air flow.',
          'chemicalControl': 'Use copper-based fungicides.',
          'affectedCrops': ['Cucumber', 'Melon', 'Pumpkin'],
          'weatherTriggers': ['Cool, moist conditions'],
          'severity': 'Medium',
          'preventionTips': 'Plant resistant varieties, avoid overhead watering.',
          'resources': ['https://www.rhs.org.uk/disease/downy-mildew'],
          'lastUpdated': now,
        },
        {
          'id': '6',
          'name': 'Anthracnose',
          'symptoms': 'Sunken dark lesions on fruit, stems, and leaves.',
          'description': 'A group of fungal diseases affecting many fruits and vegetables.',
          'organicControl': 'Remove infected fruit, use compost tea.',
          'chemicalControl': 'Apply fungicides with chlorothalonil.',
          'affectedCrops': ['Tomato', 'Pepper', 'Cucumber'],
          'weatherTriggers': ['Warm, wet weather'],
          'severity': 'Medium',
          'preventionTips': 'Rotate crops, avoid working in wet fields.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/anthracnose-information.htm'],
          'lastUpdated': now,
        },
        {
          'id': '7',
          'name': 'Fusarium Wilt',
          'symptoms': 'Yellowing and wilting of lower leaves, brown streaks in stem.',
          'description': 'A soil-borne fungal disease that blocks water flow.',
          'organicControl': 'Remove infected plants, solarize soil.',
          'chemicalControl': 'No effective chemical control.',
          'affectedCrops': ['Tomato', 'Banana', 'Watermelon'],
          'weatherTriggers': ['Warm soil'],
          'severity': 'High',
          'preventionTips': 'Use resistant varieties, rotate crops.',
          'resources': ['https://www.planetnatural.com/pest-problem-solver/plant-disease/fusarium-wilt/'],
          'lastUpdated': now,
        },
        {
          'id': '8',
          'name': 'Verticillium Wilt',
          'symptoms': 'Yellowing between leaf veins, wilting.',
          'description': 'A soil-borne fungal disease similar to Fusarium wilt.',
          'organicControl': 'Remove infected plants, solarize soil.',
          'chemicalControl': 'No effective chemical control.',
          'affectedCrops': ['Tomato', 'Potato', 'Eggplant'],
          'weatherTriggers': ['Cool soil'],
          'severity': 'Medium',
          'preventionTips': 'Use resistant varieties, rotate crops.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/verticillium-wilt.htm'],
          'lastUpdated': now,
        },
        {
          'id': '9',
          'name': 'Root Knot Nematode',
          'symptoms': 'Galls or knots on roots, stunted growth.',
          'description': 'Microscopic worms that attack plant roots.',
          'organicControl': 'Grow marigolds, solarize soil.',
          'chemicalControl': 'Apply nematicides if available.',
          'affectedCrops': ['Tomato', 'Carrot', 'Cucumber'],
          'weatherTriggers': ['Warm soil'],
          'severity': 'Medium',
          'preventionTips': 'Rotate crops, use resistant varieties.',
          'resources': ['https://www.planetnatural.com/pest-problem-solver/plant-disease/root-knot-nematode/'],
          'lastUpdated': now,
        },
        {
          'id': '10',
          'name': 'Tomato Mosaic Virus',
          'symptoms': 'Mottled, light and dark green areas on leaves.',
          'description': 'A viral disease spread by contact and contaminated tools.',
          'organicControl': 'Remove infected plants, disinfect tools.',
          'chemicalControl': 'No chemical control.',
          'affectedCrops': ['Tomato', 'Pepper'],
          'weatherTriggers': ['Any'],
          'severity': 'Medium',
          'preventionTips': 'Wash hands, disinfect tools, use certified seed.',
          'resources': ['https://en.wikipedia.org/wiki/Tobamovirus'],
          'lastUpdated': now,
        },
        {
          'id': '11',
          'name': 'Bacterial Spot',
          'symptoms': 'Small, dark, water-soaked spots on leaves and fruit.',
          'description': 'A bacterial disease common in warm, wet weather.',
          'organicControl': 'Remove infected leaves, use copper sprays.',
          'chemicalControl': 'Apply copper-based bactericides.',
          'affectedCrops': ['Tomato', 'Pepper'],
          'weatherTriggers': ['Warm, wet weather'],
          'severity': 'Medium',
          'preventionTips': 'Avoid overhead watering, rotate crops.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/bacterial-leaf-spot.htm'],
          'lastUpdated': now,
        },
        {
          'id': '12',
          'name': 'Septoria Leaf Spot',
          'symptoms': 'Small, circular spots with gray centers on leaves.',
          'description': 'A fungal disease that causes premature leaf drop.',
          'organicControl': 'Remove infected leaves, use compost tea.',
          'chemicalControl': 'Apply fungicides with chlorothalonil.',
          'affectedCrops': ['Tomato'],
          'weatherTriggers': ['Wet, humid weather'],
          'severity': 'Low',
          'preventionTips': 'Mulch soil, avoid wetting foliage.',
          'resources': ['https://extension.umn.edu/diseases/septoria-leaf-spot-tomato'],
          'lastUpdated': now,
        },
        {
          'id': '13',
          'name': 'Damping Off',
          'symptoms': 'Seedlings collapse and die.',
          'description': 'A fungal disease affecting seedlings in wet, cool soil.',
          'organicControl': 'Improve drainage, use sterile soil.',
          'chemicalControl': 'No chemical control.',
          'affectedCrops': ['All seedlings'],
          'weatherTriggers': ['Cool, wet soil'],
          'severity': 'High',
          'preventionTips': 'Use clean pots, avoid overwatering.',
          'resources': ['https://www.rhs.org.uk/disease/damping-off'],
          'lastUpdated': now,
        },
        {
          'id': '14',
          'name': 'Leaf Curl Virus',
          'symptoms': 'Upward curling of leaves, stunted growth.',
          'description': 'A viral disease spread by whiteflies.',
          'organicControl': 'Control whiteflies, remove infected plants.',
          'chemicalControl': 'Use insecticidal soap for whiteflies.',
          'affectedCrops': ['Tomato', 'Pepper'],
          'weatherTriggers': ['Warm weather'],
          'severity': 'Medium',
          'preventionTips': 'Use row covers, control whiteflies.',
          'resources': ['https://en.wikipedia.org/wiki/Tomato_yellow_leaf_curl_virus'],
          'lastUpdated': now,
        },
        {
          'id': '15',
          'name': 'Blossom End Rot',
          'symptoms': 'Dark, sunken spots on blossom end of fruit.',
          'description': 'A physiological disorder caused by calcium deficiency.',
          'organicControl': 'Maintain consistent soil moisture, add calcium.',
          'chemicalControl': 'No chemical control.',
          'affectedCrops': ['Tomato', 'Pepper'],
          'weatherTriggers': ['Drought', 'Irregular watering'],
          'severity': 'Low',
          'preventionTips': 'Water regularly, use mulch.',
          'resources': ['https://www.gardeningknowhow.com/edible/vegetables/tomato/tomato-blossom-end-rot.htm'],
          'lastUpdated': now,
        },
        {
          'id': '16',
          'name': 'Mosaic Virus (Cucumber)',
          'symptoms': 'Mottled, yellow-green leaves, stunted growth.',
          'description': 'A viral disease affecting cucurbits, spread by aphids.',
          'organicControl': 'Control aphids, remove infected plants.',
          'chemicalControl': 'No chemical control.',
          'affectedCrops': ['Cucumber', 'Melon'],
          'weatherTriggers': ['Any'],
          'severity': 'Medium',
          'preventionTips': 'Use resistant varieties, control aphids.',
          'resources': ['https://en.wikipedia.org/wiki/Cucumber_mosaic_virus'],
          'lastUpdated': now,
        },
        {
          'id': '17',
          'name': 'Rust',
          'symptoms': 'Orange or brown pustules on leaves.',
          'description': 'A fungal disease affecting many crops.',
          'organicControl': 'Remove infected leaves, use sulfur sprays.',
          'chemicalControl': 'Apply fungicides with myclobutanil.',
          'affectedCrops': ['Bean', 'Wheat', 'Tomato'],
          'weatherTriggers': ['Humid weather'],
          'severity': 'Low',
          'preventionTips': 'Plant resistant varieties, rotate crops.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/rust-fungus.htm'],
          'lastUpdated': now,
        },
        {
          'id': '18',
          'name': 'Scab',
          'symptoms': 'Corky, raised lesions on tubers or fruit.',
          'description': 'A bacterial or fungal disease affecting potatoes and apples.',
          'organicControl': 'Use disease-free seed, rotate crops.',
          'chemicalControl': 'Apply sulfur to soil.',
          'affectedCrops': ['Potato', 'Apple'],
          'weatherTriggers': ['Dry soil'],
          'severity': 'Low',
          'preventionTips': 'Maintain soil pH below 5.2.',
          'resources': ['https://en.wikipedia.org/wiki/Common_scab'],
          'lastUpdated': now,
        },
        {
          'id': '19',
          'name': 'Wilt (Bacterial or Fungal)',
          'symptoms': 'Wilting, yellowing, and death of leaves.',
          'description': 'A group of diseases caused by various pathogens.',
          'organicControl': 'Remove infected plants, solarize soil.',
          'chemicalControl': 'No effective chemical control.',
          'affectedCrops': ['Tomato', 'Banana', 'Cucumber'],
          'weatherTriggers': ['Warm, wet weather'],
          'severity': 'High',
          'preventionTips': 'Use resistant varieties, rotate crops.',
          'resources': ['https://en.wikipedia.org/wiki/Wilt_(plant_disease)'],
          'lastUpdated': now,
        },
        {
          'id': '20',
          'name': 'Clubroot',
          'symptoms': 'Swollen, distorted roots, stunted growth.',
          'description': 'A soil-borne disease caused by Plasmodiophora brassicae.',
          'organicControl': 'Remove infected plants, lime soil.',
          'chemicalControl': 'No chemical control.',
          'affectedCrops': ['Cabbage', 'Broccoli', 'Cauliflower'],
          'weatherTriggers': ['Acidic, wet soil'],
          'severity': 'High',
          'preventionTips': 'Raise soil pH, rotate crops.',
          'resources': ['https://en.wikipedia.org/wiki/Clubroot'],
          'lastUpdated': now,
        },
        // Additional 20 diseases:
        {
          'id': '21',
          'name': 'Alternaria Leaf Spot',
          'symptoms': 'Small, dark brown spots with yellow halos on leaves.',
          'description': 'A fungal disease caused by Alternaria species, leading to leaf blight and defoliation.',
          'organicControl': 'Remove infected leaves, use compost tea.',
          'chemicalControl': 'Apply fungicides with chlorothalonil.',
          'affectedCrops': ['Cabbage', 'Broccoli', 'Cauliflower'],
          'weatherTriggers': ['Warm, humid weather'],
          'severity': 'Medium',
          'preventionTips': 'Rotate crops, avoid overhead irrigation.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/alternaria-leaf-spot.htm'],
          'lastUpdated': now,
        },
        {
          'id': '22',
          'name': 'Black Rot',
          'symptoms': 'V-shaped yellow lesions on leaf edges, black veins.',
          'description': 'A bacterial disease of crucifers caused by Xanthomonas campestris.',
          'organicControl': 'Remove infected plants, use hot water seed treatment.',
          'chemicalControl': 'Apply copper-based bactericides.',
          'affectedCrops': ['Cabbage', 'Broccoli', 'Kale'],
          'weatherTriggers': ['Warm, wet weather'],
          'severity': 'High',
          'preventionTips': 'Use certified seed, rotate crops.',
          'resources': ['https://en.wikipedia.org/wiki/Black_rot'],
          'lastUpdated': now,
        },
        {
          'id': '23',
          'name': 'Bacterial Canker',
          'symptoms': 'Wilting, cankers on stems, white blisters on fruit.',
          'description': 'A bacterial disease of tomato caused by Clavibacter michiganensis.',
          'organicControl': 'Remove infected plants, disinfect tools.',
          'chemicalControl': 'Apply copper-based bactericides.',
          'affectedCrops': ['Tomato'],
          'weatherTriggers': ['Warm, wet weather'],
          'severity': 'High',
          'preventionTips': 'Use disease-free seed, rotate crops.',
          'resources': ['https://www.gardeningknowhow.com/edible/vegetables/tomato/tomato-bacterial-canker.htm'],
          'lastUpdated': now,
        },
        {
          'id': '24',
          'name': 'Cercospora Leaf Spot',
          'symptoms': 'Circular spots with tan centers and purple borders.',
          'description': 'A fungal disease affecting many vegetables, especially beet and carrot.',
          'organicControl': 'Remove infected leaves, improve air flow.',
          'chemicalControl': 'Apply fungicides with chlorothalonil.',
          'affectedCrops': ['Carrot', 'Beet', 'Spinach'],
          'weatherTriggers': ['Warm, humid weather'],
          'severity': 'Medium',
          'preventionTips': 'Rotate crops, avoid wetting foliage.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/cercospora-leaf-spot.htm'],
          'lastUpdated': now,
        },
        {
          'id': '25',
          'name': 'Crown Rot',
          'symptoms': 'Wilting, brown rot at base of stem.',
          'description': 'A fungal disease caused by Sclerotium or Fusarium species.',
          'organicControl': 'Improve drainage, remove infected plants.',
          'chemicalControl': 'Apply fungicides with fludioxonil.',
          'affectedCrops': ['Strawberry', 'Lettuce', 'Carrot'],
          'weatherTriggers': ['Wet, poorly drained soil'],
          'severity': 'High',
          'preventionTips': 'Plant in raised beds, avoid overwatering.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/crown-rot-disease.htm'],
          'lastUpdated': now,
        },
        {
          'id': '26',
          'name': 'Gummy Stem Blight',
          'symptoms': 'Water-soaked lesions on stems, gummy ooze.',
          'description': 'A fungal disease of cucurbits caused by Didymella bryoniae.',
          'organicControl': 'Remove infected vines, rotate crops.',
          'chemicalControl': 'Apply fungicides with chlorothalonil.',
          'affectedCrops': ['Cucumber', 'Melon', 'Watermelon'],
          'weatherTriggers': ['Warm, wet weather'],
          'severity': 'High',
          'preventionTips': 'Avoid overhead irrigation, use resistant varieties.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/gummy-stem-blight.htm'],
          'lastUpdated': now,
        },
        {
          'id': '27',
          'name': 'Halo Blight',
          'symptoms': 'Small, water-soaked spots with yellow halos on leaves.',
          'description': 'A bacterial disease of beans caused by Pseudomonas syringae.',
          'organicControl': 'Remove infected plants, use disease-free seed.',
          'chemicalControl': 'Apply copper-based bactericides.',
          'affectedCrops': ['Bean'],
          'weatherTriggers': ['Cool, wet weather'],
          'severity': 'Medium',
          'preventionTips': 'Rotate crops, avoid working in wet fields.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/halo-blight-beans.htm'],
          'lastUpdated': now,
        },
        {
          'id': '28',
          'name': 'Leaf Spot (Bacterial)',
          'symptoms': 'Small, angular, water-soaked spots on leaves.',
          'description': 'A bacterial disease affecting many vegetables.',
          'organicControl': 'Remove infected leaves, use copper sprays.',
          'chemicalControl': 'Apply copper-based bactericides.',
          'affectedCrops': ['Lettuce', 'Spinach', 'Pepper'],
          'weatherTriggers': ['Warm, wet weather'],
          'severity': 'Low',
          'preventionTips': 'Avoid overhead watering, rotate crops.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/bacterial-leaf-spot.htm'],
          'lastUpdated': now,
        },
        {
          'id': '29',
          'name': 'Phytophthora Root Rot',
          'symptoms': 'Wilting, root rot, plant collapse.',
          'description': 'A soil-borne disease caused by Phytophthora species.',
          'organicControl': 'Improve drainage, solarize soil.',
          'chemicalControl': 'Apply fungicides with mefenoxam.',
          'affectedCrops': ['Pepper', 'Eggplant', 'Tomato'],
          'weatherTriggers': ['Wet, poorly drained soil'],
          'severity': 'High',
          'preventionTips': 'Plant in raised beds, avoid overwatering.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/phytophthora-root-rot.htm'],
          'lastUpdated': now,
        },
        {
          'id': '30',
          'name': 'Pink Rot',
          'symptoms': 'Pink, soft rot of tubers or fruit.',
          'description': 'A fungal disease caused by Phytophthora erythroseptica.',
          'organicControl': 'Remove infected tubers, improve drainage.',
          'chemicalControl': 'Apply fungicides with mefenoxam.',
          'affectedCrops': ['Potato', 'Carrot'],
          'weatherTriggers': ['Wet, cool soil'],
          'severity': 'Medium',
          'preventionTips': 'Harvest in dry weather, cure tubers before storage.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/pink-rot-potato.htm'],
          'lastUpdated': now,
        },
        {
          'id': '31',
          'name': 'Pythium Root Rot',
          'symptoms': 'Root rot, stunted growth, yellowing leaves.',
          'description': 'A soil-borne disease caused by Pythium species.',
          'organicControl': 'Improve drainage, use sterile soil.',
          'chemicalControl': 'Apply fungicides with mefenoxam.',
          'affectedCrops': ['Lettuce', 'Spinach', 'Cucumber'],
          'weatherTriggers': ['Wet, cool soil'],
          'severity': 'Medium',
          'preventionTips': 'Avoid overwatering, rotate crops.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/pythium-root-rot.htm'],
          'lastUpdated': now,
        },
        {
          'id': '32',
          'name': 'Rhizoctonia Root Rot',
          'symptoms': 'Brown, sunken lesions on roots and stems.',
          'description': 'A fungal disease caused by Rhizoctonia solani.',
          'organicControl': 'Improve drainage, rotate crops.',
          'chemicalControl': 'Apply fungicides with fludioxonil.',
          'affectedCrops': ['Potato', 'Carrot', 'Bean'],
          'weatherTriggers': ['Warm, wet soil'],
          'severity': 'Medium',
          'preventionTips': 'Avoid overwatering, use clean seed.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/rhizoctonia-root-rot.htm'],
          'lastUpdated': now,
        },
        {
          'id': '33',
          'name': 'Sclerotinia Stem Rot',
          'symptoms': 'White, cottony growth on stems, black sclerotia.',
          'description': 'A fungal disease caused by Sclerotinia sclerotiorum.',
          'organicControl': 'Remove infected plants, rotate crops.',
          'chemicalControl': 'Apply fungicides with boscalid.',
          'affectedCrops': ['Lettuce', 'Bean', 'Cabbage'],
          'weatherTriggers': ['Cool, moist conditions'],
          'severity': 'High',
          'preventionTips': 'Improve air flow, avoid overhead irrigation.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/sclerotinia-stem-rot.htm'],
          'lastUpdated': now,
        },
        {
          'id': '34',
          'name': 'Southern Blight',
          'symptoms': 'White fungal growth at base of stem, plant collapse.',
          'description': 'A soil-borne fungal disease caused by Sclerotium rolfsii.',
          'organicControl': 'Remove infected plants, solarize soil.',
          'chemicalControl': 'Apply fungicides with flutolanil.',
          'affectedCrops': ['Tomato', 'Pepper', 'Bean'],
          'weatherTriggers': ['Warm, wet soil'],
          'severity': 'High',
          'preventionTips': 'Rotate crops, avoid overwatering.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/southern-blight.htm'],
          'lastUpdated': now,
        },
        {
          'id': '35',
          'name': 'Verticillium Wilt (Lettuce)',
          'symptoms': 'Yellowing, wilting, and death of outer leaves.',
          'description': 'A soil-borne fungal disease affecting lettuce.',
          'organicControl': 'Remove infected plants, solarize soil.',
          'chemicalControl': 'No effective chemical control.',
          'affectedCrops': ['Lettuce'],
          'weatherTriggers': ['Cool soil'],
          'severity': 'Medium',
          'preventionTips': 'Use resistant varieties, rotate crops.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/verticillium-wilt.htm'],
          'lastUpdated': now,
        },
        {
          'id': '36',
          'name': 'White Mold',
          'symptoms': 'White, cottony growth on stems and pods.',
          'description': 'A fungal disease caused by Sclerotinia sclerotiorum.',
          'organicControl': 'Remove infected plants, rotate crops.',
          'chemicalControl': 'Apply fungicides with boscalid.',
          'affectedCrops': ['Bean', 'Lettuce', 'Cabbage'],
          'weatherTriggers': ['Cool, moist conditions'],
          'severity': 'High',
          'preventionTips': 'Improve air flow, avoid overhead irrigation.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/white-mold.htm'],
          'lastUpdated': now,
        },
        {
          'id': '37',
          'name': 'Yellow Leaf Curl Virus',
          'symptoms': 'Yellowing and curling of leaves, stunted growth.',
          'description': 'A viral disease spread by whiteflies.',
          'organicControl': 'Control whiteflies, remove infected plants.',
          'chemicalControl': 'Use insecticidal soap for whiteflies.',
          'affectedCrops': ['Tomato', 'Pepper'],
          'weatherTriggers': ['Warm weather'],
          'severity': 'High',
          'preventionTips': 'Use row covers, control whiteflies.',
          'resources': ['https://en.wikipedia.org/wiki/Tomato_yellow_leaf_curl_virus'],
          'lastUpdated': now,
        },
        {
          'id': '38',
          'name': 'Zucchini Yellow Mosaic Virus',
          'symptoms': 'Yellow mosaic patterns on leaves, stunted growth.',
          'description': 'A viral disease affecting cucurbits, spread by aphids.',
          'organicControl': 'Control aphids, remove infected plants.',
          'chemicalControl': 'No chemical control.',
          'affectedCrops': ['Zucchini', 'Cucumber', 'Melon'],
          'weatherTriggers': ['Any'],
          'severity': 'Medium',
          'preventionTips': 'Use resistant varieties, control aphids.',
          'resources': ['https://en.wikipedia.org/wiki/Zucchini_yellow_mosaic_virus'],
          'lastUpdated': now,
        },
        {
          'id': '39',
          'name': 'Angular Leaf Spot',
          'symptoms': 'Angular, water-soaked spots on leaves.',
          'description': 'A bacterial disease of cucurbits caused by Pseudomonas syringae.',
          'organicControl': 'Remove infected leaves, use copper sprays.',
          'chemicalControl': 'Apply copper-based bactericides.',
          'affectedCrops': ['Cucumber', 'Melon'],
          'weatherTriggers': ['Wet, humid weather'],
          'severity': 'Low',
          'preventionTips': 'Avoid overhead watering, rotate crops.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/angular-leaf-spot.htm'],
          'lastUpdated': now,
        },
        {
          'id': '40',
          'name': 'Bacterial Soft Rot',
          'symptoms': 'Soft, watery rot of stems, leaves, or fruit.',
          'description': 'A bacterial disease caused by Erwinia species.',
          'organicControl': 'Remove infected tissue, improve air flow.',
          'chemicalControl': 'No chemical control.',
          'affectedCrops': ['Carrot', 'Potato', 'Cabbage'],
          'weatherTriggers': ['Warm, wet weather'],
          'severity': 'High',
          'preventionTips': 'Harvest in dry weather, avoid wounding plants.',
          'resources': ['https://www.gardeningknowhow.com/plant-problems/disease/bacterial-soft-rot.htm'],
          'lastUpdated': now,
        },
      ];
      for (final d in samples) {
        await box.put(d['id'], d);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initIAP();
    _loadPremium();
    _populateSampleDiseases();
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go Premium'),
        content: const Text('Upgrade to premium to unlock all diseases and features!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (kIsWeb) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.credit_card),
              label: const Text('Pay with Stripe (Web)'),
              onPressed: () async {
                const stripeUrl = 'https://checkout.stripe.com/pay/your-session-id'; // TODO: Replace with your Stripe Checkout URL
                await launchUrl(
                  Uri.parse(stripeUrl),
                  mode: LaunchMode.platformDefault,
                  webOnlyWindowName: '_self',
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('PayPal (Web)'),
              onPressed: () async {
                const paypalUrl = 'https://www.paypal.com/checkoutnow?token=...'; // TODO: Replace with your PayPal payment URL
                await launchUrl(
                  Uri.parse(paypalUrl),
                  mode: LaunchMode.platformDefault,
                  webOnlyWindowName: '_self',
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: const Text('Flutterwave (Web)'),
              onPressed: () async {
                const flutterwaveUrl = 'https://flutterwave.com/pay/...'; // TODO: Replace with your Flutterwave payment URL
                await launchUrl(
                  Uri.parse(flutterwaveUrl),
                  mode: LaunchMode.platformDefault,
                  webOnlyWindowName: '_self',
                );
              },
            ),
            ElevatedButton(
              child: const Text("I've paid! Unlock Premium"),
              onPressed: () async {
                await _setPremium(true);
                Navigator.pop(context);
              },
            ),
          ] else ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.credit_card),
              label: const Text('Pay with Stripe'),
              onPressed: () async {
                await _payWithStripe();
                Navigator.pop(context);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('PayPal'),
              onPressed: () async {
                await _payWithPayPal();
                Navigator.pop(context);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: const Text('Flutterwave'),
              onPressed: () async {
                await _payWithFlutterwave();
                Navigator.pop(context);
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showPlatformNotSupported() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not Supported'),
        content: const Text('Payments are only supported on Android and iOS devices.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _payWithInAppPurchase() async {
    if (_products.isEmpty) {
      await _initIAP();
      if (_products.isEmpty) return;
    }
    final ProductDetails product = _products.first;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    _iap.buyNonConsumable(purchaseParam: purchaseParam);
    _iap.purchaseStream.listen((purchases) {
      for (var purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased) {
          _setPremium(true);
        }
      }
    });
  }

  Future<void> _payWithPayPal() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => UsePaypal(
          sandboxMode: true, // Set to false for production
          clientId: "YOUR_PAYPAL_CLIENT_ID", // TODO: Replace with your PayPal client ID
          secretKey: "YOUR_PAYPAL_SECRET", // TODO: Replace with your PayPal secret
          returnURL: "https://samplesite.com/return",
          cancelURL: "https://samplesite.com/cancel",
          transactions: [
            {
              "amount": {
                "total": '5.00',
                "currency": 'USD',
                "details": {
                  "subtotal": '5.00',
                  "shipping": '0',
                  "shipping_discount": 0
                }
              },
              "description": "Premium Subscription",
              "item_list": {
                "items": [
                  {
                    "name": "Premium Subscription",
                    "quantity": 1,
                    "price": '5.00',
                    "currency": 'USD'
                  }
                ],
              }
            }
          ],
          note: "Contact us for any questions on your order.",
          onSuccess: (Map params) async {
            _setPremium(true);
          },
          onError: (error) {
            // Handle error
          },
          onCancel: (params) {
            // Handle cancel
          }
        ),
      ),
    );
  }

  Future<void> _payWithFlutterwave() async {
    final Customer customer = Customer(
      name: widget.username,
      phoneNumber: "1234567890",
      email: "user@email.com",
    );

    final Flutterwave flutterwave = Flutterwave(
      publicKey: "YOUR_FLUTTERWAVE_PUBLIC_KEY", // TODO: Replace with your Flutterwave public key
      currency: "USD",
      redirectUrl: "https://www.google.com",
      txRef: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: "5",
      customer: customer,
      paymentOptions: "card, payattitude",
      customization: Customization(title: "Premium Subscription"),
      isTestMode: true,
    );

    final ChargeResponse? response = await flutterwave.charge(context);
    if (response != null && response.status == "success") {
      _setPremium(true);
    }
  }

  Future<String> fetchStripeClientSecretFromBackend(String email) async {
    final response = await http.post(
      Uri.parse('http://YOUR_BACKEND_URL/create-stripe-session'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['clientSecret'] ?? data['url'];
    } else {
      throw Exception('Failed to fetch Stripe client secret');
    }
  }

  Future<void> _payWithStripe() async {
    // 1. Get payment intent client secret from your backend
    final clientSecret = await fetchStripeClientSecretFromBackend(widget.username);

    // 2. Initialize payment sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Your App Name',
      ),
    );

    // 3. Present payment sheet
    await Stripe.instance.presentPaymentSheet();

    // 4. On success, unlock premium
    await _setPremium(true);
  }

  // ───────────────────────────────── UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: null,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.star, color: _isPremium ? Colors.amber : Colors.grey),
            tooltip: _isPremium ? 'Premium user' : 'Go Premium',
            onPressed: _isPremium ? null : _showPremiumDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Crop dropdown
              Row(
                children: [
                  const Icon(Icons.sick, color: Colors.red, size: 32, semanticLabel: 'Disease'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedCrop,
                    items: _crops
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCrop = v!),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.report, semanticLabel: 'Report new disease'),
                  label: Text('Report New Disease'),
                  onPressed: _showReportDiseaseDialog,
                ),
              ),
              // Search bar
              TextField(
                decoration: InputDecoration(
                  labelText: 'Search by name or symptom',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
              ),
              const SizedBox(height: 12),
              Text(
                'Diseases for $_selectedCrop',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Admin form
              if (_isAdmin) _AdminDiseaseForm(
                nameCtl: _diseaseNameCtl,
                symptomsCtl: _symptomsCtl,
                organicCtl: _organicCtl,
                chemicalCtl: _chemicalCtl,
                cropsCtl: _affectedCropsCtl,
                triggersCtl: _weatherTriggersCtl,
                onSave: _saveDisease,
                severity: _severity,
                onSeverityChanged: (value) => setState(() => _severity = value!),
                severityLevels: _severityLevels,
                preventionTipsCtl: _preventionTipsCtl,
                resourcesCtl: _resourcesCtl,
              ),
              const SizedBox(height: 16),

              // Stream list
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: FutureBuilder<Box>(
                  future: Hive.openBox('diseases_box'),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final box = snapshot.data!;
                    final diseases = box.values
                      .where((d) => (d['affectedCrops'] as List?)?.contains(_selectedCrop) ?? false)
                      .where((d) =>
                        _searchQuery.isEmpty ||
                        (d['name']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                        (d['symptoms']?.toString().toLowerCase().contains(_searchQuery) ?? false)
                      )
                      .toList();
                    if (diseases.isEmpty) {
                      return const Center(child: Text('No diseases for this crop.'));
                    }
                    int diseaseLimit = _isPremium ? diseases.length : 3;
                    final limitedDiseases = diseases.take(diseaseLimit).toList();
                    // Move the premium banner into a variable
                    final premiumBanner = (!_isPremium && diseases.length > 3)
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: material.Card(
                            color: Colors.amber[100],
                            child: ListTile(
                              leading: const Icon(Icons.lock, color: Colors.amber),
                              title: const Text('Unlock all diseases with Premium!'),
                              trailing: ElevatedButton(
                                onPressed: _showPremiumDialog,
                                child: const Text('Go Premium'),
                              ),
                            ),
                          ),
                        )
                      : SizedBox.shrink();
                    return Column(
                      children: [
                        premiumBanner,
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 600;
                              return ListView.builder(
                                itemCount: limitedDiseases.length,
                                itemBuilder: (context, i) {
                                  final d = limitedDiseases[i];
                                  return InkWell(
                                    onTap: () => _showDiseaseDetails(d),
                                    child: material.Card(
                                      color: Colors.red[50],
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      child: ListTile(
                                        leading: const Icon(Icons.sick, color: Colors.red),
                                        title: Row(
                                          children: [
                                            Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 8),
                                            if (d['severity'] != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: d['severity'] == 'High' ? Colors.red : d['severity'] == 'Medium' ? Colors.orange : Colors.green,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  d['severity'],
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                              ),
                                          ],
                                        ),
                                        subtitle: Text(d['symptoms'] ?? ''),
                                        trailing: _isAdmin
                                            ? IconButton(
                                                icon: const Icon(Icons.delete, semanticLabel: 'Delete disease'),
                                                tooltip: 'Delete disease',
                                                onPressed: () async {
                                                  await box.delete(d['id']);
                                                  setState(() {});
                                                },
                                              )
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 8),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Admin Form (extracted for readability)
class _AdminDiseaseForm extends StatelessWidget {
  const _AdminDiseaseForm({
    required this.nameCtl,
    required this.symptomsCtl,
    required this.organicCtl,
    required this.chemicalCtl,
    required this.cropsCtl,
    required this.triggersCtl,
    required this.onSave,
    required this.severity,
    required this.onSeverityChanged,
    required this.severityLevels,
    required this.preventionTipsCtl,
    required this.resourcesCtl,
  });

  final TextEditingController nameCtl;
  final TextEditingController symptomsCtl;
  final TextEditingController organicCtl;
  final TextEditingController chemicalCtl;
  final TextEditingController cropsCtl;
  final TextEditingController triggersCtl;
  final TextEditingController preventionTipsCtl;
  final TextEditingController resourcesCtl;
  final VoidCallback onSave;
  final String severity;
  final void Function(String?) onSeverityChanged;
  final List<String> severityLevels;

  @override
  Widget build(BuildContext context) {
    return material.Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Disease Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildField('Disease name', nameCtl),
            _buildField('Symptoms', symptomsCtl, lines: 3),
            _buildField('Organic control methods', organicCtl, lines: 3),
            _buildField('Chemical control methods', chemicalCtl, lines: 3),
            _buildField('Affected crops (comma‑separated)', cropsCtl),
            _buildField('Weather triggers (comma‑separated)', triggersCtl),
            _buildField('Prevention tips', preventionTipsCtl, lines: 3),
            _buildField('Related resources (comma‑separated URLs or titles)', resourcesCtl, lines: 3),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: severity,
              decoration: const InputDecoration(labelText: 'Severity'),
              items: severityLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
              onChanged: onSeverityChanged,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctl, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctl,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
