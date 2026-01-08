// ==============================================================================
// SYSTEM: SENTINEL (ANDROID)
// MODULE: main.dart
// ROLE:   FLUTTER CLIENT UI (V173 - ANDROID LOCALHOST FIX)
// ==============================================================================

// Unused imports removed
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

// --- CONFIGURATION ---
// CRITICAL FIX: Android Emulator requires 10.0.2.2 to see the Host Mac.
// Web requires localhost.

String get serverUrl {
  // Android Emulator Localhost
  return "http://10.0.2.2:8000";
}

const String _supportEmail = "PeterJFrancoIII1@gmail.com";

// --- 1. LOCALIZATION ---
class Loc {
  static const Map<String, Map<String, String>> dict = {
    "SUBTITLE": {
      "en":
          "Real-Time Civilian Risk Intelligence from Regional Conflicts & Instability",
      "th": "ข่าวและวิเคราะห์ความเสี่ยงจากความขัดแย้งในภูมิภาค",
      "km": "ព័ត៌មាននិងការវិភាគហានិភ័យពីជម្លោះក្នុងតំបន់"
    },
    "DEFCON": {
      "en": "DEFCON",
      "th": "ระดับการเตรียมพร้อม",
      "km": "កម្រិតការពារ"
    },
    "ACTION_1": {
      "en": "EXTREME DANGER: FOLLOW LOCAL NEWS ADVISORIES.",
      "th": "อันตรายสูงสุด: โปรดติดตามข่าวสารท้องถิ่น",
      "km": "គ្រោះថ្នាក់ខ្លាំង៖ សូមតាមដានព័ត៌មានក្នុងស្រុក"
    },
    "ACTION_2": {
      "en": "SEVERE: ARTILLERY / MORTAR ACTIVITY DETECTED.",
      "th": "รุนแรง: ตรวจพบปืนใหญ่/ระเบิด",
      "km": "ធ្ងន់ធ្ងរ៖ រកឃើញសកម្មភាពកាំភ្លើងធំ"
    },
    "ACTION_3": {
      "en": "HIGH ALERT: ENEMY TROOP MOBILIZATION.",
      "th": "เตรียมพร้อม: การเคลื่อนพลข้าศึก",
      "km": "ការប្រុងប្រយ័ត្នខ្ពស់៖ ការចល័តទ័ពសត្រូវ"
    },
    "ACTION_4": {
      "en": "CAUTION: MILITARY PRESENCE INCREASED.",
      "th": "ระวัง: ทหารหนาแน่น",
      "km": "ការប្រុងប្រយ័ត្ន៖ វត្តមានយោធាកើនឡើង"
    },
    "ACTION_5": {
      "en": "LOW: STANDARD BORDER PATROL.",
      "th": "ปกติ: ลาดตระเวนปกติ",
      "km": "កម្រិតទាប៖ ការល្បាតព្រំដែនធម្មតា"
    },
    "READY_1": {
      "en": "MAINTAIN READINESS: IMMEDIATE EVACUATION",
      "th": "ความพร้อม: อพยพทันที",
      "km": "ត្រៀមខ្លួន៖ ជម្លៀសជាបន្ទាន់"
    },
    "READY_2": {
      "en": "MAINTAIN READINESS: 1 HOUR",
      "th": "ความพร้อม: 1 ชั่วโมง",
      "km": "ត្រៀមខ្លួន៖ ១ ម៉ោង"
    },
    "READY_3": {
      "en": "MAINTAIN READINESS: 6 HOURS",
      "th": "ความพร้อม: 6 ชั่วโมง",
      "km": "ត្រៀមខ្លួន៖ ៦ ម៉ោង"
    },
    "READY_4": {
      "en": "MAINTAIN READINESS: 24 HOURS",
      "th": "ความพร้อม: 24 ชั่วโมง",
      "km": "ត្រៀមខ្លួន៖ ២៤ ម៉ោង"
    },
    "READY_5": {
      "en": "MAINTAIN READINESS: RELAXED",
      "th": "ความพร้อม: ผ่อนคลาย",
      "km": "ត្រៀមខ្លួន៖ សម្រាក"
    },
    "EVACUATION_POINT": {
      "en": "NEAREST EVACUATION POINT",
      "th": "จุดอพยพที่ใกล้ที่สุด",
      "km": "ចំណុចជម្លៀសដែលនៅជិតបំផុត"
    },
    "HAZARD_DIST": {
      "en": "Distance to Kill Box",
      "th": "ระยะห่างจากพื้นที่สังหาร",
      "km": "ចម្ងាយទៅតំបន់គ្រោះថ្នាក់"
    },
    "SAFE_ZONE_DIST": {
      "en": "Distance to Evacuation Point",
      "th": "ระยะห่างจากจุดอพยพ",
      "km": "ចម្ងាយទៅចំណុចជម្លៀស"
    },
    "OPEN_MAPS": {
      "en": "Open Navigation",
      "th": "เปิดแผนที่นำทาง",
      "km": "បើកការរុករក"
    },
    "CANCEL": {"en": "Cancel", "th": "ยกเลิก", "km": "បោះបង់"},
    "DONATE": {
      "en": "Donate <3 (Paypal)",
      "th": "บริจาค <3 (Paypal)",
      "km": "បរិច្ចាគ <3 (Paypal)"
    },
    "ABOUT": {
      "en": "ABOUT SENTINEL",
      "th": "เกี่ยวกับ SENTINEL",
      "km": "អំពី SENTINEL"
    },
    "ALERTS": {"en": "SITREP", "th": "รายงานสถานการณ์", "km": "របាយការណ៍"},
    "OUTLOOK": {"en": "FORECAST", "th": "การคาดการณ์", "km": "ការព្យាករណ៍"},
    "MAP": {"en": "MAP", "th": "แผนที่", "km": "ផែនទី"},
    "SYSTEM": {"en": "SYSTEM", "th": "ระบบ", "km": "ប្រព័ន្ធ"},
    "SOURCES": {"en": "SOURCES", "th": "แหล่งที่มา", "km": "ប្រភព"},
    "LANGUAGE": {"en": "LANGUAGE", "th": "ภาษา", "km": "ភាសា"},
    "OPERATING_COUNTRY": {
      "en": "OPERATING COUNTRY",
      "th": "ประเทศปฏิบัติการ",
      "km": "ប្រទេសប្រតិបត្តិការ"
    },
    "INITIALIZE": {
      "en": "INITIALIZE UPLINK",
      "th": "เริ่มการเชื่อมต่อ",
      "km": "ចាប់ផ្តើមការតភ្ជាប់"
    },
    "OSINT_PRED": {
      "en": "OSINT PREDICTION (48 HOURS)",
      "th": "การคาดการณ์ข่าวกรอง (48 ชั่วโมง)",
      "km": "ការព្យាករណ៍ OSINT (៤៨ ម៉ោង)"
    },
    "PROBABILITY": {
      "en": "Probability",
      "th": "ความน่าจะเป็น",
      "km": "ប្រូបាប៊ីលីតេ"
    },
    "EXPERIMENTAL_HEADER": {
      "en": "EXPERIMENTAL STRATEGIC FORECAST",
      "th": "การคาดการณ์เชิงกลยุทธ์ (ทดลอง)",
      "km": "ការព្យាករណ៍យុទ្ធសាស្ត្រពិសោធន៍"
    },
    "PROJECTED_DEFCON": {
      "en": "PROJECTED DEFCON",
      "th": "DEFCON ที่คาดการณ์",
      "km": "DEFCON ដែលបានព្យាករណ៍"
    },
    "ROADS_TO_AVOID": {
      "en": "ROADS TO AVOID",
      "th": "เส้นทางที่ควรหลีกเลี่ยง",
      "km": "ផ្លូវដែលត្រូវជៀសវាង"
    },
    "DANGER_AREAS": {
      "en": "DANGER AREAS",
      "th": "พื้นที่อันตราย",
      "km": "តំបន់គ្រោះថ្នាក់"
    },
    "UPDATED": {
      "en": "UPDATED",
      "th": "อัปเดตเมื่อ",
      "km": "ធ្វើបច្ចុប្បន្នភាព"
    },
    "THREAT_MATRIX": {
      "en": "THREAT MATRIX",
      "th": "ตารางภัยคุกคาม",
      "km": "តារាងការគំរាមកំហែង"
    },
    "OSMAND": {
      "en": "OSMAnd (Offline Maps)",
      "th": "OSMAnd (แผนที่ออฟไลน์)",
      "km": "OSMAnd (ផែនទីក្រៅបណ្តាញ)"
    },
    "ZIP_HINT": {
      "en": "Enter Zip code Here",
      "th": "ใส่รหัสไปรษณีย์ที่นี่",
      "km": "បញ្ចូលលេខកូដតំបន់"
    },
    "CAUTION": {
      "en": "(Caution: AI Generated Report)",
      "th": "(คำเตือน: รายงานสร้างโดย AI)",
      "km": "(ការប្រុងប្រយ័ត្ន៖ របាយការណ៍បង្កើតដោយ AI)"
    },
    "CONTACT_US": {
      "en": "CONTACT SUPPORT",
      "th": "ติดต่อเรา",
      "km": "ទាក់ទង​មក​ពួក​យើង"
    },
  };
  static String tr(String key, String lang) =>
      dict[key]?[lang] ?? dict[key]?['en'] ?? key;
}

