import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_svg/flutter_svg.dart';
// Removed: import 'package:intl/intl.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'dart:io' show Platform;
import 'package:universal_platform/universal_platform.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart' as material;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:infofarmer/screens/login_screen.dart';
import '../services/subscription_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Hive boxes
const String kTipsBox = 'tips_box';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key, required this.isAdmin, required this.username});
  final bool isAdmin;
  final String username;

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  // ───────────────────────────────── controllers & state
  final _titleCtl = TextEditingController();
  final _descCtl  = TextEditingController();
  String _crop = 'Tomato';
  String _cat  = 'Planting';

  final _crops = [
    'Tomato','Beans','Maize','Potato','Cabbage','Carrot','Onion','Other'
  ];
  final _cats = [
    'Planting','Watering & Irrigation','Fertilization','Harvesting','Storage',
    'Pest & Disease Management','Weed Control','Soil Health','Climate Advice',
    'Market Readiness','Organic Alternatives'
  ];

  // descriptions & images (same as before)
  final Map<String,String> _catDesc = {
    'Planting':'Best practices for sowing and establishing crops.',
    'Watering & Irrigation':'Guidance on efficient water use and irrigation methods.',
    'Fertilization':'Tips for fertilizing crops for optimal growth.',
    'Harvesting':'Advice on when and how to harvest crops.',
    'Storage':'How to store produce to maintain quality.',
    'Pest & Disease Management':'Identifying, preventing, and treating crop pests and diseases.',
    'Weed Control':'Methods for effective weed management.',
    'Soil Health':'Maintaining and improving soil fertility and structure.',
    'Climate Advice':'Adapting to weather and climate conditions.',
    'Market Readiness':'Preparing produce for market and maximizing value.',
    'Organic Alternatives':'Natural and organic solutions for sustainable farming.'
  };
  final Map<String,String> _cropImages = {
    'Tomato':'assets/images/tomato.svg',
    'Beans':'assets/images/beans.svg',
    'Maize':'assets/images/maize.svg',
    'Potato':'assets/images/potato.svg',
    'Cabbage':'assets/images/cabbage.svg',
    'Carrot':'assets/images/carrot.svg',
    'Onion':'assets/images/onion.svg',
    'Other':'assets/images/other_crop.svg',
  };
  final Map<String,String> _cropDesc = {
    'Tomato':'Tomatoes are rich in vitamins and require regular watering and pest management.',
    'Beans':'Beans fix nitrogen in the soil and need support for climbing varieties.',
    'Maize':'Maize needs full sun and benefits from crop rotation.',
    'Potato':'Potatoes grow best in loose, well‑drained soil.',
    'Cabbage':'Cabbage prefers cool weather and regular fertilization.',
    'Carrot':'Carrots need deep, loose soil for straight roots.',
    'Onion':'Onions require consistent moisture and full sun.',
    'Other':'Select a crop to see more information.'
  };

  final _userTipTitleCtl = TextEditingController();
  final _userTipDescCtl = TextEditingController();
  String _userTipCrop = 'Tomato';
  String _userTipCat = 'Planting';

  // Hive box reference
  bool _showOnlyLiked = false;
  bool _isPremium = false;

  final InAppPurchase _iap = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  final String _kPremiumId = 'premium_subscription'; // TODO: Replace with your real product ID

  String get priceText {
    double priceValue = 5.00;
    String priceRaw = _products.isNotEmpty ? _products.first.price : '5.00';
    final priceRegExp = RegExp(r'[\\d.]+');
    final match = priceRegExp.firstMatch(priceRaw);
    if (match != null) {
      priceValue = double.tryParse(match.group(0) ?? '5.00') ?? 5.00;
    }
    return ' 24${priceValue.toStringAsFixed(2)}';
  }

  Future<void> _populateSampleTips() async {
    var box = await Hive.openBox(kTipsBox);
    if (box.isEmpty) {
      final now = DateTime.now().toIso8601String();
      final List<Map<String, dynamic>> samples = [
        {
          'id': '1',
          'crop': 'Tomato',
          'category': 'Planting',
          'title': 'Start seeds indoors',
          'description': 'Start tomato seeds indoors 6-8 weeks before the last frost for a head start.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/tomato.svg',
        },
        {
          'id': '2',
          'crop': 'Tomato',
          'category': 'Watering & Irrigation',
          'title': 'Water deeply',
          'description': 'Water tomato plants deeply but less frequently to encourage strong root growth.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/tomato.svg',
        },
        {
          'id': '3',
          'crop': 'Beans',
          'category': 'Planting',
          'title': 'Direct sow beans',
          'description': 'Beans grow best when sown directly into warm soil after the last frost.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/beans.svg',
        },
        {
          'id': '4',
          'crop': 'Beans',
          'category': 'Fertilization',
          'title': 'Minimal fertilizer needed',
          'description': 'Beans fix their own nitrogen and need little additional fertilizer.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/beans.svg',
        },
        {
          'id': '5',
          'crop': 'Maize',
          'category': 'Planting',
          'title': 'Plant in blocks',
          'description': 'Plant maize in blocks rather than rows for better pollination.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/maize.svg',
        },
        {
          'id': '6',
          'crop': 'Maize',
          'category': 'Fertilization',
          'title': 'Side-dress with nitrogen',
          'description': 'Apply nitrogen fertilizer when maize is knee-high for best results.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/maize.svg',
        },
        {
          'id': '7',
          'crop': 'Potato',
          'category': 'Planting',
          'title': 'Use certified seed potatoes',
          'description': 'Plant only certified, disease-free seed potatoes to prevent disease.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/potato.svg',
        },
        {
          'id': '8',
          'crop': 'Potato',
          'category': 'Storage',
          'title': 'Cure before storage',
          'description': 'Cure potatoes in a dark, well-ventilated area for 1-2 weeks before storage.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/potato.svg',
        },
        {
          'id': '9',
          'crop': 'Cabbage',
          'category': 'Planting',
          'title': 'Transplant seedlings',
          'description': 'Transplant cabbage seedlings outdoors when they have 4-5 true leaves.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/cabbage.svg',
        },
        {
          'id': '10',
          'crop': 'Cabbage',
          'category': 'Pest & Disease Management',
          'title': 'Use row covers',
          'description': 'Use row covers to protect cabbage from cabbage worms and moths.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/cabbage.svg',
        },
        {
          'id': '11',
          'crop': 'Carrot',
          'category': 'Soil Health',
          'title': 'Loosen soil deeply',
          'description': 'Carrots need deep, loose soil for straight roots.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/carrot.svg',
        },
        {
          'id': '12',
          'crop': 'Carrot',
          'category': 'Weed Control',
          'title': 'Mulch to suppress weeds',
          'description': 'Apply mulch to carrot beds to suppress weeds and retain moisture.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/carrot.svg',
        },
        {
          'id': '13',
          'crop': 'Onion',
          'category': 'Planting',
          'title': 'Plant sets or transplants',
          'description': 'Onions grow best from sets or transplants rather than seed.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/onion.svg',
        },
        {
          'id': '14',
          'crop': 'Onion',
          'category': 'Weed Control',
          'title': 'Keep beds weed-free',
          'description': 'Onions are poor competitors; keep beds weed-free for best growth.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/onion.svg',
        },
        {
          'id': '15',
          'crop': 'Tomato',
          'category': 'Harvesting',
          'title': 'Harvest when fully colored',
          'description': 'Pick tomatoes when they are fully colored for best flavor.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/tomato.svg',
        },
        {
          'id': '16',
          'crop': 'Beans',
          'category': 'Harvesting',
          'title': 'Pick regularly',
          'description': 'Pick beans regularly to encourage more production.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/beans.svg',
        },
        {
          'id': '17',
          'crop': 'Maize',
          'category': 'Storage',
          'title': 'Dry thoroughly before storage',
          'description': 'Ensure maize is fully dry before storing to prevent mold.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/maize.svg',
        },
        {
          'id': '18',
          'crop': 'Potato',
          'category': 'Pest & Disease Management',
          'title': 'Rotate crops yearly',
          'description': 'Rotate potatoes with non-solanaceous crops to reduce disease risk.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/potato.svg',
        },
        {
          'id': '19',
          'crop': 'Cabbage',
          'category': 'Fertilization',
          'title': 'Feed with nitrogen',
          'description': 'Cabbage is a heavy feeder; apply nitrogen fertilizer during growth.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/cabbage.svg',
        },
        {
          'id': '20',
          'crop': 'Carrot',
          'category': 'Harvesting',
          'title': 'Harvest when roots are finger-sized',
          'description': 'Harvest carrots when roots are finger-sized for best texture and flavor.',
          'timestamp': now,
          'author': 'admin',
          'image': 'assets/images/carrot.svg',
        },
      ];
      for (final t in samples) {
        await box.put(t['id'], t);
      }
    }
  }

  Future<void> _loadPremium() async {
    _isPremium = await SubscriptionService.isPremium(widget.username);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _setPremium(bool value) async {
    if (value) {
      await SubscriptionService.activatePremium(widget.username, 'manual_premium');
    } else {
      await SubscriptionService.removePremium(widget.username);
    }
  }

  Future<void> _initIAP() async {
    final bool available = await _iap.isAvailable();
    if (!available) return;
    final ProductDetailsResponse response = await _iap.queryProductDetails({_kPremiumId});
    if (response.notFoundIDs.isEmpty && mounted) {
      setState(() {
        _products = response.productDetails;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _populateSampleTips();
    _loadPremium();
    _initIAP();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Redirect to login if username is not set (not authenticated)
    if (widget.username.isEmpty || widget.username == 'null') {
      Future.microtask(() {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      });
    }
  }

  Future<void> _openBox() async {
    // This function is no longer needed as box access is handled by FutureBuilder
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _descCtl.dispose();
    // _box.close(); // This line is no longer needed
    super.dispose();
  }

  // ───────────────────────────────── add tip dialog (admin)
  Future<void> _showAddDialog() async {
    _titleCtl.clear();
    _descCtl.clear();
    final key = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Tip'),
        content: Form(
          key: key,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _dd('Crop', _crop, _crops, (v)=>setState(()=>_crop=v!)),
            _dd('Category', _cat, _cats, (v)=>setState(()=>_cat=v!)),
            TextFormField(controller:_titleCtl,decoration:const InputDecoration(labelText:'Title'),validator:(v)=>v!.trim().isEmpty?'Required':null),
            TextFormField(controller:_descCtl,decoration:const InputDecoration(labelText:'Description'),maxLines:3,validator:(v)=>v!.trim().isEmpty?'Required':null),
          ]),
        ),
        actions: [
          TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),
          ElevatedButton(onPressed:() async {
            if(key.currentState?.validate()!=true) return;
            final id = DateTime.now().millisecondsSinceEpoch.toString();
            var box = await Hive.openBox(kTipsBox);
            await box.put(id, {
              'id': id,
              'crop': _crop,
              'category': _cat,
              'title': _titleCtl.text.trim(),
              'description': _descCtl.text.trim(),
              'timestamp': DateTime.now().toIso8601String(),
              'author': 'admin',
              'status': 'approved', // Admin tips are automatically approved
            });
            if(mounted) setState((){});
            if(mounted) Navigator.pop(context);
          }, child: const Text('Add')),
        ],
      ),
    );
  }

  // ───────────────────────────────── get filtered tips
  // This function is no longer needed as filtering is done inside FutureBuilder
  // List<Map> _filteredTips() {
  //   if (!_box.isOpen) return [];
  //   final List<Map> all = _box.values.cast<Map>().toList();
  //   var filtered = all.where((t) => t['crop'] == _crop && t['category'] == _cat).toList()
  //     ..sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
  //   if (_showOnlyLiked) {
  //     final likedBox = Hive.box('liked_tips');
  //     filtered = filtered.where((t) => likedBox.get(t['id'], defaultValue: false)).toList();
  //   }
  //   return filtered;
  // }

  // ───────────────────────────────── ui helpers
  DropdownButtonFormField<String> _dd(String label,String value,List<String> items,void Function(String?) onChanged)=>DropdownButtonFormField(
    value:value,
    decoration:InputDecoration(labelText:label),
    items:items.map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),
    onChanged:onChanged,
  );

  void _showTipDetails(Map tip) {
    final _commentCtl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<bool>(
        future: SubscriptionService.isPremium(widget.username),
        builder: (context, snapshot) {
          final liked = snapshot.data ?? false;
          return StatefulBuilder(
            builder: (context, setStateDialog) => AlertDialog(
              title: Row(
                children: [
                  Expanded(child: Text(tip['title'] ?? '')),
                  IconButton(
                    icon: Icon(liked ? Icons.bookmark : Icons.bookmark_border, color: liked ? Colors.orange : Colors.grey, semanticLabel: liked ? 'Remove bookmark' : 'Bookmark'),
                    tooltip: liked ? 'Remove bookmark' : 'Bookmark',
                    onPressed: () {
                      _toggleLikeTip(tip['id']);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tip['image'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          height: 80,
                          child: tip['image'].toString().endsWith('.svg')
                            ? SvgPicture.asset(tip['image'], semanticsLabel: tip['crop'])
                            : Image.asset(tip['image']),
                        ),
                      ),
                    if (tip['description'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(tip['description']),
                      ),
                    if (tip['author'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('By: ${tip['author']}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      ),
                    if (tip['timestamp'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('Added: ${DateTime.parse(tip['timestamp']).toLocal().toString().split(' ')[0]}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      ),
                    if (tip['crop'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('Crop: ${tip['crop']}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      ),
                    if (tip['category'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('Category: ${tip['category']}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      ),
                    const Divider(height: 24),
                    Text('Comments', style: TextStyle(fontWeight: FontWeight.bold)),
                    FutureBuilder<Box>(
                      future: Hive.openBox('tip_comments'),
                      builder: (context, snap) {
                        if (!snap.hasData) return const SizedBox.shrink();
                        final box = snap.data!;
                        final List comments = box.get(tip['id'], defaultValue: <Map>[]) as List;
                        if (comments.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('No comments yet.'),
                          );
                        }
                        return Column(
                          children: comments.map<Widget>((c) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.comment, size: 18),
                            title: Text(c['text'] ?? ''),
                            subtitle: Text('By: ${c['author'] ?? 'user'}', style: const TextStyle(fontSize: 11)),
                          )).toList(),
                        );
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentCtl,
                            decoration: const InputDecoration(hintText: 'Add a comment...'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () async {
                            final text = _commentCtl.text.trim();
                            if (text.isEmpty) return;
                            var box = await Hive.openBox('tip_comments');
                            final List comments = box.get(tip['id'], defaultValue: <Map>[]) as List;
                            comments.add({'text': text, 'author': widget.username, 'timestamp': DateTime.now().toIso8601String()});
                            await box.put(tip['id'], comments);
                            _commentCtl.clear();
                            setStateDialog(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share, semanticLabel: 'Share tip'),
                  tooltip: 'Share',
                  onPressed: () {
                    // Use share_plus package
                    // Share tip title and description
                    // (You must have share_plus in pubspec.yaml)
                    final text = '${tip['title']}: ${tip['description']}';
                    // ignore: deprecated_member_use
                    // Share.share(text); // Uncomment if share_plus is imported
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.flag, semanticLabel: 'Report tip'),
                  tooltip: 'Report',
                  onPressed: () async {
                    var box = await Hive.openBox('tip_reports');
                    final List reports = box.get(tip['id'], defaultValue: <Map>[]) as List;
                    reports.add({'author': widget.username, 'timestamp': DateTime.now().toIso8601String()});
                    await box.put(tip['id'], reports);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tip reported.')));
                  },
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddUserTipDialog() async {
    _userTipTitleCtl.clear();
    _userTipDescCtl.clear();
    _userTipCrop = _crops.first;
    _userTipCat = _cats.first;
    final key = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Your Tip'),
        content: Form(
          key: key,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: _userTipCrop,
              decoration: const InputDecoration(labelText: 'Crop'),
              items: _crops.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => _userTipCrop = v!,
            ),
            DropdownButtonFormField<String>(
              value: _userTipCat,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _cats.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => _userTipCat = v!,
            ),
            TextFormField(controller: _userTipTitleCtl, decoration: const InputDecoration(labelText: 'Title'), validator: (v) => v!.trim().isEmpty ? 'Required' : null),
            TextFormField(controller: _userTipDescCtl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3, validator: (v) => v!.trim().isEmpty ? 'Required' : null),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (key.currentState?.validate() != true) return;
            final id = DateTime.now().millisecondsSinceEpoch.toString();
            var box = await Hive.openBox(kTipsBox);
            await box.put(id, {
              'id': id,
              'crop': _userTipCrop,
              'category': _userTipCat,
              'title': _userTipTitleCtl.text.trim(),
              'description': _userTipDescCtl.text.trim(),
              'timestamp': DateTime.now().toIso8601String(),
              'author': widget.username,
              'status': 'pending', // Add status field for approval
              'submittedBy': widget.username,
            });
            if (mounted) setState(() {});
            if (mounted) {
              Navigator.pop(context); // Just close the add tip dialog, no confirmation dialog
            }
          }, child: const Text('Submit for Review')),
        ],
      ),
    );
  }

  Future<void> _toggleLikeTip(String tipId) async {
    var box = await Hive.openBox('liked_tips');
    final liked = box.get(tipId, defaultValue: false);
    await box.put(tipId, !liked);
    setState(() {});
  }

  Future<bool> _isTipLiked(String tipId) async {
    var box = await Hive.openBox('liked_tips');
    return box.get(tipId, defaultValue: false);
  }

  final Map<String, Map<String, String>> _categoryDescriptions = {
    'Tomato': {
      'Planting': 'Start tomato seeds indoors 6-8 weeks before the last frost for a head start.',
      'Watering & Irrigation': 'Water tomatoes deeply but less frequently to encourage strong root growth.',
      'Fertilization': 'Feed tomatoes with a balanced fertilizer every 2-3 weeks.',
      'Harvesting': 'Pick tomatoes when fully colored for best flavor.',
      'Storage': 'Store ripe tomatoes at room temperature, not in the fridge.',
      'Pest & Disease Management': 'Rotate crops and use mulch to reduce disease risk.',
      'Weed Control': 'Mulch tomato beds to suppress weeds and retain moisture.',
      'Soil Health': 'Add compost to improve soil fertility for tomatoes.',
      'Climate Advice': 'Tomatoes need full sun and warm temperatures.',
      'Market Readiness': 'Harvest tomatoes with the stem on for better shelf life.',
      'Organic Alternatives': 'Use neem oil for organic pest control on tomatoes.',
    },
    'Onion': {
      'Planting': 'Onions grow best from sets or transplants in well-drained soil.',
      'Watering & Irrigation': 'Keep soil consistently moist but not waterlogged for onions.',
      'Fertilization': 'Onions benefit from nitrogen-rich fertilizer during early growth.',
      'Harvesting': 'Harvest onions when tops fall over and begin to dry.',
      'Storage': 'Cure onions in a dry, ventilated area before storage.',
      'Pest & Disease Management': 'Rotate onions with non-allium crops to reduce disease.',
      'Weed Control': 'Keep onion beds weed-free. Onions are poor competitors with weeds.',
      'Soil Health': 'Onions prefer loose, fertile soil with good drainage.',
      'Climate Advice': 'Onions grow best in cool weather for bulbing.',
      'Market Readiness': 'Harvest onions when skins are dry for best market quality.',
      'Organic Alternatives': 'Use straw mulch for organic weed control in onions.',
    },
    'Beans': {
      'Planting': 'Direct sow beans into warm soil after the last frost.',
      'Watering & Irrigation': 'Water beans regularly, especially during flowering.',
      'Fertilization': 'Beans fix their own nitrogen and need little extra fertilizer.',
      'Harvesting': 'Pick beans regularly to encourage more production.',
      'Storage': 'Store dry beans in a cool, dry place.',
      'Pest & Disease Management': 'Rotate beans with non-legume crops to reduce disease.',
      'Weed Control': 'Mulch bean beds to suppress weeds.',
      'Soil Health': 'Beans improve soil nitrogen for future crops.',
      'Climate Advice': 'Beans prefer warm weather and full sun.',
      'Market Readiness': 'Harvest beans when pods are firm and crisp.',
      'Organic Alternatives': 'Use compost tea for organic bean fertilization.',
    },
    'Maize': {
      'Planting': 'Plant maize in blocks for better pollination.',
      'Watering & Irrigation': 'Water maize deeply during tasseling and silking.',
      'Fertilization': 'Side-dress maize with nitrogen when knee-high.',
      'Harvesting': 'Harvest maize when kernels are full and milky.',
      'Storage': 'Dry maize thoroughly before storage to prevent mold.',
      'Pest & Disease Management': 'Rotate maize with legumes to reduce pest buildup.',
      'Weed Control': 'Keep maize fields weed-free during early growth.',
      'Soil Health': 'Maize prefers fertile, well-drained soil.',
      'Climate Advice': 'Maize needs warm temperatures and full sun.',
      'Market Readiness': 'Harvest maize ears when husks are dry.',
      'Organic Alternatives': 'Use green manure cover crops before maize.',
    },
    'Potato': {
      'Planting': 'Plant only certified, disease-free seed potatoes.',
      'Watering & Irrigation': 'Keep soil evenly moist, especially during tuber formation.',
      'Fertilization': 'Potatoes benefit from phosphorus-rich fertilizer.',
      'Harvesting': 'Harvest potatoes after vines die back.',
      'Storage': 'Cure potatoes in a dark, ventilated area before storage.',
      'Pest & Disease Management': 'Rotate potatoes with non-solanaceous crops.',
      'Weed Control': 'Hill soil around potato plants to suppress weeds.',
      'Soil Health': 'Potatoes prefer loose, sandy soil.',
      'Climate Advice': 'Potatoes grow best in cool weather.',
      'Market Readiness': 'Harvest potatoes with minimal skin damage.',
      'Organic Alternatives': 'Use straw mulch for organic potato growing.',
    },
    'Cabbage': {
      'Planting': 'Transplant cabbage seedlings outdoors when they have 4-5 true leaves.',
      'Watering & Irrigation': 'Water cabbage regularly for firm heads.',
      'Fertilization': 'Cabbage is a heavy feeder; apply nitrogen fertilizer.',
      'Harvesting': 'Harvest cabbage when heads are firm and full.',
      'Storage': 'Store cabbage in a cool, humid place.',
      'Pest & Disease Management': 'Use row covers to protect cabbage from pests.',
      'Weed Control': 'Mulch cabbage beds to suppress weeds.',
      'Soil Health': 'Cabbage prefers fertile, well-drained soil.',
      'Climate Advice': 'Cabbage grows best in cool weather.',
      'Market Readiness': 'Harvest cabbage with some wrapper leaves for protection.',
      'Organic Alternatives': 'Use neem oil for organic pest control on cabbage.',
    },
    'Carrot': {
      'Planting': 'Sow carrot seeds thinly in deep, loose soil.',
      'Watering & Irrigation': 'Keep carrot beds evenly moist for best root development.',
      'Fertilization': 'Carrots need little fertilizer if soil is rich.',
      'Harvesting': 'Harvest carrots when roots are finger-sized.',
      'Storage': 'Store carrots in damp sand in a cool place.',
      'Pest & Disease Management': 'Rotate carrots with non-root crops.',
      'Weed Control': 'Mulch carrot beds to suppress weeds.',
      'Soil Health': 'Carrots prefer sandy, well-drained soil.',
      'Climate Advice': 'Carrots grow best in cool weather.',
      'Market Readiness': 'Harvest carrots with tops for better shelf life.',
      'Organic Alternatives': 'Use compost tea for organic carrot fertilization.',
    },
    'Other': {
      'Planting': 'Refer to specific crop guidelines for best planting practices.',
      'Watering & Irrigation': 'Adjust watering based on crop needs and soil type.',
      'Fertilization': 'Use balanced fertilizer for general crop health.',
      'Harvesting': 'Harvest crops at peak maturity for best quality.',
      'Storage': 'Store crops in appropriate conditions for longevity.',
      'Pest & Disease Management': 'Monitor for pests and diseases regularly.',
      'Weed Control': 'Keep fields weed-free for all crops.',
      'Soil Health': 'Maintain soil fertility with organic matter.',
      'Climate Advice': 'Adjust practices based on local climate.',
      'Market Readiness': 'Harvest and handle crops carefully for market.',
      'Organic Alternatives': 'Use organic methods where possible.',
    },
  };

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go Premium'),
        content: const Text('Upgrade to premium to unlock all features!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (kIsWeb) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.credit_card),
              label: Text('Pay with Stripe ( $priceText/year)'),
              onPressed: () async {
                const stripeUrl = 'https://checkout.stripe.com/pay/your-session-id'; // TODO: Replace with your Stripe Checkout URL
                await launchUrl(
                  Uri.parse(stripeUrl),
                  mode: LaunchMode.platformDefault,
                  webOnlyWindowName: '_self',
                );
                // After payment, user will be redirected back to your app (set return_url in Stripe)
                // You can check payment status here if needed
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.account_balance_wallet),
              label: Text('PayPal ( $priceText/year)'),
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
              label: Text('Flutterwave ( $priceText/year)'),
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
              label: Text('Pay with Stripe ( $priceText/year)'),
              onPressed: () async {
                Navigator.pop(context);
                await _payWithStripe();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stripe payment complete! Premium unlocked.')),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.account_balance_wallet),
              label: Text('PayPal ( $priceText/year)'),
              onPressed: () async {
                Navigator.pop(context);
                await _payWithPayPal();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PayPal payment complete! Premium unlocked.')),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: Text('Flutterwave ( $priceText/year)'),
              onPressed: () async {
                Navigator.pop(context);
                await _payWithFlutterwave();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Flutterwave payment complete! Premium unlocked.')),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.phone_android),
              label: Text('Mobile Money ( $priceText/year)'),
              onPressed: () async {
                Navigator.pop(context);
                _showDirectMobileMoneyDialog();
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showMobileMoneyDialog() {
    final phoneCtl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mobile Money Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your Mobile Money phone number to proceed.'),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixText: '+',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Simulate payment success
              await _setPremium(true);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mobile Money payment successful! Premium unlocked.')),
              );
            },
            child: const Text('Pay'),
          ),
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
    // TODO: Replace with your real PayPal client ID and secret
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => UsePaypal(
          sandboxMode: false, // Set to false for production
          clientId: "YOUR_REAL_PAYPAL_CLIENT_ID",
          secretKey: "YOUR_REAL_PAYPAL_SECRET",
          returnURL: "https://yourdomain.com/return",
          cancelURL: "https://yourdomain.com/cancel",
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
            await _setPremium(true);
          },
          onError: (error) {},
          onCancel: (params) {},
        ),
      ),
    );
  }

  Future<void> _payWithFlutterwave() async {
    // TODO: Replace with your real Flutterwave public key
    final Customer customer = Customer(
      name: widget.username,
      phoneNumber: "", // Optionally collect phone number
      email: widget.username,
    );

    final Flutterwave flutterwave = Flutterwave(
      publicKey: "YOUR_REAL_FLUTTERWAVE_PUBLIC_KEY",
      currency: "USD",
      redirectUrl: "https://yourdomain.com/redirect",
      txRef: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: "5",
      customer: customer,
      paymentOptions: "card, banktransfer, mobilemoney, mpesa, ussd",
      customization: Customization(title: "Premium Subscription"),
      isTestMode: false, // Set to false for production
    );

    final ChargeResponse? response = await flutterwave.charge(context);
    if (response != null && response.status == "success") {
      await _setPremium(true);
    }
  }

  Future<void> _payWithStripe() async {
    // TODO: Replace with your real backend endpoint
    final clientSecret = await fetchStripeClientSecretFromBackend();
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'InfoFarmer',
      ),
    );
    await Stripe.instance.presentPaymentSheet();
    await _setPremium(true);
  }

  Future<String> fetchStripeClientSecretFromBackend() async {
    // TODO: Replace with your real backend URL
    final response = await http.post(
      Uri.parse('https://your-backend.com/create-stripe-session'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': widget.username}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['clientSecret'] ?? data['url'];
    } else {
      throw Exception('Failed to fetch Stripe client secret');
    }
  }

  void _showDirectMobileMoneyDialog() {
    final phoneCtl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Direct Mobile Money Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your Mobile Money phone number to proceed.'),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixText: '+',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Integrate with real MTN/Airtel Mobile Money API here
              // For now, simulate success
              await _setPremium(true);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mobile Money payment successful! Premium unlocked.')),
              );
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPendingApprovals() async {
    var box = await Hive.openBox(kTipsBox);
    final List<Map> pendingTips = box.values.cast<Map>()
        .where((t) => t['status'] == 'pending')
        .toList()
      ..sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
    
    if (pendingTips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending tips to approve')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pending Approvals'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: pendingTips.length,
            itemBuilder: (context, index) {
              final tip = pendingTips[index];
              final date = DateTime.parse(tip['timestamp']).toLocal().toString().split(' ')[0];
                             return material.Card(
                 child: ListTile(
                  title: Text(tip['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tip['description']),
                      const SizedBox(height: 4),
                      Text('By: ${tip['submittedBy'] ?? 'Unknown'}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      Text('Date: $date', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      Text('Crop: ${tip['crop']} - ${tip['category']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        tooltip: 'Approve',
                        onPressed: () => _approveTip(tip['id'], true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Reject',
                        onPressed: () => _approveTip(tip['id'], false),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveTip(String tipId, bool approved) async {
    var box = await Hive.openBox(kTipsBox);
    final tip = box.get(tipId);
    if (tip != null) {
      if (approved) {
        await box.put(tipId, {
          ...tip,
          'status': 'approved',
          'approvedBy': widget.username,
          'approvedAt': DateTime.now().toIso8601String(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tip approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await box.delete(tipId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tip rejected and removed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (mounted) setState(() {});
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Enforce valid username at build time
    if (widget.username.isEmpty || widget.username == 'null') {
      Future.microtask(() {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      });
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(
        title: null,
        automaticallyImplyLeading: false,
        actions: [
          if (widget.isAdmin)
            FutureBuilder<Box>(
              future: Hive.openBox(kTipsBox),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const IconButton(
                  icon: Icon(Icons.pending_actions),
                  tooltip: 'Pending Approvals',
                  onPressed: null,
                );
                final box = snapshot.data!;
                final pendingCount = box.values.cast<Map>().where((t) => t['status'] == 'pending').length;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.pending_actions),
                      tooltip: 'Pending Approvals',
                      onPressed: _showPendingApprovals,
                    ),
                    if (pendingCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          IconButton(
            icon: Icon(_showOnlyLiked ? Icons.bookmark : Icons.bookmark_border),
            tooltip: _showOnlyLiked ? 'Show all tips' : 'Show liked tips',
            onPressed: () => setState(() => _showOnlyLiked = !_showOnlyLiked),
          ),
          IconButton(
            icon: Icon(Icons.star, color: _isPremium ? Colors.amber : Colors.grey),
            tooltip: _isPremium ? 'Premium user' : 'Go Premium',
            onPressed: _isPremium ? null : _showPremiumDialog,
          ),
        ],
      ),
      body: FutureBuilder<Box>(
        future: Hive.openBox(kTipsBox),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final box = snapshot.data!;
          final List<Map> all = box.values.cast<Map>().toList();
          // Filter tips based on approval status
          var filtered = all.where((t) {
            // Admin can see all tips (approved, pending, and admin tips)
            if (widget.isAdmin) {
              return t['crop'] == _crop && t['category'] == _cat;
            }
            // Regular users can only see approved tips and admin tips
            return t['crop'] == _crop && 
                   t['category'] == _cat && 
                   (t['status'] == 'approved' || t['author'] == 'admin' || t['status'] == null);
          }).toList()
            ..sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
          if (_showOnlyLiked) {
            // Ensure liked_tips box is open before accessing
            // If not open, open it synchronously (should be fast for small boxes)
            if (!Hive.isBoxOpen('liked_tips')) {
              // ignore: unawaited_futures
              Hive.openBox('liked_tips');
            }
            final likedBox = Hive.isBoxOpen('liked_tips') ? Hive.box('liked_tips') : null;
            if (likedBox != null) {
              filtered = filtered.where((t) => likedBox.get(t['id'], defaultValue: false)).toList();
            }
          }
          int tipLimit = _isPremium ? filtered.length : 3;
          final limitedFiltered = filtered.take(tipLimit).toList();
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crop Card (tappable to select crop)
                  GestureDetector(
                    onTap: () async {
                      final selected = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Select Crop'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView(
                              shrinkWrap: true,
                              children: _crops.map((c) => ListTile(
                                leading: _cropImages[c] != null ? SvgPicture.asset(_cropImages[c]!, width: 32, height: 32, semanticsLabel: c) : null,
                                title: Text(c),
                                selected: _crop == c,
                                onTap: () => Navigator.pop(context, c),
                              )).toList(),
                            ),
                          ),
                        ),
                      );
                      if (selected != null && selected != _crop) setState(() => _crop = selected);
                    },
                    child: material.Card(
                      color: Colors.deepPurple[50],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            if (_cropImages[_crop] != null)
                              SvgPicture.asset(_cropImages[_crop]!, width: 48, height: 48, semanticsLabel: _crop),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(_crop, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.deepPurple)),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_drop_down, color: Colors.deepPurple, semanticLabel: 'Select crop'),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(_cropDesc[_crop] ?? '', style: const TextStyle(fontSize: 15, color: Colors.black54)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _cats.map((c) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(c, style: const TextStyle(fontSize: 14)),
                          selected: _cat == c,
                          onSelected: (_) => setState(() => _cat = c),
                          selectedColor: Colors.deepPurple[100],
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Show either the info box (if tips exist) or the best practice card (if not)
                  if (limitedFiltered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: material.Card(
                          color: Colors.amber[50],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.lightbulb, color: Colors.amber, size: 28),
                                    const SizedBox(width: 8),
                                    Text('Best Practice', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[900], fontSize: 16)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(_crop, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple)),
                                Text(_cat, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.deepPurple)),
                                const SizedBox(height: 8),
                                if (_categoryDescriptions[_crop]?[_cat] != null)
                                  Text(_categoryDescriptions[_crop]?[_cat] ?? '', style: const TextStyle(fontSize: 15, color: Colors.black87)),
                                if (_catDesc[_cat] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(_catDesc[_cat]!, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Description Info Box (only if tips exist)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple[25],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.deepPurple[100]!, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _categoryDescriptions[_crop]?[_cat] ?? '',
                                style: const TextStyle(fontSize: 15, color: Colors.deepPurple, fontStyle: FontStyle.italic),
                              ),
                              if (_catDesc[_cat] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _catDesc[_cat]!,
                                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Tips List
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: limitedFiltered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final t = limitedFiltered[i];
                            final date = DateTime.parse(t['timestamp']).toLocal().toString().split(' ')[0];
                            final isAdmin = t['author'] == 'admin';
                            return material.Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 3,
                              color: isAdmin ? Colors.green[50] : Colors.white,
                              child: ListTile(
                                leading: const Icon(Icons.tips_and_updates, color: Colors.teal, size: 32),
                                title: Text(t['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(t['description'], style: const TextStyle(fontSize: 14)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(isAdmin ? 'Admin' : (t['submittedBy'] ?? 'User'), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                        const SizedBox(width: 16),
                                        Icon(Icons.calendar_today, size: 15, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(date, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: widget.isAdmin && t['status'] == 'pending'
                                  ? Chip(label: const Text('Pending', style: TextStyle(fontSize: 10)), backgroundColor: Colors.orange[100])
                                  : null,
                                onTap: () => _showTipDetails(t),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Tip'),
        onPressed: _showAddUserTipDialog,
      ),
    );
  }

  Widget _cropCard(){
    return material.Card(color:Colors.deepPurple[50],child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[
      if(_cropImages[_crop]!=null)SvgPicture.asset(_cropImages[_crop]!,width:40,height:40,semanticsLabel: _crop),
      const SizedBox(width:12),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(_crop,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18,color:Colors.deepPurple)),
        const SizedBox(height:4),
        Text(_cropDesc[_crop]??'',style:const TextStyle(fontSize:14,color:Colors.black54)),
      ]))
    ])));
  }

  Widget _catChips(){
    return SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:_cats.map((c)=>Padding(padding:const EdgeInsets.symmetric(horizontal:4),child:ChoiceChip(
      label:Text(c,style:const TextStyle(fontSize:12)),
      selected:_cat==c,
      onSelected:(_)=>setState(()=>_cat=c),
    ))).toList()));
  }

  Widget _tipsList(List<Map> tips) => ListView.builder(
    itemCount: tips.length,
    itemBuilder: (_, i) {
      final t = tips[i];
      final date = DateTime.parse(t['timestamp']).toLocal().toString().split(' ')[0];
      return FutureBuilder<bool>(
        future: SubscriptionService.isPremium(widget.username),
        builder: (context, snapshot) {
          final liked = snapshot.data ?? false;
          return InkWell(
            onTap: () => _showTipDetails(t),
            child: material.Card(
              child: ExpansionTile(
                leading: const Icon(Icons.tips_and_updates, color: Colors.teal),
                title: Row(
                  children: [
                    Expanded(child: Text(t['title'], style: const TextStyle(fontWeight: FontWeight.bold))),
                    if (widget.isAdmin && t['status'] == 'pending')
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Chip(label: Text('Pending', style: TextStyle(fontSize: 10)), backgroundColor: Colors.orange[100]),
                      ),
                    if (t['author'] != 'admin' && t['status'] == 'approved')
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Chip(label: Text('Community', style: TextStyle(fontSize: 10)), backgroundColor: Colors.blue[100]),
                      ),
                    if (t['author'] == 'admin')
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Chip(label: Text('Admin', style: TextStyle(fontSize: 10)), backgroundColor: Colors.green[100]),
                      ),
                    IconButton(
                      icon: Icon(liked ? Icons.bookmark : Icons.bookmark_border, color: liked ? Colors.orange : Colors.grey, semanticLabel: liked ? 'Remove bookmark' : 'Bookmark'),
                      tooltip: liked ? 'Remove bookmark' : 'Bookmark',
                      onPressed: () => _toggleLikeTip(t['id']),
                    ),
                  ],
                ),
                subtitle: Text(date),
                children: [
                  Padding(padding: const EdgeInsets.all(12), child: Text(t['description'])),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (t['author'] == 'admin')
                          Text('Submitted by admin', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        if (t['author'] != 'admin' && t['status'] == 'approved')
                          Text('Submitted by ${t['submittedBy'] ?? 'community member'}', style: TextStyle(fontSize: 12, color: Colors.blue[700])),
                        if (widget.isAdmin && t['status'] == 'pending')
                          Text('Submitted by ${t['submittedBy'] ?? 'community member'} - Pending approval', style: TextStyle(fontSize: 12, color: Colors.orange[700])),
                        if (t['status'] == 'approved' && t['approvedBy'] != null)
                          Text('Approved by ${t['approvedBy']} on ${DateTime.parse(t['approvedAt']).toLocal().toString().split(' ')[0]}', style: TextStyle(fontSize: 12, color: Colors.green[700])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}