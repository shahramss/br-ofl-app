import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

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

class ProductSpecsApp extends StatelessWidget {
  const ProductSpecsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'اپ مشخصات محصول',
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
        home: const MainShell(),
      ),
    );
  }
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
                  const SizedBox(width: 48),
                const Spacer(),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.lock_outline_rounded, color: kOrange),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('اپ مشخصات محصول', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('ثبت مشخصات محصولات', style: TextStyle(color: kMuted, fontSize: 13)),
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

  ProductItem({required this.id, required this.name, required this.sku, required this.price, required this.image, required this.link, required this.hasSpecs});

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: _toInt(json['id']),
      name: '${json['name'] ?? ''}',
      sku: '${json['sku'] ?? ''}',
      price: '${json['price'] ?? ''}',
      image: '${json['image'] ?? ''}',
      link: '${json['link'] ?? ''}',
      hasSpecs: json['has_specs'] == true,
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

  Future<List<ProductItem>> products({required int categoryId, String search = '', String sort = 'newest', int page = 1}) async {
    final data = await _getJson(_uri('/products', {
      'category_id': '$categoryId',
      'search': search,
      'sort': sort,
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

  Future<String> saveSpecs({required int productId, required String mode, required List<SpecItem> specs, required String rawText, required String provider}) async {
    final clean = specs.where((e) => e.name.trim().isNotEmpty && e.value.trim().isNotEmpty).map((e) => e.toJson()).toList();
    final data = await _postJson(_uri('/products/$productId/specs'), {
      'mode': mode,
      'specs': clean,
      'raw_text': rawText,
      'ai_provider': provider,
    });
    return '${data['message'] ?? 'مشخصات ذخیره شد'}';
  }
}

class AiClient {
  final AppSettings settings;
  AiClient(this.settings);

  Future<List<SpecItem>> extractSpecs({required String rawText, required String productName, required String categoryName, required List<SpecItem> currentAttributes}) async {
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
فقط اطلاعات فنی‌ای را که در متن خام صریحاً گفته شده استخراج کن.
هیچ مقدار حدسی، تبلیغاتی یا ساختگی نساز.
اگر چیزی گفته نشده، آن فیلد را برنگردان.
خروجی فقط JSON معتبر باشد، بدون توضیح اضافه.
فرمت دقیق:
{"specs":[{"name":"قطر","value":"۱۰ میلی‌متر"},{"name":"جنس","value":"فولاد"}]}
''';

    final body = {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': 'تو یک دستیار استخراج مشخصات فنی محصولات فروشگاهی هستی. خروجی فقط JSON معتبر بده.'
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
      String content = '';
      if (data is Map && data['choices'] is List && (data['choices'] as List).isNotEmpty) {
        final first = (data['choices'] as List).first;
        if (first is Map && first['message'] is Map) {
          content = '${(first['message'] as Map)['content'] ?? ''}';
        }
      }
      final jsonText = _extractJsonText(content);
      final parsed = jsonDecode(jsonText);
      final specsRaw = parsed['specs'];
      if (specsRaw is! List) return [];
      return specsRaw
          .map((e) => SpecItem.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.name.trim().isNotEmpty && e.value.trim().isNotEmpty)
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('تحلیل با هوش مصنوعی انجام نشد. کلید API، مدل و اینترنت گوشی را بررسی کنید. جزئیات: $e');
    }
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _store.load();
    _site.text = s.siteUrl;
    _token.text = s.wpToken;
    _openai.text = s.openaiKey;
    _deepseek.text = s.deepseekKey;
    _openaiModel.text = s.openaiModel;
    _deepseekModel.text = s.deepseekModel;
    _provider = s.aiProvider;
    setState(() => _loading = false);
  }

  AppSettings _collect() {
    return AppSettings(
      siteUrl: normalizeSite(_site.text),
      wpToken: _token.text,
      aiProvider: _provider,
      openaiKey: _openai.text,
      deepseekKey: _deepseek.text,
      openaiModel: _openaiModel.text.isEmpty ? 'gpt-4o-mini' : _openaiModel.text,
      deepseekModel: _deepseekModel.text.isEmpty ? 'deepseek-chat' : _deepseekModel.text,
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _store.save(_collect());
    setState(() => _saving = false);
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
                    TextField(controller: _openai, obscureText: true, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'OpenAI API Key', hintText: 'sk-...', prefixIcon: Icon(Icons.lock_rounded))),
                    const SizedBox(height: 14),
                    TextField(controller: _openaiModel, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'مدل OpenAI', hintText: 'gpt-4o-mini')),
                    const SizedBox(height: 14),
                    TextField(controller: _deepseek, obscureText: true, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'DeepSeek API Key', prefixIcon: Icon(Icons.lock_rounded))),
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
  String _sort = 'newest';
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
      _items = await WordPressApi(s).products(categoryId: widget.category.id, search: _search.text.trim(), sort: _sort);
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
                  Row(
                    children: [
                      Expanded(child: _SortChip(label: 'جدیدترین', value: 'newest', selected: _sort == 'newest', onTap: _changeSort)),
                      const SizedBox(width: 8),
                      Expanded(child: _SortChip(label: 'نام', value: 'name', selected: _sort == 'name', onTap: _changeSort)),
                      const SizedBox(width: 8),
                      Expanded(child: _SortChip(label: 'قیمت', value: 'price', selected: _sort == 'price', onTap: _changeSort)),
                    ],
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
                                StatusPill(success: p.hasSpecs, text: p.hasSpecs ? 'دارای مشخصات' : 'بدون مشخصات'),
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

  void _changeSort(String value) {
    setState(() => _sort = value);
    _load();
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
    setState(() => _listening = true);
    await _speech.listen(
      localeId: 'fa_IR',
      listenMode: ListenMode.dictation,
      onResult: (SpeechRecognitionResult result) {
        setState(() => _rawText = result.recognizedWords);
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
      final specs = await AiClient(s).extractSpecs(
        rawText: _rawText,
        productName: p.name,
        categoryName: p.categoryNames.join('، '),
        currentAttributes: p.attributes,
      );
      setState(() => _aiSpecs = specs);
      _toast(specs.isEmpty ? 'اطلاعات فنی واضحی در متن پیدا نشد.' : 'مشخصات استخراج شد');
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
      final message = await WordPressApi(s).saveSpecs(productId: p.id, mode: _mode, specs: clean, rawText: _rawText, provider: s.aiProvider);
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
  final VoidCallback onRetry;
  const ErrorBox({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(children: [
        Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 40),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        AppButton(text: 'تلاش دوباره', icon: Icons.refresh_rounded, outlined: true, onPressed: onRetry),
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
