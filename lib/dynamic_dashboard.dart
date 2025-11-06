import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';
import 'package:health_app/symptom_reports_page.dart'; // Import the new page
import 'package:health_app/alerts.dart';
import 'package:health_app/water_quality.dart';

class DynamicDashboardPage extends StatefulWidget {
  const DynamicDashboardPage({super.key});

  @override
  State<DynamicDashboardPage> createState() => _DynamicDashboardPageState();
}

class _DynamicDashboardPageState extends State<DynamicDashboardPage> {
  late Future<Map<String, List<dynamic>>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchDashboardData();
  }

  Future<Map<String, List<dynamic>>> _fetchDashboardData() async {
    final alertsResponse = await ApiService.fetchAlerts();
    final symptomReportsResponse = await ApiService.fetchSymptomReports();
    final waterReportsResponse = await ApiService.fetchWaterReports();
    return {
      'alerts': alertsResponse,
      'symptomReports': symptomReportsResponse,
      'waterReports': waterReportsResponse,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<dynamic>>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (snapshot.hasData) {
          final alerts = snapshot.data!['alerts']!;
          final symptomReports = snapshot.data!['symptomReports']!;
          final waterReports = snapshot.data!['waterReports']!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMetricCard(
                  title: 'Total Alerts',
                  count: alerts.length,
                  icon: Icons.warning_amber,
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AlertsPage()),
                    );
                  },
                ),
                _buildMetricCard(
                  title: 'Symptom Reports',
                  count: symptomReports.length,
                  icon: Icons.sick,
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SymptomReportsPage()),
                    );
                  },
                ),
                _buildMetricCard(
                  title: 'Water Reports',
                  count: waterReports.length,
                  icon: Icons.water_drop,
                  color: Colors.blueAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WaterQualityPage()),
                    );
                  },
                ),
              ],
            ),
          );
        }
        return const Center(child: Text("No data found"));
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                radius: 30,
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count.toString(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
