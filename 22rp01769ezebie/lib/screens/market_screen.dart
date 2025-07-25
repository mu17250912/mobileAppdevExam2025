import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:hive/hive.dart';
import 'package:infofarmer/screens/login_screen.dart';

/// MarketScreen displays current crop prices. Only admin can add/delete.
/// Regular users can filter and view entries.
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key, required this.isAdmin});
  final bool isAdmin;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  // ───────────────────────────────── crop filter
  final _crops = <String>[
    'Maize',
    'Beans',
    'Tomato',
    'Potato',
    'Cabbage',
    'Carrot',
    'Onion',
    'Other',
  ];
  String _selectedCrop = 'Maize';

  // ───────────────────────────────── admin form controllers
  final _itemCtl       = TextEditingController();
  final _unitCtl       = TextEditingController();
  final _marketCtl     = TextEditingController();
  final _minCtl        = TextEditingController();
  final _maxCtl        = TextEditingController();
  final _avgCtl        = TextEditingController();
  final _sourceCtl     = TextEditingController();
  DateTime _date       = DateTime.now();
  bool _saving         = false;

  @override
  void dispose() {
    for (final c in [_itemCtl,_unitCtl,_marketCtl,_minCtl,_maxCtl,_avgCtl,_sourceCtl]) c.dispose();
    super.dispose();
  }

  // ───────────────────────────────── helpers
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    // basic validation
    if ([ _itemCtl, _unitCtl, _marketCtl, _minCtl, _maxCtl, _avgCtl ].any((c)=>c.text.trim().isEmpty)){
      _snack('Please fill all required fields');
      return;
    }
    setState(()=>_saving=true);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    var box = await Hive.openBox('prices_box');
    final priceEntry = {
      'id': id,
      'itemName': _itemCtl.text.trim(),
      'unit': _unitCtl.text.trim(),
      'marketName': _marketCtl.text.trim(),
      'priceMin': double.tryParse(_minCtl.text) ?? 0,
      'priceMax': double.tryParse(_maxCtl.text) ?? 0,
      'priceAvg': double.tryParse(_avgCtl.text) ?? 0,
      'date': _date.toIso8601String(),
      'source': _sourceCtl.text.trim().isEmpty ? null : _sourceCtl.text.trim(),
      'author': widget.isAdmin ? 'admin' : 'user',
    };
    print('Saving price entry: ' + priceEntry.toString());
    await box.put(id, priceEntry);
    _snack('Price entry saved');
    for (final c in [_itemCtl,_unitCtl,_marketCtl,_minCtl,_maxCtl,_avgCtl,_sourceCtl]) c.clear();
    setState(()=>_saving=false);
  }

  void _snack(String m)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // ───────────────────────────────── ui
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: null,
        automaticallyImplyLeading: false,
        actions: [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: widget.isAdmin
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _AdminForm(
                      itemCtl: _itemCtl,
                      unitCtl: _unitCtl,
                      marketCtl: _marketCtl,
                      minCtl: _minCtl,
                      maxCtl: _maxCtl,
                      avgCtl: _avgCtl,
                      sourceCtl: _sourceCtl,
                      date: _date,
                      pickDate: _pickDate,
                      onSave: _save,
                      saving: _saving,
                      crops: _crops,
                      selectedCrop: _selectedCrop,
                      onCropChanged: (v) => setState(() => _selectedCrop = v!),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 600;
                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: _PricesList(crop: _selectedCrop, isAdmin: widget.isAdmin),
                        );
                      },
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _UserNotice(),
                  const SizedBox(height: 16),
                  Expanded(child: _PricesList(crop: _selectedCrop, isAdmin: widget.isAdmin)),
                ],
              ),
      ),
    );
  }

  Row _buildHeader(){
    return Row(children:[
      const Icon(Icons.shopping_basket,color:Colors.orange,size:32, semanticLabel: 'Market Prices'),
      const SizedBox(width:8),
      DropdownButton<String>(
        value:_selectedCrop,
        items:_crops.map((c)=>DropdownMenuItem(value:c,child:Text(c))).toList(),
        onChanged:(v)=>setState(()=>_selectedCrop=v!),
      ),
    ]);
  }
}

