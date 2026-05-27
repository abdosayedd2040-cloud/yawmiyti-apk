import 'rating_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'shift_detail_screen.dart';
import 'worker_profile_screen.dart';

const royalBlue = Color(0xFF002366);

class MyShiftsScreen extends StatefulWidget {
  const MyShiftsScreen({super.key});

  @override
  State<MyShiftsScreen> createState() => _MyShiftsScreenState();
}

class _MyShiftsScreenState extends State<MyShiftsScreen> {
  String userType = '';
  String userId = '';
  bool loading = true;
  List<Map<String, dynamic>> items = [];
  String selectedStatus = 'الكل';

  final workerStatuses = ['الكل', 'pending', 'accepted', 'rejected', 'completed'];
  final employerStatuses = ['الكل', 'under_review', 'active', 'closed', 'completed'];

  final statusLabels = {
    'الكل': 'الكل',
    'pending': 'في الانتظار',
    'accepted': 'مقبول',
    'rejected': 'مرفوض',
    'completed': 'مكتمل',
    'under_review': 'تحت المراجعة',
    'active': 'نشط',
    'closed': 'مغلق',
    'cancelled': 'ملغي',
  };

  final statusColors = {
    'pending': Colors.orange,
    'accepted': Colors.green,
    'rejected': Colors.red,
    'completed': Colors.blue,
    'under_review': Colors.orange,
    'active': Colors.green,
    'closed': Colors.grey,
    'cancelled': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    userType = prefs.getString('user_type') ?? '';
    userId = prefs.getString('user_id') ?? '';
    await _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => loading = true);
    try {
      if (userType == 'worker') {
        List<Map<String, dynamic>> res;
        if (selectedStatus == 'الكل') {
          res = List<Map<String, dynamic>>.from(
            await supabase
                .from('applications')
                .select('*, shifts(title, specialty_required, salary_per_shift, location_name, shift_date, status, reject_reason)')
                .eq('worker_id', userId)
                .order('created_at', ascending: false),
          );
        } else {
          res = List<Map<String, dynamic>>.from(
            await supabase
                .from('applications')
                .select('*, shifts(title, specialty_required, salary_per_shift, location_name, shift_date, status, reject_reason)')
                .eq('worker_id', userId)
                .eq('status', selectedStatus)
                .order('created_at', ascending: false),
          );
        }
        setState(() => items = res);
      } else {
        // صاحب العمل — يشوف إعلاناته
        List<Map<String, dynamic>> res;
        if (selectedStatus == 'الكل') {
          res = List<Map<String, dynamic>>.from(
            await supabase
                .from('shifts')
                .select('*, applications(count)')
                .eq('employer_id', userId)
                .order('created_at', ascending: false),
          );
        } else {
          res = List<Map<String, dynamic>>.from(
            await supabase
                .from('shifts')
                .select('*, applications(count)')
                .eq('employer_id', userId)
                .eq('status', selectedStatus)
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

  Future<void> _updateApplicationStatus(String appId, String newStatus) async {
    try {
      await supabase
          .from('applications')
          .update({
            'status': newStatus,
            'phone_revealed': newStatus == 'accepted',
          })
          .eq('id', appId);
      await _fetchItems();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newStatus == 'accepted' ? '✅ تم القبول' : '❌ تم الرفض'),
        backgroundColor: newStatus == 'accepted' ? Colors.green : Colors.red,
      ));
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  List<String> get currentStatuses =>
      userType == 'worker' ? workerStatuses : employerStatuses;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: royalBlue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      userType == 'worker' ? 'طلباتي' : 'إعلاناتي',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _fetchItems,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // فلاتر
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: currentStatuses.length,
                  itemBuilder: (_, i) {
                    final s = currentStatuses[i];
                    final active = selectedStatus == s;
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedStatus = s);
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
                            color: active
                                ? royalBlue
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          statusLabels[s] ?? s,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: active ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

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
                              itemCount: items.length,
                              itemBuilder: (_, i) => userType == 'worker'
                                  ? _workerAppCard(items[i])
                                  : _employerShiftCard(items[i]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // كارت العامل
  Widget _workerAppCard(Map<String, dynamic> app) {
    final shift = app['shifts'] as Map<String, dynamic>?;
    final status = app['status'] ?? 'pending';
    final color = statusColors[status] ?? Colors.grey;
    return Container(
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
              Expanded(
                child: Text(shift?['title'] ?? 'بدون عنوان',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabels[status] ?? status,
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.work_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(shift?['specialty_required'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const Spacer(),
              const Icon(Icons.attach_money, size: 14, color: Colors.grey),
              Text('${shift?['salary_per_shift'] ?? 0} ج',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          if (status == 'accepted') ...[
            const Divider(height: 16),
            const Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                SizedBox(width: 6),
                Text('تم القبول! تواصل مع صاحب العمل',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.green,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          if (status == 'completed') ...[
  const Divider(height: 16),
  if (app['worker_rated'] != true)
    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RatingScreen(
              applicationId: app['id'],
              toUserId: app['employer_id'],
              toUserName: 'صاحب العمل',
              toUserType: 'employer',
              isEmployerRating: false,
            ),
          ),
        ),
        icon: const Icon(Icons.star, color: Colors.white),
        label: const Text('قيّم صاحب العمل ⭐',
            style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    )
  else
    const Text('✅ تم إرسال تقييمك',
        style: TextStyle(color: Colors.green)),
],
        ],
      ),
    );
  }

  // كارت صاحب العمل - إعلاناته
  Widget _employerShiftCard(Map<String, dynamic> shift) {
    final status = shift['status'] ?? 'under_review';
    final color = statusColors[status] ?? Colors.grey;
    final canEdit = status == 'under_review';
    final applicationsData = shift['applications'];
    int appCount = 0;
    if (applicationsData is List) {
      appCount = applicationsData.length;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShiftDetailScreen(
              shift: shift,
              canEdit: canEdit,
              onUpdate: _fetchItems,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: canEdit
              ? Border.all(color: Colors.orange, width: 1.5)
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabels[status] ?? status,
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(shift['specialty_required'] ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('الأجر: ${shift['salary_per_shift'] ?? 0} ج',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                if (canEdit)
                  const Text('✏️ يمكنك التعديل',
                      style: TextStyle(
                          fontSize: 11, color: Colors.orange)),
                const Spacer(),
                if (status == 'active') ...[
                  const Icon(Icons.people_outline,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('$appCount متقدم',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios,
                    size: 12, color: Colors.grey),
              ],
            ),
            if (shift['reject_reason'] != null) ...[
              const Divider(height: 12),
              Text('❌ سبب الرفض: ${shift['reject_reason']}',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.red)),
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
          const Text('📋', style: TextStyle(fontSize: 50)),
          const SizedBox(height: 16),
          Text(
            userType == 'worker'
                ? 'مفيش طلبات بعد'
                : 'مفيش إعلانات بعد',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}