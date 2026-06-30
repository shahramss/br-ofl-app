import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProductSpecsApp());
}

const Color kOrange = Color(0xFFF97316);
const Color kOrangeDark = Color(0xFFEA580C);
const Color kBg = Color(0xFFFAFAFA);
const Color kText = Color(0xFF1F2937);
const Color kMuted = Color(0xFF6B7280);
const Color kLine = Color(0xFFE5E7EB);
const String kAppName = 'مدیریت هوشمند';
const String kAppVersion = '1.1.1';
const String kFooterText = 'طراحی در گروه وب تیما';
const String kWebTeamaUrl = 'https://webteama.com';

class ProductSpecsApp extends StatelessWidget {
  const ProductSpecsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'مدیریت هوشمند',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: kOrange),
          scaffoldBackgroundColor: kBg,
          appBarTheme: const AppBarTheme(
            backgroundColor: kBg,
            elevation: 0,
            foregroundColor: kText,
            centerTitle: true,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: kLine),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: kLine),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: kOrange, width: 1.5),
            ),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}


class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // برای امنیت، بعد از هر بار باز شدن اپ، صفحه ورود نمایش داده می‌شود.
    // نام کاربری ذخیره می‌شود، اما رمز ذخیره نمی‌شود؛ ورود سریع با اثر انگشت انجام می‌شود.
    if (mounted) {
      setState(() {
        _loggedIn = false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_loggedIn) {
      return LoginScreen(onLoggedIn: () => setState(() => _loggedIn = true));
    }
    return AuthScope(
      onLogout: () async {
        await AuthSessionStore().logout();
        if (mounted) setState(() => _loggedIn = false);
      },
      child: const MainShell(),
    );
  }
}

class AuthScope extends InheritedWidget {
  final Future<void> Function() onLogout;

  const AuthScope({
    super.key,
    required this.onLogout,
    required super.child,
  });

  static Future<void> logout(BuildContext context) async {
    final element = context.getElementForInheritedWidgetOfExactType<AuthScope>();
    final scope = element?.widget as AuthScope?;
    if (scope != null) {
      await scope.onLogout();
    }
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) => onLogout != oldWidget.onLogout;
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final List<Widget> _pages = const [
    CategoriesScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: kOrange.withOpacity(0.12),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              selectedIcon: Icon(Icons.grid_view_rounded, color: kOrange),
              label: 'دسته‌بندی‌ها',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_rounded),
              selectedIcon: Icon(Icons.history_rounded, color: kOrange),
              label: 'تاریخچه',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_rounded),
              selectedIcon: Icon(Icons.settings_rounded, color: kOrange),
              label: 'تنظیمات',
            ),
          ],
        ),
      ),
    );
  }
}

class AppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBack;

  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBack = false,
  });

  Future<void> _logoutNow(BuildContext context) async {
    await AuthScope.logout(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
        child: Column(
          children: [
            Row(
              children: [
                if (showBack)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  )
                else
                  IconButton(
                    tooltip: 'خروج از اکانت',
                    onPressed: () => _logoutNow(context),
                    icon: const Icon(Icons.logout_rounded, color: kMuted),
                  ),
                const Spacer(),
                const BrandBadge(size: 44),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kAppName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('ثبت هوشمند مشخصات محصولات', style: TextStyle(color: kMuted, fontSize: 13)),
                  ],
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 26),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                title,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kText),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(subtitle, style: const TextStyle(color: kMuted, fontSize: 15)),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Container(width: 52, height: 4, decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(8))),
            ),
          ],
        ),
      ),
    );
  }
}


class BrandBadge extends StatelessWidget {
  final double size;
  const BrandBadge({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [BoxShadow(color: kOrange.withOpacity(0.20), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/app_icon/source_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kLine),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(borderRadius: BorderRadius.circular(22), onTap: onTap, child: card);
  }
}

class AppButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool loading;

  const AppButton({super.key, required this.text, this.icon, this.onPressed, this.outlined = false, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        else if (icon != null) Icon(icon, size: 22),
        if (icon != null || loading) const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );

    if (outlined) {
      return OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: kOrangeDark,
          side: const BorderSide(color: kOrange),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: child,
      );
    }

    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: kOrange,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: child,
    );
  }
}

class AppSettings {
  final String siteUrl;
  final String wpToken;
  final String aiProvider;
  final String openaiKey;
  final String deepseekKey;
  final String openaiModel;
  final String deepseekModel;

  const AppSettings({
    this.siteUrl = '',
    this.wpToken = '',
    this.aiProvider = 'openai',
    this.openaiKey = '',
    this.deepseekKey = '',
    this.openaiModel = 'gpt-4o-mini',
    this.deepseekModel = 'deepseek-chat',
  });

  AppSettings copyWith({
    String? siteUrl,
    String? wpToken,
    String? aiProvider,
    String? openaiKey,
    String? deepseekKey,
    String? openaiModel,
    String? deepseekModel,
  }) {
    return AppSettings(
      siteUrl: siteUrl ?? this.siteUrl,
      wpToken: wpToken ?? this.wpToken,
      aiProvider: aiProvider ?? this.aiProvider,
      openaiKey: openaiKey ?? this.openaiKey,
      deepseekKey: deepseekKey ?? this.deepseekKey,
      openaiModel: openaiModel ?? this.openaiModel,
      deepseekModel: deepseekModel ?? this.deepseekModel,
    );
  }

  bool get hasWordPress => siteUrl.trim().isNotEmpty && wpToken.trim().isNotEmpty;
  bool get hasAi {
    if (aiProvider == 'deepseek') return deepseekKey.trim().isNotEmpty;
    return openaiKey.trim().isNotEmpty;
  }
}

class SettingsStore {
  static const _storage = FlutterSecureStorage();

  Future<AppSettings> load() async {
    return AppSettings(
      siteUrl: await _storage.read(key: 'siteUrl') ?? '',
      wpToken: await _storage.read(key: 'wpToken') ?? '',
      aiProvider: await _storage.read(key: 'aiProvider') ?? 'openai',
      openaiKey: await _storage.read(key: 'openaiKey') ?? '',
      deepseekKey: await _storage.read(key: 'deepseekKey') ?? '',
      openaiModel: await _storage.read(key: 'openaiModel') ?? 'gpt-4o-mini',
      deepseekModel: await _storage.read(key: 'deepseekModel') ?? 'deepseek-chat',
    );
  }

  Future<void> save(AppSettings s) async {
    await _storage.write(key: 'siteUrl', value: s.siteUrl.trim());
    await _storage.write(key: 'wpToken', value: s.wpToken.trim());
    await _storage.write(key: 'aiProvider', value: s.aiProvider.trim());
    await _storage.write(key: 'openaiKey', value: s.openaiKey.trim());
    await _storage.write(key: 'deepseekKey', value: s.deepseekKey.trim());
    await _storage.write(key: 'openaiModel', value: s.openaiModel.trim());
    await _storage.write(key: 'deepseekModel', value: s.deepseekModel.trim());
  }
}

