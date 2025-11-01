import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentPage extends StatefulWidget {
  final String ipAddress;
  const PaymentPage({super.key, required this.ipAddress});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // IP controllers
  final TextEditingController ip1 = TextEditingController();
  final TextEditingController ip2 = TextEditingController();
  final TextEditingController ip3 = TextEditingController();
  final TextEditingController ip4 = TextEditingController();

  // Username and amount
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceInput = "";

  bool isLoading = false;
  String result = '';

  @override
  void initState() {
    super.initState();
    final parts = widget.ipAddress.split('.');
    if (parts.length == 4) {
      ip1.text = parts[0];
      ip2.text = parts[1];
      ip3.text = parts[2];
      ip4.text = parts[3];
    }
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      // Show Snackbar to instruct user before start listening
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please say: send/pay/transfer amount to name'),
          duration: Duration(seconds: 3),
        ),
      );

      // Small delay to ensure Snackbar is visible
      await Future.delayed(const Duration(seconds: 1));

      bool available = await _speech.initialize(
        onStatus: (val) => print('Speech status: $val'),
        onError: (val) => print('Speech error: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _voiceInput = val.recognizedWords;
              _processVoiceCommand(_voiceInput);
            });
          },
          localeId: 'en_IN', // Adjust as needed
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        );
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  void _processVoiceCommand(String command) {
    final regex = RegExp(r'(pay|send|transfer)\s+(\d+)\s+(?:to|for)?\s+(\w+)', caseSensitive: false);
    final match = regex.firstMatch(command);
    if (match != null) {
      final amount = match.group(2);
      final username = match.group(3);
      if (amount != null) amountController.text = amount;
      if (username != null) usernameController.text = username;
      print('Voice command parsed - Amount: $amount, Username: $username');
    } else {
      print('Voice command not recognized or does not match format');
    }
  }

  String get ipAddress =>
      "${ip1.text.trim()}.${ip2.text.trim()}.${ip3.text.trim()}.${ip4.text.trim()}";

  bool validateIp() {
    final parts = [ip1.text, ip2.text, ip3.text, ip4.text];
    for (var part in parts) {
      if (part.isEmpty) return false;
      final numVal = int.tryParse(part);
      if (numVal == null || numVal < 0 || numVal > 255) return false;
    }
    return true;
  }

  Future<void> submitPayment() async {
    final username = usernameController.text.trim();
    final amountText = amountController.text.trim();

    if (!validateIp()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid IP address'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    if (username.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all fields'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid amount'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final url = Uri.parse("http://$ipAddress:5000/pay");
    final data = {'username': username, 'amount': amount};

    setState(() {
      isLoading = true;
      result = '';
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      setState(() {
        result = "Status: ${response.statusCode}\nResponse: ${response.body}";
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment Successful!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        result = "Error: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    ip1.dispose();
    ip2.dispose();
    ip3.dispose();
    ip4.dispose();
    usernameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Widget _buildIpBox(TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: 3,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1a1f36),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1a1f36),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1a1f36),
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with mic button and instructions
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Payment',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: _isListening ? Colors.red : Colors.white,
                      onPressed: _listen,
                      child: Icon(_isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.white : Colors.black),
                    ),
                  ],
                ),
              ),
              // Content card with IP, username, amount fields and submit button
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Server IP Address',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1a1f36),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(child: _buildIpBox(ip1)),
                            const SizedBox(width: 6),
                            const Text(".", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF667eea))),
                            Expanded(child: _buildIpBox(ip2)),
                            const SizedBox(width: 6),
                            const Text(".", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF667eea))),
                            Expanded(child: _buildIpBox(ip3)),
                            const SizedBox(width: 6),
                            const Text(".", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF667eea))),
                            Expanded(child: _buildIpBox(ip4)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildInputField(
                          controller: usernameController,
                          label: 'Username',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 24),
                        _buildInputField(
                          controller: amountController,
                          label: 'Amount',
                          icon: Icons.currency_rupee,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: isLoading ? null : submitPayment,
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      )
                                    : const Text(
                                        'Submit Payment',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        if (result.isNotEmpty)
                          ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: result.contains('Error') ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: result.contains('Error') ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    result.contains('Error') ? Icons.error_outline : Icons.check_circle_outline,
                                    color: result.contains('Error') ? Colors.red : Colors.green,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      result,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: result.contains('Error') ? Colors.red : Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
