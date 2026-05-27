import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

const royalBlue = Color(0xFF002366);

class ShiftDetailWorkerScreen extends StatefulWidget {
  final Map<String, dynamic> shift;

  const ShiftDetailWorkerScreen({super.key, required this.shift});

  @override
  State<ShiftDetailWorkerScreen> createState() =>
      _ShiftDetailWorkerScreenState();
}

class _ShiftDetailWorkerScreenState extends State<ShiftDetailWorkerScreen> {
  String userId = '';
  String badge = 'gray';
  bool loading = false;
  bool alreadyApplied = false;
  String applicationStatus = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id') ?? '';
    badge = prefs.getString('badge') ?? 'gray';
    await _checkApplied();
  }

  Future<void> _checkApplied() async {
    try {
      final res = await supabase
          .from('applications')
          .select('status')
          .eq('shift_id', widget.shift['id'])
          .eq('worker_id', userId);
      if (res.isNotEmpty) {
        setState(() {
          alreadyApplied = true;
          applicationStatus = res[0]['status'];
        });
      }
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> _apply() async {
    if (badge == 'gray') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يجب توثيق حسابك أولاً للتقديم'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await supabase.from('applications').insert({
        'shift_id': widget.shift['id'],
        'worker_id': userId,
        'employer_id': widget.shift['employer_id'],
        'status': 'pending',
      });

      setState(() {
        alreadyApplied = true;
        applicationStatus = 'pending';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم إرسال طلبك بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final shift = widget.shift;
    final employer = shift['profiles'] as Map<String, dynamic>?;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          backgroundColor: royalBlue,
          title: const Text('تفاصيل الشيفت',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header كارت
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [royalBlue, Color(0xFF0A3580)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shift['title'] ?? '',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(shift['specialty_required'] ?? '',
                        style: const TextStyle(
                            color: Color(0xFF93C5FD), fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _badge('💰 ${shift['salary_per_shift'] ?? 0} ج'),
                        const SizedBox(width: 8),
                        _badge('📍 ${shift['location_name'] ?? 'غير محدد'}'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // تفاصيل
              _section('تفاصيل الشيفت', [
                _infoRow(Icons.description_outlined, 'الوصف',
                    shift['description'] ?? 'لا يوجد وصف'),
                _infoRow(Icons.work_outline, 'التخصص المطلوب',
                    shift['specialty_required'] ?? '-'),
                _infoRow(Icons.attach_money, 'الأجر',
                    '${shift['salary_per_shift'] ?? 0} جنيه'),
                _infoRow(Icons.location_on_outlined, 'الموقع',
                    shift['location_name'] ?? '-'),
                _infoRow(Icons.map_outlined, 'المحافظة',
                    shift['governorate'] ?? '-'),
                _infoRow(Icons.calendar_today_outlined, 'تاريخ الشيفت',
                    shift['shift_date']?.toString().substring(0, 10) ?? '-'),
                _infoRow(Icons.access_time_outlined, 'وقت البداية',
                    shift['start_time']?.toString() ?? '-'),
                _infoRow(Icons.people_outline, 'عدد العمال المطلوب',
                    '${shift['workers_needed'] ?? 1} عامل'),
              ]),

              const SizedBox(height: 16),

              // بيانات صاحب العمل
              if (employer != null)
                _section('صاحب العمل', [
                  _infoRow(Icons.person_outline, 'الاسم',
                      employer['full_name'] ?? '-'),
                  _infoRow(Icons.verified_outlined, 'الشارة',
                      employer['badge_status'] == 'green'
                          ? '👑 موصى به'
                          : employer['badge_status'] == 'blue'
                              ? '🔵 موثق'
                              : '⚪ غير موثق'),
                ]),

              const SizedBox(height: 24),

              // زرار التقديم
              SizedBox(
                width: double.infinity,
                child: alreadyApplied
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: applicationStatus == 'accepted'
                              ? Colors.green[50]
                              : applicationStatus == 'rejected'
                                  ? Colors.red[50]
                                  : Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: applicationStatus == 'accepted'
                                ? Colors.green
                                : applicationStatus == 'rejected'
                                    ? Colors.red
                                    : Colors.orange,
                          ),
                        ),
                        child: Text(
                          applicationStatus == 'accepted'
                              ? '✅ تم قبولك في هذا الشيفت!'
                              : applicationStatus == 'rejected'
                                  ? '❌ تم رفض طلبك'
                                  : '⏳ طلبك قيد المراجعة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: applicationStatus == 'accepted'
                                ? Colors.green
                                : applicationStatus == 'rejected'
                                    ? Colors.red
                                    : Colors.orange,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: loading ? null : _apply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: badge == 'gray'
                              ? Colors.grey
                              : royalBlue,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                badge == 'gray'
                                    ? 'وثّق حسابك للتقديم'
                                    : 'تقديم الآن 🚀',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: royalBlue)),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: royalBlue),
          const SizedBox(width: 10),
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
}