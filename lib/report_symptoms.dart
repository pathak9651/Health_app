import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart'; // ✅ This import is correct

class ReportSymptomsPage extends StatefulWidget {
  const ReportSymptomsPage({super.key});

  @override
  State<ReportSymptomsPage> createState() => _ReportSymptomsPageState();
}

class _ReportSymptomsPageState extends State<ReportSymptomsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();

  void _submitReport() async {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> data = {
        "village": _villageController.text,
        "symptoms": _symptomsController.text.split(',').map((s) => s.trim()).toList(),
      };

      try {
        final response = await ApiService.reportSymptoms(data); // ✅ This will now work

        if (!mounted) return;

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Report submitted successfully!"),
              backgroundColor: Colors.green,
            ),
          );
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
    _symptomsController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Symptoms")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Village", Icons.location_on, controller: _villageController),
              const SizedBox(height: 10),
              _buildTextField("Symptoms (comma-separated)", Icons.sick, maxLines: 3, controller: _symptomsController),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _submitReport,
                icon: const Icon(Icons.send),
                label: const Text("Submit Report", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, {int maxLines = 1, required TextEditingController controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter a value";
          }
          return null;
        },
      ),
    );
  }
}