import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(const LoginApp());

/// Data model for login page. Not strictly necessary for this simple example
/// but demonstrates a pattern for more complex forms.
/// We don't use ChangeNotifier for this simple state as it's local.
class LoginData {
  String email;
  String password;
  bool rememberMe;

  LoginData({this.email = '', this.password = '', this.rememberMe = false});
}

/// Data model for settings page, using ChangeNotifier for state management.
class SettingsData extends ChangeNotifier {
  bool _receiveNotifications;
  bool _contextNotificationsEnabled;
  bool _suggestedAccountsNotifications;
  bool _rewardsNotifications;
  bool _privateProfile;
  bool _anonymousRewards;
  bool _trackAnalytics;
  bool _darkModeEnabled;

  SettingsData({
    bool receiveNotifications = true,
    bool contextNotificationsEnabled = true,
    bool suggestedAccountsNotifications = true,
    bool rewardsNotifications = true,
    bool privateProfile = false,
    bool anonymousRewards = false,
    bool trackAnalytics = true,
    bool darkModeEnabled = false,
  })  : _receiveNotifications = receiveNotifications,
        _contextNotificationsEnabled = contextNotificationsEnabled,
        _suggestedAccountsNotifications = suggestedAccountsNotifications,
        _rewardsNotifications = rewardsNotifications,
        _privateProfile = privateProfile,
        _anonymousRewards = anonymousRewards,
        _trackAnalytics = trackAnalytics,
        _darkModeEnabled = darkModeEnabled;

  bool get receiveNotifications => _receiveNotifications;
  bool get contextNotificationsEnabled => _contextNotificationsEnabled;
  bool get suggestedAccountsNotifications => _suggestedAccountsNotifications;
  bool get rewardsNotifications => _rewardsNotifications;
  bool get privateProfile => _privateProfile;
  bool get anonymousRewards => _anonymousRewards;
  bool get trackAnalytics => _trackAnalytics;
  bool get darkModeEnabled => _darkModeEnabled;

  set receiveNotifications(bool value) {
    if (_receiveNotifications != value) {
      _receiveNotifications = value;
      notifyListeners();
    }
  }

  set contextNotificationsEnabled(bool value) {
    if (_contextNotificationsEnabled != value) {
      _contextNotificationsEnabled = value;
      notifyListeners();
    }
  }

  set suggestedAccountsNotifications(bool value) {
    if (_suggestedAccountsNotifications != value) {
      _suggestedAccountsNotifications = value;
      notifyListeners();
    }
  }

  set rewardsNotifications(bool value) {
    if (_rewardsNotifications != value) {
      _rewardsNotifications = value;
      notifyListeners();
    }
  }

  set privateProfile(bool value) {
    if (_privateProfile != value) {
      _privateProfile = value;
      notifyListeners();
    }
  }

  set anonymousRewards(bool value) {
    if (_anonymousRewards != value) {
      _anonymousRewards = value;
      notifyListeners();
    }
  }

  set trackAnalytics(bool value) {
    if (_trackAnalytics != value) {
      _trackAnalytics = value;
      notifyListeners();
    }
  }

  set darkModeEnabled(bool value) {
    if (_darkModeEnabled != value) {
      _darkModeEnabled = value;
      notifyListeners();
    }
  }
}

/// Data model for a single reward item.
class RewardItem {
  final String name;
  final IconData icon;
  final Color color;

  RewardItem({required this.name, required this.icon, required this.color});
}

/// Data model for the rewards page, using ChangeNotifier for state management.
class RewardsData extends ChangeNotifier {
  final List<RewardItem> _rewards = <RewardItem>[
    RewardItem(name: "50 Points", icon: Icons.control_point, color: Colors.blue),
    RewardItem(name: "Free Coffee", icon: Icons.coffee, color: Colors.green),
    RewardItem(name: "100 Points", icon: Icons.control_point_duplicate, color: Colors.orange),
    RewardItem(name: "Discount Coupon", icon: Icons.local_offer, color: Colors.purple),
    RewardItem(name: "No Reward", icon: Icons.close, color: Colors.grey),
    RewardItem(name: "200 Points", icon: Icons.add_circle, color: Colors.red),
    RewardItem(name: "Exclusive Access", icon: Icons.vpn_key, color: Colors.teal),
    RewardItem(name: "Small Gift", icon: Icons.card_giftcard, color: Colors.pink),
  ];

  RewardItem? _currentReward;
  bool _isSpinning = false;
  double _currentRotation = 0.0; // Current visual rotation of the wheel in radians

  List<RewardItem> get rewards => _rewards;
  RewardItem? get currentReward => _currentReward;
  bool get isSpinning => _isSpinning;
  double get currentRotation => _currentRotation;