String normalizeSite(String value) {
  var url = value.trim();
  if (url.endsWith('/')) url = url.substring(0, url.length - 1);
  return url;
}


class LoginResult {
  final int id;
  final String username;
  final String displayName;
  final List<String> roles;

  LoginResult({required this.id, required this.username, required this.displayName, required this.roles});

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    return LoginResult(
      id: _toInt(json['id']),
      username: '${json['username'] ?? ''}',
      displayName: '${json['display_name'] ?? json['username'] ?? ''}',
      roles: rawRoles is List ? rawRoles.map((e) => '$e').toList() : <String>[],
    );
  }
}

class AuthSessionStore {
  static const _storage = FlutterSecureStorage();
  static const _savedUsernameKey = 'savedWpUsername';
  static const _loggedInKey = 'authLoggedIn';
  static const _displayNameKey = 'authDisplayName';
  static const _rolesKey = 'authRoles';

  Future<bool> isLoggedIn() async => (await _storage.read(key: _loggedInKey)) == '1';
  Future<String> savedUsername() async => await _storage.read(key: _savedUsernameKey) ?? '';
  Future<String> displayName() async => await _storage.read(key: _displayNameKey) ?? '';

  Future<void> saveLogin(LoginResult result) async {
    await _storage.write(key: _loggedInKey, value: '1');
    await _storage.write(key: _savedUsernameKey, value: result.username.trim());
    await _storage.write(key: _displayNameKey, value: result.displayName.trim());
    await _storage.write(key: _rolesKey, value: result.roles.join(','));
  }

  Future<void> logout() async {
    await _storage.write(key: _loggedInKey, value: '0');
  }
}

class LoginAttemptStore {
  static const _countKey = 'loginFailCount';
  static const _lockUntilKey = 'loginLockUntil';

  Future<DateTime?> lockUntil() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lockUntilKey) ?? '';
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<bool> isLocked() async {
    final until = await lockUntil();
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    await reset();
    return false;
  }

  Future<int> failedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_countKey) ?? 0;
  }

  Future<DateTime?> registerFailure() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(_countKey) ?? 0) + 1;
    await prefs.setInt(_countKey, next);
    if (next >= 5) {
      final until = DateTime.now().add(const Duration(minutes: 10));
      await prefs.setString(_lockUntilKey, until.toIso8601String());
      return until;
    }
    return null;
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_countKey);
    await prefs.remove(_lockUntilKey);
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class CategoryItem {
  final int id;
  final String name;
  final String image;
  final int count;

  CategoryItem({required this.id, required this.name, required this.image, required this.count});

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: _toInt(json['id']),
      name: '${json['name'] ?? ''}',
      image: '${json['image'] ?? ''}',
      count: _toInt(json['count']),
    );
  }
}

class ProductItem {
  final int id;
  final String name;
  final String sku;
  final String price;
  final String image;
  final String link;
  final bool hasSpecs;
  final bool inStock;
  final String stockStatus;

  ProductItem({required this.id, required this.name, required this.sku, required this.price, required this.image, required this.link, required this.hasSpecs, required this.inStock, required this.stockStatus});

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final status = '${json['stock_status'] ?? ''}';
    return ProductItem(
      id: _toInt(json['id']),
      name: '${json['name'] ?? ''}',
      sku: '${json['sku'] ?? ''}',
      price: '${json['price'] ?? ''}',
      image: '${json['image'] ?? ''}',
      link: '${json['link'] ?? ''}',
      hasSpecs: json['has_specs'] == true,
      inStock: json['in_stock'] == true || status == 'instock',
      stockStatus: status,
    );
  }
}

class SpecItem {
  String name;
  String value;
  SpecItem({required this.name, required this.value});

  factory SpecItem.fromJson(Map<String, dynamic> json) => SpecItem(name: '${json['name'] ?? ''}', value: '${json['value'] ?? ''}');

  Map<String, dynamic> toJson() => {'name': name.trim(), 'value': value.trim()};
}


class AiExtractResult {
  final List<SpecItem> specs;
  final String content;
  final String seoTitle;
  final String seoDescription;
  const AiExtractResult({required this.specs, required this.content, required this.seoTitle, required this.seoDescription});
}

class ProductDetails {
  final int id;
  final String name;
  final String sku;
  final String price;
  final String image;
  final String link;
  final List<String> categoryNames;
  final List<SpecItem> attributes;

