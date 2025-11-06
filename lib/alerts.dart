import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  late Future<List<dynamic>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = ApiService.fetchAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _alertsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (snapshot.hasData) {
          final alerts = snapshot.data!;
          if (alerts.isEmpty) {
            return const Center(
              child: Text(
                "No active alerts.\nStay safe!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: Colors.redAccent.withValues(alpha: 0.2),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    child: const Icon(Icons.warning_amber, color: Colors.red),
                  ),
                  title: Text(
                    alert['message'] ?? "No message",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(alert['village'] ?? "Unknown location"),
                ),
              );
            },
          );
        }
        return const Center(child: Text("No data found"));
      },
    );
  }
}
