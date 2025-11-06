import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';

class SymptomReportsPage extends StatelessWidget {
  const SymptomReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Symptom Reports"),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.fetchSymptomReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            final reports = snapshot.data!;
            if (reports.isEmpty) {
              return const Center(
                child: Text(
                  "No symptom reports found.",
                  style: TextStyle(fontSize: 18),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                final symptoms = (report['symptoms'] as List).join(', ');
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.sick, color: Colors.white),
                    ),
                    title: Text(
                      report['village'] ?? "Unknown Village",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Symptoms: $symptoms",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Text(
                      _formatDate(report['created_at']),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: Text("No data found"));
        },
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return "${date.day}/${date.month}/${date.year}";
  }
}