// --- 2. DATA MODELS ---
class SourceMetadata {
  final String publisher;
  final String title;
  final String url;
  const SourceMetadata(
      {required this.publisher, required this.title, required this.url});
  factory SourceMetadata.fromJson(Map<String, dynamic> json) => SourceMetadata(
      publisher: json['publisher'] ?? "Unknown Source",
      title: json['title'] ?? "Intel Report",
      url: json['url'] ?? "");
}

class IntelDetails {
  final int defconStatus;
  final String? trend;
  final EvacPoint evacuationPoint;
  final List<String> roadsToAvoid;
  final List<String> emergencyAvoidLocations;
  final List<String> summary;
  final String? lastUpdated;
  final GeoPoint? userLocation;
  final List<ThreatZone> tacticalOverlays;
  final PredictiveData? predictive;
  final double? threatDistanceKm;
  final String? locationName;
  final String? zipCode;
  final List<SourceMetadata> sources;
  final bool isCertified;
  final String? analystModel;
  final String? translatorModel;
  final String? systemUrl;

  const IntelDetails(
      {required this.defconStatus,
      this.trend,
      required this.evacuationPoint,
      required this.roadsToAvoid,
      required this.emergencyAvoidLocations,
      required this.summary,
      this.lastUpdated,
      this.userLocation,
      required this.tacticalOverlays,
      this.predictive,
      this.threatDistanceKm,
      this.locationName,
      this.zipCode,
      this.sources = const [],
      this.isCertified = true,
      this.analystModel,
      this.translatorModel,
      this.systemUrl});

