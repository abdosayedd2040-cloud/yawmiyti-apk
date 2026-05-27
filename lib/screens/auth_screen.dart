import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'home_screen.dart';
import 'admin_screen.dart';

const royalBlue = Color(0xFF002366);
const lightBlue = Color(0xFFE8EEF8);

const specialties = [
  'كهربائي', 'سباك', 'نجار', 'دهان', 'ميكانيكي',
  'لحام', 'تكييف وتبريد', 'بناء', 'سائق',
  'أمن وحراسة', 'تنظيف', 'طباخ', 'أخرى'
];

const governorates = [
  'القاهرة', 'الجيزة', 'الإسكندرية', 'الدقهلية',
  'الشرقية', 'المنوفية', 'القليوبية', 'الغربية',
  'البحيرة', 'الفيوم', 'بني سويف', 'المنيا',
  'أسيوط', 'سوهاج', 'قنا', 'الأقصر', 'أسوان',
  'بورسعيد', 'الإسماعيلية', 'السويس', 'دمياط'
];

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  int step = 1;
  bool loading = false;
  bool showPass = false;

  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final backupPhoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final expCtrl = TextEditingController();
  final nationalIdCtrl = TextEditingController();
  final companyNameCtrl = TextEditingController();
  final commercialRegCtrl = TextEditingController();
  final taxNumCtrl = TextEditingController();
  final companyAddressCtrl = TextEditingController();
  final responsibleNameCtrl = TextEditingController();
  final landlineCtrl = TextEditingController();
  final websiteCtrl = TextEditingController();

  String role = '';
  String employerType = '';
  String specialty = '';
  String governorate = '';

  void showSnack(String msg, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textDirection: TextDirection.rtl),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
  }

  Future<void> handleLogin() async {
    if (phoneCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
      showSnack('من فضلك ادخل رقم الهاتف وكلمة المرور');
      return;
    }

    setState(() => loading = true);

  // تحقق من الأدمن من قاعدة البيانات
    try {
      final adminList = await supabase
          .from('admins')
          .select()
          .eq('username', phoneCtrl.text.trim())
          .eq('password', passwordCtrl.text);

      if (adminList.isNotEmpty) {
        if (!mounted) return;
        setState(() => loading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminScreen()),
        );
        return;
      }
    } catch (e) {
      debugPrint('Admin check: $e');
    }

    try {
      final res = await supabase
          .from('profiles')
          .select()
          .eq('phone', phoneCtrl.text.trim())
          .eq('password', passwordCtrl.text)
          .single();

      if (res['status'] == 'banned' || res['status'] == 'suspended') {
        showSnack('هذا الحساب موقوف أو محظور');
        setState(() => loading = false);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', res['id']);
      await prefs.setString('user_type', res['user_type']);
      await prefs.setString('user_name', res['full_name']);
      await prefs.setString('badge', res['badge_status'] ?? 'gray');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      showSnack('رقم الهاتف أو كلمة المرور غلط');
    }
    setState(() => loading = false);
  }

  Future<void> handleRegister() async {
    setState(() => loading = true);
    try {
      final existing = await supabase
          .from('profiles')
          .select('id')
          .eq('phone', phoneCtrl.text.trim());

      if (existing.isNotEmpty) {
        showSnack('رقم الهاتف ده مسجل بالفعل');
        setState(() => loading = false);
        return;
      }

      final data = {
        'full_name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'backup_phone': backupPhoneCtrl.text.trim().isEmpty
            ? null : backupPhoneCtrl.text.trim(),
        'email': emailCtrl.text.trim().isEmpty
            ? null : emailCtrl.text.trim(),
        'password': passwordCtrl.text,
        'user_type': role,
        'badge_status': 'gray',
        'status': 'active',
      };

      if (role == 'worker') {
        data['specialty'] = specialty;
        data['experience_years'] =
            (int.tryParse(expCtrl.text) ?? 0).toString();
        data['governorate'] = governorate;
      }

      if (role == 'employer') {
        data['employer_type'] = employerType;
        if (employerType == 'individual') {
          data['national_id'] = nationalIdCtrl.text.trim();
        } else {
          data['company_name'] = companyNameCtrl.text.trim();
          data['commercial_register'] = commercialRegCtrl.text.trim();
          data['tax_number'] = taxNumCtrl.text.trim();
          data['company_address'] = companyAddressCtrl.text.trim();
          data['responsible_name'] = responsibleNameCtrl.text.trim();
          data['landline'] = landlineCtrl.text.trim();
          if (websiteCtrl.text.trim().isNotEmpty) {
            data['website'] = websiteCtrl.text.trim();
          }
        }
      }

      final res = await supabase
          .from('profiles')
          .insert([data])
          .select()
          .single();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', res['id']);
      await prefs.setString('user_type', res['user_type']);
      await prefs.setString('user_name', res['full_name']);
      await prefs.setString('badge', res['badge_status'] ?? 'gray');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      showSnack('حدث خطأ، حاول تاني: $e');
    }
    setState(() => loading = false);
  }

  void nextStep() {
    if (step == 1) {
      if (nameCtrl.text.isEmpty ||
          phoneCtrl.text.isEmpty ||
          passwordCtrl.text.isEmpty) {
        showSnack('من فضلك اكمل البيانات المطلوبة');
        return;
      }
      if (phoneCtrl.text.length < 11) {
        showSnack('رقم الهاتف يجب أن يكون 11 رقم');
        return;
      }
    }
    if (step == 2) {
      if (role.isEmpty) {
        showSnack('من فضلك اختار نوع حسابك');
        return;
      }
      if (role == 'employer' && employerType.isEmpty) {
        showSnack('من فضلك اختار نوع النشاط');
        return;
      }
    }
    setState(() => step++);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: royalBlue,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                    )],
                  ),
                  child: const Center(
                    child: Text('⚡', style: TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('يوميتي - ون شيفت',
                    style: TextStyle(fontSize: 22,
                        fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('Yawmiyti - One Shift',
                    style: TextStyle(fontSize: 13,
                        color: Color(0xFF93C5FD))),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                    )],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            _tab('تسجيل الدخول', isLogin, () {
                              setState(() { isLogin = true; step = 1; });
                            }),
                            _tab('حساب جديد', !isLogin, () {
                              setState(() { isLogin = false; step = 1; });
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isLogin) _buildLogin()
                      else _buildRegister(),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? royalBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13,
                color: active ? Colors.white : Colors.grey,
              )),
        ),
      ),
    );
  }

  Widget _buildLogin() {
    return Column(
      children: [
        _field('رقم الهاتف أو اسم المستخدم', phoneCtrl,
            icon: Icons.phone, keyboard: TextInputType.text),
        _field('كلمة المرور', passwordCtrl,
            icon: Icons.lock, obscure: !showPass,
            suffix: IconButton(
              icon: Icon(showPass
                  ? Icons.visibility_off : Icons.visibility,
                  size: 18, color: Colors.grey),
              onPressed: () => setState(() => showPass = !showPass),
            )),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: royalBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('دخول',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildRegister() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) => Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: step > i ? royalBlue : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )),
        ),
        const SizedBox(height: 12),
        Text(
          step == 1 ? 'البيانات الأساسية'
              : step == 2 ? 'نوع الحساب' : 'بيانات إضافية',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 16),

        if (step == 1) ...[
          _field('الاسم الرباعي *', nameCtrl, icon: Icons.person),
          _field('رقم الهاتف *', phoneCtrl,
              icon: Icons.phone, keyboard: TextInputType.phone),
          _field('رقم احتياطي (اختياري)', backupPhoneCtrl,
              icon: Icons.phone_outlined, keyboard: TextInputType.phone),
          _field('البريد الإلكتروني (اختياري)', emailCtrl,
              icon: Icons.email, keyboard: TextInputType.emailAddress),
          _field('كلمة المرور *', passwordCtrl,
              icon: Icons.lock, obscure: !showPass,
              suffix: IconButton(
                icon: Icon(showPass
                    ? Icons.visibility_off : Icons.visibility,
                    size: 18, color: Colors.grey),
                onPressed: () => setState(() => showPass = !showPass),
              )),
        ],

        if (step == 2) ...[
          const Text('أنت مين؟',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              _roleCard('worker', '👷', 'عامل / صنايعي', 'ابحث عن شغل'),
              const SizedBox(width: 10),
              _roleCard('employer', '💼', 'صاحب عمل', 'انشر إعلانات'),
            ],
          ),
          if (role == 'employer') ...[
            const SizedBox(height: 16),
            const Text('نوع النشاط:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                _typeCard('individual', 'فرد 👤'),
                const SizedBox(width: 10),
                _typeCard('company', 'شركة 🏢'),
              ],
            ),
          ],
        ],

        if (step == 3) ...[
          if (role == 'worker') ...[
            _dropdown('التخصص *', specialty, specialties,
                    (v) => setState(() => specialty = v!)),
            _field('سنوات الخبرة', expCtrl,
                keyboard: TextInputType.number),
            _dropdown('المحافظة', governorate, governorates,
                    (v) => setState(() => governorate = v!)),
          ],
          if (role == 'employer' && employerType == 'individual')
            _field('رقم البطاقة (14 رقم) *', nationalIdCtrl,
                keyboard: TextInputType.number),
          if (role == 'employer' && employerType == 'company') ...[
            _field('اسم الشركة *', companyNameCtrl),
            _field('رقم السجل التجاري *', commercialRegCtrl),
            _field('الرقم الضريبي *', taxNumCtrl),
            _field('عنوان الشركة *', companyAddressCtrl),
            _field('اسم المسؤول *', responsibleNameCtrl),
            _field('الهاتف الأرضي *', landlineCtrl,
                keyboard: TextInputType.phone),
            _field('الموقع الإلكتروني (اختياري)', websiteCtrl),
          ],
        ],

        const SizedBox(height: 8),
        Row(
          children: [
            if (step > 1)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => step--),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('رجوع',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            if (step > 1) const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: loading ? null : () {
                  if (step < 3) nextStep();
                  else handleRegister();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: royalBlue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        step < 3 ? 'التالي ←' : 'إنشاء الحساب ✅',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {IconData? icon, bool obscure = false,
        TextInputType keyboard = TextInputType.text,
        Widget? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13,
                  color: Color(0xFF374151))),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            obscureText: obscure,
            keyboardType: keyboard,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Icon(icon, size: 18, color: Colors.grey) : null,
              suffixIcon: suffix,
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
          Text(label,
              style: const TextStyle(
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
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _roleCard(String val, String icon, String label, String sub) {
    final active = role == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => role = val),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
                color: active ? royalBlue : const Color(0xFFE2E8F0),
                width: 2),
            borderRadius: BorderRadius.circular(14),
            color: active ? lightBlue : Colors.white,
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center),
              Text(sub,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeCard(String val, String label) {
    final active = employerType == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => employerType = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
                color: active ? royalBlue : const Color(0xFFE2E8F0),
                width: 2),
            borderRadius: BorderRadius.circular(12),
            color: active ? lightBlue : Colors.white,
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: active ? royalBlue : const Color(0xFF374151))),
        ),
      ),
    );
  }
}