import 'package:flutter/material.dart';
import 'package:flutter_app/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmail(); 
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserEmail() async {
    debugPrint("TRYING TO LOAD SAVED EMAIL ");
    final prefs = await SharedPreferences.getInstance();
    

    final bool rememberMe = prefs.getBool('remember_me') ?? false;
    final String? savedEmail = prefs.getString('saved_email');

    debugPrint("Remember Me status: $rememberMe");
    debugPrint("Saved Email: $savedEmail");

    if (mounted) {
      setState(() {
        _rememberMe = rememberMe;
        

        if (rememberMe && savedEmail != null) {
          _emailController.text = savedEmail;
          debugPrint("EMAIL FILLED SUCCESSFULY ");
        }
      });
    }
  }

  Future<void> _handleRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      debugPrint("SAVING EMAIL: ${_emailController.text.trim()} ---");
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setBool('remember_me', true);
    } else {
      debugPrint("CLEARING SAVED EMAIL ");
      await prefs.remove('saved_email');
      await prefs.setBool('remember_me', false);
    }
  }

  Future<void> _loginWithEmail() async {
    setState(() => _loading = true);
    final user = await _authService.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (user != null) {
      await _handleRememberMe(); 
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login failed")),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    final user = await _authService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);

    if (user != null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google login failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final onPrimaryColor = theme.colorScheme.onPrimary; 
    
    return Scaffold(
        body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icon.png',
                height: 150,
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email),
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock),
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),

              // "Remember Me" Checkbox
              CheckboxListTile(
                title: const Text("Remember Me"),
                value: _rememberMe,
                onChanged: (newValue) {
                  setState(() {
                    _rememberMe = newValue ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 10),

              

              // Login button
              

SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.primary, // Ensures background is Primary
      foregroundColor: onPrimaryColor, // Ensures text/icon is OnPrimary
    ),
    onPressed: _loading ? null : _loginWithEmail,
    child: _loading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              // Use onPrimary so the spinner matches the text color
              color: onPrimaryColor, 
              strokeWidth: 2.5,
            ),
          )
        : Text(
            "Login",
            style: TextStyle(
              // This explicitly forces the text to use the theme's contrast color
              color: onPrimaryColor, 
              fontWeight: FontWeight.bold,
            ),
          ),
  ),
),
              const SizedBox(height: 20),

              // Google login
              OutlinedButton.icon(
                icon: Image.asset(
                  'assets/google_logo.svg.png',
                  height: 20,
                ),
                label: const Text("Continue with Google"),
                onPressed: _loading ? null : _loginWithGoogle,
              ),
              const SizedBox(height: 16),

              // Sign up button
              OutlinedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text("Sign Up"),
                onPressed: _loading
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpPage()),
                        ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}