  // Method to update rotation during animation (for `RewardWheel` to call)
  void updateRotation(double rotation) {
    _currentRotation = rotation;
    notifyListeners();
  }

  // Method to trigger the spin logic (to be called by the `RewardWheel` widget)
  void startSpin() {
    if (!_isSpinning) {
      _isSpinning = true;
      _currentReward = null; // Clear previous reward
      notifyListeners();
    }
  }

  void endSpin(RewardItem selectedReward) {
    _currentReward = selectedReward;
    _isSpinning = false;
    notifyListeners();
  }
}

class LoginApp extends StatelessWidget {
  const LoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SettingsData>(
      create: (BuildContext context) => SettingsData(),
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Login and Home Screen",
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors
                    .blueAccent, // Set a default background color for ElevatedButtons
                foregroundColor: Colors
                    .white, // Set a default text color for ElevatedButtons
              ),
            ),
            brightness: Provider.of<SettingsData>(context).darkModeEnabled
                ? Brightness.dark
                : Brightness.light,
          ),
          home: const LoginPage(),
        );
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false; // State for the "Remember Me" checkbox

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // In a real app, this would involve authentication logic.
    // For now, it just navigates to the home page.
    // debugPrint('Email: ${_emailController.text}');
    // debugPrint('Password: ${_passwordController.text}');
    // debugPrint('Remember Me: $_rememberMe');

    // Navigate to HomePage after successful login
    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // App Title
              Text(
                "Engage Point",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              // Logo / Title
              Image.network(
                'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg',
                height: 80,
                width: 80,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 20),
              Text(
                "Welcome Back",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 30),

              // Email Field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email),
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock),
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                enableSuggestions: false,
                autocorrect: false,
              ),
              const SizedBox(height: 16),

              // Remember Me checkbox
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (bool? newValue) {
                          setState(() {
                            _rememberMe = newValue ?? false;
                          });
                        },
                      ),
                      const Text("Remember Me"),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      // Handle forgot password logic
                      debugPrint('Forgot Password pressed');
                    },
                    child: const Text("Forgot Password?"),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _handleLogin,
                  child: const Text("Login", style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),

              // Divider
              const Row(
                children: <Widget>[
                  Expanded(child: Divider(thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("OR"),
                  ),
                  Expanded(child: Divider(thickness: 1)),
                ],
              ),
              const SizedBox(height: 20),

              // Google Login Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: Image.network(
                    'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg', // Placeholder for Google logo
                    height: 20,
                  ),
                  label: const Text(
                    "Continue with Google",
                    style: TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Handle Google login
                    debugPrint('Google login button pressed');
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text("Sign Up", style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Handle sign up
                    debugPrint('Sign Up button pressed');
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => const SignUpPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    // In a real app, this would involve registration logic.
    // For now, it just prints the values and navigates to the home page.
    debugPrint('Full Name: ${_fullNameController.text}');
    debugPrint('Email: ${_emailController.text}');
    debugPrint('Password: ${_passwordController.text}');
    debugPrint('Confirm Password: ${_confirmPasswordController.text}');

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match!')));
      return;
    }

    // Simulate successful sign up and navigate to HomePage
    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "Create Your Account",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 30),

              // Full Name Field
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person),
                  labelText: "Full Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),

              // Email Field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email),
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock),
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                enableSuggestions: false,
                autocorrect: false,
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock),
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                enableSuggestions: false,
                autocorrect: false,
              ),
              const SizedBox(height: 24),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _handleSignUp,
                  child: const Text("Sign Up", style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to LoginPage
                    },
                    child: const Text("Login"),
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const ProfilePage(),
                  ),
                );
              },
              child: const CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg', // Placeholder profile picture
                ),
                radius: 20,
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // Modified DrawerHeader to be smaller and a bit higher
            Container(
              height: 100.0, // Reduced height for the header
              decoration: const BoxDecoration(color: Colors.blueAccent),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 16.0, bottom: 16.0),
                  child: Text(
                    'Navigation',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Already on Home page, so no navigation needed.
                // If this were a stack, you might pop until Home is the only route.
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const ProfilePage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.leaderboard,
              ), // Changed icon for combined page
              title: const Text('Rewards & Progression'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        const RewardsAndProgressionPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const SettingsPage(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.pushReplacement<void, void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const LoginPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.home,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              "Welcome to the Home Page!",
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "You have successfully logged in.",
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20), // Add some initial space from the top
              const CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg', // Placeholder profile picture
                ),
                radius: 80, // Made profile picture bigger
              ),
              const SizedBox(height: 20),
              Text(
                "John Doe", // Placeholder name
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                "john.doe@example.com", // Placeholder email
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 20), // Spacing before the following count
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "1,234", // Placeholder for following count
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    "Following",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Edit Profile"),
                onTap: () {
                  debugPrint('Edit Profile tapped');
                  // Navigate to an edit profile page or show a dialog
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Settings"),
                onTap: () {
                  debugPrint('Settings tapped');
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => const SettingsPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text("Notifications"),
                onTap: () {
                  debugPrint('Notifications tapped');
                  // Navigate to notifications page
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pushReplacement<void, void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => const LoginPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the reward wheel segments.
class _WheelPainter extends CustomPainter {
  final List<RewardItem> rewards;

  _WheelPainter(this.rewards);

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double segmentAngle = 2 * pi / rewards.length;

    for (int i = 0; i < rewards.length; i++) {
      // ignore: deprecated_member_use
     
      // ignore: deprecated_member_use
      final Paint paint = Paint()..color = rewards[i].color.withOpacity(0.8);

      // Start angle for segment i, such that segment 0 is centered at the top (-pi/2 or 270 degrees)
      // `(i * segmentAngle)` shifts for the specific segment.
      // `(-pi/2 - segmentAngle / 2)` accounts for the starting point of segment 0
      // if it were to be centered at the top.
      final double startAngle = (i * segmentAngle) - (segmentAngle / 2) - (pi / 2);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Draw reward text
      canvas.save();
      canvas.translate(center.dx, center.dy);

      // Rotate canvas to align with the center of the current segment for text drawing.
      // `startAngle + segmentAngle / 2` gives the absolute center angle of the segment
      // relative to the 0-radian (right) mark, going clockwise.
      final double segmentCenterAngle = startAngle + segmentAngle / 2;
      canvas.rotate(segmentCenterAngle);

      final TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      // Changed font size for text to be a bit bigger.
      const TextStyle textStyle = TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16, // Increased font size
      );

      textPainter.text = TextSpan(
        text: rewards[i].name,
        style: textStyle,
      );
      textPainter.layout();

      // Position text along the radius.
      // `radius * 0.6` is the distance from the wheel's center.
      // Since we rotated the canvas, the text is drawn horizontally relative to the rotated canvas.
      textPainter.paint(
        canvas,
        Offset(radius * 0.6 - textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.rewards != rewards;
  }
}

/// A widget that displays a spin-the-wheel game for rewards.
class RewardWheel extends StatefulWidget {
  const RewardWheel({super.key});

  @override
  State<RewardWheel> createState() => _RewardWheelState();
}

class _RewardWheelState extends State<RewardWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  final Random _random = Random();
  int? _selectedIndexForSpin; // Stores the randomly chosen index for the current spin

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Spin duration
    )..addListener(() {
        // Update rotation in ChangeNotifier.
        // The listen: false is crucial here to avoid circular rebuilds.
        Provider.of<RewardsData>(context, listen: false).updateRotation(
          _rotationAnimation.value,
        );
      });

    _rotationAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic, // Slows down towards the end
      ),
    );

    _animationController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        if (_selectedIndexForSpin != null) {
          final RewardsData rewardsData = Provider.of<RewardsData>(context, listen: false);
          rewardsData.endSpin(rewardsData.rewards[_selectedIndexForSpin!]);
          _selectedIndexForSpin = null; // Reset after use
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _spinTheWheel() {
    final RewardsData rewardsData = Provider.of<RewardsData>(context, listen: false);
    if (rewardsData.isSpinning) return;

    rewardsData.startSpin();

    final int numRewards = rewardsData.rewards.length;
    final int selectedIndex = _random.nextInt(numRewards); // Randomly pick a reward
    _selectedIndexForSpin = selectedIndex; // Store it for post-animation logic

    final double segmentAngle = 2 * pi / numRewards;

    // We want segment `selectedIndex` to align with the top pointer.
    // Since segment 0 is centered at the top when rotation is 0,
    // to bring segment `selectedIndex` to the top, we need to rotate it by `selectedIndex * segmentAngle` clockwise.
    final double targetRelativeRotation = selectedIndex * segmentAngle;

    // Add multiple full rotations for visual effect. e.g., 5-9 full spins.
    final double fullSpins = (_random.nextInt(5) + 5) * (2 * pi).toDouble();
    final double finalRotation = fullSpins + targetRelativeRotation;

    _rotationAnimation = Tween<double>(
      begin: rewardsData.currentRotation,
      end: rewardsData.currentRotation + finalRotation,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // The Wheel itself
        Center( // Center the wheel on the screen
          child: SizedBox( // Made the wheel slightly smaller by constraining its size
            width: 300, // Fixed width
            height: 300, // Fixed height
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none, // Allow children to draw outside bounds
              children: <Widget>[
                // Wheel body
                Consumer<RewardsData>(
                  builder: (BuildContext context, RewardsData rewards, Widget? child) {
                    return Transform.rotate(
                      angle: rewards.currentRotation,
                      child: CustomPaint(
                        painter: _WheelPainter(rewards.rewards),
                        child: Container(),
                      ),
                    );
                  },
                ),
                // Pointer (fixed at the top, adjusted to touch the wheel)
                Positioned(
                  top: -40.0, // Adjusted pointer position to move it down slightly
                  child: Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 50,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Consumer<RewardsData>(
          builder: (BuildContext context, RewardsData rewards, Widget? child) {
            return ElevatedButton.icon(
              icon: rewards.isSpinning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,),
                    )
                  : const Icon(Icons.refresh),
              label: Text(rewards.isSpinning ? "Spinning..." : "Spin for Reward"),
              onPressed: rewards.isSpinning ? null : _spinTheWheel,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Consumer<RewardsData>(
          builder: (BuildContext context, RewardsData rewards, Widget? child) {
            if (rewards.currentReward != null && !rewards.isSpinning) {
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        rewards.currentReward!.icon,
                        size: 30,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "You won: ${rewards.currentReward!.name}!",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Container();
          },
        ),
      ],
    );
  }
}

class RewardsAndProgressionPage extends StatelessWidget {
  const RewardsAndProgressionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RewardsData>(
      create: (BuildContext context) => RewardsData(),
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          appBar: AppBar(title: const Text("Rewards & Progression")),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.leaderboard,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Your Achievements & Rewards",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Track your journey, celebrate milestones, and claim your well-deserved rewards here!",
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  const RewardWheel(), // Integrate the new widget
                  const SizedBox(height: 30),
                  const ListTile(
                    leading: Icon(Icons.military_tech),
                    title: Text("Current Rank: Gold I"),
                    subtitle: Text("Next rank in 250 points"),
                  ),
                  const ListTile(
                    leading: Icon(Icons.star),
                    title: Text("Total Rewards Earned: 15"),
                    subtitle: Text("View your collection"),
                  ),
                  const ListTile(
                    leading: Icon(Icons.trending_up),
                    title: Text("Weekly Progress: +12%"),
                    subtitle: Text("Keep up the great work!"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Consumer<SettingsData>(
        builder: (BuildContext context, SettingsData settings, Widget? child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Notifications",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                SwitchListTile(
                  title: const Text("Receive Notifications"),
                  value: settings.receiveNotifications,
                  onChanged: (bool value) {
                    settings.receiveNotifications = value;
                  },
                ),
                SwitchListTile(
                  title: const Text("Context Notifications"),
                  subtitle: settings.receiveNotifications
                      ? null
                      : const Text("Enable 'Receive Notifications' first"),
                  value: settings.contextNotificationsEnabled,
                  onChanged: settings.receiveNotifications
                      ? (bool value) {
                          settings.contextNotificationsEnabled = value;
                        }
                      : null,
                ),
                if (settings.receiveNotifications &&
                    settings.contextNotificationsEnabled)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      children: <Widget>[
                        CheckboxListTile(
                          title: const Text("Suggested Accounts"),
                          value: settings.suggestedAccountsNotifications,
                          onChanged: (bool? value) {
                            settings.suggestedAccountsNotifications =
                                value ?? false;
                          },
                        ),
                        CheckboxListTile(
                          title: const Text("Rewards"),
                          value: settings.rewardsNotifications,
                          onChanged: (bool? value) {
                            settings.rewardsNotifications = value ?? false;
                          },
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Privacy",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                CheckboxListTile(
                  title: const Text("Private Profile"),
                  value: settings.privateProfile,
                  onChanged: (bool? value) {
                    settings.privateProfile = value ?? false;
                  },
                ),
                CheckboxListTile(
                  title: const Text("Anonymous Rewards"),
                  value: settings.anonymousRewards,
                  onChanged: (bool? value) {
                    settings.anonymousRewards = value ?? false;
                  },
                ),
                CheckboxListTile(
                  title: const Text("Track Analytics"),
                  value: settings.trackAnalytics,
                  onChanged: (bool? value) {
                    settings.trackAnalytics = value ?? false;
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "App",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                SwitchListTile(
                  title: const Text("Dark Mode"),
                  value: settings.darkModeEnabled,
                  onChanged: (bool value) {
                    settings.darkModeEnabled = value;
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text("Help"),
                  onTap: () {
                    debugPrint('Help tapped');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening help documentation...'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cleaning_services),
                  title: const Text("Clear Cache"),
                  onTap: () {
                    debugPrint('Clear Cache tapped');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared.')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text("About"),
                  onTap: () {
                    debugPrint('About tapped');
                    showAboutDialog(
                      context: context,
                      applicationName: 'Login and Home App',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2023 Example Company',
                      children: <Widget>[
                        const Text('This is a demonstration application.'),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}