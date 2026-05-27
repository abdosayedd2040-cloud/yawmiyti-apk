import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

const royalBlue = Color(0xFF002366);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool loading = true;
  String userId = '';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _subscribeToNotifications();
  }

void _subscribeToNotifications() {
  supabase
      .channel('notifications:$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        callback: (payload) => _loadNotifications(),
      )
      .subscribe();
}

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id') ?? '';
    setState(() => loading = true);

    try {
      final res = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() => notifications = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint('$e');
    }
    setState(() => loading = false);
  }

  Future<void> _markAllRead() async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId);
      await _loadNotifications();
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> _markRead(String id) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
      setState(() {
        final idx = notifications.indexWhere((n) => n['id'] == id);
        if (idx != -1) notifications[idx]['is_read'] = true;
      });
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await supabase.from('notifications').delete().eq('id', id);
      setState(() => notifications.removeWhere((n) => n['id'] == id));
    } catch (e) {
      debugPrint('$e');
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'verification': return Icons.verified;
      case 'verification_rejected': return Icons.cancel;
      case 'shift_approved': return Icons.check_circle;
      case 'shift_rejected': return Icons.cancel;
      case 'new_application': return Icons.person_add;
      case 'application_accepted': return Icons.thumb_up;
      case 'application_rejected': return Icons.thumb_down;
      case 'new_rating': return Icons.star;
      case 'shift_completed': return Icons.task_alt;
      case 'new_shift': return Icons.work;
      default: return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'verification': return Colors.blue;
      case 'verification_rejected': return Colors.red;
      case 'shift_approved': return Colors.green;
      case 'shift_rejected': return Colors.red;
      case 'new_application': return royalBlue;
      case 'application_accepted': return Colors.green;
      case 'application_rejected': return Colors.red;
      case 'new_rating': return Colors.amber;
      case 'shift_completed': return Colors.blue;
      case 'new_shift': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _timeAgo(String createdAt) {
    final date = DateTime.parse(createdAt).toLocal();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${date.day}/${date.month}/${date.year}';
  }

  int get unreadCount =>
      notifications.where((n) => n['is_read'] == false).length;

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
                child: Row(
                  children: [
                    const Text('الإشعارات',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$unreadCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                    const Spacer(),
                    if (unreadCount > 0)
                      TextButton(
                        onPressed: _markAllRead,
                        child: const Text('قراءة الكل',
                            style: TextStyle(color: Colors.white70)),
                      ),
                    IconButton(
                      onPressed: _loadNotifications,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // المحتوى
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: royalBlue))
                    : notifications.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('🔔',
                                    style: TextStyle(fontSize: 50)),
                                SizedBox(height: 12),
                                Text('مفيش إشعارات بعد',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 16)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadNotifications,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: notifications.length,
                              itemBuilder: (_, i) =>
                                  _notificationCard(notifications[i]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notificationCard(Map<String, dynamic> notif) {
    final isRead = notif['is_read'] == true;
    final type = notif['type'] ?? '';
    final color = _getColor(type);

    return Dismissible(
      key: Key(notif['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(notif['id']),
      child: GestureDetector(
        onTap: () => _markRead(notif['id']),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: isRead
                ? null
                : Border.all(color: royalBlue.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 6)
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(_getIcon(type), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(notif['title'] ?? '',
                              style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontSize: 14)),
                        ),
                        if (!isRead)
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                              color: royalBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notif['body'] ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(
                      notif['created_at'] != null
                          ? _timeAgo(notif['created_at'])
                          : '',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}