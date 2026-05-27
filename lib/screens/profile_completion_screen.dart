import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../main.dart';

const royalBlue = Color(0xFF002366);

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  Map<String, dynamic> profile = {};
  bool loading = true;
  bool saving = false;
  String userType = '';
  String userId = '';
  String employerType = '';

  // Controllers
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final idNumberCtrl = TextEditingController();
  final birthDateCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final companyNameCtrl = TextEditingController();
  final commercialRegCtrl = TextEditingController();
  final taxNumCtrl = TextEditingController();
  final companyAddressCtrl = TextEditingController();
  final responsibleCtrl = TextEditingController();
  final landlineCtrl = TextEditingController();
  final websiteCtrl = TextEditingController();
  final skillsCtrl = TextEditingController();

  String specialty = '';
  String governorate = '';
  int experienceYears = 0;

  // صور
  File? avatarImage;
  File? idCardFront;
  File? idCardBack;
  File? cvImage;
  File? certificate;

  final picker = ImagePicker();

  final specialties = [
    'كهربائي', 'سباك', 'نجار', 'دهان', 'ميكانيكي',
    'لحام', 'تكييف وتبريد', 'بناء', 'سائق',
    'أمن وحراسة', 'تنظيف', 'طباخ', 'أخرى'
  ];

  final governorates = [
    'القاهرة', 'الجيزة', 'الإسكندرية', 'الدقهلية',
    'الشرقية', 'المنوفية', 'القليوبية', 'الغربية',
    'البحيرة', 'الفيوم', 'بني سويف', 'المنيا',
    'أسيوط', 'سوهاج', 'قنا', 'الأقصر', 'أسوان',
    'بورسعيد', 'الإسماعيلية', 'السويس', 'دمياط'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id') ?? '';
    userType = prefs.getString('user_type') ?? '';
    try {
      final res = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      setState(() {
        profile = res;
        employerType = res['employer_type'] ?? '';
        nameCtrl.text = res['full_name'] ?? '';
        phoneCtrl.text = res['phone'] ?? '';
        emailCtrl.text = res['email'] ?? '';
        idNumberCtrl.text = res['id_number'] ?? res['national_id'] ?? '';
        birthDateCtrl.text = res['birth_date'] ?? '';
        addressCtrl.text = res['address'] ?? '';
        specialty = res['specialty'] ?? '';
        governorate = res['governorate'] ?? '';
        experienceYears = res['experience_years'] ?? 0;
        companyNameCtrl.text = res['company_name'] ?? '';
        commercialRegCtrl.text = res['commercial_register'] ?? '';
        taxNumCtrl.text = res['tax_number'] ?? '';
        companyAddressCtrl.text = res['company_address'] ?? '';
        responsibleCtrl.text = res['responsible_name'] ?? '';
        landlineCtrl.text = res['landline'] ?? '';
        websiteCtrl.text = res['website'] ?? '';
      });
    } catch (e) {
      debugPrint('Error: $e');
    }
    setState(() => loading = false);
  }

  // التحقق من العمر
  bool _isOver18(String birthDate) {
    try {
      final date = DateTime.parse(birthDate);
      final age = DateTime.now().difference(date).inDays ~/ 365;
      return age >= 18;
    } catch (e) {
      return false;
    }
  }

  // التحقق من رقم الهوية
  bool _isValidId(String id) {
    return id.length == 14 && (id.startsWith('2') || id.startsWith('3'));
  }

  // التحقق من رقم الهاتف
  bool _isValidPhone(String phone) {
    return phone.length == 11 && phone.startsWith('01');
  }

  // نسبة الإكمال
  bool get _mandatoryComplete {
    if (userType == 'worker') {
      return nameCtrl.text.isNotEmpty &&
          _isValidPhone(phoneCtrl.text) &&
          _isValidId(idNumberCtrl.text) &&
          birthDateCtrl.text.isNotEmpty &&
          _isOver18(birthDateCtrl.text) &&
          addressCtrl.text.isNotEmpty &&
          specialty.isNotEmpty &&
          governorate.isNotEmpty &&
          avatarImage != null &&
          idCardFront != null &&
          idCardBack != null;
    } else if (employerType == 'individual') {
      return nameCtrl.text.isNotEmpty &&
          _isValidPhone(phoneCtrl.text) &&
          _isValidId(idNumberCtrl.text);
    } else {
      return companyNameCtrl.text.isNotEmpty &&
          _isValidPhone(phoneCtrl.text) &&
          commercialRegCtrl.text.isNotEmpty &&
          taxNumCtrl.text.isNotEmpty &&
          companyAddressCtrl.text.isNotEmpty &&
          responsibleCtrl.text.isNotEmpty;
    }
  }

  bool get _allComplete {
    if (userType == 'worker') {
      return _mandatoryComplete &&
          emailCtrl.text.isNotEmpty &&
          cvImage != null &&
          certificate != null &&
          skillsCtrl.text.isNotEmpty;
    }
    return _mandatoryComplete && emailCtrl.text.isNotEmpty;
  }

  double get completionPercent {
    if (userType == 'worker') {
      int filled = 0;
      const total = 11;
      if (nameCtrl.text.isNotEmpty) filled++;
      if (_isValidPhone(phoneCtrl.text)) filled++;
      if (_isValidId(idNumberCtrl.text)) filled++;
      if (birthDateCtrl.text.isNotEmpty && _isOver18(birthDateCtrl.text)) filled++;
      if (addressCtrl.text.isNotEmpty) filled++;
      if (specialty.isNotEmpty) filled++;
      if (governorate.isNotEmpty) filled++;
      if (avatarImage != null) filled++;
      if (idCardFront != null) filled++;
      if (idCardBack != null) filled++;
      if (experienceYears > 0) filled++;
      return filled / total;
    }
    return _mandatoryComplete ? 1.0 : 0.5;
  }

  Future<void> _pickImage(String type) async {
  // خيار الكاميرا أو المعرض
  final source = await showDialog<ImageSource>(
    context: context,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('اختار مصدر الصورة'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('الكاميرا'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('المعرض'),
          ),
        ],
      ),
    ),
  );

  if (source == null) return;

  final picked = await picker.pickImage(
    source: source,
    imageQuality: 80,
  );
  if (picked == null) return;

  setState(() {
    switch (type) {
      case 'avatar': avatarImage = File(picked.path); break;
      case 'front': idCardFront = File(picked.path); break;
      case 'back': idCardBack = File(picked.path); break;
      case 'cv': cvImage = File(picked.path); break;
      case 'cert': certificate = File(picked.path); break;
    }
  });
}

  Future<void> _save() async {
    // التحققات
    if (!_isValidPhone(phoneCtrl.text)) {
      _showError('رقم الهاتف يجب أن يكون 11 رقم ويبدأ بـ 01');
      return;
    }

    if (userType == 'worker') {
      if (!_isValidId(idNumberCtrl.text)) {
        _showError('رقم البطاقة يجب أن يكون 14 رقم ويبدأ بـ 2 أو 3');
        return;
      }
      if (birthDateCtrl.text.isEmpty || !_isOver18(birthDateCtrl.text)) {
        _showError('يجب أن يكون عمرك 18 سنة أو أكثر');
        return;
      }
      if (avatarImage == null) {
        _showError('من فضلك أضف صورة شخصية');
        return;
      }
      if (idCardFront == null || idCardBack == null) {
        _showError('من فضلك أضف صور البطاقة (وجه وظهر)');
        return;
      }
    }

    if (!_mandatoryComplete) {
      _showError('من فضلك أكمل جميع البيانات الإلزامية');
      return;
    }

    setState(() => saving = true);

    try {
      // رفع الصور لـ Supabase Storage
      String? avatarUrl;
      String? idFrontUrl;
      String? idBackUrl;
      String? cvUrl;
      String? certUrl;

      if (avatarImage != null) {
        final bytes = await avatarImage!.readAsBytes();
        await supabase.storage
            .from('profiles')
            .uploadBinary('$userId/avatar.jpg', bytes,
                fileOptions: const FileOptions(upsert: true));
        avatarUrl = supabase.storage
            .from('profiles')
            .getPublicUrl('$userId/avatar.jpg');
      }

      if (idCardFront != null) {
        final bytes = await idCardFront!.readAsBytes();
        await supabase.storage
            .from('profiles')
            .uploadBinary('$userId/id_front.jpg', bytes,
                fileOptions: const FileOptions(upsert: true));
        idFrontUrl = supabase.storage
            .from('profiles')
            .getPublicUrl('$userId/id_front.jpg');
      }

      if (idCardBack != null) {
        final bytes = await idCardBack!.readAsBytes();
        await supabase.storage
            .from('profiles')
            .uploadBinary('$userId/id_back.jpg', bytes,
                fileOptions: const FileOptions(upsert: true));
        idBackUrl = supabase.storage
            .from('profiles')
            .getPublicUrl('$userId/id_back.jpg');
      }

      if (cvImage != null) {
        final bytes = await cvImage!.readAsBytes();
        await supabase.storage
            .from('profiles')
            .uploadBinary('$userId/cv.jpg', bytes,
                fileOptions: const FileOptions(upsert: true));
        cvUrl = supabase.storage
            .from('profiles')
            .getPublicUrl('$userId/cv.jpg');
      }

      if (certificate != null) {
        final bytes = await certificate!.readAsBytes();
        await supabase.storage
            .from('profiles')
            .uploadBinary('$userId/certificate.jpg', bytes,
                fileOptions: const FileOptions(upsert: true));
        certUrl = supabase.storage
            .from('profiles')
            .getPublicUrl('$userId/certificate.jpg');
      }

      // تحديد الشارة
      String badge = 'gray';
      if (_allComplete) {
        badge = 'green';
      } else if (_mandatoryComplete) {
        badge = 'blue';
      }

      final data = <String, dynamic>{
        'full_name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'badge_status': badge,
        'status': _mandatoryComplete ? 'under_review' : 'active',
      };

      if (emailCtrl.text.isNotEmpty) data['email'] = emailCtrl.text.trim();
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;

      if (userType == 'worker') {
        data['id_number'] = idNumberCtrl.text.trim();
        data['birth_date'] = birthDateCtrl.text.trim();
        data['address'] = addressCtrl.text.trim();
        data['specialty'] = specialty;
        data['governorate'] = governorate;
        data['experience_years'] = experienceYears;
        if (idFrontUrl != null) data['id_card_front'] = idFrontUrl;
        if (idBackUrl != null) data['id_card_back'] = idBackUrl;
        if (cvUrl != null) data['cv_url'] = cvUrl;
        if (certUrl != null) data['certificates'] = [certUrl];
        if (skillsCtrl.text.isNotEmpty) {
          data['skills'] = skillsCtrl.text
              .split(',')
              .map((s) => s.trim())
              .toList();
        }
      } else if (employerType == 'individual') {
        data['national_id'] = idNumberCtrl.text.trim();
      } else {
        data['company_name'] = companyNameCtrl.text.trim();
        data['commercial_register'] = commercialRegCtrl.text.trim();
        data['tax_number'] = taxNumCtrl.text.trim();
        data['company_address'] = companyAddressCtrl.text.trim();
        data['responsible_name'] = responsibleCtrl.text.trim();
        data['landline'] = landlineCtrl.text.trim();
        if (websiteCtrl.text.isNotEmpty) data['website'] = websiteCtrl.text.trim();
      }

      await supabase.from('profiles').update(data).eq('id', userId);

      // تحديث SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('badge', badge);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(badge == 'green'
            ? '👑 تم الحفظ! حسابك موصى به'
            : '🔵 تم الحفظ! في انتظار مراجعة الإدارة'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context);
    } catch (e) {
      _showError('خطأ: $e');
    }
    setState(() => saving = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textDirection: TextDirection.rtl),
      backgroundColor: Colors.red,
    ));
  }

