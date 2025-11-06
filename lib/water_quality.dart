import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';

class WaterQualityPage extends StatefulWidget {
  const WaterQualityPage({super.key});

  @override
  State<WaterQualityPage> createState() => _WaterQualityPageState();
}

class _WaterQualityPageState extends State<WaterQualityPage> {
  late Future<List<dynamic>> _waterReportsFuture;

  final Map<String, Map<String, dynamic>> qualityStyles = {
    "Unsafe": {"icon": Icons.error, "color": Colors.red},
    "Moderate": {"icon": Icons.warning, "color": Colors.orange},
    "Safe": {"icon": Icons.check_circle, "color": Colors.green},
  };

  @override
  void initState() {
    super.initState();
    _waterReportsFuture = ApiService.fetchWaterReports();
  }

  void _refreshReports() {
    setState(() {
      _waterReportsFuture = ApiService.fetchWaterReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: _waterReportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            final waterReports = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: waterReports.length,
              itemBuilder: (context, index) {
                final report = waterReports[index];
                final quality = report["quality"] ?? "Unknown";

                final style = qualityStyles[quality] ??
                    {"icon": Icons.help_outline, "color": Colors.grey};

                final Color color = style["color"];
                final IconData icon = style["icon"];

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.1),
                      child: Icon(icon, color: color),
                    ),
                    title: Text(
                      report["location"] ?? "Unknown Location",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Quality: $quality"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ),
                );
              },
            );
          }
          return const Center(child: Text("No data found"));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showReportForm(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showReportForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return WaterReportForm(onReportSubmitted: _refreshReports);
      },
    );
  }
}

class WaterReportForm extends StatefulWidget {
  final VoidCallback onReportSubmitted;
  const WaterReportForm({super.key, required this.onReportSubmitted});

  @override
  State<WaterReportForm> createState() => _WaterReportFormState();
}

class _WaterReportFormState extends State<WaterReportForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  String _selectedPh = 'Normal (6.5-8.5)';
  String _selectedTurbidity = 'Clear';
  String _selectedChlorine = 'Normal (0.5-1.5 ppm)';
  bool _bacteriaPresent = false;
  String _selectedQuality = "Safe";

  void _submitReport() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final Map<String, dynamic> data = {
        "location": _locationController.text,
        "ph": _selectedPh,
        "turbidity": _selectedTurbidity,
        "chlorine": _selectedChlorine,
        "bacteria_present": _bacteriaPresent,
        "quality": _selectedQuality,
      };

      try {
        final response = await ApiService.reportWater(data);
        if (!mounted) return;

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Water report submitted successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          widget.onReportSubmitted();
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ Failed to submit report: ${response.statusCode}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ An error occurred: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16.0,
        right: 16.0,
        top: 16.0,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Submit New Water Report',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: "Location/Village",
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a location' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedPh,
                decoration: const InputDecoration(
                  labelText: "pH Level",
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                items: ["Acidic (<6.5)", "Normal (6.5-8.5)", "Alkaline (>8.5)"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPh = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedTurbidity,
                decoration: const InputDecoration(
                  labelText: "Turbidity",
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                items: ["Clear", "Slightly Cloudy", "Very Cloudy"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedTurbidity = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedChlorine,
                decoration: const InputDecoration(
                  labelText: "Chlorine Level",
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                items: ["Low (<0.5 ppm)", "Normal (0.5-1.5 ppm)", "High (>1.5 ppm)"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedChlorine = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Bacteria Present:", style: TextStyle(fontSize: 16)),
                  Switch(
                    value: _bacteriaPresent,
                    onChanged: (value) {
                      setState(() {
                        _bacteriaPresent = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedQuality,
                decoration: const InputDecoration(
                  labelText: "Quality",
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                items: ["Safe", "Moderate", "Unsafe"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedQuality = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submitReport,
                icon: const Icon(Icons.send),
                label: const Text("Submit Report"),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}