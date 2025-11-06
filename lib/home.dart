import 'package:flutter/material.dart';
import 'package:health_app/alerts.dart';
import 'package:health_app/report_symptoms.dart';
import 'package:health_app/water_quality.dart';
import 'package:health_app/profile.dart';
import 'package:health_app/awareness.dart';
import 'package:health_app/models/user.dart';
import 'package:health_app/outbreak_prediction.dart';
import 'package:health_app/dynamic_dashboard.dart';
import 'package:health_app/services/api_service.dart';
import 'package:health_app/chatbot_page.dart';

class HomePage extends StatefulWidget {
  final User? user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _alertCount = 0; // State variable to hold the alert count

  final List<String> _titles = const [
    "📊 Dashboard",
    "📝 Report Symptoms",
    "💧 Water Quality",
    "📚 Health Awareness",
    "🧪 Prediction",
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DynamicDashboardPage(),
      const ReportSymptomsPage(),
      const WaterQualityPage(),
      const AwarenessPage(),
      const OutbreakPredictionPage(),
    ];
    _fetchAlertCount(); // Fetch alerts when the page is initialized
  }

  // Method to fetch alerts from the backend and update the count
  void _fetchAlertCount() async {
    try {
      final alerts = await ApiService.fetchAlerts();
      if (!mounted) return;
      setState(() {
        _alertCount = alerts.length;
      });
    } catch (e) {
      if (!mounted) return;
      // Handle error, e.g., show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch alerts: $e")),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal,
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          // Alerts icon with red dot
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () async {
                  // Navigate to the alerts page and refresh count when user returns
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AlertsPage()),
                  );
                  _fetchAlertCount(); // Refresh count after returning from the page
                },
              ),
              if (_alertCount > 0)
                Positioned(
                  right: 11,
                  top: 11,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                  ),
                ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage(user: widget.user)),
                );
              },
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18,
                child: Icon(Icons.person_outline, color: Colors.teal),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              spreadRadius: 2,
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.teal,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                label: "Dashboard",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.edit_note),
                label: "Report",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.water_drop_outlined),
                label: "Water",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.info_outline),
                label: "Awareness",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_outlined),
                label: "Predict",
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "chatbotFab",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotPage()),
              );
            },
            child: const Icon(Icons.chat_bubble_outline),
          ),
          const SizedBox(height: 16),
          // This button now navigates to the Water Quality page directly.
          FloatingActionButton(
            heroTag: "plusFab",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WaterQualityPage()),
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