bool get _isVerified =>
    profile['badge_status'] == 'blue' ||
    profile['badge_status'] == 'green';

bool get _isFullyVerified => profile['badge_status'] == 'green';

Widget _fullyVerifiedWidget() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          const Text('👑', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 20),
          const Text('حسابك موصى به',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: royalBlue)),
          const SizedBox(height: 10),
          const Text(
            'تم إكمال جميع البيانات والموافقة عليها\nلا تحتاج لإضافة أي بيانات إضافية',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    ),
  );
}

  @override
Widget build(BuildContext context) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: royalBlue,
        title: const Text('إكمال التوثيق',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: royalBlue))
          : _isFullyVerified
              ? _fullyVerifiedWidget()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _progressCard(),
                      const SizedBox(height: 16),
                      if (userType == 'worker') ..._workerFields(),
                      if (userType == 'employer' && employerType == 'individual')
                        ..._individualEmployerFields(),
                      if (userType == 'employer' && employerType == 'company')
                        ..._companyEmployerFields(),
                      const SizedBox(height: 20),
                      if (!_isVerified)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: royalBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: saving
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('حفظ وإرسال للمراجعة ✅',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock, color: Colors.blue, size: 18),
                              SizedBox(width: 8),
                              Text(
                                '🔵 حسابك موثق - للتعديل تواصل مع الدعم',
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    ),
  );
}
  Widget _progressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('نسبة إكمال الملف',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${(completionPercent * 100).toInt()}%',
                  style: const TextStyle(
                      color: royalBlue, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completionPercent,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation(
              _allComplete ? Colors.green : royalBlue,
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            _allComplete
                ? '👑 ممتاز! ستحصل على شارة موصى به'
                : _mandatoryComplete
                    ? '🔵 البيانات الإلزامية مكتملة - ستحصل على شارة موثق'
                    : '⚠️ أكمل البيانات الإلزامية (*) للتوثيق',
            style: TextStyle(
              fontSize: 12,
              color: _allComplete
                  ? Colors.green
                  : _mandatoryComplete
                      ? Colors.blue
                      : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _workerFields() {
    return [
      _section('البيانات الأساسية', [
        _field('الاسم الرباعي *', nameCtrl),
        _field('رقم الهاتف *', phoneCtrl,
            keyboard: TextInputType.phone,
            hint: '01xxxxxxxxx'),
        _field('البريد الإلكتروني (اختياري)', emailCtrl,
            keyboard: TextInputType.emailAddress),
        _field('رقم البطاقة الوطنية * (14 رقم يبدأ بـ 2 أو 3)',
            idNumberCtrl, keyboard: TextInputType.number),
        _field('تاريخ الميلاد * (YYYY-MM-DD)', birthDateCtrl,
            hint: '2000-01-15'),
        _field('العنوان بالتفصيل *', addressCtrl),
      ]),
      const SizedBox(height: 12),
      _section('البيانات المهنية', [
        _dropdown('التخصص *', specialty, specialties,
                (v) => setState(() => specialty = v!)),
        _dropdown('المحافظة *', governorate, governorates,
                (v) => setState(() => governorate = v!)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('سنوات الخبرة *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    if (experienceYears > 0) experienceYears--;
                  }),
                  icon: const Icon(Icons.remove_circle_outline, color: royalBlue),
                ),
                Text('$experienceYears',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold,
                        color: royalBlue)),
                IconButton(
                  onPressed: () => setState(() => experienceYears++),
                  icon: const Icon(Icons.add_circle_outline, color: royalBlue),
                ),
              ],
            ),
          ],
        ),
      ]),
      const SizedBox(height: 12),
      _section('الصور الإلزامية', [
        _imageField('صورة شخصية *', avatarImage, () => _pickImage('avatar')),
        _imageField('صورة البطاقة (وجه) *', idCardFront, () => _pickImage('front')),
        _imageField('صورة البطاقة (ظهر) *', idCardBack, () => _pickImage('back')),
      ]),
      const SizedBox(height: 12),
      _section('بيانات اختيارية (للحصول على شارة موصى به 👑)', [
        _field('المهارات (افصل بفاصلة)', skillsCtrl,
            hint: 'مثال: لحام, برادة, تشغيل آلات'),
        _imageField('صورة السيرة الذاتية (اختياري)', cvImage,
                () => _pickImage('cv')),
        _imageField('شهادة (اختياري)', certificate, () => _pickImage('cert')),
      ]),
    ];
  }

  List<Widget> _individualEmployerFields() {
    return [
      _section('بيانات التوثيق', [
        _field('الاسم الرباعي *', nameCtrl),
        _field('رقم الهاتف *', phoneCtrl,
            keyboard: TextInputType.phone, hint: '01xxxxxxxxx'),
        _field('البريد الإلكتروني (اختياري)', emailCtrl,
            keyboard: TextInputType.emailAddress),
        _field('رقم البطاقة الوطنية * (14 رقم يبدأ بـ 2 أو 3)',
            idNumberCtrl, keyboard: TextInputType.number),
      ]),
    ];
  }

  List<Widget> _companyEmployerFields() {
    return [
      _section('بيانات الشركة', [
        _field('اسم الشركة *', companyNameCtrl),
        _field('رقم الهاتف *', phoneCtrl,
            keyboard: TextInputType.phone, hint: '01xxxxxxxxx'),
        _field('الهاتف الأرضي (اختياري)', landlineCtrl,
            keyboard: TextInputType.phone),
        _field('رقم السجل التجاري *', commercialRegCtrl),
        _field('الرقم الضريبي *', taxNumCtrl),
        _field('عنوان الشركة *', companyAddressCtrl),
        _field('اسم المسؤول *', responsibleCtrl),
        _field('الموقع الإلكتروني (اختياري)', websiteCtrl),
        _field('البريد الإلكتروني (اختياري)', emailCtrl,
            keyboard: TextInputType.emailAddress),
      ]),
    ];
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
              style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.bold, color: royalBlue)),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType keyboard = TextInputType.text, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13,
              color: Color(0xFF374151))),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: keyboard,
            textDirection: TextDirection.rtl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: royalBlue, width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13,
              color: Color(0xFF374151))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value.isEmpty ? null : value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
            hint: const Text('اختار...'),
            items: items.map((e) => DropdownMenuItem(
              value: e,
              child: Text(e, textDirection: TextDirection.rtl),
            )).toList(),
            onChanged: (v) {
              onChanged(v);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _imageField(String label, File? file, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13,
              color: Color(0xFF374151))),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: file != null ? 120 : 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: file != null ? Colors.green : const Color(0xFFE2E8F0),
                  width: file != null ? 2 : 1,
                ),
              ),
              child: file != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child:kIsWeb
    ? Image.network(
        Uri.dataFromBytes(file.readAsBytesSync()).toString(),
        fit: BoxFit.cover,
      )
    : Image.file(file, fit: BoxFit.cover),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_outlined, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('اضغط لرفع الصورة',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}