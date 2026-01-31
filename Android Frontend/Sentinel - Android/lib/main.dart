// ==============================================================================
// SYSTEM: SENTINEL (ANDROID)
// MODULE: main.dart
// ROLE:   FLUTTER CLIENT UI (V173 - ANDROID LOCALHOST FIX)
// ==============================================================================

// Unused imports removed
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

// Jobs v2 Module
import 'jobs_v2/jobs_v2.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:sentinel_android/services/iap_service.dart';

// --- CONFIGURATION ---
// CRITICAL FIX: Android Emulator requires 10.0.2.2 to see the Host Mac.
// Web requires localhost.

// Initialized to fail-safe localhost, but updated by determineServerUrl
String _activeServerUrl = "http://10.0.2.2:8000";

String get serverUrl {
  return _activeServerUrl;
}

/// Checks VPS connectivity. If reachable, sets serverUrl to VPS.
/// If not (timeout/error), uses Localhost (Emulator).
Future<void> determineServerUrl() async {
  const String vpsUrl = "http://146.190.7.51";
  final String localUrl = (kIsWeb || Platform.isIOS || Platform.isMacOS)
      ? "http://127.0.0.1:8000"
      : "http://10.0.2.2:8000";

  // 1. Try Localhost FIRST (For Dev/Debug)
  try {
    debugPrint("[INIT] Checking LOCAL connectivity: $localUrl");
    final response = await http
        .get(Uri.parse("$localUrl/intel/status"))
        .timeout(const Duration(seconds: 2));
    if (response.statusCode == 200) {
      debugPrint("[INIT] Local Server detected. Using LOCALHOST.");
      _activeServerUrl = localUrl;
      return;
    }
  } catch (_) {}

  // 2. Fallback to VPS (Production)
  try {
    debugPrint("[INIT] Checking VPS connectivity: $vpsUrl");
    final response = await http
        .get(Uri.parse("$vpsUrl/intel/status"))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      debugPrint("[INIT] VPS Reached & Healthy. Using PRODUCTION URL.");
      _activeServerUrl = vpsUrl;
      return;
    } else {
      debugPrint("[INIT] VPS Reached but returned ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("[INIT] VPS Unreachable: $e");
  }

  // 3. Last Resort: Default to Localhost
  debugPrint("[INIT] No servers found. Defaulting to Localhost.");
  _activeServerUrl = localUrl;
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
    "JOBS": {"en": "JOBS", "th": "งาน", "km": "ការងារ"},
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
    // --- MISSING KEYS ADDED ---
    "SITREP_DETAIL": {
      "en": "SITREP DETAIL",
      "th": "รายละเอียดรายงาน",
      "km": "ព័ត៌មានលម្អិត"
    },
    "SERVER_GENERATED_INTEL": {
      "en": "SERVER-GENERATED INTEL REPORT",
      "th": "รายงานข่าวกรองจากเซิร์ฟเวอร์",
      "km": "របាយការណ៍ស៊ើបការណ៍ពីម៉ាស៊ីនមេ"
    },
    "SOURCE_CITATIONS": {
      "en": "SOURCE CITATIONS",
      "th": "อ้างอิงแหล่งที่มา",
      "km": "ប្រភពឯកសារយោង"
    },
    "NO_CITATIONS": {
      "en": "No citations available.",
      "th": "ไม่มีข้อมูลอ้างอิง",
      "km": "មិនមានឯកសារយោង"
    },
    "UNCERTIFIED": {
      "en": "UNCERTIFIED",
      "th": "ยังไม่รับรอง",
      "km": "មិនទាន់បញ្ជាក់"
    },
    "CERTIFIED": {"en": "CERTIFIED", "th": "รับรองแล้ว", "km": "បានបញ្ជាក់"},
    "PENDING_VERIFICATION": {
      "en": "PENDING VERIFICATION",
      "th": "รอการตรวจสอบ",
      "km": "កំពុងរង់ចាំការផ្ទៀងផ្ទាត់"
    },
    "INTELLIGENCE_REPORT": {
      "en": "SITUATION REPORT",
      "th": "รายงานข่าวกรอง",
      "km": "របាយការណ៍ស៊ើបការណ៍"
    },
    "INTELLIGENCE_SUMMARY": {
      "en": "INTELLIGENCE SUMMARY",
      "th": "สรุปข่าวกรอง",
      "km": "សេចក្តីសង្ខេបស៊ើបការណ៍"
    },
    "CONFIDENCE": {
      "en": "CONFIDENCE",
      "th": "ความเชื่อมั่น",
      "km": "ទំនុកចិត្ត"
    },
    "ANALYST_RATIONALE": {
      "en": "ANALYST RATIONALE",
      "th": "เหตุผลของนักวิเคราะห์",
      "km": "ហេតុផលរបស់អ្នកវិភាគ"
    },
    "HISTORICAL_AND_SOURCE": {
      "en": "HISTORICAL & SOURCE CITATIONS",
      "th": "ประวัติและแหล่งที่มา",
      "km": "ប្រវត្តិនិងប្រភព"
    },
    "NO_SPECIFIC_CITATIONS": {
      "en": "No specific citations linked.",
      "th": "ไม่มีการเชื่อมโยงการอ้างอิง",
      "km": "មិនមានឯកសារយោងជាក់លាក់"
    },
    "NO_INTEL_AVAILABLE": {
      "en": "No Intel Available",
      "th": "ไม่มีข้อมูลข่าวกรอง",
      "km": "មិនមានព័ត៌មាន"
    },
    "SYSTEM_DIAGNOSTICS": {
      "en": "SYSTEM DIAGNOSTICS",
      "th": "การวินิจฉัยระบบ",
      "km": "ការធ្វើរោគវិនិច្ឆ័យប្រព័ន្ធ"
    },
    "SENTINEL_ID": {
      "en": "SENTINEL ID",
      "th": "รหัส SENTINEL",
      "km": "អត្តសញ្ញាណ SENTINEL"
    },
    "VERSION": {"en": "VERSION", "th": "เวอร์ชัน", "km": "កំណែ"},
    "DATE": {"en": "DATE", "th": "วันที่", "km": "កាលបរិច្ឆេទ"},
    "ANALYST": {"en": "ANALYST", "th": "นักวิเคราะห์", "km": "អ្នកវិភាគ"},
    "TRANSLATOR": {"en": "TRANSLATOR", "th": "นักแปล", "km": "អ្នកបកប្រែ"},
    "DATA_SOURCES": {
      "en": "DATA SOURCES",
      "th": "แหล่งข้อมูล",
      "km": "ប្រភពទិន្នន័យ"
    },
    "LAST_UPDATE": {
      "en": "LAST UPDATE",
      "th": "อัปเดตล่าสุด",
      "km": "ការធ្វើបច្ចុប្បន្នភាពចុងក្រោយ"
    },
    "VISIT_WEBSITE": {
      "en": "VISIT WEBSITE",
      "th": "เยี่ยมชมเว็บไซต์",
      "km": "ចូលមើលគេហទំព័រ"
    },
    "DONATE_BUTTON": {
      "en": "DONATE (PAYPAL)",
      "th": "บริจาค (PAYPAL)",
      "km": "បរិច្ចាគ (PAYPAL)"
    },
    "CONTACT_SUPPORT_BUTTON": {
      "en": "CONTACT SUPPORT",
      "th": "ติดต่อฝ่ายสนับสนุน",
      "km": "ទាក់ទងជំនួយ"
    },
    "OPEN_WEBSITE": {
      "en": "Open Sentinel Website <3",
      "th": "เปิดเว็บไซต์ Sentinel <3",
      "km": "បើកគេហទំព័រ Sentinel <3"
    },
    "DONATE_IAP": {
      "en": "Donate (Apple In-App Purchase)",
      "th": "บริจาค (ผ่าน Apple)",
      "km": "បរិច្ចាគ (Apple In-App)"
    },
    "SELECT_AMOUNT": {
      "en": "Select a donation amount",
      "th": "เลือกยอดบริจาค",
      "km": "ជ្រើសរើសចំនួនបរិច្ចាគ"
    },
    "IAP_UNAVAILABLE": {
      "en": "IAP Unavailable",
      "th": "ไม่สามารถซื้อภายในแอปได้",
      "km": "មិនអាចទិញក្នុងកម្មវិធីបានទេ"
    },
    "IAP_ERROR_MSG": {
      "en":
          "In-App Purchases are not available on the Simulator or Products failed to load.",
      "th": "การซื้อภายในแอปไม่พร้อมใช้งาน",
      "km": "ការទិញក្នុងកម្មវិធីមិនមានទេ"
    },
    "MAIL_APP_UNAVAILABLE": {
      "en": "Mail App Unavailable",
      "th": "แอปอีเมลไม่พร้อมใช้งาน",
      "km": "កម្មវិធីអ៊ីមែលមិនមានទេ"
    },
    "COULD_NOT_OPEN_MAIL": {
      "en": "Could not open mail app",
      "th": "เปิดแอปอีเมลไม่ได้",
      "km": "មិនអាចបើកកម្មវិធីអ៊ីមែលបានទេ"
    }
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

class Citation {
  final String source;
  final String date;
  final String url;
  const Citation({required this.source, required this.date, required this.url});
  factory Citation.fromJson(Map<String, dynamic> json) => Citation(
      source: json['source'] ?? "Unknown",
      date: json['date'] ?? "",
      url: json['url'] ?? "");
}

class CitationResponse {
  final List<Citation> citations;
  final String description;
  const CitationResponse({required this.citations, required this.description});
}

class SitRepEntry {
  final String id;
  final String topic;
  final String summary;
  final String date;
  final String type;
  final int confidenceScore;
  const SitRepEntry(
      {required this.id,
      required this.topic,
      required this.summary,
      required this.date,
      this.type = "General",
      this.confidenceScore = 0});
  factory SitRepEntry.fromJson(Map<String, dynamic> json) => SitRepEntry(
      id: json['id'] ?? "",
      topic: json['topic'] ?? "Update",
      summary: json['summary'] ?? "",
      date: json['date'] ?? "",
      type: json['type'] ?? "General",
      confidenceScore: json['confidence_score'] ?? 0);
}

class ForecastEntry {
  final String topic;
  final String prediction;
  final String rationale;
  const ForecastEntry(
      {required this.topic, required this.prediction, required this.rationale});
  factory ForecastEntry.fromJson(Map<String, dynamic> json) => ForecastEntry(
      topic: json['topic'] ?? "",
      prediction: json['prediction'] ?? "",
      rationale: json['rationale'] ?? "");
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
  final String? donateUrl;
  final List<SitRepEntry> sitrepEntries;
  final List<ForecastEntry> forecastEntries;

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
      this.systemUrl,
      this.donateUrl,
      this.sitrepEntries = const [],
      this.forecastEntries = const []});

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
        systemUrl: json['system_url'],
        donateUrl: json['donate_url'],
        sitrepEntries: (json['sitrep_entries'] as List?)
                ?.map((e) => SitRepEntry.fromJson(e))
                .toList() ??
            [],
        forecastEntries: (json['forecast_entries'] as List?)
                ?.map((e) => ForecastEntry.fromJson(e))
                .toList() ??
            []);
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
  final String? date;

  const ThreatZone(
      {required this.name,
      required this.lat,
      required this.lon,
      required this.radius,
      this.type,
      this.lastKinetic,
      this.date});

  factory ThreatZone.fromJson(Map<String, dynamic> json) {
    return ThreatZone(
        name: json['name'] ?? "Unknown Threat",
        lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
        lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
        radius: (json['radius'] as num?)?.toDouble() ?? 1000.0,
        type: json['type'],
        lastKinetic: json['last_kinetic'],
        date: json['date']);
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
  String donateUrl =
      "https://www.paypal.com/donate?hosted_button_id=SKTF4DM7JLV26";
  String websiteUrl = "https://sentinelcivilianriskanalysis.netlify.app";
  String loadingStage = "Initializing...";

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
    fetchConfig(); // Get dynamic URLs
    fetchLatestIntel();
    pollServerStatus(); // Start polling status
  }

  void resetSystem() {
    isLocked = true;
    intel = null;
    notifyListeners();
  }

  Future<void> fetchConfig() async {
    try {
      final url = Uri.parse("$serverUrl/config/public");
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        donateUrl = data['donate_url'] ?? donateUrl;
        websiteUrl = data['website_url'] ?? websiteUrl;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Config Error: $e");
    }
  }

  Future<void> pollServerStatus() async {
    if (intel != null || isLocked) return;

    try {
      final url = Uri.parse("$serverUrl/intel/status");
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        loadingStage = data['stage'] ?? "Processing...";
        notifyListeners();
      }
    } catch (_) {}

    if (intel == null && !isLocked) {
      Future.delayed(const Duration(seconds: 2), pollServerStatus);
    }
  }

  Future<String> fetchServerLogs() async {
    try {
      // Admin endpoint - secure in prod, open in local dev
      final url = Uri.parse(
          "$serverUrl/admin/ops/logs?lines=200&_t=${DateTime.now().millisecondsSinceEpoch}");
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['logs'] ?? "No logs returned.";
      }
      return "Error: ${response.statusCode}";
    } catch (e) {
      return "Connection Error: $e";
    }
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

  Future<CitationResponse> fetchCitations(String type, String key) async {
    final url = Uri.parse(
        "$serverUrl/intel/citations?zip=$userZip&lang=$userLang&type=$type&key=$key");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'success') {
          final data = decoded['data'];
          final description = decoded['description'] ?? "";
          List<dynamic> raw = [];
          if (type == 'sitrep') {
            raw = data['sitrep_citations']?[key] ?? [];
          } else {
            raw = data['forecast_citations']?[key] ?? [];
          }
          final quotes = raw.map((e) => Citation.fromJson(e)).toList();
          return CitationResponse(citations: quotes, description: description);
        }
      }
    } catch (e) {
      debugPrint("Citation Error: $e");
    }
    return const CitationResponse(
        citations: [], description: "Error fetching report.");
  }
}