  factory IntelDetails.fromJson(Map<String, dynamic> json) {
    return IntelDetails(
        defconStatus: json['defcon_status'] ?? 5,
        trend: json['trend'],
        evacuationPoint: EvacPoint.fromJson(json['evacuation_point'] ?? {}),
        roadsToAvoid: List<String>.from(json['roads_to_avoid'] ?? []),
        emergencyAvoidLocations:
            List<String>.from(json['emergency_avoid_locations'] ?? []),
        summary: List<String>.from(json['summary'] ?? []),
        lastUpdated: json['last_updated'],
        userLocation: json['user_location'] != null
            ? GeoPoint.fromJson(json['user_location'])
            : null,
        tacticalOverlays: (json['tactical_overlays'] as List?)
                ?.map((i) => ThreatZone.fromJson(i))
                .toList() ??
            [],
        predictive: json['predictive'] != null
            ? PredictiveData.fromJson(json['predictive'])
            : null,
        threatDistanceKm: (json['threat_distance_km'] as num?)?.toDouble(),
        locationName: json['location_name'],
        zipCode: json['zip_code'],
        sources: (json['sources'] as List<dynamic>? ?? [])
            .map((e) => SourceMetadata.fromJson(e))
            .toList(),
        isCertified: json['is_certified'] ?? true,
        analystModel: json['analyst_model'],
        translatorModel: json['translator_model'],
        systemUrl: json['system_url']);
  }
}

class EvacPoint {
  final String name;
  final double lat;
  final double lon;
  final double? distanceKm;
  final String reason;
  const EvacPoint(
      {required this.name,
      required this.lat,
      required this.lon,
      this.distanceKm,
      required this.reason});
  factory EvacPoint.fromJson(Map<String, dynamic> json) {
    return EvacPoint(
        name: json['name'] ?? "Unknown",
        lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
        lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        reason: json['reason'] ?? "Designated Safe Zone");
  }
}

class ThreatZone {
  final String name;
  final double lat;
  final double lon;
  final double radius;
  final String? type;
  final String? lastKinetic;

  const ThreatZone(
      {required this.name,
      required this.lat,
      required this.lon,
      required this.radius,
      this.type,
      this.lastKinetic});

  factory ThreatZone.fromJson(Map<String, dynamic> json) {
    return ThreatZone(
        name: json['name'] ?? "Unknown Threat",
        lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
        lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
        radius: (json['radius'] as num?)?.toDouble() ?? 1000.0,
        type: json['type'],
        lastKinetic: json['last_kinetic']);
  }
}

class PredictiveData {
  final int defcon;
  final String? trend;
  final List<String> forecastSummary;
  final int riskProbability;
  const PredictiveData(
      {required this.defcon,
      this.trend,
      required this.forecastSummary,
      required this.riskProbability});
  factory PredictiveData.fromJson(Map<String, dynamic> json) {
    return PredictiveData(
        defcon: json['defcon'] ?? 5,
        trend: json['trend'],
        forecastSummary: List<String>.from(json['forecast_summary'] ?? []),
        riskProbability: json['risk_probability'] ?? 0);
  }
}

class GeoPoint {
  final double lat;
  final double lon;
  const GeoPoint({required this.lat, required this.lon});
  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0);
}

// --- 3. STATE ---
class SentinelProvider with ChangeNotifier {
  IntelDetails? intel;
  String connectionStatus = "Ready";
  String userZip = "";
  String userCountry = "TH";
  String userLang = "en";
  bool isLocked = true;
  String sentinelID = "unknown";
  SentinelProvider() {
    _loadInitData();
  }

  Future<void> _loadInitData() async {
    final prefs = await SharedPreferences.getInstance();
    sentinelID = prefs.getString('SentinelID') ?? "";
    String createdStr = prefs.getString('IDCreatedDate') ?? "";

    // EPHEMERAL ID ROTATION (PDPA COMPLIANCE)
    bool needsRotation = false;
    if (createdStr.isEmpty) {
      needsRotation = true;
    } else {
      final created = DateTime.parse(createdStr);
      final age = DateTime.now().difference(created);
      if (age.inHours > 24) needsRotation = true;
    }

    if (sentinelID.isEmpty || needsRotation) {
      debugPrint(">> [PDPA] Rotating Ephemeral ID");
      sentinelID = const Uuid().v4();
      await prefs.setString('SentinelID', sentinelID);
      await prefs.setString('IDCreatedDate', DateTime.now().toIso8601String());
    }
    userZip = prefs.getString('SavedZip') ?? "";
    notifyListeners();
  }

  Future<void> saveZip(String zip) async {
    userZip = zip;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('SavedZip', zip);
    notifyListeners();
  }

  void setLang(String lang) {
    userLang = lang;
    notifyListeners();
  }

  void setCountry(String country) {
    userCountry = country;
    notifyListeners();
  }

  Future<void> initializeSystem() async {
    if (userZip.isEmpty) return;
    intel = null;
    isLocked = false;
    connectionStatus = "ESTABLISHING UPLINK...";
    notifyListeners();
    fetchLatestIntel();
  }