  ProductDetails({required this.id, required this.name, required this.sku, required this.price, required this.image, required this.link, required this.categoryNames, required this.attributes});

  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    final attrsRaw = json['attributes'];
    final catsRaw = json['categories'];
    return ProductDetails(
      id: _toInt(json['id']),
      name: '${json['name'] ?? ''}',
      sku: '${json['sku'] ?? ''}',
      price: '${json['price'] ?? ''}',
      image: '${json['image'] ?? ''}',
      link: '${json['link'] ?? ''}',
      categoryNames: catsRaw is List ? catsRaw.map((e) => '${e['name'] ?? e}').toList() : <String>[],
      attributes: attrsRaw is List ? attrsRaw.map((e) => SpecItem.fromJson(Map<String, dynamic>.from(e))).toList() : <SpecItem>[],
    );
  }
}

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class WordPressApi {
  final AppSettings settings;
  WordPressApi(this.settings);

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = normalizeSite(settings.siteUrl);
    return Uri.parse('$base/wp-json/product-specs/v1$path').replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer ${settings.wpToken}',
      };

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 25));
      final body = utf8.decode(res.bodyBytes);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException(_extractMessage(body, 'خطا در ارتباط با سایت: ${res.statusCode}'));
      }
      return Map<String, dynamic>.from(jsonDecode(body));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('ارتباط با سایت برقرار نشد. اینترنت، آدرس سایت یا توکن را بررسی کنید. جزئیات: $e');
    }
  }

  Future<Map<String, dynamic>> _postJson(Uri uri, Map<String, dynamic> payload) async {
    try {
      final res = await http.post(uri, headers: _headers, body: jsonEncode(payload)).timeout(const Duration(seconds: 35));
      final body = utf8.decode(res.bodyBytes);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException(_extractMessage(body, 'خطا در ارسال به سایت: ${res.statusCode}'));
      }
      return Map<String, dynamic>.from(jsonDecode(body));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('ارسال به سایت انجام نشد. اینترنت یا تنظیمات را بررسی کنید. جزئیات: $e');
    }
  }

  String _extractMessage(String body, String fallback) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['message'] != null) return '${data['message']}';
    } catch (_) {}
    return fallback;
  }

  Future<LoginResult> login({required String username, required String password}) async {
    final data = await _postJson(_uri('/login'), {
      'username': username.trim(),
      'password': password,
    });
    return LoginResult.fromJson(Map<String, dynamic>.from(data['user'] ?? data));
  }

  Future<String> ping() async {
    final data = await _getJson(_uri('/ping'));
    return '${data['message'] ?? 'اتصال موفق است'}';
  }

  Future<List<CategoryItem>> categories() async {
    final data = await _getJson(_uri('/categories'));
    final items = data['items'];
    if (items is! List) return [];
    return items.map((e) => CategoryItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<ProductItem>> products({required int categoryId, String search = '', int page = 1}) async {
    final data = await _getJson(_uri('/products', {
      'category_id': '$categoryId',
      'search': search,
      'sort': 'available_newest',
      'fresh': DateTime.now().millisecondsSinceEpoch.toString(),
      'page': '$page',
      'per_page': '30',
    }));
    final items = data['items'];
    if (items is! List) return [];
    return items.map((e) => ProductItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<ProductDetails> product(int id) async {
    final data = await _getJson(_uri('/products/$id'));
    return ProductDetails.fromJson(data);
  }

  Future<String> saveSpecs({required int productId, required String mode, required List<SpecItem> specs, required String rawText, required String provider, required String productContent, required String seoTitle, required String seoDescription}) async {
    final clean = specs.where((e) => e.name.trim().isNotEmpty && e.value.trim().isNotEmpty).map((e) => e.toJson()).toList();
    final data = await _postJson(_uri('/products/$productId/specs'), {
      'mode': mode,
      'specs': clean,
      'raw_text': rawText,
      'ai_provider': provider,
      'product_content': productContent,
      'seo_title': seoTitle,
      'seo_description': seoDescription,
    });
    return '${data['message'] ?? 'مشخصات ذخیره شد'}';
  }
}

class AiClient {
  final AppSettings settings;
  AiClient(this.settings);

  Future<AiExtractResult> extractSpecs({required String rawText, required String productName, required String categoryName, required List<SpecItem> currentAttributes}) async {
    final provider = settings.aiProvider;
    final apiKey = provider == 'deepseek' ? settings.deepseekKey.trim() : settings.openaiKey.trim();
    final model = provider == 'deepseek' ? settings.deepseekModel.trim() : settings.openaiModel.trim();
    final endpoint = provider == 'deepseek'
        ? 'https://api.deepseek.com/chat/completions'
        : 'https://api.openai.com/v1/chat/completions';

    if (apiKey.isEmpty) {
      throw ApiException('کلید API هوش مصنوعی وارد نشده است. از تنظیمات، کلید ChatGPT یا DeepSeek را وارد کنید.');
    }

    final current = currentAttributes.map((e) => '${e.name}: ${e.value}').join('\n');
    final prompt = '''
نام محصول: $productName
دسته‌بندی: $categoryName
ویژگی‌های فعلی محصول:
$current

متن خام کاربر:
$rawText

وظیفه:
۱. فقط اطلاعات فنی‌ای را که در متن خام صریحاً گفته شده استخراج کن.
۲. اگر کاربر هر مشخصه دیگری هم گفت، حتی اگر در لیست‌های معمول دسته‌بندی نبود، آن را هم به مشخصات اضافه کن.
۳. هیچ مقدار حدسی، تبلیغاتی یا ساختگی نساز.
۴. اگر چیزی گفته نشده، آن فیلد را برنگردان.
۵. بر اساس نام محصول و مشخصات استخراج‌شده، یک پاراگراف توضیح محصول بساز؛ متن کامل‌تر و کاربردی‌تر باشد، حدود ۹۰ تا ۱۴۰ کلمه فارسی، اما فقط یک پاراگراف باشد.
۶. پاراگراف فقط بر اساس اطلاعات موجود باشد و ویژگی ساختگی، ادعای دروغ، گزافه‌گویی، تبلیغات اغراق‌آمیز، بهترین/ارزان‌ترین/تضمینی بودن یا مقایسه بی‌دلیل اضافه نکند.
۷. آخر پاراگراف دقیقاً این جمله را اضافه کن: این محصول با ارسال فوری از بازار قفل سفارش بدید
۸. یک عنوان سئو یکتا بساز که برای محصول مناسب فروشگاهی باشد. ترجیحاً با «قیمت و خرید» شروع شود، نام محصول را داشته باشد و اگر مشخصات مهم وجود دارد یکی از آن‌ها را کوتاه اضافه کند. می‌توان از عبارت‌هایی مثل «قیمت عمده»، «خرید عمده» یا «ارسال سریع» استفاده کرد، اما عنوان تکراری و کلی نساز. عنوان حداکثر ۱۰ کلمه و حداکثر ۶۰ کاراکتر باشد.
۹. یک توضیح متای یکتا و کوتاه بساز که شامل نام محصول و ۱ تا ۳ مشخصه مهم باشد. متن متا برای همه محصولات شبیه هم نباشد؛ عبارت‌های فروشگاهی را طبیعی و متنوع استفاده کن، مثل خرید با قیمت عمده، ارسال سریع یا خرید از واردکننده؛ اما ادعای دروغ یا غیرقابل اثبات ننویس. توضیح متا حداکثر ۲۵ کلمه و حداکثر ۱۵۵ کاراکتر باشد.
خروجی فقط JSON معتبر باشد، بدون توضیح اضافه.
فرمت دقیق:
{"specs":[{"name":"قطر","value":"۱۰ میلی‌متر"},{"name":"جنس","value":"فولاد"}],"content":"این محصول با قطر ۱۰ میلی‌متر و جنس فولاد برای استفاده‌های فنی مرتبط با مشخصات اعلام‌شده مناسب است. با توجه به ابعاد و جنس گفته‌شده، می‌توان آن را برای انتخاب دقیق‌تر در زمان خرید و مقایسه مشخصات محصول بررسی کرد. در توضیحات این محصول فقط اطلاعاتی آمده که از متن ثبت‌شده استخراج شده و از افزودن ویژگی‌های نامشخص یا ادعاهای غیرواقعی خودداری شده است. این محصول با ارسال فوری از بازار قفل سفارش بدید","seo_title":"قیمت و خرید سنبه قطر ۱۰ میلی‌متر عمده","seo_description":"خرید سنبه قطر ۱۰ میلی‌متر با جنس فولاد، مناسب بررسی مشخصات فنی و سفارش با قیمت عمده و ارسال سریع."}
''';

    final body = {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': 'تو یک دستیار استخراج مشخصات فنی، تولید توضیح محصول و ساخت عنوان و توضیح متای سئو هستی. خروجی فقط JSON معتبر بده.'
        },
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.1,
      'stream': false,
    };

    try {
      final res = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      final decodedBody = utf8.decode(res.bodyBytes);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException('خطای هوش مصنوعی: ${res.statusCode} - ${_safeError(decodedBody)}');
      }

      final data = jsonDecode(decodedBody);
      String aiContent = '';
      if (data is Map && data['choices'] is List && (data['choices'] as List).isNotEmpty) {
        final first = (data['choices'] as List).first;
        if (first is Map && first['message'] is Map) {
          aiContent = '${(first['message'] as Map)['content'] ?? ''}';
        }
      }
      final jsonText = _extractJsonText(aiContent);
      final parsed = jsonDecode(jsonText);
      final specsRaw = parsed['specs'];
      final specs = specsRaw is List
          ? specsRaw
              .map((e) => SpecItem.fromJson(Map<String, dynamic>.from(e)))
              .where((e) => e.name.trim().isNotEmpty && e.value.trim().isNotEmpty)
              .toList()
          : <SpecItem>[];
      var productContent = '${parsed['content'] ?? ''}'.trim();
      if (productContent.isEmpty && specs.isNotEmpty) {
        productContent = _buildFallbackContent(productName, specs);
      }
      var seoTitle = '${parsed['seo_title'] ?? ''}'.trim();
      var seoDescription = '${parsed['seo_description'] ?? ''}'.trim();
      if (seoTitle.isEmpty) seoTitle = _buildFallbackSeoTitle(productName, specs);
      if (seoDescription.isEmpty) seoDescription = _buildFallbackSeoDescription(productName, specs);
      return AiExtractResult(specs: specs, content: _limitChars(productContent, 900), seoTitle: _limitWords(_limitChars(seoTitle, 60), 10), seoDescription: _limitWords(_limitChars(seoDescription, 155), 25));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('تحلیل با هوش مصنوعی انجام نشد. کلید API، مدل و اینترنت گوشی را بررسی کنید. جزئیات: $e');
    }
  }

  String _buildFallbackContent(String productName, List<SpecItem> specs) {
    final parts = specs
        .where((e) => e.name.trim().isNotEmpty && e.value.trim().isNotEmpty)
        .map((e) => '${e.name.trim()} ${e.value.trim()}')
        .join('، ');
    final name = productName.trim().isEmpty ? 'این محصول' : productName.trim();
    final base = parts.isEmpty
        ? '$name یک محصول کاربردی برای استفاده‌های فنی و فروشگاهی است.'
        : '$name با مشخصاتی مانند $parts برای استفاده‌های فنی و فروشگاهی مناسب است.';
    return '$base این محصول با ارسال فوری از بازار قفل سفارش بدید';
  }

  String _buildFallbackSeoTitle(String productName, List<SpecItem> specs) {
    final name = productName.trim().isEmpty ? 'محصول' : productName.trim();
    final main = specs.take(1).map((e) => '${e.name} ${e.value}').join(' ').trim();
    final text = main.isEmpty ? 'قیمت و خرید $name' : 'قیمت و خرید $name $main';
    return _limitWords(_limitChars(text.trim(), 60), 10);
  }

  String _buildFallbackSeoDescription(String productName, List<SpecItem> specs) {
    final parts = specs.take(3).map((e) => '${e.name} ${e.value}').join('، ');
    final name = productName.trim().isEmpty ? 'محصول' : productName.trim();
    final text = parts.isEmpty
        ? 'خرید $name با امکان بررسی مشخصات محصول، قیمت مناسب و ارسال سریع.'
        : 'خرید $name با $parts، مناسب بررسی مشخصات فنی، قیمت عمده و ارسال سریع.';
    return _limitWords(_limitChars(text, 155), 25);
  }

  String _limitChars(String input, int max) {
    final text = input.trim();
    if (text.length <= max) return text;
    return text.substring(0, max).trim();
  }

  String _limitWords(String input, int maxWords) {
    final words = input.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (words.length <= maxWords) return input.trim();
    return words.take(maxWords).join(' ');
  }

  String _safeError(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['error'] != null) return '${data['error']}';
      if (data is Map && data['message'] != null) return '${data['message']}';
    } catch (_) {}
    return body.length > 180 ? body.substring(0, 180) : body;
  }

  String _extractJsonText(String content) {
    var text = content.trim();
    if (text.startsWith('```')) {
      text = text.replaceAll(RegExp(r'^```json\s*', multiLine: true), '');
      text = text.replaceAll(RegExp(r'^```\s*', multiLine: true), '');
      text = text.replaceAll(RegExp(r'```\s*$', multiLine: true), '');
      text = text.replaceAll('```', '').trim();
    }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) return text.substring(start, end + 1);
    return text;
  }
}

