import 'package:flutter/material.dart';
import '../main.dart';

const royalBlue = Color(0xFF002366);

class ServiceOfferDetailScreen extends StatelessWidget {
  final Map<String, dynamic> offer;

  const ServiceOfferDetailScreen({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final worker = offer['profiles'] as Map<String, dynamic>?;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          backgroundColor: royalBlue,
          title: const Text('تفاصيل عرض الخدمة',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header العامل
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
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(36),
                      ),
                      child: worker?['avatar_url'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(36),
                              child: Image.network(
                                worker!['avatar_url'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.person,
                                        color: Colors.white, size: 36),
                              ),
                            )
                          : const Icon(Icons.person,
                              color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(worker?['full_name'] ?? '',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(offer['specialty'] ?? '',
                        style: const TextStyle(
                            color: Color(0xFF93C5FD), fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      worker?['badge_status'] == 'green'
                          ? '👑 موصى به'
                          : worker?['badge_status'] == 'blue'
                              ? '🔵 موثق'
                              : '⚪ غير موثق',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // إحصائيات العامل
              Row(
                children: [
                  _statCard('⭐ التقييم',
                      '${worker?['rating'] ?? 0}', Colors.amber),
                  const SizedBox(width: 10),
                  _statCard('✅ الأعمال',
                      '${worker?['completed_shifts'] ?? 0}', Colors.green),
                  const SizedBox(width: 10),
                  _statCard('📅 الخبرة',
                      '${worker?['experience_years'] ?? 0} سنة', royalBlue),
                ],
              ),

              const SizedBox(height: 16),

              // تفاصيل الخدمة
              _section('تفاصيل الخدمة', [
                _infoRow(Icons.work_outline, 'التخصص',
                    offer['specialty'] ?? '-'),
                _infoRow(Icons.description_outlined, 'الوصف',
                    offer['description'] ?? '-'),
                _infoRow(Icons.attach_money, 'نطاق السعر',
                    '${offer['price_min'] ?? 0} - ${offer['price_max'] ?? 0} جنيه'),
                if (offer['available_from'] != null)
                  _infoRow(Icons.calendar_today_outlined, 'متاح من',
                      offer['available_from'].toString().substring(0, 10)),
              ]),

              const SizedBox(height: 16),

              // بيانات التواصل
              _section('بيانات العامل', [
                _infoRow(Icons.person_outline, 'الاسم',
                    worker?['full_name'] ?? '-'),
                _infoRow(Icons.location_on_outlined, 'المحافظة',
                    worker?['governorate'] ?? '-'),
                _infoRow(Icons.phone_outlined, 'الهاتف',
                    worker?['phone'] ?? '-'),
              ]),

              const SizedBox(height: 20),
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
                style: const TextStyle(fontSize: 10, color: Colors.grey),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: royalBlue),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
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