  void resetSystem() {
    isLocked = true;
    intel = null;
    notifyListeners();
  }

  Future<void> fetchLatestIntel() async {
    final url = Uri.parse(
        "$serverUrl/intel?zip=$userZip&country=$userCountry&lang=$userLang&device_id=$sentinelID");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'success') {
          intel = IntelDetails.fromJson(decoded['data']);
          connectionStatus = "Online";
        } else if (decoded['status'] == 'calculating') {
          connectionStatus = "GATHERING INTEL...";
          notifyListeners();
          await Future.delayed(const Duration(seconds: 3));
          if (!isLocked) fetchLatestIntel();
          return;
        } else {
          connectionStatus = decoded['message'] ?? "Error";
        }
      } else {
        connectionStatus = "Server Error (500)";
      }
    } catch (e) {
      connectionStatus = "Connection Error: Check Internet";
    }
    notifyListeners();
  }
}

// --- 4. MAIN ---
void main() {
  runApp(MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => SentinelProvider())],
      child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentinel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050505),
        primaryColor: Colors.yellow,
        colorScheme: const ColorScheme.dark(
            primary: Colors.yellow, secondary: Colors.red),
        textTheme: Typography.whiteMountainView.apply(fontFamily: 'Courier'),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<SentinelProvider>(context);
    if (vm.isLocked) return const LandingPage();
    if (vm.intel == null) return const LoadingPage();
    return const DashboardPage();
  }
}

// --- 5. CUSTOM PAINTERS ---
class IOSRingPainter extends CustomPainter {
  final Color color;
  final int defcon;
  final double pulse;
  const IOSRingPainter(
      {required this.color, required this.defcon, required this.pulse});
  @override
  void paint(Canvas canvas, Size size) {
    Paint bgPaint = Paint()
      ..color = Colors.grey[900]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2, bgPaint);
    Paint fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.butt;
    if (defcon == 1 || defcon == 5) {
      fgPaint.maskFilter = MaskFilter.blur(BlurStyle.solid, 20 * pulse);
    }
    double sweepAngle = 0;
    if (defcon == 5) sweepAngle = 0.05 * math.pi;
    if (defcon == 4) sweepAngle = 0.5 * math.pi;
    if (defcon == 3) sweepAngle = 1.0 * math.pi;
    if (defcon == 2) sweepAngle = 1.5 * math.pi;
    if (defcon == 1) sweepAngle = 2 * math.pi;
    canvas.drawArc(
        Rect.fromCircle(
            center: Offset(size.width / 2, size.height / 2),
            radius: size.width / 2),
        -math.pi / 2,
        sweepAngle,
        false,
        fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

Color _getGlobalDefconColor(int level) {
  switch (level) {
    case 1:
      return Colors.red;
    case 2:
      return Colors.orange;
    case 3:
      return Colors.yellow;
    case 4:
      return Colors.green;
    default:
      return Colors.blue;
  }
}

Widget _buildTrendWidget(String? trend) {
  if (trend == "rising") {
    return const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.arrow_upward, color: Colors.red, size: 16),
      Text(" RISING",
          style: TextStyle(
              color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14))
    ]);
  }
  if (trend == "falling") {
    return const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.arrow_downward, color: Colors.green, size: 16),
      Text(" FALLING",
          style: TextStyle(
              color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14))
    ]);
  }
  return const Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.remove, color: Colors.grey, size: 16),
    Text(" STABLE",
        style: TextStyle(
            color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14))
  ]);
}

Widget _buildRichText(String text) {
  List<TextSpan> spans = [];
  final RegExp exp = RegExp(r"(\*\*[^*]+\*\*)|(\*[^*]+\*)");
  int start = 0;

  for (Match m in exp.allMatches(text)) {
    if (m.start > start) {
      spans.add(TextSpan(text: text.substring(start, m.start)));
    }

    String match = m.group(0)!;
    if (match.startsWith("**")) {
      spans.add(TextSpan(
          text: match.substring(2, match.length - 2),
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white)));
    } else if (match.startsWith("*")) {
      spans.add(TextSpan(
          text: match.substring(1, match.length - 1),
          style: const TextStyle(
              fontStyle: FontStyle.italic, color: Colors.yellow)));
    }

    start = m.end;
  }

  if (start < text.length) {
    spans.add(TextSpan(text: text.substring(start)));
  }

  return RichText(
      text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.white),
          children: spans));
}