class HistoryItem {
  final int productId;
  final String productName;
  final String sku;
  final String status;
  final String message;
  final String date;

  HistoryItem({required this.productId, required this.productName, required this.sku, required this.status, required this.message, required this.date});

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'sku': sku,
        'status': status,
        'message': message,
        'date': date,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        productId: _toInt(json['productId']),
        productName: '${json['productName'] ?? ''}',
        sku: '${json['sku'] ?? ''}',
        status: '${json['status'] ?? ''}',
        message: '${json['message'] ?? ''}',
        date: '${json['date'] ?? ''}',
      );
}

class HistoryStore {
  static const key = 'history_items_v1';

  Future<List<HistoryItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final items = jsonDecode(raw);
      if (items is! List) return [];
      return items.map((e) => HistoryItem.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> add(HistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await load();
    items.insert(0, item);
    final limited = items.take(100).map((e) => e.toJson()).toList();
    await prefs.setString(key, jsonEncode(limited));
  }
}


class LoginScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;
  const LoginScreen({super.key, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _settingsStore = SettingsStore();
  final _authStore = AuthSessionStore();
  final _attemptStore = LoginAttemptStore();
  final _localAuth = LocalAuthentication();

  final _site = TextEditingController();
  final _token = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _captcha = TextEditingController();

  final _rand = Random();
  int _a = 1;
  int _b = 1;
  bool _loading = true;
  bool _loggingIn = false;
  bool _biometricReady = false;
  DateTime? _lockUntil;

  @override
  void initState() {
    super.initState();
    _newCaptcha();
    _load();
  }

  Future<void> _load() async {
    final s = await _settingsStore.load();
    _site.text = s.siteUrl;
    _token.text = s.wpToken;
    _username.text = await _authStore.savedUsername();
    _lockUntil = await _attemptStore.lockUntil();
    final hasSavedUser = _username.text.trim().isNotEmpty && await _authStore.isLoggedIn();
    var canBio = false;
    try {
      canBio = hasSavedUser && (await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported());
    } catch (_) {
      canBio = false;
    }
    if (mounted) {
      setState(() {
        _biometricReady = canBio;
        _loading = false;
      });
    }
  }

  void _newCaptcha() {
    _a = _rand.nextInt(8) + 1;
    _b = _rand.nextInt(8) + 1;
    _captcha.clear();
  }

  Future<void> _login() async {
    if (await _attemptStore.isLocked()) {
      final until = await _attemptStore.lockUntil();
      setState(() => _lockUntil = until);
      _toast('به دلیل ورود اشتباه، تا ${_timeText(until)} امکان ورود ندارید.', error: true);
      return;
    }
    if (_site.text.trim().isEmpty || _token.text.trim().isEmpty) {
      _toast('آدرس سایت و توکن اتصال وردپرس را وارد کنید.', error: true);
      return;
    }
    if (_username.text.trim().isEmpty || _password.text.isEmpty) {
      _toast('نام کاربری و رمز وردپرس را وارد کنید.', error: true);
      return;
    }
    if (int.tryParse(_captcha.text.trim()) != _a + _b) {
      await _fail('کد امنیتی عددی اشتباه است.');
      _newCaptcha();
      setState(() {});
      return;
    }

    setState(() => _loggingIn = true);
    try {
      final old = await _settingsStore.load();
      final settings = old.copyWith(siteUrl: normalizeSite(_site.text), wpToken: _token.text);
      await _settingsStore.save(settings);
      final result = await WordPressApi(settings).login(username: _username.text, password: _password.text);
      await _attemptStore.reset();
      await _authStore.saveLogin(result);
      _password.clear();
      widget.onLoggedIn();
    } catch (e) {
      await _fail('$e');
      _newCaptcha();
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  Future<void> _fail(String message) async {
    final until = await _attemptStore.registerFailure();
    setState(() => _lockUntil = until);
    if (until != null) {
      _toast('۵ بار ورود اشتباه ثبت شد. ۱۰ دقیقه بعد دوباره تلاش کنید.', error: true);
    } else {
      final left = 5 - await _attemptStore.failedCount();
      _toast('$message ${left > 0 ? 'تلاش باقی‌مانده: $left' : ''}', error: true);
    }
  }

  Future<void> _biometricLogin() async {
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'برای ورود به مدیریت هوشمند اثر انگشت یا قفل گوشی را تأیید کنید.',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (ok) widget.onLoggedIn();
    } catch (e) {
      _toast('ورود با اثر انگشت انجام نشد: $e', error: true);
    }
  }

  String _timeText(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _openWebTeama() async {
    final uri = Uri.parse(kWebTeamaUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textDirection: TextDirection.rtl),
      backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final locked = _lockUntil != null && DateTime.now().isBefore(_lockUntil!);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          children: [
            const SizedBox(height: 14),
            const Center(child: BrandBadge(size: 78)),
            const SizedBox(height: 14),
            const Text(kAppName, textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kText)),
            const SizedBox(height: 6),
            const Text('ورود مدیر فروشگاه یا مدیر سایت', textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 15)),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                children: [
                  TextField(controller: _site, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'آدرس سایت وردپرس', hintText: 'https://example.com', prefixIcon: Icon(Icons.public_rounded))),
                  const SizedBox(height: 12),
                  TextField(controller: _token, obscureText: true, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'توکن اتصال افزونه', prefixIcon: Icon(Icons.vpn_key_rounded))),
                  const Divider(height: 30),
                  TextField(controller: _username, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'نام کاربری وردپرس', prefixIcon: Icon(Icons.person_rounded))),
                  const SizedBox(height: 12),
                  TextField(controller: _password, obscureText: true, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'رمز عبور وردپرس', prefixIcon: Icon(Icons.lock_rounded))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFED7AA))),
                        child: Text('$_a + $_b = ؟', textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900, color: kOrangeDark)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: _captcha, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'کپچا عددی'))),
                      IconButton(onPressed: () => setState(_newCaptcha), icon: const Icon(Icons.refresh_rounded)),
                    ],
                  ),
                  if (locked) ...[
                    const SizedBox(height: 12),
                    ErrorBox(message: 'حساب اپلیکیشن تا ${_timeText(_lockUntil)} قفل است. ۱۰ دقیقه بعد دوباره تلاش کنید.'),
                  ],
                  const SizedBox(height: 16),
                  AppButton(text: 'ورود', icon: Icons.login_rounded, loading: _loggingIn, onPressed: locked ? null : _login),
                  if (_biometricReady) ...[
                    const SizedBox(height: 10),
                    AppButton(text: 'ورود با اثر انگشت', icon: Icons.fingerprint_rounded, outlined: true, onPressed: _biometricLogin),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  const Text('طراحی در گروه ', style: TextStyle(color: kMuted)),
                  InkWell(onTap: _openWebTeama, child: const Text('وب تیما', style: TextStyle(color: kOrangeDark, fontWeight: FontWeight.w900, decoration: TextDecoration.underline))),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text('شهرام سعیدنیا', textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 4),
            const Text('نسخه نرم افزار $kAppVersion', textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _store = SettingsStore();
  final _site = TextEditingController();
  final _token = TextEditingController();
  final _openai = TextEditingController();
  final _deepseek = TextEditingController();
  final _openaiModel = TextEditingController();
  final _deepseekModel = TextEditingController();
  String _provider = 'openai';
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  AppSettings _loadedSettings = const AppSettings();
  bool _openaiSaved = false;
  bool _deepseekSaved = false;
  bool _editOpenai = true;
  bool _editDeepseek = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _store.load();
    _loadedSettings = s;
    _site.text = s.siteUrl;
    _token.text = s.wpToken;
    _openai.clear();
    _deepseek.clear();
    _openaiModel.text = s.openaiModel;
    _deepseekModel.text = s.deepseekModel;
    _provider = s.aiProvider;
    _openaiSaved = s.openaiKey.trim().isNotEmpty;
    _deepseekSaved = s.deepseekKey.trim().isNotEmpty;
    _editOpenai = !_openaiSaved;
    _editDeepseek = !_deepseekSaved;
    setState(() => _loading = false);
  }

  AppSettings _collect() {
    final keepOpenai = _openaiSaved && !_editOpenai;
    final keepDeepseek = _deepseekSaved && !_editDeepseek;
    return AppSettings(
      siteUrl: normalizeSite(_site.text),
      wpToken: _token.text,
      aiProvider: _provider,
      openaiKey: keepOpenai ? _loadedSettings.openaiKey : _openai.text,
      deepseekKey: keepDeepseek ? _loadedSettings.deepseekKey : _deepseek.text,
      openaiModel: _openaiModel.text.isEmpty ? 'gpt-4o-mini' : _openaiModel.text,
      deepseekModel: _deepseekModel.text.isEmpty ? 'deepseek-chat' : _deepseekModel.text,
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final next = _collect();
    await _store.save(next);
    setState(() {
      _loadedSettings = next;
      _openaiSaved = next.openaiKey.trim().isNotEmpty;
      _deepseekSaved = next.deepseekKey.trim().isNotEmpty;
      _editOpenai = !_openaiSaved;
      _editDeepseek = !_deepseekSaved;
      _openai.clear();
      _deepseek.clear();
      _saving = false;
    });
    if (mounted) _toast('تنظیمات ذخیره شد');
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    try {
      final s = _collect();
      await _store.save(s);
      final message = await WordPressApi(s).ping();
      if (mounted) _toast(message);
    } catch (e) {
      if (mounted) _toast('$e', error: true);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textDirection: TextDirection.rtl),
      backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
    ));
  }

  Widget _apiKeyField({required String label, required bool saved, required bool editing, required TextEditingController controller, required VoidCallback onReplace}) {
    if (saved && !editing) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB), border: Border.all(color: kLine), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text('$label ثبت شده است.', style: const TextStyle(color: kMuted))),
            TextButton(onPressed: onReplace, child: const Text('پاک کردن و ثبت جدید')),
          ],
        ),
      );
    }
    return TextField(
      controller: controller,
      obscureText: true,
      enableInteractiveSelection: false,
      autocorrect: false,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(labelText: label, hintText: 'کلید API را وارد کنید', prefixIcon: const Icon(Icons.lock_rounded)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const AppHeader(title: 'تنظیمات اتصال', subtitle: 'آدرس سایت، توکن وردپرس و کلیدهای هوش مصنوعی را وارد کنید'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              AppCard(
                child: Column(
                  children: [
                    const Icon(Icons.language_rounded, size: 54, color: kOrange),
                    const SizedBox(height: 10),
                    const Text('اتصال به وردپرس / ووکامرس', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text('توکن را از تنظیمات افزونه اپ مشخصات محصول در وردپرس بگیرید.', style: TextStyle(color: kMuted)),
                    const SizedBox(height: 18),
                    TextField(controller: _site, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'آدرس سایت', hintText: 'https://example.com', prefixIcon: Icon(Icons.public_rounded))),
                    const SizedBox(height: 14),
                    TextField(controller: _token, obscureText: true, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'توکن اتصال وردپرس', prefixIcon: Icon(Icons.key_rounded))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: kOrange),
                        SizedBox(width: 8),
                        Text('هوش مصنوعی داخل اپلیکیشن', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('کلیدها روی گوشی و در حافظه امن ذخیره می‌شوند، نه روی وردپرس.', style: TextStyle(color: kMuted)),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _provider,
                      decoration: const InputDecoration(labelText: 'ارائه‌دهنده هوش مصنوعی'),
                      items: const [
                        DropdownMenuItem(value: 'openai', child: Text('ChatGPT / OpenAI')),
                        DropdownMenuItem(value: 'deepseek', child: Text('DeepSeek')),
                      ],
                      onChanged: (v) => setState(() => _provider = v ?? 'openai'),
                    ),
                    const SizedBox(height: 14),
                    _apiKeyField(
                      label: 'OpenAI API Key',
                      saved: _openaiSaved,
                      editing: _editOpenai,
                      controller: _openai,
                      onReplace: () => setState(() {
                        _editOpenai = true;
                        _openaiSaved = false;
                        _openai.clear();
                        _loadedSettings = _loadedSettings.copyWith(openaiKey: '');
                      }),
                    ),
                    const SizedBox(height: 14),
                    TextField(controller: _openaiModel, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'مدل OpenAI', hintText: 'gpt-4o-mini')),
                    const SizedBox(height: 14),
                    _apiKeyField(
                      label: 'DeepSeek API Key',
                      saved: _deepseekSaved,
                      editing: _editDeepseek,
                      controller: _deepseek,
                      onReplace: () => setState(() {
                        _editDeepseek = true;
                        _deepseekSaved = false;
                        _deepseek.clear();
                        _loadedSettings = _loadedSettings.copyWith(deepseekKey: '');
                      }),
                    ),
                    const SizedBox(height: 14),
                    TextField(controller: _deepseekModel, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'مدل DeepSeek', hintText: 'deepseek-chat')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppButton(text: 'تست اتصال وردپرس', icon: Icons.wifi_tethering_rounded, outlined: true, loading: _testing, onPressed: _test),
              const SizedBox(height: 10),
              AppButton(text: 'ذخیره تنظیمات', icon: Icons.save_rounded, loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ],
    );
  }
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _settings = SettingsStore();
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<CategoryItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() {}));
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _settings.load();
      if (!s.hasWordPress) {
        throw ApiException('ابتدا از صفحه تنظیمات، آدرس سایت و توکن وردپرس را وارد کنید.');
      }
      _items = await WordPressApi(s).categories();
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim();
    final filtered = q.isEmpty ? _items : _items.where((e) => e.name.contains(q)).toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const AppHeader(title: 'دسته‌بندی‌ها', subtitle: 'دسته‌بندی مورد نظر خود را انتخاب کنید'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                TextField(controller: _search, decoration: const InputDecoration(hintText: 'جستجو در دسته‌بندی‌ها', prefixIcon: Icon(Icons.search_rounded))),
                const SizedBox(height: 16),
                if (_loading) const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                if (!_loading && _error != null) ErrorBox(message: _error!, onRetry: _load),
                if (!_loading && _error == null && filtered.isEmpty) const EmptyBox(text: 'دسته‌بندی‌ای پیدا نشد'),
                ...filtered.map((cat) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductsScreen(category: cat))),
                        child: Row(
                          children: [
                            CategoryImage(url: cat.image),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(cat.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text('${cat.count} محصول', style: const TextStyle(color: kMuted)),
                            ])),
                            const Icon(Icons.chevron_left_rounded, color: kMuted),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryImage extends StatelessWidget {
  final String url;
  const CategoryImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(color: kOrange.withOpacity(0.08), borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty ? const Icon(Icons.category_rounded, color: kOrange) : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.category_rounded, color: kOrange)),
    );
  }
}

