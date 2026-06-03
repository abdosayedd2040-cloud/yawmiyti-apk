import 'package:flutter/material.dart';
import '../main.dart';
import 'worker_profile_screen.dart';
import 'rating_screen.dart';

const royalBlue = Color(0xFF002366);

class ApplicantsScreen extends StatefulWidget {
  final String shiftId;
  final String shiftTitle;

  const ApplicantsScreen({
    super.key,
    required this.shiftId,
    required this.shiftTitle,
  });

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  List<Map<String, dynamic>> applicants = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
    setState(() => loading = true);
    try {
      final res = await supabase
          .from('applications')
          .select('*, profiles!worker_id(id, full_name, specialty, experience_years, badge_status, rating, phone, governorate, avatar_url)')
          .eq('shift_id', widget.shiftId)
          .order('created_at', ascending: false);
      setState(() => applicants = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint('Error: $e');
    }
    setState(() => loading = false);
  }

  Future<void> _updateStatus(
    String appId, String status, Map<String, dynamic> app) async {
  try {
    await supabase.from('applications').update({
      'status': status,
      'phone_revealed': status == 'accepted',
    }).eq('id', appId);

    if (status == 'accepted') {
      await supabase.from('notifications').insert({
        'user_id': app['worker_id'] ?? '',
        'type': 'application_accepted',
        'title': ' تم قبول طلبك!',
        'body': 'مبروك! تم قبول طلبك. تواصل مع صاحب العمل الآن.',
        'is_read': false,
      });
    } else if (status == 'rejected') {
      await supabase.from('notifications').insert({
        'user_id': app['worker_id'] ?? '',
        'type': 'application_rejected',
        'title': ' تم رفض طلبك',
        'body': 'للأسف تم رفض طلبك. حاول التقديم على شيفتات أخرى.',
        'is_read': false,
      });
    }

    await _loadApplicants();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(status == 'accepted' ? ' تم القبول' : ' تم الرفض'),
      backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
    ));
  } catch (e) {
    debugPrint('Error: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          backgroundColor: royalBlue,
          title: Text('المتقدمون على: ${widget.shiftTitle}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator(color: royalBlue))
            : applicants.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('📭', style: TextStyle(fontSize: 50)),
                        SizedBox(height: 12),
                        Text('مفيش متقدمين بعد',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadApplicants,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: applicants.length,
                      itemBuilder: (_, i) => _applicantCard(applicants[i]),
                    ),
                  ),
      ),
    );
  }

  Widget _applicantCard(Map<String, dynamic> app) {
    final worker = app['profiles'] as Map<String, dynamic>?;
    final status = app['status'] ?? 'pending';
    final badge = worker?['badge_status'] ?? 'gray';

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
        children: [
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEF8),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: worker?['avatar_url'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(worker!['avatar_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person, color: royalBlue)),
                      )
                    : const Icon(Icons.person, color: royalBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(worker?['full_name'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 6),
                        Text(
                          badge == 'green' ? '👑'
                              : badge == 'blue' ? '🔵' : '⚪',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    Text(worker?['specialty'] ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                    Text(
                      '⭐ ${worker?['rating'] ?? 0} | خبرة ${worker?['experience_years'] ?? 0} سنة | ${worker?['governorate'] ?? ''}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (status == 'pending') ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkerProfileScreen(
                            workerId: worker?['id'] ?? ''),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: royalBlue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('عرض البروفايل',
                        style: TextStyle(color: royalBlue)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(app['id'], 'accepted', app),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('قبول ',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _updateStatus(app['id'], 'rejected' , app),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('رفض',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ] else if (status == 'accepted') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(worker?['phone'] ?? '',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await supabase.from('applications').update({
  'status': 'completed',
}).eq('id', app['id']);

// إغلاق الشيفت
await supabase.from('shifts').update({
  'status': 'completed',
}).eq('id', widget.shiftId);
                  await _loadApplicants();
                },
                icon: const Icon(Icons.check_circle_outline, color: royalBlue),
                label: const Text('إنهاء الشيفت',
                    style: TextStyle(color: royalBlue)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: royalBlue),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ] else if (status == 'completed') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.blue, size: 16),
                  SizedBox(width: 6),
                  Text('تم إنهاء الشيفت بنجاح ',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (app['employer_rated'] != true)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RatingScreen(
                        applicationId: app['id'],
                        toUserId: worker?['id'] ?? '',
                        toUserName: worker?['full_name'] ?? 'العامل',
                        toUserType: 'worker',
                        isEmployerRating: true,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.star, color: Colors.white),
                  label: const Text('قيّم العامل ⭐',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              )
            else
              const Text(' تم تقييم العامل',
                  style: TextStyle(color: Colors.green)),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('تم الرفض',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        ],
      ),
    );
  }
}