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