class ProductsScreen extends StatefulWidget {
  final CategoryItem category;
  const ProductsScreen({super.key, required this.category});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _settings = SettingsStore();
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<ProductItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _settings.load();
      _items = await WordPressApi(s).products(categoryId: widget.category.id, search: _search.text.trim());
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            AppHeader(title: 'محصولات', subtitle: 'دسته: ${widget.category.name}', showBack: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _load(),
                    decoration: InputDecoration(
                      hintText: 'جستجو در محصولات',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.arrow_back_rounded)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: const Text(
                      'اولویت نمایش: فقط محصولات موجود، از جدیدترین به قدیمی‌ترین. محصولات ناموجود همیشه در انتهای لیست قرار می‌گیرند.',
                      style: TextStyle(color: kOrangeDark, fontWeight: FontWeight.w800, fontSize: 12.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_loading) const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                  if (!_loading && _error != null) ErrorBox(message: _error!, onRetry: _load),
                  if (!_loading && _error == null && _items.isEmpty) const EmptyBox(text: 'محصولی پیدا نشد'),
                  ..._items.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id))),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ProductImage(url: p.image, size: 82),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 7),
                                if (p.price.isNotEmpty) Text('${p.price} تومان', style: const TextStyle(color: kOrangeDark, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 5),
                                Text('SKU: ${p.sku.isEmpty ? 'ندارد' : p.sku}', textDirection: TextDirection.ltr, style: const TextStyle(color: kMuted)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    StatusPill(success: p.hasSpecs, text: p.hasSpecs ? 'دارای مشخصات' : 'بدون مشخصات'),
                                    StatusPill(success: p.inStock, text: p.inStock ? 'موجود' : 'ناموجود'),
                                  ],
                                ),
                              ])),
                              const Icon(Icons.chevron_left_rounded, color: kMuted),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onTap;
  const _SortChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? kOrange.withOpacity(0.11) : Colors.white,
          border: Border.all(color: selected ? kOrange : kLine),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: TextStyle(color: selected ? kOrangeDark : kText, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  final String url;
  final double size;
  const ProductImage({super.key, required this.url, this.size = 90});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty ? const Icon(Icons.inventory_2_outlined, color: kMuted) : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, color: kMuted)),
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _settingsStore = SettingsStore();
  final _historyStore = HistoryStore();
  final _speech = SpeechToText();
  ProductDetails? _product;
  AppSettings? _settings;
  bool _loading = true;
  bool _listening = false;
  bool _analyzing = false;
  bool _sending = false;
  String? _error;
  String _rawText = '';
  String _listenBaseText = '';
  String _productContent = '';
  String _seoTitle = '';
  String _seoDescription = '';
  String _mode = 'append';
  List<SpecItem> _aiSpecs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _settings = await _settingsStore.load();
      _product = await WordPressApi(_settings!).product(widget.productId);
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _product;
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ListView(padding: EdgeInsets.zero, children: [
                  const AppHeader(title: 'جزئیات محصول', subtitle: 'خطا در دریافت محصول', showBack: true),
                  Padding(padding: const EdgeInsets.all(20), child: ErrorBox(message: _error!, onRetry: _load)),
                ])
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const AppHeader(title: 'جزئیات محصول', subtitle: 'مشخصات و اطلاعات کامل محصول را مشاهده و ویرایش کنید', showBack: true),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        children: [
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22)), child: ProductHeroImage(url: p!.image)),
                                Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 8),
                                    if (p.price.isNotEmpty) Text('${p.price} تومان', style: const TextStyle(fontSize: 19, color: kOrangeDark, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 12),
                                    InfoLine(label: 'شناسه محصول', value: '${p.id}'),
                                    InfoLine(label: 'SKU', value: p.sku.isEmpty ? 'ندارد' : p.sku),
                                    InfoLine(label: 'دسته‌بندی', value: p.categoryNames.join('، ')),
                                  ]),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SectionTitle(icon: Icons.description_outlined, title: 'مشخصات فعلی'),
                          AppCard(child: p.attributes.isEmpty ? const Text('برای این محصول مشخصاتی ثبت نشده است.', style: TextStyle(color: kMuted)) : SpecsView(specs: p.attributes)),
                          const SizedBox(height: 16),
                          AppButton(text: _listening ? 'توقف ضبط ویس' : 'شروع ضبط ویس', icon: _listening ? Icons.stop_rounded : Icons.mic_rounded, onPressed: _toggleListen),
                          const SizedBox(height: 16),
                          SectionTitle(icon: Icons.record_voice_over_rounded, title: 'متن خام ویس'),
                          TextField(
                            minLines: 5,
                            maxLines: 10,
                            controller: TextEditingController(text: _rawText)..selection = TextSelection.collapsed(offset: _rawText.length),
                            onChanged: (v) => _rawText = v,
                            decoration: const InputDecoration(hintText: 'اینجا متن تبدیل‌شده از ویس نمایش داده می‌شود. امکان تایپ دستی هم دارید.'),
                          ),
                          const SizedBox(height: 12),
                          AppButton(text: 'تحلیل با هوش مصنوعی', icon: Icons.auto_awesome_rounded, loading: _analyzing, onPressed: _analyze),
                          const SizedBox(height: 18),
                          SectionTitle(icon: Icons.tune_rounded, title: 'مشخصات استخراج‌شده'),
                          AppCard(
                            child: Column(
                              children: [
                                if (_aiSpecs.isEmpty) const Text('هنوز مشخصاتی استخراج نشده است.', style: TextStyle(color: kMuted)),
                                ..._aiSpecs.asMap().entries.map((entry) => SpecEditorRow(
                                      item: entry.value,
                                      onDelete: () => setState(() => _aiSpecs.removeAt(entry.key)),
                                    )),
                                const SizedBox(height: 8),
                                TextButton.icon(onPressed: () => setState(() => _aiSpecs.add(SpecItem(name: '', value: ''))), icon: const Icon(Icons.add_rounded), label: const Text('افزودن مشخصه دستی')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SectionTitle(icon: Icons.article_outlined, title: 'محتوای محصول'),
                          TextField(
                            minLines: 4,
                            maxLines: 8,
                            controller: TextEditingController(text: _productContent)..selection = TextSelection.collapsed(offset: _productContent.length),
                            onChanged: (v) => _productContent = v,
                            decoration: const InputDecoration(hintText: 'بعد از تحلیل، یک پاراگراف توضیح محصول اینجا ساخته می‌شود و قابل ویرایش است.'),
                          ),
                          const SizedBox(height: 16),
                          SectionTitle(icon: Icons.manage_search_rounded, title: 'عنوان و توضیح متای سئو'),
                          TextField(
                            maxLength: 60,
                            controller: TextEditingController(text: _seoTitle)..selection = TextSelection.collapsed(offset: _seoTitle.length),
                            onChanged: (v) => _seoTitle = v,
                            decoration: const InputDecoration(labelText: 'عنوان سئو', hintText: 'حداکثر ۱۰ کلمه / ۶۰ کاراکتر'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            maxLength: 155,
                            minLines: 2,
                            maxLines: 4,
                            controller: TextEditingController(text: _seoDescription)..selection = TextSelection.collapsed(offset: _seoDescription.length),
                            onChanged: (v) => _seoDescription = v,
                            decoration: const InputDecoration(labelText: 'توضیح متا', hintText: 'حداکثر ۲۵ کلمه / ۱۵۵ کاراکتر'),
                          ),
                          const SizedBox(height: 16),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('نحوه ذخیره مشخصات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                                RadioListTile<String>(
                                  value: 'append',
                                  groupValue: _mode,
                                  activeColor: kOrange,
                                  onChanged: (v) => setState(() => _mode = v ?? 'append'),
                                  title: const Text('افزودن به مشخصات قبلی'),
                                  subtitle: const Text('حالت امن و پیش‌فرض؛ اطلاعات قبلی پاک نمی‌شود.'),
                                ),
                                RadioListTile<String>(
                                  value: 'replace',
                                  groupValue: _mode,
                                  activeColor: kOrange,
                                  onChanged: (v) => setState(() => _mode = v ?? 'append'),
                                  title: const Text('جایگزینی مشخصات قبلی'),
                                  subtitle: const Text('ویژگی‌های اختصاصی قبلی محصول با موارد جدید جایگزین می‌شود.'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppButton(text: 'ارسال مشخصات', icon: Icons.cloud_upload_rounded, loading: _sending, onPressed: _previewAndSend),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final available = await _speech.initialize(
      onError: (e) => _toast('خطای ضبط صدا: ${e.errorMsg}', error: true),
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
    );
    if (!available) {
      _toast('تبدیل گفتار به متن روی این گوشی فعال نیست. می‌توانید متن را دستی تایپ کنید.', error: true);
      return;
    }
    _listenBaseText = _rawText.trim();
    setState(() => _listening = true);
    await _speech.listen(
      localeId: 'fa_IR',
      listenMode: ListenMode.dictation,
      onResult: (SpeechRecognitionResult result) {
        final words = result.recognizedWords.trim();
        final combined = [_listenBaseText, words].where((e) => e.trim().isNotEmpty).join(' ');
        setState(() => _rawText = combined);
      },
    );
  }

  Future<void> _analyze() async {
    final p = _product;
    final s = _settings ?? await _settingsStore.load();
    if (p == null) return;
    if (_rawText.trim().isEmpty) {
      _toast('اول ویس بگیرید یا متن خام را دستی وارد کنید.', error: true);
      return;
    }
    setState(() => _analyzing = true);
    try {
      final result = await AiClient(s).extractSpecs(
        rawText: _rawText,
        productName: p.name,
        categoryName: p.categoryNames.join('، '),
        currentAttributes: p.attributes,
      );
      setState(() {
        _aiSpecs = result.specs;
        _productContent = result.content;
        _seoTitle = result.seoTitle;
        _seoDescription = result.seoDescription;
      });
      _toast(result.specs.isEmpty ? 'اطلاعات فنی واضحی در متن پیدا نشد.' : 'مشخصات و محتوای محصول ساخته شد');
    } catch (e) {
      _toast('$e', error: true);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _previewAndSend() async {
    final p = _product;
    if (p == null) return;
    final clean = _aiSpecs.where((e) => e.name.trim().isNotEmpty && e.value.trim().isNotEmpty).toList();
    if (clean.isEmpty) {
      _toast('هیچ مشخصه‌ای برای ارسال وجود ندارد.', error: true);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('پیش‌نمایش ارسال'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('شناسه: ${p.id} | SKU: ${p.sku}'),
              const Divider(height: 22),
              Text(_mode == 'append' ? 'روش ذخیره: افزودن به قبلی' : 'روش ذخیره: جایگزینی قبلی', style: const TextStyle(color: kOrangeDark, fontWeight: FontWeight.w800)),
              if (_productContent.trim().isNotEmpty) ...[
                const Text('محتوای محصول:', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(_productContent.trim()),
                const Divider(height: 22),
              ],
              if (_seoTitle.trim().isNotEmpty || _seoDescription.trim().isNotEmpty) ...[
                const Text('سئو:', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                if (_seoTitle.trim().isNotEmpty) Text('عنوان: ${_seoTitle.trim()}'),
                if (_seoDescription.trim().isNotEmpty) Text('متا: ${_seoDescription.trim()}'),
                const Divider(height: 22),
              ],
              const SizedBox(height: 12),
              ...clean.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('${e.name}: ${e.value}'),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('برگشت')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ارسال مشخصات')),
        ],
      ),
    );
    if (ok != true) return;
    await _send(clean);
  }

  Future<void> _send(List<SpecItem> clean) async {
    final p = _product;
    final s = _settings ?? await _settingsStore.load();
    if (p == null) return;
    setState(() => _sending = true);
    try {
      final message = await WordPressApi(s).saveSpecs(productId: p.id, mode: _mode, specs: clean, rawText: _rawText, provider: s.aiProvider, productContent: _productContent, seoTitle: _seoTitle, seoDescription: _seoDescription);
      await _historyStore.add(HistoryItem(productId: p.id, productName: p.name, sku: p.sku, status: 'success', message: message, date: DateTime.now().toString().substring(0, 19)));
      _toast(message);
      await _load();
    } catch (e) {
      await _historyStore.add(HistoryItem(productId: p.id, productName: p.name, sku: p.sku, status: 'error', message: '$e', date: DateTime.now().toString().substring(0, 19)));
      _toast('$e', error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textDirection: TextDirection.rtl),
      backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
    ));
  }
}

class ProductHeroImage extends StatelessWidget {
  final String url;
  const ProductHeroImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      color: const Color(0xFFF3F4F6),
      child: url.isEmpty ? const Icon(Icons.inventory_2_outlined, size: 70, color: kMuted) : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, size: 70, color: kMuted)),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const SectionTitle({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [Icon(icon, color: kOrange), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))]),
    );
  }
}

class InfoLine extends StatelessWidget {
  final String label;
  final String value;
  const InfoLine({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [Text('$label:', style: const TextStyle(color: kMuted)), const SizedBox(width: 8), Expanded(child: Text(value, textDirection: TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.w700)))]),
    );
  }
}

