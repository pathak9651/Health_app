import 'package:flutter/material.dart';
import 'package:health_app/home.dart';
import 'package:health_app/models/user.dart';
import 'package:health_app/register.dart';
import 'package:health_app/services/api_service.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;

  void _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final response = await ApiService.sendOtp(_phoneController.text);
      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _otpSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ OTP not  sent! Check terminal for mock OTP")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to send OTP: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ An error occurred: $e")),
      );
    }
  }

  void _verifyOtpAndLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final response = await ApiService.verifyOtp(_phoneController.text, _otpController.text);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final loginResponse = await ApiService.loginUser(_phoneController.text);
        if (loginResponse.statusCode == 200) {
          final userData = jsonDecode(loginResponse.body)['user'];
          final user = User.fromJson(userData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Login successful!")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(user: user)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Login failed after OTP verification.")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ OTP verification failed: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ An error occurred: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Welcome Back',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text('Sign in to continue', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length != 10) {
                          return 'Phone number must be 10 digits long';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    if (_otpSent) ...[
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "OTP",
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the OTP';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _verifyOtpAndLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Verify & Login",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ] else
                      ElevatedButton(
                        onPressed: _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Send OTP",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterPage()),
                        );
                      },
                      child: const Text("Don't have an account? Register here."),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
