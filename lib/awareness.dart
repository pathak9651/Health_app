import 'package:flutter/material.dart';
import 'package:health_app/awareness_detail.dart';

class AwarenessPage extends StatelessWidget {
  const AwarenessPage({super.key});

  final List<Map<String, String>> topics = const [
    {"title": "Handwashing Steps", "subtitle": "Learn the correct way to wash hands", "icon": "✋"},
    {"title": "Water Purification", "subtitle": "Methods to make water safe to drink", "icon": "💧"},
    {"title": "Disease Symptoms", "subtitle": "Common symptoms of water-borne diseases", "icon": "🩺"},
    {"title": "First Aid for Diarrhea", "subtitle": "What to do during an outbreak", "icon": "🩹"},
    {"title": "Sanitation & Hygiene", "subtitle": "Best practices for a clean community", "icon": "🧼"},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        final Color cardColor = Colors.teal.withValues(alpha: 0.1);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          color: cardColor,
          child: ListTile(
            leading: Text(topic["icon"]!, style: const TextStyle(fontSize: 40)),
            title: Text(topic["title"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(topic["subtitle"]!),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AwarenessDetailPage(
                  title: topic["title"]!,
                  content: topic["subtitle"]!,
                )),
              );
            },
          ),
        );
      },
    );
  }
}
