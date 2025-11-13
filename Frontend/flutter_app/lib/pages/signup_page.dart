import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  SignUpPageState createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUpPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _loading = false;

  // state variable to track if the user is signing up as a business
  bool _isBusiness = false;

  final TextEditingController _businessTypeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _businessTypeController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await _authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        isBusiness: _isBusiness,
        businessType: _isBusiness ? _businessTypeController.text.trim() : null,
        description: _isBusiness ? _descriptionController.text.trim() : null,
        website: _isBusiness ? _websiteController.text.trim() : null,
      );

      // This check is good!
      if (!mounted) return;

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // ---- ADD THIS CHECK ----
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? "Sign up failed")));
    } catch (e) {
      // ---- AND ADD THIS CHECK ----
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }

    // ---- AND THIS FINAL CHECK ----
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Sign Up")),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      labelText: "Full Name or Business Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      labelText: "Password",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      labelText: "Confirm Password",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text("Sign up as a Business Account"),
                    subtitle: const Text("You will require verification."),
                    value: _isBusiness,
                    onChanged: (newValue) {
                      setState(() {
                        _isBusiness = newValue ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isBusiness
                        ? Column(
                            key: const ValueKey('businessFields'),
                            children: [
                              const SizedBox(height: 16),
                              TextField(
                                controller: _businessTypeController,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.store),
                                  labelText: "Business Type (Optional)",
                                  hintText: "e.g., Restaurant, Retail, Cafe",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _descriptionController,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.notes),
                                  labelText: "Description (Optional)",
                                  hintText:
                                      "Tell customers about your business...",
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _websiteController,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.language),
                                  labelText: "Website (Optional)",
                                  hintText: "https://www.yourbusiness.com",
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.url,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signUp,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text("Sign Up"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