// --- LANDING PAGE ---
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _zipCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<SentinelProvider>(context, listen: false);
      _zipCtrl.text = vm.userZip;
    });
  }

  @override
  void dispose() {
    _zipCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  void _showSupportDialog() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text("About & Support",
                  style: TextStyle(color: Colors.white)),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("SENTINEL V172",
                        style: TextStyle(
                            color: Colors.yellow, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text("For support or to report source errors:",
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 5),
                    GestureDetector(
                        onTap: () => _launchURL("mailto:$_supportEmail"),
                        child: const Text(_supportEmail,
                            style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline))),
                    const SizedBox(height: 10),
                    const Text("Official Website:",
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 5),
                    GestureDetector(
                        onTap: () => _launchURL(
                            "https://sentinelcivilianriskanalysis.netlify.app"),
                        child: const Text(
                            "sentinelcivilianriskanalysis.netlify.app",
                            style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline))),
                    const SizedBox(height: 20),
                    const Text("Data Source Policy:",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const Text(
                        "Aggregated from verified open sources (OSINT) and news feeds.",
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("CLOSE"))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<SentinelProvider>(context);
    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x33FFEB3B), blurRadius: 20)
                            ]),
                        child: Image.asset('assets/sentinel_dark.png',
                            errorBuilder: (c, o, s) => const Icon(Icons.shield,
                                size: 70, color: Colors.yellow))),
                    const SizedBox(height: 30),
                    const Text("SENTINEL",
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            fontFamily: 'Courier')),
                    const SizedBox(height: 10),
                    Text(Loc.tr("SUBTITLE", vm.userLang).toUpperCase(),
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 10, letterSpacing: 1),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 40),
                    SizedBox(
                        width: double.infinity,
                        child: CupertinoSegmentedControl<String>(
                          children: const {
                            "en": Padding(
                                padding: EdgeInsets.all(8),
                                child: Text("ENGLISH")),
                            "th": Padding(
                                padding: EdgeInsets.all(8),
                                child: Text("ภาษาไทย")),
                            "km": Padding(
                                padding: EdgeInsets.all(8),
                                child: Text("ភាសាខ្មែរ"))
                          },
                          groupValue: vm.userLang,
                          onValueChanged: (v) => vm.setLang(v),
                          borderColor: Colors.grey[800],
                          selectedColor: Colors.yellow,
                          unselectedColor: Colors.black,
                          pressedColor: const Color(0x33FFEB3B),
                        )),
                    const SizedBox(height: 15),
                    SizedBox(
                        width: double.infinity,
                        child: CupertinoSegmentedControl<String>(
                          children: const {
                            "TH": Padding(
                                padding: EdgeInsets.all(8),
                                child: Text("THAILAND")),
                            "KH": Padding(
                                padding: EdgeInsets.all(8),
                                child: Text("CAMBODIA"))
                          },
                          groupValue: vm.userCountry,
                          onValueChanged: (v) => vm.setCountry(v),
                          borderColor: Colors.grey[800],
                          selectedColor: Colors.red,
                          unselectedColor: Colors.black,
                        )),
                    const SizedBox(height: 25),
                    TextField(
                      controller: _zipCtrl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Courier',
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1A1A1A),
                          hintText: Loc.tr("ZIP_HINT", vm.userLang),
                          hintStyle: TextStyle(color: Colors.grey[700]),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none)),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => vm.saveZip(v),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                            onPressed: () => vm.initializeSystem(),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))),
                            child: Text(Loc.tr("INITIALIZE", vm.userLang),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1)))),
                    const SizedBox(height: 50),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.favorite,
                            size: 14, color: Colors.white),
                        label: Text(Loc.tr("DONATE", vm.userLang),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
                        onPressed: () => _launchURL(
                            "https://www.paypal.com/donate?hosted_button_id=SKTF4DM7JLV26"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20))),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.info,
                            size: 14, color: Colors.white),
                        label: Text(Loc.tr("ABOUT", vm.userLang),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
                        onPressed: _showSupportDialog,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20))),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<SentinelProvider>(context);
    return Scaffold(
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const CircularProgressIndicator(color: Colors.red),
      const SizedBox(height: 20),
      Text(vm.connectionStatus,
          style: const TextStyle(color: Colors.yellow, fontFamily: 'Courier')),
      const SizedBox(height: 40),
      TextButton(
          onPressed: () => vm.resetSystem(),
          child: const Text("ABORT",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))
    ])));
  }
}

// --- DASHBOARD ---
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(duration: const Duration(seconds: 1), vsync: this)
          ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<SentinelProvider>(context);
    final data = vm.intel!;
    final tabs = [
      SitRepView(
          data: data, lang: vm.userLang, pulseAnimation: _pulseAnimation),
      ForecastView(data: data, lang: vm.userLang),
      MapTab(data: data, lang: vm.userLang),
      SystemView(vm: vm, data: data)
    ];

    String displayDate = "SYNCING...";
    if (data.lastUpdated != null) {
      try {
        DateTime parsed = DateTime.parse(data.lastUpdated!).toUtc();
        displayDate = "${DateFormat("MM/dd/yy HH:mm").format(parsed)} UTC";
      } catch (e) {
        displayDate = data.lastUpdated!;
      }
    }

    return Scaffold(
      appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  size: 20, color: Colors.grey),
              onPressed: () => vm.resetSystem()),
          title:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                  child: Text(
                      "${data.zipCode ?? vm.userZip} | ${vm.userCountry}",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis))
            ]),
            Text(data.locationName?.toUpperCase() ?? "UNKNOWN CITY",
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
          ]),
          actions: [
            Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("DATA FRESHNESS",
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold)),
                      Text(displayDate,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold))
                    ]))
          ]),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF0D0D0D),
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 9,
        unselectedFontSize: 9,
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.warning_amber),
              label: Loc.tr("ALERTS", vm.userLang)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.visibility),
              label: Loc.tr("OUTLOOK", vm.userLang)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.map), label: Loc.tr("MAP", vm.userLang)),
          const BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "SYSTEM"),
        ],
      ),
    );
  }
}

// --- REPLACED SOURCES VIEW WITH NOTHING ---
// --- (SourcesView Removed) ---

// --- TAB 1: SITREP ---
class SitRepView extends StatelessWidget {
  final IntelDetails data;
  final String lang;
  final Animation<double> pulseAnimation;
  const SitRepView(
      {required this.data,
      required this.lang,
      required this.pulseAnimation,
      super.key});