class SpecsView extends StatelessWidget {
  final List<SpecItem> specs;
  const SpecsView({super.key, required this.specs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: specs.map((e) => Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 2, child: Text('${e.name}:', style: const TextStyle(color: kMuted))),
              Expanded(flex: 3, child: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
          )).toList(),
    );
  }
}

class SpecEditorRow extends StatelessWidget {
  final SpecItem item;
  final VoidCallback onDelete;
  const SpecEditorRow({super.key, required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: item.name,
              onChanged: (v) => item.name = v,
              decoration: const InputDecoration(labelText: 'نام', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: item.value,
              onChanged: (v) => item.value = v,
              decoration: const InputDecoration(labelText: 'مقدار', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            ),
          ),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: Colors.red)),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _store = HistoryStore();
  late Future<List<HistoryItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _store.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const AppHeader(title: 'تاریخچه', subtitle: 'محصولاتی که مشخصاتشان ارسال شده است'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: FutureBuilder<List<HistoryItem>>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final items = snap.data!;
              if (items.isEmpty) return const EmptyBox(text: 'هنوز چیزی در تاریخچه ثبت نشده است.');
              return Column(
                children: items.map((h) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [Expanded(child: Text(h.productName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))), StatusPill(success: h.status == 'success', text: h.status == 'success' ? 'موفق' : 'خطا')]),
                          const SizedBox(height: 8),
                          Text('SKU: ${h.sku} | شناسه: ${h.productId}', style: const TextStyle(color: kMuted)),
                          const SizedBox(height: 6),
                          Text(h.date, textDirection: TextDirection.ltr, style: const TextStyle(color: kMuted)),
                          const SizedBox(height: 8),
                          Text(h.message),
                        ]),
                      ),
                    )).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  final bool success;
  final String text;
  const StatusPill({super.key, required this.success, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = success ? Colors.green : kOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withOpacity(0.25))),
      child: Text(text, style: TextStyle(color: success ? Colors.green.shade800 : kOrangeDark, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorBox({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(children: [
        Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 40),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          AppButton(text: 'تلاش دوباره', icon: Icons.refresh_rounded, outlined: true, onPressed: onRetry),
        ],
      ]),
    );
  }
}

class EmptyBox extends StatelessWidget {
  final String text;
  const EmptyBox({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(children: [
        const Icon(Icons.inbox_outlined, color: kMuted, size: 42),
        const SizedBox(height: 10),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]),
    );
  }
}
