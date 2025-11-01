import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'scan.dart';
import 'profile.dart';
import 'payment_page.dart';
import 'fingerprint_auth_page.dart'; 
import 'recive_page.dart';
import 'add_funds.dart'; // <-- Make sure this page exists!

final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({Key? key}) : super(key: key);

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  String? connectedIp;
  String username = '';
  double balance = 7630.0; // Start balance, update as needed

  final List<Map<String, dynamic>> transactions = [
    {'name': 'JoeMoe Coffee', 'method': 'Visa **** 2192', 'amount': '\$50.21', 'type': 'send'},
    {'name': 'Starbucks', 'method': 'Visa **** 2192', 'amount': '\$32.50', 'type': 'receive'},
    {'name': 'Amazon', 'method': 'Visa **** 2192', 'amount': '\$125.99', 'type': 'send'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final storedUsername = await secureStorage.read(key: 'user_username');
    if (storedUsername != null && storedUsername.isNotEmpty) {
      setState(() {
        username = storedUsername;
      });
    }
  }

  // --- Add Funds Navigation ---
  Future<void> _navigateToAddFunds() async {
    final added = await Navigator.push<double>(
      context,
      MaterialPageRoute(builder: (context) => const AddFundsPage()),
    );
    if (added != null && added > 0) {
      setState(() {
        balance += added;
        transactions.insert(0, {
          'name': 'Funds Added',
          'method': 'Balance top-up',
          'amount': '\₹${added.toStringAsFixed(2)}',
          'type': 'receive',
        });
      });
    }
  }

  void _showEditIpDialog() {
    final a = TextEditingController();
    final b = TextEditingController();
    final c = TextEditingController();
    final d = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter IP Address"),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ipBox(a),
            const Text('.'),
            _ipBox(b),
            const Text('.'),
            _ipBox(c),
            const Text('.'),
            _ipBox(d),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => connectedIp = "${a.text}.${b.text}.${c.text}.${d.text}");
              Navigator.of(context).pop();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _ipBox(TextEditingController controller) {
    return SizedBox(
      width: 35,
      child: TextField(
        controller: controller,
        maxLength: 3,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(counterText: ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = connectedIp != null;
    return Scaffold(
      backgroundColor: const Color(0xFF6B66E8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar (Dashboard & Controls)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final ip = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const QrScanPage()),
                              );
                              if (ip != null && ip is String && ip.isNotEmpty) {
                                setState(() => connectedIp = ip);
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.withOpacity(.09),
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                              ),
                              padding: const EdgeInsets.all(9),
                              child: Icon(
                                Icons.qr_code_scanner,
                                color: isConnected ? Colors.green : Colors.red,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          GestureDetector(
                            onTap: _showEditIpDialog,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.withOpacity(.09),
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                              ),
                              padding: const EdgeInsets.all(9),
                              child: Icon(
                                Icons.edit_rounded,
                                color: isConnected ? Colors.green : Colors.red,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 11),
                          Row(
                            children: [
                              Icon(Icons.circle, size: 12, color: isConnected ? Colors.green : Colors.red),
                              const SizedBox(width: 7),
                              Text(
                                isConnected ? connectedIp! : "Scan QR",
                                style: TextStyle(
                                  color: isConnected ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage()));
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFEDEAFF),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(Icons.person, color: Color(0xFF7B67E9), size: 26),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 19),
                  // Username heading as portfolio title
                  Text(
                    username.isEmpty ? "My Portfolio" : "$username's Portfolio",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      color: Color(0xFF202233),
                    ),
                  ),
                  const SizedBox(height: 19),
                  // Balance card with add
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(30, 24, 58, 35),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(23),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Balance",
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "\₹${balance.toStringAsFixed(2)}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 38),
                            ),
                            const SizedBox(height: 11),
                            const Text("**** 8149", style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 6)),
                          ],
                        ),
                      ),
                      const Positioned(
                        top: 22,
                        right: 23,
                        child: Icon(Icons.credit_card, size: 32, color: Colors.white60),
                      ),
                      // --- Change: "+" button opens AddFundsPage! ---
                      Positioned(
                        right: 18,
                        bottom: 13,
                        child: GestureDetector(
                          onTap: _navigateToAddFunds,
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C5DF9),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                              ],
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 30),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                 Row(
  children: [
    Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 9),
        height: 87,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 13,
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            if (connectedIp != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentPage(ipAddress: connectedIp!),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please connect to hotspot before sending!',
                    textAlign: TextAlign.center,
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(13),
                child: const Icon(Icons.arrow_upward_rounded,
                    color: Colors.green, size: 28),
              ),
              const SizedBox(height: 7),
              const Text('Send',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ),
      ),
    ),
    Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 9),
        height: 87,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 13,
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            if (connectedIp != null && username.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        ReceivePaymentPage(ipAddress: connectedIp!, username: username)),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please connect to hotspot before sending!',
                    textAlign: TextAlign.center,
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(13),
                child: const Icon(Icons.arrow_downward_rounded,
                    color: Colors.red, size: 28),
              ),
              const SizedBox(height: 7),
              const Text('Receive',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ),
      ),
    ),
  ],
),
const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(23),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username.isEmpty ? "Transaction History" : "$username's Transaction History",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 21,
                            color: Color(0xFF202233),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "A list of historical transactions",
                          style: TextStyle(color: Color(0xFF8D8EA2), fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        for (var txn in transactions)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 11),
                            child: _txnItem(
                              txn['name'] as String,
                              txn['method'] as String,
                              txn['amount'] as String,
                              txn['type'] as String,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _txnItem(String name, String method, String amount, String type) {
    final bool isSend = type == 'send';
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isSend ? Colors.green.withOpacity(0.17) : Colors.red.withOpacity(0.16),
              borderRadius: BorderRadius.circular(13),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(
              isSend ? Icons.arrow_upward : Icons.arrow_downward,
              color: isSend ? Colors.green : Colors.red,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF232325),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Paid with: $method',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFB2B5BF),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isSend ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
