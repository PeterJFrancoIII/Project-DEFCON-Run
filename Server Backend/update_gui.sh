#!/bin/bash

# ==============================================================================
# MODULE: update_gui.sh
# AUTHOR: Gemini (AI Assistant)
# DATE: 2025-12-30
#
# DESCRIPTION:
# This script generates the Flutter (Dart) files required to update the GUI
# for the Sentinel application. It targets the 'lib' directory.
#
# UPDATES:
# 1. Threat Matrix: Implements specific Readiness text ("Maintain a Readiness...")
#    and color-coding logic.
# 2. System Tab: Fixes "Last Update" formatting and replaces the Sources tab
#    with a clickable "View Data Sources" button (Bottom Sheet).
# 3. Data Model: Updates JSON parsing to handle new backend fields.
# ==============================================================================

# Ensure directory structure exists
mkdir -p lib/models
mkdir -p lib/ui

# ------------------------------------------------------------------------------
# FILE 1: INTEL DATA MODEL
# ROLE: Handles JSON parsing from the Sentinel Backend
# ------------------------------------------------------------------------------
cat << 'DART' > lib/models/intel_model.dart
class DataSource {
  final String title;
  final String source;
  final String url;
  final String timestamp;

  DataSource({
    required this.title,
    required this.source,
    required this.url,
    required this.timestamp,
  });

  factory DataSource.fromJson(Map<String, dynamic> json) {
    return DataSource(
      title: json['title'] ?? 'Unknown Report',
      source: json['source'] ?? 'Unknown Source',
      url: json['url'] ?? '#',
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class IntelReport {
  final int defconStatus;
  final String trend;
  final double threatDistanceKm;
  final String readinessCondition; // NEW FIELD
  final List<String> summary;
  final String lastUpdated;
  final String locationName;
  final List<DataSource> dataSources; // NEW FIELD

  IntelReport({
    required this.defconStatus,
    required this.trend,
    required this.threatDistanceKm,
    required this.readinessCondition,
    required this.summary,
    required this.lastUpdated,
    required this.locationName,
    required this.dataSources,
  });

  factory IntelReport.fromJson(Map<String, dynamic> json) {
    // Parse Sources List
    var sList = json['data_sources'] as List? ?? [];
    List<DataSource> sources = sList.map((i) => DataSource.fromJson(i)).toList();

    // Parse Summary Strings
    var sumList = json['summary'] as List? ?? [];
    List<String> summaryText = sumList.map((i) => i.toString()).toList();

    return IntelReport(
      defconStatus: json['defcon_status'] ?? 5,
      trend: json['trend'] ?? 'Stable',
      threatDistanceKm: (json['threat_distance_km'] ?? 999.0).toDouble(),
      // Default text if null to prevent UI crash
      readinessCondition: json['readiness_condition'] ?? "Maintain a Readiness Standard of : None",
      summary: summaryText,
      lastUpdated: json['last_updated'] ?? 'Unknown',
      locationName: json['location_name'] ?? 'Unknown Location',
      dataSources: sources,
    );
  }
}
DART

# ------------------------------------------------------------------------------
# FILE 2: SOURCES BOTTOM SHEET
# ROLE: The pop-up menu that displays source data (Replacing the old tab)
# ------------------------------------------------------------------------------
cat << 'DART' > lib/ui/sources_sheet.dart
import 'package:flutter/material.dart';
import '../models/intel_model.dart';

class SourcesBottomSheet extends StatelessWidget {
  final List<DataSource> sources;

  const SourcesBottomSheet({Key? key, required this.sources}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E), // Dark Theme Background
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Colors.amberAccent, width: 2)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 40, height: 4,
            margin: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
          ),
          
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hub, color: Colors.amberAccent),
              SizedBox(width: 10),
              Text(
                "INTELLIGENCE SOURCES",
                style: TextStyle(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ],
          ),
          Divider(color: Colors.grey[800], height: 30),