// --- 4. MAIN ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await determineServerUrl();
  if (!kIsWeb) {
    await IAPService().initialize();
  }
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
  final t = trend?.toLowerCase() ?? "stable";
  if (t == "rising") {
    return const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.arrow_upward, color: Colors.red, size: 16),
      Text(" RISING",
          style: TextStyle(
              color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14))
    ]);
  }
  if (t == "falling") {
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
    try {
      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (!mounted) return;
      if (urlString.startsWith("mailto:")) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text("Mail App Unavailable"),
            content: Text(
                "Could not open mail app.\nPlease email: ${urlString.replaceFirst('mailto:', '')}"),
            actions: [
              CupertinoDialogAction(
                  child: const Text("OK"), onPressed: () => Navigator.pop(ctx))
            ],
          ),
        );
      } else {
        debugPrint("Error launching URL: $e");
      }
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
                        onPressed: () => _handleDonate(context, vm.donateUrl),
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

  void _handleDonate(BuildContext context, String url) {
    if (kIsWeb) {
      _launchURL(url);
      return;
    }
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              child: const Text('Open Sentinel Website <3',
                  style: TextStyle(color: Colors.pink)),
              onPressed: () {
                Navigator.pop(context);
                _launchURL("https://sentinelcivilianriskanalysis.netlify.app/");
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Donate (Apple In-App Purchase)',
                  style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.pop(context);
                showCupertinoModalPopup(
                  context: context,
                  builder: (BuildContext context) => CupertinoActionSheet(
                    message: const Text('Select a donation amount'),
                    actions: <CupertinoActionSheetAction>[
                      for (final tier in [
                        {
                          'price': '\$0.99',
                          'id': 'Sentinel_Donation_Button_0001'
                        },
                        {
                          'price': '\$2.99',
                          'id': 'Sentinel_Donation_Button_0003'
                        },
                        {
                          'price': '\$4.99',
                          'id': 'Sentinel_Donation_Button_0005'
                        },
                        {
                          'price': '\$9.99',
                          'id': 'Sentinel_Donation_Button_0010'
                        },
                        {
                          'price': '\$19.99',
                          'id': 'Sentinel_Donation_Button_0020'
                        },
                      ])
                        CupertinoActionSheetAction(
                          child: Text(tier['price']!),
                          onPressed: () async {
                            Navigator.pop(context);
                            final success = await IAPService()
                                .purchaseDonation(tier['id']!);
                            if (!success && context.mounted) {
                              showCupertinoDialog(
                                  context: context,
                                  builder: (ctx) => CupertinoAlertDialog(
                                          title: const Text("IAP Unavailable"),
                                          content: const Text(
                                              "In-App Purchases are not available on the Simulator or Products failed to load."),
                                          actions: [
                                            CupertinoDialogAction(
                                                child: const Text("OK"),
                                                onPressed: () =>
                                                    Navigator.pop(ctx))
                                          ]));
                            }
                          },
                        ),
                    ],
                    cancelButton: CupertinoActionSheetAction(
                      isDefaultAction: true,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                );
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      _launchURL(url);
    }
  }
}

// --- LOG VIEWER DIALOG (LIVE POLLING) ---
class LogViewerDialog extends StatefulWidget {
  const LogViewerDialog({super.key});
  @override
  State<LogViewerDialog> createState() => _LogViewerDialogState();
}

class _LogViewerDialogState extends State<LogViewerDialog> {
  String _logs = "Initializing Live Stream...";
  Timer? _timer;
  final ScrollController _scrollController = ScrollController();
  final bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchLogs());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    if (!mounted) return;
    final vm = Provider.of<SentinelProvider>(context, listen: false);
    String newLogs = await vm.fetchServerLogs();

    if (mounted) {
      setState(() {
        _logs = newLogs;
      });
      // Auto-scroll to bottom if enabled
      if (_autoScroll && _scrollController.hasClients) {
        // _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        // Actually, logs usually come reverse or we want to see the end?
        // User asked for "Live stream". Typically tail -f.
        // Backend text is usually "last N lines".
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        backgroundColor: Colors.black,
        title:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("LIVE SERVER LOGS",
              style: TextStyle(color: Colors.yellow, fontFamily: 'Courier')),
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: const [
                    BoxShadow(color: Colors.green, blurRadius: 5)
                  ]))
        ]),
        content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
                controller: _scrollController,
                reverse: true, // Show bottom first (tail)
                child: Text(_logs,
                    style: const TextStyle(
                        color: Colors.green,
                        fontFamily: 'Courier',
                        fontSize: 10)))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE CONNECTION"))
        ]);
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  void _showLogs(BuildContext context) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const LogViewerDialog());
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<SentinelProvider>(context);
    return Scaffold(
        body: Stack(children: [
      Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CircularProgressIndicator(color: Colors.red),
        const SizedBox(height: 20),
        Text(vm.connectionStatus,
            style:
                const TextStyle(color: Colors.yellow, fontFamily: 'Courier')),
        if (vm.connectionStatus.contains("GATHERING") ||
            vm.connectionStatus == "ESTABLISHING UPLINK...")
          Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text("STATUS: ${vm.loadingStage}",
                  style: const TextStyle(color: Colors.grey, fontSize: 10))),
        const SizedBox(height: 40),
        TextButton(
            onPressed: () => vm.resetSystem(),
            child: const Text("ABORT",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))
      ])),
      Positioned(
          top: 40,
          right: 20,
          child: IconButton(
              icon: const Icon(Icons.terminal, color: Colors.grey),
              tooltip: "Live Server Logs",
              onPressed: () => _showLogs(context)))
    ]));
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
      // Jobs v2 - Rebuilt with Sentinel theme
      JobsV2Gate(serverUrl: serverUrl),
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
          BottomNavigationBarItem(
              icon: const Icon(Icons.work), label: Loc.tr("JOBS", vm.userLang)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.settings),
              label: Loc.tr("SYSTEM", vm.userLang)),
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

  void _showCitations(BuildContext context, SitRepEntry entry) async {
    final vm = Provider.of<SentinelProvider>(context, listen: false);

    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1A1A1A),
        builder: (ctx) => const SizedBox(
            height: 150,
            child: Center(
                child: CircularProgressIndicator(color: Colors.yellow))));

    final citations = await vm.fetchCitations('sitrep', entry.id);
    if (context.mounted) Navigator.pop(context); // Close loading

    if (context.mounted) {
      showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1A1A1A),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (ctx) => Container(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "${Loc.tr("SITREP_DETAIL", vm.userLang)}: ${entry.topic.toUpperCase()}",
                          style: const TextStyle(
                              color: Colors.yellow,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2)),
                      const SizedBox(height: 15),
                      Text(entry.summary,
                          style: const TextStyle(
                              color: Colors.white, height: 1.5)),
                      /* SERVER INTEL REMOVED */
                      const SizedBox(height: 20),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 15),
                      Text(Loc.tr("SOURCE_CITATIONS", vm.userLang),
                          style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2)),
                      const SizedBox(height: 15),
                      if (citations.citations.isEmpty)
                        Text(Loc.tr("NO_CITATIONS", vm.userLang),
                            style: const TextStyle(color: Colors.grey)),
                      ...citations.citations.map((c) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(c.source,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(c.date,
                                style: const TextStyle(color: Colors.grey)),
                            trailing: const Icon(Icons.open_in_new,
                                color: Colors.blue, size: 18),
                            onTap: () => launchUrl(Uri.parse(c.url)),
                          ))
                    ]),
              )));
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
                          !data.isCertified
                              ? Loc.tr("UNCERTIFIED", lang)
                              : Loc.tr("CERTIFIED", lang),
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
                        ? Loc.tr("PENDING_VERIFICATION", lang)
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
                                      "${Loc.tr("SAFE_ZONE_DIST", lang)}: ${data.evacuationPoint.distanceKm != null ? "${data.evacuationPoint.distanceKm!.toInt()} km" : "Calculating..."}",
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
          if (data.sitrepEntries.isNotEmpty)
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.yellow)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Text(Loc.tr("INTELLIGENCE_REPORT", lang),
                              style: const TextStyle(
                                  color: Colors.yellow,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14))),
                      const SizedBox(height: 10),
                      Divider(color: Colors.grey[800]),
                      const SizedBox(height: 10),
                      ...data.sitrepEntries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: InkWell(
                              onTap: () => _showCitations(context, e),
                              child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.grey[800]!,
                                          width: 0.5)),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                      color: Colors.blue[900],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4)),
                                                  child: Text(
                                                      e.type.toUpperCase(),
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight
                                                              .bold))),
                                              if (e.confidenceScore > 0)
                                                Text(
                                                    "${Loc.tr("CONFIDENCE", lang)}: ${e.confidenceScore}%",
                                                    style: const TextStyle(
                                                        color: Colors.green,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold))
                                            ]),
                                        const SizedBox(height: 8),
                                        Row(children: [
                                          Expanded(
                                              child: Text(
                                                  "${e.topic.toUpperCase()} // ${e.date}",
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  overflow:
                                                      TextOverflow.ellipsis)),
                                          const Icon(Icons.touch_app,
                                              color: Colors.grey, size: 14)
                                        ]),
                                        const SizedBox(height: 8),
                                        _buildRichText(e.summary),
                                      ])))))
                    ]))
          else if (data.summary.isNotEmpty) ...[
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Loc.tr("INTELLIGENCE_SUMMARY", lang),
                          style: const TextStyle(
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
          ]
        ]));
  }
}

