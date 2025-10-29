import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'fingerprint_auth_page.dart'; 
import 'signup_page.dart';

final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String email = '';
  String username = '';
  
  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final storedEmail = await secureStorage.read(key: 'user_email') ?? '';
    final storedUsername = await secureStorage.read(key: 'user_username') ?? '';
    setState(() {
      email = storedEmail;
      username = storedUsername;
    });
  }

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => FingerprintAuthPage(
  onAuthenticated: () {
   
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SignupPage()),
    );
  },
)),

      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 46,
                      backgroundColor: Color(0xFF667eea),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundImage: AssetImage('assets/profile.jpg'), 
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Username displayed as main heading
                    Text(
                      username.isNotEmpty ? username : "Username not set",
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1a1f36),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Email as subtext
                    Text(
                      email.isNotEmpty ? email : "No email",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF8b92a8),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action Row (optional, phone removed for username-only style)
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFe53e3e),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          "Logout",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
