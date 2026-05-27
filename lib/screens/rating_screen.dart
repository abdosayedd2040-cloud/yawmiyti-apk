import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

const royalBlue = Color(0xFF002366);

class RatingScreen extends StatefulWidget {
  final String applicationId;
  final String toUserId;
  final String toUserName;
  final String toUserType;
  final bool isEmployerRating;

  const RatingScreen({
    super.key,
    required this.applicationId,
    required this.toUserId,
    required this.toUserName,
    required this.toUserType,
    this.isEmployerRating = false,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double stars = 0;
  final commentCtrl = TextEditingController();
  bool saving = false;
  String userId = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id') ?? '';
  }

  Future<void> _submitRating() async {
    if (stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك اختار عدد النجوم')));
      return;
    }
    setState(() => saving = true);
    try {
      await supabase.from('ratings').insert({
        'application_id': widget.applicationId,
        'from_user_id': userId,
        'to_user_id': widget.toUserId,
        'stars': stars.toInt(),
        'comment': commentCtrl.text.trim().isEmpty
            ? null : commentCtrl.text.trim(),
      });

      final allRatings = await supabase
          .from('ratings')
          .select('stars')
          .eq('to_user_id', widget.toUserId);

      if (allRatings.isNotEmpty) {
        final total = allRatings.fold<int>(
            0, (sum, r) => sum + (r['stars'] as int));
        final avg = total / allRatings.length;
        await supabase.from('profiles').update({
          'rating': double.parse(avg.toStringAsFixed(1)),
        }).eq('id', widget.toUserId);
      }

      // تحديث حالة التقييم
      if (widget.isEmployerRating) {
        await supabase.from('applications').update({
          'employer_rated': true,
        }).eq('id', widget.applicationId);
      } else {
        await supabase.from('applications').update({
          'worker_rated': true,
        }).eq('id', widget.applicationId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم إرسال تقييمك بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
    setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          backgroundColor: royalBlue,
          title: const Text('تقييم',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEF8),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Center(
                  child: Text(
                    widget.toUserType == 'worker' ? '👷' : '💼',
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'كيف كانت تجربتك مع\n${widget.toUserName}؟',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              RatingBar.builder(
                initialRating: stars,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 50,
                itemPadding: const EdgeInsets.symmetric(horizontal: 6),
                itemBuilder: (_, __) =>
                    const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (r) => setState(() => stars = r),
              ),
              const SizedBox(height: 12),
              Text(
                stars == 0 ? 'اختار تقييمك'
                    : stars == 1 ? '😞 سيئ جداً'
                    : stars == 2 ? '😕 سيئ'
                    : stars == 3 ? '😐 مقبول'
                    : stars == 4 ? '😊 جيد'
                    : '😄 ممتاز!',
                style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold,
                  color: stars == 0 ? Colors.grey
                      : stars <= 2 ? Colors.red
                      : stars == 3 ? Colors.orange
                      : Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تعليق (اختياري)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: royalBlue)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentCtrl,
                      textDirection: TextDirection.rtl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'اكتب تعليقك هنا...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: royalBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('إرسال التقييم ⭐',
                          style: TextStyle(
                              fontSize: 16,
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
}