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
