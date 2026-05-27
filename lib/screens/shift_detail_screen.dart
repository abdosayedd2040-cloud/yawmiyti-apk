import 'package:flutter/material.dart';
import '../main.dart';
import 'applicants_screen.dart';

const royalBlue = Color(0xFF002366);

class ShiftDetailScreen extends StatefulWidget {
  final Map<String, dynamic> shift;
  final bool canEdit;
  final VoidCallback onUpdate;

  const ShiftDetailScreen({
    super.key,
    required this.shift,
    required this.canEdit,
    required this.onUpdate,
  });

  @override
  State<ShiftDetailScreen> createState() => _ShiftDetailScreenState();
}

class _ShiftDetailScreenState extends State<ShiftDetailScreen> {
  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;
  late TextEditingController salaryCtrl;
  late TextEditingController locationCtrl;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(
        text: widget.shift['title'] ?? '');
    descCtrl = TextEditingController(
        text: widget.shift['description'] ?? '');
    salaryCtrl = TextEditingController(
        text: '${widget.shift['salary_per_shift'] ?? ''}');
    locationCtrl = TextEditingController(
        text: widget.shift['location_name'] ?? '');
  }

  Future<void> _saveEdit() async {
    setState(() => saving = true);
    try {
      await supabase.from('shifts').update({
        'title': titleCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'salary_per_shift': double.tryParse(salaryCtrl.text) ?? 0,
        'location_name': locationCtrl.text.trim(),
        'status': 'under_review',
      }).eq('id', widget.shift['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم حفظ التعديلات وإعادة الإرسال للمراجعة'),
          backgroundColor: Colors.orange,
        ),
      );
      widget.onUpdate();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'),
            backgroundColor: Colors.red));
    }
    setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.shift['status'] ?? '';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          backgroundColor: royalBlue,
          title: Text(widget.canEdit ? 'تعديل الإعلان' : 'تفاصيل الإعلان',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (status == 'active')
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ApplicantsScreen(
                      shiftId: widget.shift['id'],
                      shiftTitle: widget.shift['title'] ?? '',
                    ),
                  ),
                ),
                icon: const Icon(Icons.people, color: Colors.white),
                label: const Text('المتقدمون',
                    style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field('عنوان الشيفت *', titleCtrl,
                        enabled: widget.canEdit),
                    _field('وصف العمل', descCtrl,
                        enabled: widget.canEdit, maxLines: 3),
                    _field('الأجر (جنيه)', salaryCtrl,
                        enabled: widget.canEdit,
                        keyboard: TextInputType.number),
                    _field('الموقع', locationCtrl,
                        enabled: widget.canEdit),

                    // بيانات للقراءة فقط
                    _readRow('التخصص المطلوب',
                        widget.shift['specialty_required'] ?? '-'),
                    _readRow('تاريخ الشيفت',
                        widget.shift['shift_date']?.toString() ?? '-'),

                    if (widget.shift['reject_reason'] != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'سبب الرفض: ${widget.shift['reject_reason']}',
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (widget.canEdit) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : _saveEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: royalBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : const Text('حفظ وإعادة الإرسال للمراجعة ✅',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool enabled = true,
      int maxLines = 1,
      TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF374151))),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            enabled: enabled,
            maxLines: maxLines,
            keyboardType: keyboard,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled
                  ? const Color(0xFFFAFAFA)
                  : const Color(0xFFE5E7EB),
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
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}