// ───────────────────────────────── PRICES LIST
class _PricesList extends StatelessWidget{
  const _PricesList({required this.crop,required this.isAdmin});
  final String crop;
  final bool isAdmin;
  @override
  Widget build(BuildContext context){
    return FutureBuilder<Box>(
      future: Hive.openBox('prices_box'),
      builder:(context,snapshot){
        if(!snapshot.hasData) return const Center(child:CircularProgressIndicator());
        final box = snapshot.data!;
        final data = box.values.toList(); // Show all prices for all crops
        if(data.isEmpty) {
          return const Center(child:Text('No price entries found.'));
        }
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: data.length,
          itemBuilder: (c, i) {
            final e = data[data.length - 1 - i];
            final date = DateTime.parse(e['date']).toLocal();
            final avg = e['priceAvg'] ?? 0;
            final min = e['priceMin'] ?? 0;
            final max = e['priceMax'] ?? 0;
            final unit = e['unit'] ?? '';
            final source = e['source'];
            return Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_basket, color: Colors.orange, semanticLabel: 'Market Prices'),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${e['itemName']} - ${e['marketName']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'RWF ${avg.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.deepOrange),
                    ),
                    Text(
                      unit,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Range: RWF ${min.toStringAsFixed(0)} - RWF ${max.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text('Date: ${date.toString().split(' ')[0]}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (source != null && source.toString().isNotEmpty)
                      Text('Source: $source', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (isAdmin)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: IconButton(
                          icon: Icon(Icons.delete, semanticLabel: 'Delete entry'),
                          tooltip: 'Delete entry',
                          onPressed: () async {
                            await box.delete(e['id']);
                            (context as Element).markNeedsBuild();
                          },
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
}

// ───────────────────────────────── ADMIN ONLY FORM
class _AdminForm extends StatelessWidget{
  const _AdminForm({
    required this.itemCtl,required this.unitCtl,required this.marketCtl,
    required this.minCtl,required this.maxCtl,required this.avgCtl,
    required this.sourceCtl,required this.date,required this.pickDate,
    required this.onSave,required this.saving,
    required this.crops,required this.selectedCrop,required this.onCropChanged});

  final TextEditingController itemCtl,unitCtl,marketCtl,minCtl,maxCtl,avgCtl,sourceCtl;
  final DateTime date;final VoidCallback pickDate;final VoidCallback onSave;final bool saving;
  final List<String> crops;
  final String selectedCrop;
  final ValueChanged<String?> onCropChanged;

  @override
  Widget build(BuildContext context){
    return Card(
      elevation:3,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),
      child:Padding(
        padding:const EdgeInsets.all(16),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Add price entry',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
          const SizedBox(height:12),
          // Use dropdown for crop selection
          DropdownButtonFormField<String>(
            value: selectedCrop,
            decoration: const InputDecoration(labelText: 'Crop'),
            items: crops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: onCropChanged,
          ),
          _f(unitCtl,'Unit (e.g. per kg)'),
          _f(marketCtl,'Market/location'),
          Row(children:[Expanded(child:_f(minCtl,'Min',num:true)),const SizedBox(width:8),Expanded(child:_f(maxCtl,'Max',num:true))]),
          _f(avgCtl,'Average',num:true),
          ListTile(title:Text('Date: ${date.toLocal().toString().split(' ')[0]}'),trailing:const Icon(Icons.calendar_today),onTap:pickDate),
          _f(sourceCtl,'Source (optional)'),
          const SizedBox(height:12),
          SizedBox(width:double.infinity,child:ElevatedButton(onPressed:saving?null:onSave,child:saving?const CircularProgressIndicator():const Text('Save'))),
        ]),
      ),
    );
  }
  Widget _f(TextEditingController c,String l,{bool num=false})=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:TextField(controller:c,keyboardType:num?TextInputType.number:TextInputType.text,decoration:InputDecoration(labelText:l,border:OutlineInputBorder(borderRadius:BorderRadius.circular(10)))));
}

// ───────────────────────────────── USER NOTICE
class _UserNotice extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return Container(
      padding:const EdgeInsets.all(12),
      decoration:BoxDecoration(color:Colors.orange[100],borderRadius:BorderRadius.circular(8)),
      child:const Text('Price data is managed by the administrator. You can only view the latest updates.',style:TextStyle(color:Colors.black87)),
    );
  }
}
