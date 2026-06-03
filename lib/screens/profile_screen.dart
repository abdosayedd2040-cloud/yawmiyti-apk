import '../main.dart';
import 'legal_screen.dart';
import 'admin_screen.dart';
import 'profile_completion_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';

const royalBlue = Color(0xFF002366);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> profile = {};
  bool loading = true;
  int completedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    try {
      final res = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final completedRes = await supabase
          .from('applications')
          .select('id')
          .eq('worker_id', userId)
          .eq('status', 'completed');

      setState(() {
        profile = res;
        completedCount = completedRes.length;
      });
    } catch (e) {
      debugPrint('Error: $e');
    }
    setState(() => loading = false);
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

  String get badgeText {
    switch (profile['badge_status']) {
      case 'blue': return '🔵 موثق';
      case 'green': return '👑 موصى به';
      default: return '⚪ غير موثق';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        body: SafeArea(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: royalBlue))
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
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(36),
                              ),
                              child: const Center(
                                child: Text('👤',
                                    style: TextStyle(fontSize: 36)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(profile['full_name'] ?? '',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(
                              profile['user_type'] == 'worker'
                                  ? '👷 عامل / صنايعي'
                                  : '💼 صاحب عمل',
                              style: const TextStyle(
                                  color: Color(0xFF93C5FD), fontSize: 14),
                            ),
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

                      // بيانات الحساب
                      _section('بيانات الحساب', [
                        _infoRow(Icons.phone, 'الهاتف',
                            profile['phone'] ?? ''),
                        if (profile['backup_phone'] != null)
                          _infoRow(Icons.phone_outlined, 'رقم احتياطي',
                              profile['backup_phone']),
                        if (profile['email'] != null)
                          _infoRow(Icons.email_outlined, 'البريد',
                              profile['email']),
                      ]),

                      // بيانات العامل
                      if (profile['user_type'] == 'worker') ...[
                        const SizedBox(height: 12),
                        _section('البيانات المهنية', [
                          _infoRow(Icons.work_outline, 'التخصص',
                              profile['specialty'] ?? 'غير محدد'),
                          _infoRow(Icons.timeline, 'الخبرة',
                              '${profile['experience_years'] ?? 0} سنة'),
                          _infoRow(Icons.location_on_outlined, 'المحافظة',
                              profile['governorate'] ?? 'غير محدد'),
                        ]),
                      ],

                      // بيانات الشركة
                      if (profile['user_type'] == 'employer' &&
                          profile['employer_type'] == 'company') ...[
                        const SizedBox(height: 12),
                        _section('بيانات الشركة', [
                          _infoRow(Icons.business, 'اسم الشركة',
                              profile['company_name'] ?? ''),
                          _infoRow(Icons.numbers, 'السجل التجاري',
                              profile['commercial_register'] ?? ''),
                        ]),
                      ],

                      const SizedBox(height: 12),

                      // إكمال التوثيق
                      if (profile['badge_status'] != 'green')
                        _section('الحساب', [
                          _menuItem(Icons.verified_user_outlined,
                              'إكمال التوثيق', () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ProfileCompletionScreen()));
                          }),
                        ]),

                      const SizedBox(height: 12),

                      // الإحصائيات
                      _section('الإحصائيات', [
                        _infoRow(Icons.star_outline, 'التقييم',
                            '${profile['rating'] ?? 0} ⭐ من 5'),
                        _infoRow(Icons.check_circle_outline,
                            'الشيفتات المكتملة', '$completedCount'),
                        if ((profile['rating'] ?? 0) > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: (profile['rating'] ?? 0) / 5,
                                    backgroundColor:
                                        const Color(0xFFE5E7EB),
                                    valueColor:
                                        const AlwaysStoppedAnimation(
                                            Colors.amber),
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('${profile['rating'] ?? 0}/5',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber)),
                              ],
                            ),
                          ),
                      ]),

                      const SizedBox(height: 12),

                      // المركز القانوني
                      _section('المركز القانوني', [
                        _menuItem(Icons.gavel_outlined, 'الشروط والسياسات',
                            () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LegalScreen()));
                        }),
                      ]),

                      const SizedBox(height: 24),

                      // تسجيل الخروج
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text('تسجيل الخروج',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
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
        children: [
          Icon(icon, size: 18, color: royalBlue),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827))),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: royalBlue),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF374151))),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}