  void _showMapOptions(BuildContext context, double lat, double lon) {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1A1A1A),
        builder: (ctx) => Wrap(children: [
              ListTile(
                  title: Text(Loc.tr("OPEN_MAPS", lang),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))),
              ListTile(
                  leading: const Icon(Icons.map, color: Colors.orange),
                  title: Text(Loc.tr("OSMAND", lang)),
                  textColor: Colors.white,
                  onTap: () => _launchMap("OSM", lat, lon)),
              ListTile(
                  leading: const Icon(Icons.map, color: Colors.blue),
                  title: const Text("Google Maps"),
                  textColor: Colors.white,
                  onTap: () => _launchMap("Google", lat, lon)),
              ListTile(
                  leading: const Icon(Icons.close, color: Colors.red),
                  title: Text(Loc.tr("CANCEL", lang)),
                  textColor: Colors.red,
                  onTap: () => Navigator.pop(context)),
            ]));
  }

  Future<void> _launchMap(String type, double lat, double lon) async {
    String url = "";
    if (type == "OSM") {
      url = "osmandmaps://?lat=$lat&lon=$lon";
    }
    if (type == "Google") {
      url = "https://www.google.com/maps/dir/?api=1&destination=$lat,$lon";
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (type == "OSM") {
        launchUrl(Uri.parse(
            "https://play.google.com/store/apps/details?id=net.osmand"));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String killBoxDist = "N/A";
    if (data.userLocation != null && data.tacticalOverlays.isNotEmpty) {
      const Distance distance = Distance();
      double km = distance.as(
          LengthUnit.Kilometer,
          LatLng(data.userLocation!.lat, data.userLocation!.lon),
          LatLng(data.tacticalOverlays[0].lat, data.tacticalOverlays[0].lon));
      killBoxDist = "${km.toStringAsFixed(1)} km";
    }

    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 20),
          Center(
              child: GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DefconListScreen(lang: lang))),
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                  width: 220,
                  height: 220,
                  child: AnimatedBuilder(
                      animation: pulseAnimation,
                      builder: (context, child) => CustomPaint(
                          painter: IOSRingPainter(
                              color: !data.isCertified && data.defconStatus <= 2
                                  ? Colors.white
                                  : _getGlobalDefconColor(data.defconStatus),
                              defcon: data.defconStatus,
                              pulse: pulseAnimation.value)))),
              Column(children: [
                Text(Loc.tr("DEFCON", lang),
                    style: TextStyle(
                        color: !data.isCertified && data.defconStatus <= 2
                            ? Colors.white
                            : _getGlobalDefconColor(data.defconStatus),
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                AnimatedBuilder(
                    animation: pulseAnimation,
                    builder: (ctx, child) => Text("${data.defconStatus}",
                        style: TextStyle(
                            fontSize: 90,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Courier',
                            color: !data.isCertified && data.defconStatus <= 2
                                ? Colors.white
                                : _getGlobalDefconColor(data.defconStatus),
                            shadows: data.defconStatus <= 2 && data.isCertified
                                ? [
                                    BoxShadow(
                                        color: Colors.red,
                                        blurRadius: 20 * pulseAnimation.value)
                                  ]
                                : []))),
                // NEW: Certification Label
                if (data.defconStatus <= 2)
                  Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: !data.isCertified
                                  ? Colors.white
                                  : _getGlobalDefconColor(data.defconStatus)),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(
                          !data.isCertified ? "UNCERTIFIED" : "CERTIFIED",
                          style: TextStyle(
                              color: !data.isCertified
                                  ? Colors.white
                                  : _getGlobalDefconColor(data.defconStatus),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 2))),
                if (data.defconStatus > 2) _buildTrendWidget(data.trend)
              ])
            ]),
          )),
          const SizedBox(height: 30),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _getGlobalDefconColor(data.defconStatus))),
              child: Column(children: [
                Text(
                    data.defconStatus <= 2 && !data.isCertified
                        ? "PENDING VERIFICATION"
                        : Loc.tr("ACTION_${data.defconStatus}", lang),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center),
                const SizedBox(height: 5),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: _getGlobalDefconColor(data.defconStatus)
                        .withValues(alpha: 0.2),
                    child: Text(Loc.tr("READY_${data.defconStatus}", lang),
                        style: TextStyle(
                            color: _getGlobalDefconColor(data.defconStatus),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)))
              ])),
          const SizedBox(height: 15),
          InkWell(
              onTap: () => _showMapOptions(
                  context, data.evacuationPoint.lat, data.evacuationPoint.lon),
              child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.directions_run,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Text(Loc.tr("EVACUATION_POINT", lang),
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12))
                        ]),
                        const SizedBox(height: 5),
                        Text(data.evacuationPoint.name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            overflow: TextOverflow.ellipsis),
                        if (data.evacuationPoint.reason.isNotEmpty)
                          Text(data.evacuationPoint.reason,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 11)),
                        Divider(color: Colors.grey[800]),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                  child: Text(
                                      "${Loc.tr("SAFE_ZONE_DIST", lang)}: ${data.evacuationPoint.distanceKm?.toInt()} km",
                                      style: const TextStyle(
                                          color: Colors.green, fontSize: 12),
                                      overflow: TextOverflow.ellipsis))
                            ])
                      ]))),
          const SizedBox(height: 15),
          if (data.emergencyAvoidLocations.isNotEmpty) ...[
            Text(Loc.tr("DANGER_AREAS", lang),
                style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.warning, color: Colors.red, size: 12),
                        const SizedBox(width: 5),
                        Text("${Loc.tr("HAZARD_DIST", lang)}: $killBoxDist",
                            style: const TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold))
                      ]),
                      const Divider(color: Colors.red),
                      ...data.emergencyAvoidLocations.map((r) => Text("• $r",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)))
                    ])),
            const SizedBox(height: 15),
          ],
          if (data.roadsToAvoid.isNotEmpty) ...[
            Text(Loc.tr("ROADS_TO_AVOID", lang),
                style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.yellow)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: data.roadsToAvoid
                        .map((r) => Text("• $r",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)))
                        .toList())),
            const SizedBox(height: 15),
          ],
          if (data.summary.isNotEmpty)
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("INTELLIGENCE SUMMARY",
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ...data.summary.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("• ",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 14)),
                              Expanded(
                                  child: _buildRichText(
                                      s.replaceAll(RegExp(r'^\d+\.\s*'), '')))
                            ],
                          )))
                    ]))
        ]));
  }
}

