import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'auth_screen.dart';

const royalBlue = Color(0xFF002366);

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool loading = true;

  // بيانات التوثيق
  List<Map<String, dynamic>> pendingUsers = [];

  // بيانات المستخدمين
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  String userSearchPhone = '';
  String userTypeFilter = 'الكل';
  String userStatusFilter = 'الكل';

  // بيانات الإعلانات
  List<Map<String, dynamic>> pendingShifts = [];
  List<Map<String, dynamic>> pendingServiceOffers = [];
  List<Map<String, dynamic>> allShifts = [];
  List<Map<String, dynamic>> filteredShifts = [];
  String shiftSearchPhone = '';

  // إحصائيات
  Map<String, dynamic> stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);
    await Future.wait([
      _loadPendingUsers(),
      _loadAllUsers(),
      _loadShifts(),
      _loadStats(),
    ]);
    setState(() => loading = false);
  }

  Future<void> _loadPendingUsers() async {
    try {
      final res = await supabase
          .from('profiles')
          .select()
          .eq('status', 'under_review')
          .order('created_at', ascending: false);
      setState(() => pendingUsers = List<Map<String, dynamic>>.from(res));
    } catch (e) { debugPrint('$e'); }
  }

  Future<void> _loadAllUsers() async {
    try {
      final res = await supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        allUsers = List<Map<String, dynamic>>.from(res);
        filteredUsers = allUsers;
      });
    } catch (e) { debugPrint('$e'); }
  }

