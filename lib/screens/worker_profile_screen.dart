import 'package:flutter/material.dart';
import '../main.dart';

const royalBlue = Color(0xFF002366);

class WorkerProfileScreen extends StatefulWidget {
  final String workerId;

  const WorkerProfileScreen({super.key, required this.workerId});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  Map<String, dynamic> worker = {};
  List<Map<String, dynamic>> ratings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadWorker();
  }

  Future<void> _loadWorker() async {
    try {
      final res = await supabase
          .from('profiles')
          .select()
          .eq('id', widget.workerId)
          .single();
      // جلب التقييمات
      final ratingsRes = await supabase
          .from('ratings')
          .select('stars, comment, created_at, profiles!from_user_id(full_name)')
          .eq('to_user_id', widget.workerId)
          .eq('is_hidden', false)
          .order('created_at', ascending: false);
      setState(() {
        worker = res;
        ratings = List<Map<String, dynamic>>.from(ratingsRes);
      });
    } catch (e) {
      debugPrint('Error: $e');
    }
    setState(() => loading = false);
  }

  String get badgeText {
    switch (worker['badge_status']) {
      case 'green': return '👑 موصى به';
      case 'blue': return '🔵 موثق';
      default: return '⚪ غير موثق';
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
          title: const Text('بروفايل العامل',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(color: royalBlue))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [royalBlue, Color(0xFF0A3580)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: worker['avatar_url'] != null
                                ? ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(40),
                                    child: Image.network(
                                      worker['avatar_url'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.person,
                                              color: Colors.white,
                                              size: 40),
                                    ),
                                  )
                                : const Icon(Icons.person,
                                    color: Colors.white, size: 40),
                          ),
                          const SizedBox(height: 12),
                          Text(worker['full_name'] ?? '',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(worker['specialty'] ?? '',
                              style: const TextStyle(
                                  color: Color(0xFF93C5FD),
                                  fontSize: 14)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(badgeText,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // إحصائيات
                    Row(
                      children: [
                        _statCard('⭐ التقييم',
                            '${worker['rating'] ?? 0}', Colors.orange),
                        const SizedBox(width: 10),
                        _statCard('✅ الشيفتات',
                            '${worker['completed_shifts'] ?? 0}',
                            Colors.green),
                        const SizedBox(width: 10),
                        _statCard('📅 الخبرة',
                            '${worker['experience_years'] ?? 0} سنة',
                            royalBlue),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // البيانات
                    _section('البيانات المهنية', [
                      _infoRow('التخصص',
                          worker['specialty'] ?? '-'),
                      _infoRow('المحافظة',
                          worker['governorate'] ?? '-'),
                      _infoRow('العنوان',
                          worker['address'] ?? '-'),
                    ]),

                    const SizedBox(height: 12),

                    // الصور
                    if (worker['avatar_url'] != null ||
                        worker['cv_url'] != null) ...[
                      _section('الملفات', [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (worker['avatar_url'] != null)
                                _imgPreview('صورة شخصية',
                                    worker['avatar_url']),
                              if (worker['cv_url'] != null)
                                _imgPreview('السيرة الذاتية',
                                    worker['cv_url']),
                            ],
                          ),
                        ),
                      ]),
                    ],

                    const SizedBox(height: 12),
                    if (ratings.isNotEmpty)
                      _section('التقييمات ⭐', [
                        ...ratings.map((r) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '⭐' * (r['stars'] as int),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const Spacer(),
                                  Text(
                                    r['created_at']?.toString().substring(0, 10) ?? '',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              if (r['comment'] != null) ...[
                                const SizedBox(height: 4),
                                Text(r['comment'],
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                              ],
                              const Divider(height: 12),
                            ],
                          ),
                        )).toList(),
                      ]),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
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

  Widget _imgPreview(String label, String url) {
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
                  width: 100, height: 100, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100, height: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
                  )),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}