// --- TAB 2: FORECAST ---
class ForecastView extends StatelessWidget {
  final IntelDetails data;
  final String lang;
  const ForecastView({required this.data, required this.lang, super.key});

  @override
  Widget build(BuildContext context) {
    if (data.predictive == null) {
      return const Center(child: Text("No Intel Available"));
    }
    final pred = data.predictive!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(Loc.tr("EXPERIMENTAL_HEADER", lang),
              style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 10)),
          Text(Loc.tr("CAUTION", lang),
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 20),
          Stack(alignment: Alignment.center, children: [
            CustomPaint(
                size: const Size(180, 180),
                painter: IOSRingPainter(
                    color: _getGlobalDefconColor(pred.defcon),
                    defcon: pred.defcon,
                    pulse: 1.0)),
            Column(children: [
              Text(Loc.tr("PROJECTED_DEFCON", lang),
                  style: const TextStyle(color: Colors.grey, fontSize: 10)),
              Text("${pred.defcon}",
                  style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: _getGlobalDefconColor(pred.defcon))),
              _buildTrendWidget(pred.trend)
            ])
          ]),
          const SizedBox(height: 20),
          Text(
              "${Loc.tr("PROBABILITY", lang).toUpperCase()}: ${pred.riskProbability}%",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Loc.tr("OSINT_PRED", lang),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 10)),
                const SizedBox(height: 10),
                ...pred.forecastSummary.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text("• ${s.replaceAll(RegExp(r'^\d+\.\s*'), '')}",
                          style: const TextStyle(color: Colors.white)),
                    )),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- TAB 3: MAP ---
class MapTab extends StatefulWidget {
  final IntelDetails data;
  final String lang;
  const MapTab({required this.data, required this.lang, super.key});
  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();
  bool isForecastMode = false;
  void _zoom(double change) {
    _mapController.move(
        _mapController.camera.center, _mapController.camera.zoom + change);
  }

  @override
  Widget build(BuildContext context) {
    final userPos = LatLng(widget.data.userLocation?.lat ?? 14.0,
        widget.data.userLocation?.lon ?? 100.0);

    final markers = <Marker>[];
    final circles = <CircleMarker>[];

    markers.add(Marker(
        point: userPos,
        child:
            const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40)));
    markers.add(Marker(
        point: LatLng(
            widget.data.evacuationPoint.lat, widget.data.evacuationPoint.lon),
        child: const Icon(Icons.run_circle, color: Colors.green, size: 40)));