          // List
          Expanded(
            child: sources.isEmpty 
              ? Center(child: Text("No source metadata available.", style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  itemCount: sources.length,
                  separatorBuilder: (ctx, i) => Divider(color: Colors.grey[900]),
                  itemBuilder: (context, index) {
                    final source = sources[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.article, color: Colors.blueGrey, size: 20),
                      title: Text(
                        source.title, 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Text(source.source, style: TextStyle(color: Colors.amber, fontSize: 12)),
                          SizedBox(width: 8),
                          Text("•  ${source.timestamp}", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
DART

# ------------------------------------------------------------------------------
# FILE 3: SYSTEM TAB
# ROLE: Displays System Status, Location, Last Update, and Source Button
# ------------------------------------------------------------------------------
cat << 'DART' > lib/ui/system_tab.dart
import 'package:flutter/material.dart';
import '../models/intel_model.dart';
import 'sources_sheet.dart';

class SystemTab extends StatelessWidget {
  final IntelReport? report;
  final bool isLoading;

  const SystemTab({Key? key, this.report, required this.isLoading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.amber));
    }

    if (report == null) {
      return Center(child: Text("System Offline", style: TextStyle(color: Colors.grey)));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Text("SYSTEM STATUS", style: TextStyle(color: Colors.grey, letterSpacing: 2)),
          SizedBox(height: 10),
          
          // MAIN LOCATION CARD
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3))
            ),
            child: Column(
              children: [
                Icon(Icons.location_on, color: Colors.greenAccent, size: 40),
                SizedBox(height: 10),
                Text(
                  report!.locationName.toUpperCase(),
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Text(
                  "ACTIVE MONITORING ZONE",
                  style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),

          // LAST UPDATE (FIXED FORMATTING)
          // Placed directly below date/time visual, above analyst window as requested.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoBox("DATA FRESHNESS", "LIVE FEED"),
              _buildInfoBox("LAST UPDATE", report!.lastUpdated),
            ],
          ),

          SizedBox(height: 20),

          // ANALYST WINDOW STUB (Placeholder for where graph would be)
          Container(
            width: double.infinity,
            height: 100,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[800]!),
              borderRadius: BorderRadius.circular(4)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ANALYST SIGNAL", style: TextStyle(color: Colors.grey, fontSize: 10)),
                Expanded(child: Center(child: Text("SIGNAL STABLE", style: TextStyle(color: Colors.white, fontFamily: 'Courier')))),
              ],
            ),
          ),

          Spacer(),

          // DATA SOURCES BUTTON (CLICKABLE SUB-MENU)
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              icon: Icon(Icons.storage, color: Colors.black),
              label: Text("VIEW DATA SOURCES", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber, // High Vis Yellow/Amber
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, // Allows full height if needed
                  backgroundColor: Colors.transparent,
                  builder: (context) => FractionallySizedBox(
                    heightFactor: 0.6, // Takes up 60% of screen
                    child: SourcesBottomSheet(sources: report!.dataSources),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: Colors.grey, fontSize: 10)),
            SizedBox(height: 4),
            Text(
              value, 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
DART

# ------------------------------------------------------------------------------
# FILE 4: THREAT MATRIX TAB
# ROLE: Displays DEFCON, Readiness, and Summary
# ------------------------------------------------------------------------------
cat << 'DART' > lib/ui/threat_matrix_tab.dart
import 'package:flutter/material.dart';
import '../models/intel_model.dart';

class ThreatMatrixTab extends StatelessWidget {
  final IntelReport? report;
  final bool isLoading;

  const ThreatMatrixTab({Key? key, this.report, required this.isLoading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Center(child: CircularProgressIndicator(color: Colors.red));
    if (report == null) return Center(child: Text("No Intel Available"));

    // Dynamic Color Logic based on DEFCON
    Color statusColor;
    if (report!.defconStatus <= 2) statusColor = Colors.red;
    else if (report!.defconStatus == 3) statusColor = Colors.orange;
    else if (report!.defconStatus == 4) statusColor = Colors.yellow;
    else statusColor = Colors.green;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // DEFCON CIRCLE
          Container(
            width: 150, height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: statusColor, width: 4),
              boxShadow: [BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 20)]
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("DEFCON", style: TextStyle(color: Colors.grey, fontSize: 14)),
                Text("${report!.defconStatus}", style: TextStyle(color: statusColor, fontSize: 60, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          SizedBox(height: 30),

          // READINESS CONDITION (UPDATED UI)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.5))
            ),
            child: Text(
              report!.readinessCondition.toUpperCase(), // "MAINTAIN A READINESS STANDARD OF : XX HOURS"
              textAlign: TextAlign.center,
              style: TextStyle(
                color: statusColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1
              ),
            ),
          ),

          SizedBox(height: 30),

          // SUMMARY LIST
          Align(alignment: Alignment.centerLeft, child: Text("SITUATION SUMMARY", style: TextStyle(color: Colors.grey))),
          Divider(color: Colors.grey[800]),
          ...report!.summary.map((line) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("• ", style: TextStyle(color: statusColor, fontSize: 18)),
                Expanded(child: Text(line, style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4))),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
DART

echo "[✔] GUI files generated successfully in 'lib/ui' and 'lib/models'."
