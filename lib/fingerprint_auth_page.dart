import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class FingerprintAuthPage extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const FingerprintAuthPage({Key? key, required this.onAuthenticated}) : super(key: key);

  @override
  State<FingerprintAuthPage> createState() => _FingerprintAuthPageState();
}

class _FingerprintAuthPageState extends State<FingerprintAuthPage> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _authStatus = 'Scan your fingerprint to proceed';

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    bool canCheckBiometrics = false;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } catch (e) {
      setState(() {
        _authStatus = 'Error checking biometrics: $e';
      });
      return;
    }

    if (!canCheckBiometrics) {
      setState(() {
        _authStatus = 'Biometric authentication not available';
      });
      return;
    }

    try {
      setState(() {
        _isAuthenticating = true;
        _authStatus = 'Authenticating...';
      });

      bool authenticated = await auth.authenticate(localizedReason: 'Please authenticate to continue');

      setState(() {
        _isAuthenticating = false;
      });

      if (authenticated) {
        setState(() {
          _authStatus = 'Authentication successful';
        });

        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;

        // Call the callback to notify parent/app to navigate accordingly
        widget.onAuthenticated();
      } else {
        setState(() {
          _authStatus = 'Authentication failed. Try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authStatus = 'Error during authentication: $e';
      });
    }
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.fingerprint,
                      size: 96,
                      color: Color(0xFF667eea),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _authStatus,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF1a1f36),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    if (!_isAuthenticating)
                      ElevatedButton(
                        onPressed: _authenticate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(fontSize: 16, color: Colors.white),
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