    for (var t in widget.data.tacticalOverlays) {
      String type = "MULTIPLE/UNKNOWN";
      double radius = 5000;
      Color color = Colors.red;

      String nameLower = t.name.toLowerCase();
      String typeLower = (t.type ?? "").toLowerCase();
      String combined = "$nameLower $typeLower";

      if (combined.contains("artillery") || combined.contains("mortar")) {
        type = "ARTILLERY";
        radius = 20000;
      } else if (combined.contains("infantry") || combined.contains("troop")) {
        type = "INFANTRY";
        radius = 5000;
      } else if (combined.contains("armor") || combined.contains("tank")) {
        type = "ARMOR";
        radius = 10000;
      } else if (combined.contains("rocket") || combined.contains("missile")) {
        type = "ROCKETS";
        radius = 40000;
      } else if (combined.contains("air") || combined.contains("strike")) {
        type = "AIR STRIKE";
        radius = 50000;
      }

      if (isForecastMode) {
        color = Colors.orange;
        radius = radius * 1.5;
        type = "PRED. $type";
      }

      circles.add(CircleMarker(
          point: LatLng(t.lat, t.lon),
          color: color.withValues(alpha: 0.2),
          borderColor: color,
          borderStrokeWidth: 2,
          useRadiusInMeter: true,
          radius: radius));

      markers.add(Marker(
          width: 120,
          height: 80, // Increased height for date
          point: LatLng(t.lat, t.lon),
          child: Column(children: [
            Icon(Icons.warning, color: color, size: 30),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                color: Colors.black,
                child: Column(children: [
                  Text(type,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold)),
                  if (t.lastKinetic != null)
                    Text(t.lastKinetic!,
                        style:
                            const TextStyle(color: Colors.yellow, fontSize: 6))
                ]))
          ])));
    }

    return Stack(children: [
      FlutterMap(
        mapController: _mapController,
        options: MapOptions(
            initialCenter: userPos,
            initialZoom: 9.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            )),
        children: [
          TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.sentinel.android'),
          CircleLayer(circles: circles),
          MarkerLayer(markers: markers)
        ],
      ),
      Positioned(
          bottom: 20,
          right: 20,
          child: Column(children: [
            FloatingActionButton(
                heroTag: "z1",
                mini: true,
                onPressed: () => _zoom(1),
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                child: const Icon(Icons.add)),
            const SizedBox(height: 10),
            FloatingActionButton(
                heroTag: "z2",
                mini: true,
                onPressed: () => _zoom(-1),
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                child: const Icon(Icons.remove)),
            const SizedBox(height: 10),
            FloatingActionButton(
                heroTag: "z3",
                mini: true,
                onPressed: () => _mapController.move(userPos, 9.0),
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                child: const Icon(Icons.my_location)),
          ])),
      Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Container(
            height: 40,
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: Colors.black87, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Expanded(
                  child: GestureDetector(
                      onTap: () => setState(() => isForecastMode = false),
                      child: Container(
                          decoration: BoxDecoration(
                              color: !isForecastMode
                                  ? Colors.red
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6)),
                          alignment: Alignment.center,
                          child: Text(Loc.tr("ALERTS", widget.lang),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12))))),
              Expanded(
                  child: GestureDetector(
                      onTap: () => setState(() => isForecastMode = true),
                      child: Container(
                          decoration: BoxDecoration(
                              color: isForecastMode
                                  ? Colors.orange
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6)),
                          alignment: Alignment.center,
                          child: Text(Loc.tr("OUTLOOK", widget.lang),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12))))),
            ]),
          ))
    ]);
  }
}

// --- TAB 5: SYSTEM ---
class SystemView extends StatelessWidget {
  final SentinelProvider vm;
  final IntelDetails data;
  const SystemView({required this.vm, required this.data, super.key});

  Future<void> _launchEmail(String email) async {
    final Uri url = Uri.parse("mailto:$email");
    if (!await launchUrl(url)) throw Exception('Could not launch $url');
  }

  Future<void> _launchWeb(String? url) async {
    if (url == null) return;
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Row(children: [
        Icon(Icons.dns, color: Colors.green),
        SizedBox(width: 10),
        Text("SYSTEM DIAGNOSTICS",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white))
      ]),
      const SizedBox(height: 20),
      _sysRow("SENTINEL ID", vm.sentinelID, Colors.green),
      _sysRow("VERSION", "V173", Colors.white),
      _sysRow("DATE", "2026-01-03", Colors.white),
      _sysRow(
          "ANALYST", data.analystModel ?? "gemini-3-pro-preview", Colors.white),
      _sysRow("TRANSLATOR", data.translatorModel ?? "gemini-2.5-flash-lite",
          Colors.white),
      _sysRow("DATA SOURCES", "Google RSS, OSINT", Colors.white),
      _sysRow("LAST UPDATE", _formatTime(data.lastUpdated), Colors.white),
      const SizedBox(height: 20),
      if (data.systemUrl != null && data.systemUrl!.isNotEmpty) ...[
        GestureDetector(
            onTap: () => _launchWeb(data.systemUrl),
            child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.blue[900],
                    borderRadius: BorderRadius.circular(8)),
                child: const Center(
                    child: Text("VISIT WEBSITE",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1))))),
        const SizedBox(height: 10),
      ],
      GestureDetector(
          onTap: () => _launchEmail(_supportEmail),
          child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.blue[900],
                  borderRadius: BorderRadius.circular(8)),
              child: const Center(
                  child: Text("CONTACT SUPPORT",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)))))
    ]);
  }

  Widget _sysRow(String label, String val, Color valColor) {
    return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8)),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(val,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: valColor, fontFamily: 'Courier'),
                  softWrap: true))
        ]));
  }

  String _formatTime(String? iso) {
    if (iso == null) return "N/A";
    try {
      final dt = DateTime.parse(iso).toUtc();
      return "${DateFormat("MM/dd/yy HH:mm").format(dt)} UTC";
    } catch (e) {
      return iso;
    }
  }
}

// --- NEW PAGE: THREAT MATRIX ---
class DefconListScreen extends StatelessWidget {
  final String lang;
  const DefconListScreen({required this.lang, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Loc.tr("THREAT_MATRIX", lang),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                letterSpacing: 2)),
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.grey),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children:
            [1, 2, 3, 4, 5].map((level) => _buildLevelItem(level)).toList(),
      ),
    );
  }

  Widget _buildLevelItem(int level) {
    Color c = _getGlobalDefconColor(level);
    return Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            border: Border.all(color: c),
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Text("$level",
              style: TextStyle(
                  fontSize: 40, fontWeight: FontWeight.bold, color: c)),
          const SizedBox(width: 20),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text("DEFCON $level",
                    style: TextStyle(
                        color: c, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(Loc.tr("ACTION_$level", lang),
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        border: Border.all(color: c.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(4),
                        color: c.withValues(alpha: 0.1)),
                    child: Text(Loc.tr("READY_$level", lang),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)))
              ]))
        ]));
  }
}
