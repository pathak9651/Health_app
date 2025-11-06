import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';

class OutbreakPredictionPage extends StatefulWidget {
  const OutbreakPredictionPage({super.key});

  @override
  State<OutbreakPredictionPage> createState() => _OutbreakPredictionPageState();
}

class _OutbreakPredictionPageState extends State<OutbreakPredictionPage> {
  String? _selectedVillage;
  Map<String, dynamic>? _predictionResult;
  bool _isLoading = false;

  final List<String> villages = ['Village A', 'Village B', 'Village C'];

  void _getPrediction() async {
    if (_selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a village")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _predictionResult = null;
    });

    try {
      final result = await ApiService.predictOutbreak(_selectedVillage!);
      if (mounted) {
        setState(() {
          _predictionResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    "Predict Outbreak Risk",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedVillage,
                    decoration: const InputDecoration(
                      labelText: "Select Village",
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    items: villages.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedVillage = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _getPrediction,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.analytics_outlined),
                    label: Text(_isLoading ? "Analyzing..." : "Analyze Risk"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_predictionResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Outbreak Risk Analysis",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text("Risk Score: ${_predictionResult!['risk_score']}", style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Text("Risk Level: ", style: TextStyle(fontSize: 16)),
                          Text(
                            _predictionResult!['risk_level'].toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getRiskColor(_predictionResult!['risk_level']),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text("Diarrhea Reports (last 48h): ${_predictionResult!['diarrhea_reports']}"),
                      Text("Water Quality Issues (last 48h): ${_predictionResult!['water_issues']}"),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
