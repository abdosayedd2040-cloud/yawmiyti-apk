import 'service_offer_detail_screen.dart';
import 'shift_detail_worker_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

const royalBlue = Color(0xFF002366);

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String userType = '';
  String userId = '';
  String badge = '';
  bool loading = true;
  List<Map<String, dynamic>> items = [];
  String searchQuery = '';
  String selectedSpecialty = '';

  final specialties = [
    'الكل', 'كهربائي', 'سباك', 'نجار', 'دهان', 'ميكانيكي',
    'لحام', 'تكييف وتبريد', 'بناء', 'سائق', 'أمن وحراسة',
    'تنظيف', 'طباخ', 'أخرى'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    userType = prefs.getString('user_type') ?? '';
    userId = prefs.getString('user_id') ?? '';
    badge = prefs.getString('badge') ?? 'gray';
    await _fetchItems();
  }

Future<void> _fetchItems() async {
  setState(() => loading = true);
  try {
    if (userType == 'worker') {
      List<Map<String, dynamic>> res;
      if (selectedSpecialty.isEmpty || selectedSpecialty == 'الكل') {
        res = List<Map<String, dynamic>>.from(
          await supabase
              .from('shifts')
              .select('*, profiles!employer_id(full_name, badge_status)')
              .eq('status', 'active')
              .order('created_at', ascending: false),
        );
      } else {
        res = List<Map<String, dynamic>>.from(
          await supabase
              .from('shifts')
              .select('*, profiles!employer_id(full_name, badge_status)')
              .eq('status', 'active')
              .eq('specialty_required', selectedSpecialty)
              .order('created_at', ascending: false),
        );
      }
      setState(() => items = res);
    } else {
      List<Map<String, dynamic>> res;
      if (selectedSpecialty.isEmpty || selectedSpecialty == 'الكل') {
        res = List<Map<String, dynamic>>.from(
          await supabase
              .from('service_offers')
              .select('*, profiles!worker_id(full_name, badge_status, specialty, experience_years)')
              .eq('status', 'active')
              .order('created_at', ascending: false),
        );
      } else {
        res = List<Map<String, dynamic>>.from(
          await supabase
              .from('service_offers')
              .select('*, profiles!worker_id(full_name, badge_status, specialty, experience_years)')
              .eq('status', 'active')
              .eq('specialty', selectedSpecialty)
              .order('created_at', ascending: false),
        );
      }
      setState(() => items = res);
    }
  } catch (e) {
    debugPrint('Error: $e');
  }
  setState(() => loading = false);
}

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: royalBlue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            userType == 'worker' ? 'الشيفتات المتاحة' : 'عروض الخدمة',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        IconButton(
                          onPressed: _fetchItems,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // البحث
                    TextField(
                      textDirection: TextDirection.rtl,
                      onChanged: (v) => setState(() => searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'ابحث...',
                        hintTextDirection: TextDirection.rtl,
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),

              // فلاتر التخصص
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: specialties.length,
                  itemBuilder: (_, i) {
                    final s = specialties[i];
                    final active = selectedSpecialty == s ||
                        (s == 'الكل' && selectedSpecialty.isEmpty);
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedSpecialty = s == 'الكل' ? '' : s);
                        _fetchItems();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: active ? royalBlue : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? royalBlue : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(s,
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold,
                            color: active ? Colors.white : Colors.grey,
                          )),
                      ),
                    );
                  },
                ),
              ),

              // المحتوى
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: royalBlue))
                    : items.isEmpty
                        ? _emptyState()
                        : RefreshIndicator(
                            onRefresh: _fetchItems,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: items.where((item) {
                                if (searchQuery.isEmpty) return true;
                                final title = (userType == 'worker'
                                    ? item['title']
                                    : item['specialty']) ?? '';
                                return title.toString().contains(searchQuery);
                              }).length,
                              itemBuilder: (_, i) {
                                final filtered = items.where((item) {
                                  if (searchQuery.isEmpty) return true;
                                  final title = (userType == 'worker'
                                      ? item['title']
                                      : item['specialty']) ?? '';
                                  return title.toString().contains(searchQuery);
                                }).toList();
                                return userType == 'worker'
                                    ? _shiftCard(filtered[i])
                                    : _workerCard(filtered[i]);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
        floatingActionButton: badge != 'gray'
            ? FloatingActionButton.extended(
                backgroundColor: royalBlue,
                onPressed: () => _showAddSheet(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  userType == 'worker' ? 'إضافة خدمة' : 'إضافة إعلان',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
    );
  }

  Widget _shiftCard(Map<String, dynamic> shift) {
    final employer = shift['profiles'] as Map<String, dynamic>?;
  return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShiftDetailWorkerScreen(shift: shift),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEF8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                      child: Text('💼', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shift['title'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(shift['specialty_required'] ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${shift['salary_per_shift'] ?? 0} ج',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF16A34A),
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(shift['location_name'] ?? 'غير محدد',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(shift['shift_date']?.toString().substring(0, 10) ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            if (employer != null) ...[
              const Divider(height: 16),
              Row(
                children: [
                  Text('صاحب العمل: ${employer['full_name'] ?? ''}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                  const Text('اضغط للتفاصيل',
                      style: TextStyle(fontSize: 11, color: royalBlue)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

Widget _workerCard(Map<String, dynamic> offer) {
  final worker = offer['profiles'] as Map<String, dynamic>?;
  return GestureDetector(
    onTap: userType == 'employer'
        ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServiceOfferDetailScreen(offer: offer),
              ),
            )
        : null,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEF8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                    child: Text('👷', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(worker?['full_name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(offer['specialty'] ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text(
                worker?['badge_status'] == 'green'
                    ? '👑'
                    : worker?['badge_status'] == 'blue'
                        ? '🔵'
                        : '⚪',
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(offer['description'] ?? '',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF374151)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.attach_money, size: 14, color: Colors.grey),
              Text(
                '${offer['price_min'] ?? 0} - ${offer['price_max'] ?? 0} ج',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Spacer(),
              Text(
                'خبرة: ${worker?['experience_years'] ?? 0} سنة',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          if (userType == 'employer') ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: royalBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('عرض التفاصيل',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 50)),
          const SizedBox(height: 16),
          Text(
            userType == 'worker'
                ? 'مفيش شيفتات متاحة دلوقتي'
                : 'مفيش عروض خدمة دلوقتي',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _fetchItems,
            child: const Text('تحديث', style: TextStyle(color: royalBlue)),
          ),
        ],
      ),
    );
  }

  Future<void> _applyShift(String shiftId) async {
    try {
      // تحقق مش متقدم قبل كده
      final existing = await supabase
          .from('applications')
          .select('id')
          .eq('shift_id', shiftId)
          .eq('worker_id', userId);

      if (existing.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('أنت متقدم على هذا الشيفت بالفعل'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // جلب employer_id
      final shift = await supabase
          .from('shifts')
          .select('employer_id')
          .eq('id', shiftId)
          .single();

      await supabase.from('applications').insert({
        'shift_id': shiftId,
        'worker_id': userId,
        'employer_id': shift['employer_id'],
        'status': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم إرسال طلبك بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => userType == 'worker'
          ? _AddServiceSheet(userId: userId, onDone: _fetchItems)
          : _AddShiftSheet(userId: userId, onDone: _fetchItems),
    );
  }
}

// ==================== إضافة شيفت ====================
class _AddShiftSheet extends StatefulWidget {
  final String userId;
  final VoidCallback onDone;
  const _AddShiftSheet({required this.userId, required this.onDone});

  @override
  State<_AddShiftSheet> createState() => _AddShiftSheetState();
}

class _AddShiftSheetState extends State<_AddShiftSheet> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final salaryCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  String specialty = '';
  bool loading = false;

  final specialties = [
    'كهربائي', 'سباك', 'نجار', 'دهان', 'ميكانيكي',
    'لحام', 'تكييف وتبريد', 'بناء', 'سائق', 'أخرى'
  ];

  Future<void> _submit() async {
  if (titleCtrl.text.isEmpty || salaryCtrl.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('من فضلك اكمل البيانات المطلوبة')));
    return;
  }
  setState(() => loading = true);
  try {
    await supabase.from('shifts').insert({
      'employer_id': widget.userId,
      'title': titleCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'specialty_required': specialty,
      'salary_per_shift': double.tryParse(salaryCtrl.text) ?? 0,
      'location_name': locationCtrl.text.trim(),
      'status': 'under_review',
      'shift_date': DateTime.now().toIso8601String().substring(0, 10),
    });
    if (!mounted) return;
    Navigator.pop(context);
    widget.onDone();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ تم إرسال الإعلان للمراجعة'),
        backgroundColor: Colors.orange,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
  }
  setState(() => loading = false);
}

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إضافة إعلان جديد',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: royalBlue)),
              const SizedBox(height: 16),
              _field('عنوان الشيفت *', titleCtrl),
              _field('وصف العمل', descCtrl, maxLines: 3),
              _field('الأجر (جنيه) *', salaryCtrl,
                  keyboard: TextInputType.number),
              _field('الموقع', locationCtrl),
              const Text('التخصص المطلوب',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 13, color: Color(0xFF374151))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: specialties.map((s) {
                  final active = specialty == s;
                  return GestureDetector(
                    onTap: () => setState(() => specialty = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? royalBlue : Colors.white,
                        border: Border.all(
                          color: active ? royalBlue : const Color(0xFFE2E8F0),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(s,
                          style: TextStyle(
                              fontSize: 12,
                              color: active ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: royalBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('نشر الإعلان ✅',
                          style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13,
              color: Color(0xFF374151))),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboard,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: royalBlue, width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== إضافة خدمة ====================
class _AddServiceSheet extends StatefulWidget {
  final String userId;
  final VoidCallback onDone;
  const _AddServiceSheet({required this.userId, required this.onDone});

  @override
  State<_AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends State<_AddServiceSheet> {
  final descCtrl = TextEditingController();
  final minPriceCtrl = TextEditingController();
  final maxPriceCtrl = TextEditingController();
  String specialty = '';
  bool loading = false;

  final specialties = [
    'كهربائي', 'سباك', 'نجار', 'دهان', 'ميكانيكي',
    'لحام', 'تكييف وتبريد', 'بناء', 'سائق', 'أخرى'
  ];

  Future<void> _submit() async {
  if (specialty.isEmpty || descCtrl.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('من فضلك اكمل البيانات المطلوبة')));
    return;
  }
  setState(() => loading = true);
  try {
    await supabase.from('service_offers').insert({
      'worker_id': widget.userId,
      'specialty': specialty,
      'description': descCtrl.text.trim(),
      'price_min': double.tryParse(minPriceCtrl.text) ?? 0,
      'price_max': double.tryParse(maxPriceCtrl.text) ?? 0,
      'status': 'under_review',
    });
    if (!mounted) return;
    Navigator.pop(context);
    widget.onDone();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ تم إرسال عرض خدمتك للمراجعة'),
        backgroundColor: Colors.orange,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
  }
  setState(() => loading = false);
}

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إضافة عرض خدمة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: royalBlue)),
              const SizedBox(height: 16),
              const Text('التخصص *',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 13, color: Color(0xFF374151))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: specialties.map((s) {
                  final active = specialty == s;
                  return GestureDetector(
                    onTap: () => setState(() => specialty = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? royalBlue : Colors.white,
                        border: Border.all(
                          color: active ? royalBlue : const Color(0xFFE2E8F0),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(s,
                          style: TextStyle(
                              fontSize: 12,
                              color: active ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _field('وصف خدمتك *', descCtrl, maxLines: 3),
              Row(
                children: [
                  Expanded(child: _field('أقل سعر', minPriceCtrl,
                      keyboard: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('أعلى سعر', maxPriceCtrl,
                      keyboard: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: royalBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('نشر الخدمة ✅',
                          style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13,
              color: Color(0xFF374151))),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboard,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: royalBlue, width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}