// --- TAB 2: FORECAST ---
class ForecastView extends StatelessWidget {
  final IntelDetails data;
  final String lang;
  const ForecastView({required this.data, required this.lang, super.key});

  void _showRationale(BuildContext context, ForecastEntry entry) async {
    final vm = Provider.of<SentinelProvider>(context, listen: false);

    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1A1A1A),
        builder: (ctx) => const SizedBox(
            height: 150,
            child: Center(
                child: CircularProgressIndicator(color: Colors.yellow))));

    final citations = await vm.fetchCitations('forecast', entry.topic);
    if (context.mounted) Navigator.pop(context);

    if (context.mounted) {
      showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1A1A1A),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (ctx) => Container(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "${Loc.tr("ANALYST_RATIONALE", vm.userLang)}: ${entry.topic.toUpperCase()}",
                          style: const TextStyle(
                              color: Colors.yellow,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2)),
                      const SizedBox(height: 20),
                      Text(entry.rationale,
                          style: const TextStyle(
                              color: Colors.white, height: 1.5)),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 10),
                      Text(Loc.tr("HISTORICAL_AND_SOURCE", vm.userLang),
                          style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 10)),
                      const SizedBox(height: 10),
                      if (citations.citations.isEmpty)
                        Text(Loc.tr("NO_SPECIFIC_CITATIONS", vm.userLang),
                            style: const TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic)),
                      ...citations.citations.map((c) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(c.source,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(c.date,
                                style: const TextStyle(color: Colors.grey)),
                            trailing: const Icon(Icons.open_in_new,
                                color: Colors.blue, size: 18),
                            onTap: () => launchUrl(Uri.parse(c.url)),
                          ))
                    ]),
              )));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (data.predictive == null) {
      return Center(child: Text(Loc.tr("NO_INTEL_AVAILABLE", lang)));
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
                if (data.forecastEntries.isNotEmpty)
                  ...data.forecastEntries.map((e) => InkWell(
                        onTap: () => _showRationale(context, e),
                        child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Colors.grey[800]!, width: 0.5))),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(e.topic.toUpperCase(),
                                            style: const TextStyle(
                                                color: Colors.yellow,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(e.prediction,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13))
                                      ])),
                                  const Icon(Icons.arrow_forward_ios,
                                      color: Colors.grey, size: 12)
                                ])),
                      ))
                else
                  ...pred.forecastSummary.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                            "• ${s.replaceAll(RegExp(r'^\d+\.\s*'), '')}",
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

      // STALE CHECK
      bool isStale = false;
      if (t.lastKinetic != null) {
        try {
          DateTime d = DateTime.parse(t.lastKinetic!);
          if (DateTime.now().difference(d).inHours > 72) {
            isStale = true; // 3 Days
          }
        } catch (e) {
          // Ignore parse errors
        }
      }

      if (isStale) {
        color = Colors.grey;
        type = "$type (OLD)";
      }

      if (isForecastMode) {
        color = Colors.orange;
        radius = radius * 1.5;
        type = "PRED. $type";
      }

      circles.add(CircleMarker(
          point: LatLng(t.lat, t.lon),
          color: color.withValues(alpha: isStale ? 0.05 : 0.2),
          borderColor: color.withValues(alpha: isStale ? 0.5 : 1.0),
          borderStrokeWidth: 2,
          useRadiusInMeter: true,
          radius: radius));

      markers.add(Marker(
          width: 140, // Expanded width
          height: 90,
          point: LatLng(t.lat, t.lon),
          child: Column(children: [
            Icon(isStale ? Icons.history : Icons.warning,
                color: color, size: 30),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                color: Colors.black.withValues(alpha: 0.8),
                child: Column(children: [
                  Text(type,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),

                  // NEW: Display Report Date
                  if (t.date != null)
                    Text(t.date!,
                        style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 7,
                            fontWeight: FontWeight.bold)),

                  if (t.lastKinetic != null && t.date == null)
                    Text(t.lastKinetic!,
                        style: TextStyle(
                            color: isStale ? Colors.grey : Colors.orange,
                            fontSize: 7))
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

  Future<void> _launchEmail(BuildContext context, String email) async {
    final Uri url = Uri.parse("mailto:$email");
    try {
      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Text(Loc.tr("MAIL_APP_UNAVAILABLE", vm.userLang)),
            content: Text(
                "${Loc.tr("COULD_NOT_OPEN_MAIL", vm.userLang)}: $e\nPlease email: $email"),
            actions: [
              CupertinoDialogAction(
                  child: const Text("OK"), onPressed: () => Navigator.pop(ctx))
            ],
          ),
        );
      }
    }
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
      Row(children: [
        const Icon(Icons.dns, color: Colors.green),
        const SizedBox(width: 10),
        Text(Loc.tr("SYSTEM_DIAGNOSTICS", vm.userLang),
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white))
      ]),
      const SizedBox(height: 20),
      _sysRow(Loc.tr("SENTINEL_ID", vm.userLang), vm.sentinelID, Colors.green),
      _sysRow(Loc.tr("VERSION", vm.userLang), "V173", Colors.white),
      _sysRow(Loc.tr("DATE", vm.userLang), "2026-01-03", Colors.white),
      _sysRow(Loc.tr("ANALYST", vm.userLang),
          data.analystModel ?? "gemini-3-pro-preview", Colors.white),
      _sysRow(Loc.tr("TRANSLATOR", vm.userLang),
          data.translatorModel ?? "gemini-2.5-flash-lite", Colors.white),
      _sysRow(Loc.tr("DATA_SOURCES", vm.userLang), "Google RSS, OSINT",
          Colors.white),
      _sysRow(Loc.tr("LAST_UPDATE", vm.userLang), _formatTime(data.lastUpdated),
          Colors.white),
      const SizedBox(height: 20),

      // WEBSITE
      GestureDetector(
          onTap: () => _launchWeb(data.systemUrl ?? vm.websiteUrl),
          child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.blue[900],
                  borderRadius: BorderRadius.circular(8)),
              child: Center(
                  child: Text(Loc.tr("VISIT_WEBSITE", vm.userLang),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1))))),
      const SizedBox(height: 10),

      // DONATE
      GestureDetector(
          onTap: () => _handleDonate(context, data.donateUrl ?? vm.donateUrl),
          child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.pink[800],
                  borderRadius: BorderRadius.circular(8)),
              child: Center(
                  child: Text(Loc.tr("DONATE_BUTTON", vm.userLang),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1))))),

      const SizedBox(height: 10),

      GestureDetector(
          onTap: () => _launchEmail(context, _supportEmail),
          child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8)),
              child: Center(
                  child: Text(Loc.tr("CONTACT_SUPPORT_BUTTON", vm.userLang),
                      style: const TextStyle(
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

  void _handleDonate(BuildContext context, String url) {
    if (kIsWeb) {
      _launchWeb(url);
      return;
    }
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              child: Text(
                  Loc.tr(
                      "OPEN_WEBSITE",
                      Provider.of<SentinelProvider>(context, listen: false)
                          .userLang),
                  style: const TextStyle(color: Colors.pink)),
              onPressed: () {
                Navigator.pop(context);
                _launchWeb("https://sentinelcivilianriskanalysis.netlify.app/");
              },
            ),
            CupertinoActionSheetAction(
              child: Text(
                  Loc.tr(
                      "DONATE_IAP",
                      Provider.of<SentinelProvider>(context, listen: false)
                          .userLang),
                  style: const TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.pop(context);
                showCupertinoModalPopup(
                  context: context,
                  builder: (BuildContext context) => CupertinoActionSheet(
                    message: Text(Loc.tr(
                        "SELECT_AMOUNT",
                        Provider.of<SentinelProvider>(context, listen: false)
                            .userLang)),
                    actions: <CupertinoActionSheetAction>[
                      for (final tier in [
                        {
                          'price': '\$0.99',
                          'id': 'Sentinel_Donation_Button_0001'
                        },
                        {
                          'price': '\$2.99',
                          'id': 'Sentinel_Donation_Button_0003'
                        },
                        {
                          'price': '\$4.99',
                          'id': 'Sentinel_Donation_Button_0005'
                        },
                        {
                          'price': '\$9.99',
                          'id': 'Sentinel_Donation_Button_0010'
                        },
                        {
                          'price': '\$19.99',
                          'id': 'Sentinel_Donation_Button_0020'
                        },
                      ])
                        CupertinoActionSheetAction(
                          child: Text(tier['price']!),
                          onPressed: () async {
                            Navigator.pop(context);
                            final success = await IAPService()
                                .purchaseDonation(tier['id']!);
                            if (!success && context.mounted) {
                              showCupertinoDialog(
                                  context: context,
                                  builder: (ctx) => CupertinoAlertDialog(
                                          title: Text(Loc.tr(
                                              "IAP_UNAVAILABLE",
                                              Provider.of<SentinelProvider>(
                                                      context,
                                                      listen: false)
                                                  .userLang)),
                                          content: Text(Loc.tr(
                                              "IAP_ERROR_MSG",
                                              Provider.of<SentinelProvider>(
                                                      context,
                                                      listen: false)
                                                  .userLang)),
                                          actions: [
                                            CupertinoDialogAction(
                                                child: const Text("OK"),
                                                onPressed: () =>
                                                    Navigator.pop(ctx))
                                          ]));
                            }
                          },
                        ),
                    ],
                    cancelButton: CupertinoActionSheetAction(
                      isDefaultAction: true,
                      onPressed: () => Navigator.pop(context),
                      child: Text(Loc.tr(
                          "CANCEL",
                          Provider.of<SentinelProvider>(context, listen: false)
                              .userLang)),
                    ),
                  ),
                );
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(Loc.tr(
                "CANCEL",
                Provider.of<SentinelProvider>(context, listen: false)
                    .userLang)),
          ),
        ),
      );
    } else {
      _launchWeb(url);
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