Future<void> _loadShifts() async {
  try {
    final pending = await supabase
        .from('shifts')
        .select('*, profiles!employer_id(full_name, phone)')
        .eq('status', 'under_review')
        .order('created_at', ascending: false);

    final pendingOffers = await supabase
        .from('service_offers')
        .select('*, profiles!worker_id(full_name, phone, specialty)')
        .eq('status', 'under_review')
        .order('created_at', ascending: false);

    final all = await supabase
        .from('shifts')
        .select('*, profiles!employer_id(full_name, phone)')
        .order('created_at', ascending: false);

    setState(() {
      pendingShifts = List<Map<String, dynamic>>.from(pending);
      pendingServiceOffers = List<Map<String, dynamic>>.from(pendingOffers);
      allShifts = List<Map<String, dynamic>>.from(all);
      filteredShifts = allShifts;
    });
  } catch (e) {
    debugPrint('$e');
  }
}

  Future<void> _loadStats() async {
    try {
      final workers = await supabase
          .from('profiles').select('id').eq('user_type', 'worker');
      final employers = await supabase
          .from('profiles').select('id').eq('user_type', 'employer');
      final totalShifts = await supabase
          .from('shifts').select('id');
      final applications = await supabase
          .from('applications').select('id');
      final accepted = await supabase
          .from('applications').select('id').eq('status', 'accepted');
      final topSpecialties = await supabase
          .from('shifts')
          .select('specialty_required')
          .not('specialty_required', 'is', null);
      final topAreas = await supabase
          .from('shifts')
          .select('governorate')
          .not('governorate', 'is', null);

      // أعلى تقييم عمال
      final topWorkers = await supabase
          .from('profiles')
          .select('full_name, rating, completed_shifts')
          .eq('user_type', 'worker')
          .order('rating', ascending: false)
          .limit(5);

      // أعلى تقييم أصحاب عمل
      final topEmployers = await supabase
          .from('profiles')
          .select('full_name, rating, company_name')
          .eq('user_type', 'employer')
          .order('rating', ascending: false)
          .limit(5);

      // إحصاء التخصصات
      Map<String, int> specialtyCount = {};
      for (var s in topSpecialties) {
        final sp = s['specialty_required'] ?? '';
        specialtyCount[sp] = (specialtyCount[sp] ?? 0) + 1;
      }
      final sortedSpecialties = specialtyCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // إحصاء المناطق
      Map<String, int> areaCount = {};
      for (var a in topAreas) {
        final ar = a['governorate'] ?? '';
        areaCount[ar] = (areaCount[ar] ?? 0) + 1;
      }
      final sortedAreas = areaCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        stats = {
          'workers': workers.length,
          'employers': employers.length,
          'totalShifts': totalShifts.length,
          'applications': applications.length,
          'accepted': accepted.length,
          'topSpecialties': sortedSpecialties.take(5).toList(),
          'topAreas': sortedAreas.take(5).toList(),
          'topWorkers': topWorkers,
          'topEmployers': topEmployers,
        };
      });
    } catch (e) { debugPrint('$e'); }
  }

  void _filterUsers() {
    setState(() {
      filteredUsers = allUsers.where((u) {
        final phoneMatch = userSearchPhone.isEmpty ||
            (u['phone'] ?? '').contains(userSearchPhone);
        final typeMatch = userTypeFilter == 'الكل' ||
            (userTypeFilter == 'عامل' && u['user_type'] == 'worker') ||
            (userTypeFilter == 'صاحب عمل' && u['user_type'] == 'employer');
        final statusMatch = userStatusFilter == 'الكل' ||
            (userStatusFilter == 'نشط' && u['status'] == 'active') ||
            (userStatusFilter == 'معلق' && u['status'] == 'suspended') ||
            (userStatusFilter == 'محظور' && u['status'] == 'banned');
        return phoneMatch && typeMatch && statusMatch;
      }).toList();
    });
  }

  void _filterShifts() {
    setState(() {
      filteredShifts = allShifts.where((s) {
        final employer = s['profiles'] as Map<String, dynamic>?;
        final phone = employer?['phone'] ?? '';
        return shiftSearchPhone.isEmpty || phone.contains(shiftSearchPhone);
      }).toList();
    });
  }

  // ============ أحداث التوثيق ============
  Future<void> _approveUser(String userId) async {
  // جلب بيانات المستخدم
  final user = pendingUsers.firstWhere((u) => u['id'] == userId);
  final isWorker = user['user_type'] == 'worker';

  // التحقق من اكتمال البيانات الإلزامية
  bool mandatoryComplete = false;
  bool allComplete = false;

  if (isWorker) {
    mandatoryComplete = user['full_name'] != null &&
        user['phone'] != null &&
        user['id_number'] != null &&
        user['birth_date'] != null &&
        user['address'] != null &&
        user['specialty'] != null &&
        user['governorate'] != null &&
        user['avatar_url'] != null &&
        user['id_card_front'] != null &&
        user['id_card_back'] != null;

    allComplete = mandatoryComplete &&
        user['email'] != null &&
        user['cv_url'] != null &&
        user['certificates'] != null;
  } else {
    if (user['employer_type'] == 'individual') {
      mandatoryComplete = user['national_id'] != null &&
          user['phone'] != null &&
          user['full_name'] != null;
    } else {
      mandatoryComplete = user['company_name'] != null &&
          user['commercial_register'] != null &&
          user['tax_number'] != null &&
          user['company_address'] != null &&
          user['responsible_name'] != null;
    }
    allComplete = mandatoryComplete && user['email'] != null;
  }

  // لو البيانات مش مكتملة — ظهر تحذير
  if (!mandatoryComplete) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Text('⚠️', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text('تحذير',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange)),
            ],
          ),
          content: const Text(
            'هذا المستخدم لم يكمل البيانات الإلزامية بعد.\n\nهل أنت متأكد من الموافقة على التوثيق؟',
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _doApprove(userId, 'blue');
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange),
              child: const Text('موافقة رغم ذلك',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    return;
  }

  // لو البيانات الإلزامية مكتملة بس مش كلها
  if (!allComplete) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Text('ℹ️', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text('اختر نوع التوثيق',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'البيانات الإلزامية مكتملة.\nالبيانات الاختيارية غير مكتملة.\n\nاختر نوع الشارة:',
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _doApprove(userId, 'blue');
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue),
              child: const Text('🔵 موثق',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    return;
  }

  // كل البيانات مكتملة — اختر الشارة
  if (!mounted) return;
  showDialog(
    context: context,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('✅', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('اختر نوع التوثيق',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'كل البيانات مكتملة!\nاختر نوع الشارة:',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _doApprove(userId, 'blue');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue),
            child: const Text('🔵 موثق',
                style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _doApprove(userId, 'green');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green),
            child: const Text('👑 موصى به',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

Future<void> _doApprove(String userId, String badge) async {
  try {
    await supabase.from('profiles').update({
      'badge_status': badge,
      'status': 'active',
      'reject_reason': null,
    }).eq('id', userId);

    await supabase.from('notifications').insert({
      'user_id': userId,
      'type': 'verification',
      'title': badge == 'green'
          ? '👑 تهانينا! حسابك موصى به'
          : '🔵 تم توثيق حسابك!',
      'body': badge == 'green'
          ? 'مبروك! تم منحك شارة موصى به. ستظهر في مقدمة نتائج البحث.'
          : 'مبروك! تم مراجعة بياناتك والموافقة عليها.',
      'is_read': false,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(badge == 'green'
          ? '👑 تم منح شارة موصى به'
          : '🔵 تم توثيق الحساب'),
      backgroundColor: Colors.green,
    ));
    await _loadAll();
  } catch (e) {
    debugPrint('$e');
  }
}

  Future<void> _rejectUser(String userId, String reason) async {
    try {
      await supabase.from('profiles').update({
        'badge_status': 'gray',
        'status': 'active',
        'reject_reason': reason,
      }).eq('id', userId);
      await supabase.from('notifications').insert({
        'user_id': userId,
        'type': 'verification_rejected',
        'title': '❌ تم رفض طلب التوثيق',
        'body': 'سبب الرفض: $reason. يرجى تصحيح بياناتك وإعادة الإرسال.',
        'is_read': false,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفض الطلب'),
            backgroundColor: Colors.red));
      await _loadAll();
    } catch (e) { debugPrint('$e'); }
  }

  Future<void> _approveGreen(String userId) async {
    try {
      await supabase.from('profiles').update({
        'badge_status': 'green',
        'status': 'active',
      }).eq('id', userId);
      await supabase.from('notifications').insert({
        'user_id': userId,
        'type': 'verification',
        'title': '👑 تهانينا! حسابك موصى به',
        'body': 'تم منحك شارة موصى به. ستظهر في مقدمة نتائج البحث.',
        'is_read': false,
      });
      await _loadAll();
    } catch (e) { debugPrint('$e'); }
  }

  // ============ أحداث المستخدمين ============
  Future<void> _suspendUser(String userId) async {
    try {
      await supabase.from('profiles')
          .update({'status': 'suspended'}).eq('id', userId);
      await _loadAllUsers();
      _filterUsers();
    } catch (e) { debugPrint('$e'); }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await supabase.from('profiles')
          .update({'status': 'banned'}).eq('id', userId);
      await _loadAllUsers();
      _filterUsers();
    } catch (e) { debugPrint('$e'); }
  }

  Future<void> _activateUser(String userId) async {
    try {
      await supabase.from('profiles')
          .update({'status': 'active'}).eq('id', userId);
      await _loadAllUsers();
      _filterUsers();
    } catch (e) { debugPrint('$e'); }
  }

  // ============ أحداث الإعلانات ============
  Future<void> _approveShift(String shiftId, String employerId) async {
    try {
      await supabase.from('shifts')
          .update({'status': 'active'}).eq('id', shiftId);
      await supabase.from('notifications').insert({
        'user_id': employerId,
        'type': 'shift_approved',
        'title': '✅ تم نشر إعلانك',
        'body': 'تمت مراجعة إعلانك والموافقة عليه. يمكن للعمال التقديم الآن.',
        'is_read': false,
      });
      await _loadShifts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم نشر الإعلان'),
            backgroundColor: Colors.green));
    } catch (e) { debugPrint('$e'); }
  }

  Future<void> _rejectShift(String shiftId, String employerId, String reason) async {
    try {
      await supabase.from('shifts').update({
        'status': 'cancelled',
        'reject_reason': reason,
      }).eq('id', shiftId);
      await supabase.from('notifications').insert({
        'user_id': employerId,
        'type': 'shift_rejected',
        'title': '❌ تم رفض إعلانك',
        'body': 'سبب الرفض: $reason. يمكنك تعديل الإعلان وإعادة إرساله.',
        'is_read': false,
      });
      await _loadShifts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفض الإعلان'),
            backgroundColor: Colors.red));
    } catch (e) { debugPrint('$e'); }
  }

  Future<void> _deleteShift(String shiftId) async {
    try {
      await supabase.from('shifts')
          .update({'status': 'cancelled'}).eq('id', shiftId);
      await _loadShifts();
      _filterShifts();
    } catch (e) { debugPrint('$e'); }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          backgroundColor: royalBlue,
          automaticallyImplyLeading: false,
          title: const Text('لوحة التحكم 🛡️',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'تسجيل الخروج',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            isScrollable: true,
            tabs: [
              Tab(text: 'التوثيق (${pendingUsers.length})'),
              const Tab(text: 'المستخدمين'),
              Tab(text: 'الإعلانات (${pendingShifts.length})'),
              const Tab(text: 'الإحصائيات'),
            ],
          ),
        ),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(color: royalBlue))
            : TabBarView(
                controller: _tabController,
                children: [
                  _verificationTab(),
                  _usersTab(),
                  _shiftsTab(),
                  _statsTab(),
                ],
              ),
      ),
    );
  }

  // ==================== تاب التوثيق ====================
  Widget _verificationTab() {
    if (pendingUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('✅', style: TextStyle(fontSize: 50)),
            SizedBox(height: 12),
            Text('مفيش طلبات في الانتظار',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: pendingUsers.length,
        itemBuilder: (_, i) => _pendingUserCard(pendingUsers[i]),
      ),
    );
  }

  Widget _pendingUserCard(Map<String, dynamic> user) {
    final isWorker = user['user_type'] == 'worker';
    return GestureDetector(
      onTap: () => _showUserDetailModal(user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFEF3C7), width: 2),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Text(isWorker ? '👷' : '💼',
                style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['full_name'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(isWorker
                      ? '${user['specialty'] ?? ''} - ${user['governorate'] ?? ''}'
                      : user['employer_type'] == 'company'
                          ? user['company_name'] ?? ''
                          : 'فرد',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                  Text(user['phone'] ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('انتظار',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                const Text('اضغط للتفاصيل',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetailModal(Map<String, dynamic> user) {
    final rejectCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(user['user_type'] == 'worker' ? '👷' : '💼',
                        style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['full_name'] ?? '',
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold)),
                          Text(user['phone'] ?? '',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // البيانات النصية
                if (user['user_type'] == 'worker') ...[
                  _detailRow('التخصص', user['specialty'] ?? '-'),
                  _detailRow('المحافظة', user['governorate'] ?? '-'),
                  _detailRow('العنوان', user['address'] ?? '-'),
                  _detailRow('رقم الهوية', user['id_number'] ?? '-'),
                  _detailRow('تاريخ الميلاد', user['birth_date'] ?? '-'),
                  _detailRow('سنوات الخبرة',
                      '${user['experience_years'] ?? 0} سنة'),
                  _detailRow('البريد', user['email'] ?? '-'),
                ] else ...[
                  if (user['employer_type'] == 'company') ...[
                    _detailRow('اسم الشركة', user['company_name'] ?? '-'),
                    _detailRow('السجل التجاري',
                        user['commercial_register'] ?? '-'),
                    _detailRow('الرقم الضريبي', user['tax_number'] ?? '-'),
                    _detailRow('عنوان الشركة',
                        user['company_address'] ?? '-'),
                    _detailRow('المسؤول',
                        user['responsible_name'] ?? '-'),
                  ] else ...[
                    _detailRow('رقم البطاقة',
                        user['national_id'] ?? '-'),
                  ],
                ],

                // الصور
                if (user['avatar_url'] != null ||
                    user['id_card_front'] != null) ...[
                  const SizedBox(height: 12),
                  const Text('الصور المرفوعة',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: royalBlue)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (user['avatar_url'] != null)
                          _imgThumb('صورة شخصية',
                              user['avatar_url']),
                        if (user['id_card_front'] != null)
                          _imgThumb('البطاقة وجه',
                              user['id_card_front']),
                        if (user['id_card_back'] != null)
                          _imgThumb('البطاقة ظهر',
                              user['id_card_back']),
                        if (user['cv_url'] != null)
                          _imgThumb('السيرة الذاتية',
                              user['cv_url']),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // حقل سبب الرفض
                TextField(
                  controller: rejectCtrl,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'سبب الرفض (اكتب هنا إذا أردت الرفض)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _approveUser(user['id']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('قبول 🔵',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (rejectCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('من فضلك اكتب سبب الرفض')));
                            return;
                          }
                          Navigator.pop(context);
                          _rejectUser(user['id'], rejectCtrl.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('رفض ❌',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== تاب المستخدمين ====================
  Widget _usersTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                textDirection: TextDirection.rtl,
                onChanged: (v) {
                  userSearchPhone = v;
                  _filterUsers();
                },
                decoration: InputDecoration(
                  hintText: 'بحث برقم الهاتف',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _filterDropdown(
                    value: userTypeFilter,
                    items: ['الكل', 'عامل', 'صاحب عمل'],
                    onChanged: (v) {
                      userTypeFilter = v!;
                      _filterUsers();
                    },
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _filterDropdown(
                    value: userStatusFilter,
                    items: ['الكل', 'نشط', 'معلق', 'محظور'],
                    onChanged: (v) {
                      userStatusFilter = v!;
                      _filterUsers();
                    },
                  )),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAll,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredUsers.length,
              itemBuilder: (_, i) => _userManageCard(filteredUsers[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _userManageCard(Map<String, dynamic> user) {
    final badge = user['badge_status'] ?? 'gray';
    final status = user['status'] ?? 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(user['user_type'] == 'worker' ? '👷' : '💼',
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['full_name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(user['phone'] ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                    Text('⭐ ${user['rating'] ?? 0}',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(badge == 'green' ? '👑'
                      : badge == 'blue' ? '🔵' : '⚪',
                      style: const TextStyle(fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: status == 'active'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status == 'active' ? 'نشط'
                          : status == 'suspended' ? 'معلق'
                          : status == 'banned' ? 'محظور'
                          : status,
                      style: TextStyle(
                          fontSize: 11,
                          color: status == 'active'
                              ? Colors.green : Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (status == 'active') ...[
                _actionBtn('تعليق', Colors.orange,
                        () => _suspendUser(user['id'])),
                const SizedBox(width: 6),
                _actionBtn('حذف', Colors.red,
                        () => _deleteUser(user['id'])),
                const SizedBox(width: 6),
                if (badge == 'blue')
                  _actionBtn('👑 موصى به', Colors.green,
                          () => _approveGreen(user['id'])),
              ] else ...[
                _actionBtn('تفعيل', Colors.green,
                        () => _activateUser(user['id'])),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ==================== تاب الإعلانات ====================
  Widget _shiftsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  const Text('في الانتظار: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${pendingShifts.length}',
                        style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold)),
                  ),
                  // في _shiftsTab بعد قائمة الشيفتات أضف
if (pendingServiceOffers.isNotEmpty) ...[
  const Padding(
    padding: EdgeInsets.all(12),
    child: Text('عروض الخدمة تحت المراجعة',
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: royalBlue,
            fontSize: 15)),
  ),
  ...pendingServiceOffers.map((offer) => _serviceOfferAdminCard(offer)),
],
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                textDirection: TextDirection.rtl,
                onChanged: (v) {
                  shiftSearchPhone = v;
                  _filterShifts();
                },
                decoration: InputDecoration(
                  hintText: 'بحث برقم هاتف الناشر',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadShifts,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredShifts.length,
              itemBuilder: (_, i) => _shiftAdminCard(filteredShifts[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _shiftAdminCard(Map<String, dynamic> shift) {
    final employer = shift['profiles'] as Map<String, dynamic>?;
    final status = shift['status'] ?? '';
    final isPending = status == 'under_review';
    return GestureDetector(
      onTap: () => _showShiftDetailModal(shift),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPending
              ? Border.all(color: Colors.orange, width: 2)
              : null,
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(shift['title'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                _statusBadge(status),
              ],
            ),
            const SizedBox(height: 4),
            Text(shift['specialty_required'] ?? '',
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey)),
            Text('الناشر: ${employer?['full_name'] ?? ''} | ${employer?['phone'] ?? ''}',
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey)),
            Text('الأجر: ${shift['salary_per_shift'] ?? 0} ج',
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('اضغط للتفاصيل',
                    style: TextStyle(
                        fontSize: 11, color: royalBlue)),
                const Spacer(),
                _actionBtn('حذف', Colors.red,
                        () => _deleteShift(shift['id'])),
              ],
            ),
          ],
        ),
      ),
    );
  }
Widget _serviceOfferAdminCard(Map<String, dynamic> offer) {
  final worker = offer['profiles'] as Map<String, dynamic>?;
  return GestureDetector(
    onTap: () => _showServiceOfferModal(offer),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(offer['specialty'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              _statusBadge('under_review'),
            ],
          ),
          Text('العامل: ${worker?['full_name'] ?? ''} | ${worker?['phone'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text('الوصف: ${offer['description'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 2),
          const SizedBox(height: 8),
          const Text('اضغط للتفاصيل',
              style: TextStyle(fontSize: 11, color: royalBlue)),
        ],
      ),
    ),
  );
}

void _showServiceOfferModal(Map<String, dynamic> offer) {
  final rejectCtrl = TextEditingController();
  showDialog(
    context: context,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(offer['specialty'] ?? '',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: royalBlue)),
              const Divider(height: 16),
              _detailRow('الوصف', offer['description'] ?? '-'),
              _detailRow('السعر من',
                  '${offer['price_min'] ?? 0} جنيه'),
              _detailRow('السعر إلى',
                  '${offer['price_max'] ?? 0} جنيه'),
              const SizedBox(height: 12),
              TextField(
                controller: rejectCtrl,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'سبب الرفض (إذا أردت الرفض)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await supabase
                            .from('service_offers')
                            .update({'status': 'active'})
                            .eq('id', offer['id']);
                        await supabase.from('notifications').insert({
                          'user_id': offer['worker_id'],
                          'type': 'shift_approved',
                          'title': '✅ تم نشر عرض خدمتك',
                          'body': 'تمت مراجعة عرض خدمتك والموافقة عليه.',
                          'is_read': false,
                        });
                        if (!mounted) return;
                        Navigator.pop(context);
                        await _loadShifts();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('✅ تم نشر عرض الخدمة'),
                              backgroundColor: Colors.green));
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text('قبول ✅',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (rejectCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('اكتب سبب الرفض')));
                          return;
                        }
                        await supabase.from('service_offers').update({
                          'status': 'deleted',
                          'reject_reason': rejectCtrl.text,
                        }).eq('id', offer['id']);
                        await supabase.from('notifications').insert({
                          'user_id': offer['worker_id'],
                          'type': 'shift_rejected',
                          'title': '❌ تم رفض عرض خدمتك',
                          'body': 'سبب الرفض: ${rejectCtrl.text}',
                          'is_read': false,
                        });
                        if (!mounted) return;
                        Navigator.pop(context);
                        await _loadShifts();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('تم رفض عرض الخدمة'),
                              backgroundColor: Colors.red));
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red),
                      child: const Text('رفض ❌',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
  void _showShiftDetailModal(Map<String, dynamic> shift) {
    final rejectCtrl = TextEditingController();
    final employer = shift['profiles'] as Map<String, dynamic>?;
    final isPending = shift['status'] == 'under_review';
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(shift['title'] ?? '',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold,
                        color: royalBlue)),
                const Divider(height: 16),
                _detailRow('التخصص',
                    shift['specialty_required'] ?? '-'),
                _detailRow('الوصف', shift['description'] ?? '-'),
                _detailRow('الأجر',
                    '${shift['salary_per_shift'] ?? 0} جنيه'),
                _detailRow('الموقع',
                    shift['location_name'] ?? '-'),
                _detailRow('المحافظة',
                    shift['governorate'] ?? '-'),
                _detailRow('التاريخ',
                    shift['shift_date']?.toString() ?? '-'),
                _detailRow('وقت البداية',
                    shift['start_time']?.toString() ?? '-'),
                _detailRow('الناشر',
                    employer?['full_name'] ?? '-'),
                _detailRow('هاتف الناشر',
                    employer?['phone'] ?? '-'),
                const SizedBox(height: 12),
                if (isPending) ...[
                  TextField(
                    controller: rejectCtrl,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'سبب الرفض (اكتب هنا إذا أردت الرفض)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _approveShift(
                                shift['id'],
                                shift['employer_id']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(10)),
                          ),
                          child: const Text('نشر ✅',
                              style:
                              TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (rejectCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                  content: Text(
                                      'اكتب سبب الرفض')));
                              return;
                            }
                            Navigator.pop(context);
                            _rejectShift(
                                shift['id'],
                                shift['employer_id'],
                                rejectCtrl.text);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(10)),
                          ),
                          child: const Text('رفض ❌',
                              style:
                              TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== تاب الإحصائيات ====================
  Widget _statsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // أرقام رئيسية
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _statBox('👷 عمال',
                  '${stats['workers'] ?? 0}', Colors.blue),
              _statBox('💼 أصحاب عمل',
                  '${stats['employers'] ?? 0}', Colors.purple),
              _statBox('📢 إعلانات',
                  '${stats['totalShifts'] ?? 0}', Colors.orange),
              _statBox('📋 تقديمات',
                  '${stats['applications'] ?? 0}', Colors.teal),
              _statBox('✅ مقبولة',
                  '${stats['accepted'] ?? 0}', Colors.green),
              _statBox('⏳ انتظار توثيق',
                  '${pendingUsers.length}', Colors.red),
            ],
          ),

          const SizedBox(height: 16),
_sectionTitle('🔧 أكثر المهن المطلوبة'),
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    children: (stats['topSpecialties'] as List? ?? [])
        .map((e) => _rankRow(e.key, e.value))
        .toList(),
  ),
),

const SizedBox(height: 16),
_sectionTitle('📍 أكثر المناطق طلباً'),
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    children: (stats['topAreas'] as List? ?? [])
        .map((e) => _rankRow(e.key, e.value))
        .toList(),
  ),
),

          const SizedBox(height: 16),

          // أعلى عمال تقييماً
          _sectionTitle('⭐ أعلى 5 عمال تقييماً'),
          ...(stats['topWorkers'] as List? ?? []).map((w) =>
              _rankRow(
                  w['full_name'] ?? '',
                  (w['rating'] ?? 0).toDouble(),
                  isRating: true)),

          const SizedBox(height: 16),

          // أعلى أصحاب عمل تقييماً
          _sectionTitle('⭐ أعلى 5 أصحاب عمل تقييماً'),
          ...(stats['topEmployers'] as List? ?? []).map((e) =>
              _rankRow(
                  e['company_name'] ?? e['full_name'] ?? '',
                  (e['rating'] ?? 0).toDouble(),
                  isRating: true)),
        ],
      ),
    );
  }

  // ==================== Helpers ====================
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _imgThumb(String label, String url) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => Dialog(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(url,
                  width: 80, height: 80, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80, height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
                  )),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'under_review': color = Colors.orange; label = 'انتظار'; break;
      case 'active': color = Colors.green; label = 'نشط'; break;
      case 'cancelled': color = Colors.red; label = 'مرفوض'; break;
      case 'completed': color = Colors.blue; label = 'مكتمل'; break;
      default: color = Colors.grey; label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _filterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 8),
      ),
      items: items.map((e) => DropdownMenuItem(
        value: e,
        child: Text(e, style: const TextStyle(fontSize: 13)),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: royalBlue)),
    );
  }

  Widget _rankRow(String label, dynamic value,
      {bool isRating = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13)),
          ),
          Text(
            isRating
                ? '⭐ $value'
                : '$value مرة',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: royalBlue),
          ),
        ],
      ),
    );
  }
}