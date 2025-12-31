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
