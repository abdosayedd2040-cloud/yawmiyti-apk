import 'notifications_screen.dart';
import 'profile_completion_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'auth_screen.dart';
import 'marketplace_screen.dart';
import 'my_shifts_screen.dart';
import 'profile_screen.dart';

const royalBlue = Color(0xFF002366);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentTab = 0;
  String name = '';
  String userType = '';
  String badge = 'gray';
  String userId = '';
  bool loading = true;
  int unreadNotifications = 0;
  double userRating = 0;
  List<Map<String, dynamic>> recentItems = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('user_name') ?? '';
      userType = prefs.getString('user_type') ?? '';
      userId = prefs.getString('user_id') ?? '';
      badge = prefs.getString('badge') ?? 'gray';
    });

    try {
      final res = await supabase
          .from('profiles')
          .select('badge_status, full_name, rating')
          .eq('id', userId)
          .single();

      final newBadge = res['badge_status'] ?? 'gray';
      await prefs.setString('badge', newBadge);
      await prefs.setString('user_name', res['full_name'] ?? name);

      setState(() {
        badge = newBadge;
        name = res['full_name'] ?? name;
        userRating = (res['rating'] ?? 0).toDouble();
      });
    } catch (e) {
      debugPrint('$e');
    }

    await _loadRecentItems();
    await _loadUnreadCount();
    setState(() => loading = false);
  }

  Future<void> _loadUnreadCount() async {
    try {
      final res = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
      setState(() => unreadNotifications = res.length);
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> _loadRecentItems() async {
    try {
      if (userType == 'employer') {
        final res = await supabase
            .from('shifts')
            .select()
            .eq('employer_id', userId)
            .order('created_at', ascending: false)
            .limit(3);
        setState(() => recentItems = List<Map<String, dynamic>>.from(res));
      } else {
        final res = await supabase
            .from('applications')
            .select('*, shifts(*)')
            .eq('worker_id', userId)
            .order('created_at', ascending: false)
            .limit(3);
        setState(() => recentItems = List<Map<String, dynamic>>.from(res));
      }
    } catch (e) {
      debugPrint('$e');
    }
  }

  String get badgeText {
    switch (badge) {
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
              : IndexedStack(
                  index: currentTab,
                  children: [
                    _buildHome(),
                    const MarketplaceScreen(),
                    const MyShiftsScreen(),
                    const ProfileScreen(),
                  ],
                ),
        ),
        bottomNavigationBar: _buildNavBar(),
      ),
    );
  }

  Widget _buildHome() {
    return RefreshIndicator(
      onRefresh: _loadUser,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [royalBlue, Color(0xFF0A3580)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('أهلاً، $name ',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          userType == 'worker'
                              ? ' عامل / صنايعي'
                              : ' صاحب عمل',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF93C5FD)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(badgeText,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NotificationsScreen()),
                          );
                          await _loadUnreadCount();
                        },
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 28),
                      ),
                      if (unreadNotifications > 0)
                        Positioned(
                          right: 8, top: 8,
                          child: Container(
                            width: 16, height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('$unreadNotifications',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('⚡', style: TextStyle(fontSize: 26)),
                    ),
                  ),
                ],
              ),
            ),

            if (badge == 'gray') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('حسابك غير موثق',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E))),
                          Text('أكمل بياناتك للحصول على الشارة الزرقاء',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF92400E))),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ProfileCompletionScreen())),
                      child: const Text('إكمال',
                          style: TextStyle(
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            if (userType == 'worker')
              Row(
                children: [
                  _statCard('طلباتي', '${recentItems.length}',
                      Icons.work_outline, Colors.blue),
                  const SizedBox(width: 12),
                  _statCard('مقبول', '0',
                      Icons.check_circle_outline, Colors.green),
                  const SizedBox(width: 12),
                  _statCard('تقييمي', '$userRating ⭐',
                      Icons.star_outline, Colors.orange),
                ],
              ),

            if (userType == 'employer')
              Row(
                children: [
                  _statCard('إعلاناتي', '${recentItems.length}',
                      Icons.campaign_outlined, Colors.blue),
                  const SizedBox(width: 12),
                  _statCard('نشط', '0',
                      Icons.check_circle_outline, Colors.green),
                  const SizedBox(width: 12),
                  _statCard('تقييمي', '$userRating ⭐',
                      Icons.star_outline, Colors.orange),
                ],
              ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  userType == 'worker' ? 'آخر طلباتي' : 'آخر إعلاناتي',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827)),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('عرض الكل',
                      style: TextStyle(color: royalBlue)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            recentItems.isEmpty
                ? _emptyState()
                : Column(
                    children: recentItems
                        .map((item) => _itemCard(item))
                        .toList()),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 نصيحة اليوم',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: royalBlue)),
                  const SizedBox(height: 6),
                  Text(
                    userType == 'worker'
                        ? 'أكمل بياناتك للحصول على فرص أكثر وظهور أفضل في نتائج البحث'
                        : 'أضف وصفاً تفصيلياً لإعلانك لجذب أفضل العمال',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF1E40AF)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 8)
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Center(
        child: Column(
          children: [
            const Text('📭', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              userType == 'worker'
                  ? 'لم تتقدم على أي شيفت بعد'
                  : 'لم تنشر أي إعلان بعد',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(Map<String, dynamic> item) {
    final shift = userType == 'worker' ? item['shifts'] : item;
    if (shift == null) return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEF8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
                child: Text('💼', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shift['title'] ?? 'بدون عنوان',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(shift['specialty_required'] ?? '',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(shift['status'] ?? 'active',
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return BottomNavigationBar(
      currentIndex: currentTab,
      onTap: (i) => setState(() => currentTab = i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: royalBlue,
      unselectedItemColor: Colors.grey,
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.search), label: 'الإعلانات'),
        BottomNavigationBarItem(
          icon: const Icon(Icons.assignment_outlined),
          label: userType == 'employer' ? 'إعلاناتي' : 'طلباتي',
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'حسابي'),
      ],
    );
  }
}