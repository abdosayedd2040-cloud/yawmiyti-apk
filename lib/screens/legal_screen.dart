import 'package:flutter/material.dart';

const royalBlue = Color(0xFF002366);

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: royalBlue,
            title: const Text('المركز القانوني',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            iconTheme: const IconThemeData(color: Colors.white),
            bottom: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(text: 'شروط الاستخدام'),
                Tab(text: 'سياسة الخصوصية'),
                Tab(text: 'إخلاء المسؤولية'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _LegalPage(title: 'شروط الاستخدام', content: _termsContent),
              _LegalPage(title: 'سياسة الخصوصية', content: _privacyContent),
              _LegalPage(title: 'إخلاء المسؤولية', content: _disclaimerContent),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalPage extends StatelessWidget {
  final String title;
  final String content;
  const _LegalPage({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: royalBlue)),
          const SizedBox(height: 12),
          Text(content,
              style: const TextStyle(fontSize: 14, height: 1.8, color: Color(0xFF374151))),
        ],
      ),
    );
  }
}

const _termsContent = '''
1. مقدمة
مرحبًا بك في يوميتي - ون شيفت. باستخدامك للتطبيق، فإنك توافق على الالتزام بهذه الشروط والأحكام.

2. وصف الخدمة
يوميتي - ون شيفت منصة إلكترونية تربط بين أصحاب الأعمال والعمال والسائقين والصنايعية ومقدمي الخدمات المؤقتة.

3. شروط التسجيل
- أن يكون عمرك 18 عامًا أو أكثر
- تقديم بيانات صحيحة ودقيقة
- عدم إنشاء أكثر من حساب بغرض الاحتيال

4. مسؤولية المستخدم
- استخدام التطبيق بشكل قانوني
- عدم نشر أي محتوى مسيء أو احتيالي
- الالتزام بمواعيد العمل المتفق عليها

5. المدفوعات والعمولات
قد يفرض التطبيق رسوم خدمة مستقبلاً، وسيتم توضيح أي رسوم قبل تأكيد الطلب.

6. التقييمات
يحق للطرفين تقييم بعضهما بعد انتهاء الشيفت أو العمل.

7. إيقاف الحسابات
يحق للتطبيق تعليق أو حذف أي حساب في حال الاحتيال أو إساءة الاستخدام.

8. تعديل الشروط
يحق للتطبيق تعديل شروط الاستخدام في أي وقت.
''';

const _privacyContent = '''
1. المعلومات التي نجمعها
- الاسم ورقم الهاتف
- الموقع الجغرافي
- بيانات الجهاز وسجل الاستخدام

2. استخدام المعلومات
- تشغيل التطبيق وعرض فرص العمل القريبة
- تحسين الأداء والتواصل مع المستخدمين
- الحماية من الاحتيال

3. مشاركة المعلومات
لا نقوم ببيع بيانات المستخدمين. تتم مشاركة البيانات فقط عند تنفيذ الخدمة أو الامتثال للقوانين.

4. الموقع الجغرافي
يستخدم التطبيق الموقع لعرض الشيفتات القريبة. يمكنك إيقاف الإذن من إعدادات الهاتف.

5. حماية البيانات
نعمل على حماية بياناتك بوسائل تقنية مناسبة.

6. حقوق المستخدم
- تعديل بياناتك
- طلب حذف الحساب
- التواصل للاستفسار عن بياناتك
''';

const _disclaimerContent = '''
1. طبيعة الخدمة
يوميتي - ون شيفت منصة إلكترونية للربط فقط، ولا تعتبر طرفًا مباشرًا في أي اتفاق بين المستخدمين.

2. عدم ضمان النتائج
لا يضمن التطبيق توفر فرص عمل بشكل دائم أو جودة جميع الإعلانات.

3. مسؤولية الأطراف
يتحمل كل مستخدم المسؤولية الكاملة عن سلوكه والتزامه.

4. النزاعات
أي نزاع ينشأ بين المستخدمين يكون بينهم مباشرة.

5. الأعطال التقنية
لا يتحمل التطبيق المسؤولية عن توقف الخدمة المؤقت أو الأعطال التقنية.

6. القوانين المحلية
يلتزم المستخدم باستخدام التطبيق وفق القوانين المحلية.
''';