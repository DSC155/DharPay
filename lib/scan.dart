import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'payment_page.dart';

class HotspotQrApp extends StatelessWidget {
  const HotspotQrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QrScanPage(),
    );
  }
}

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController controller = MobileScannerController();
  bool _scanned = false;
  String status = "Scan a hotspot QR code";
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.location.request();
  }

  String normalizeSSID(String? ssid) => ssid?.replaceAll('"', '') ?? '';

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    setState(() {
      _scanned = true;
      status = "QR detected! Parsing...";
    });

    final wifiData = _parseWifiQr(code);
    if (wifiData['ssid']!.isEmpty) {
      setState(() => status = "❌ Invalid QR code format.");
      _scanned = false;
      return;
    }

    setState(() => status = "Connecting to ${wifiData['ssid']}...");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Connecting...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1a1f36),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                wifiData['ssid']!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8b92a8),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await WiFiForIoTPlugin.connect(
        wifiData['ssid']!,
        password: wifiData['password'],
        security: wifiData['type'] == 'WEP'
            ? NetworkSecurity.WEP
            : NetworkSecurity.WPA,
        joinOnce: true,
      );

      bool isConnected = false;
      for (int i = 0; i < 10; i++) {
        final currentSSID = normalizeSSID(await WiFiForIoTPlugin.getSSID());
        if (currentSSID == wifiData['ssid']) {
          isConnected = true;
          break;
        }
        await Future.delayed(const Duration(seconds: 1));
      }

      Navigator.of(context).pop(); // close loading dialog

      if (isConnected) {
  setState(() => status = "✅ Connected to ${wifiData['ssid']}");
  // Get hotspot IP here and return it to PortfolioPage
  String? hotspotIp = await WiFiForIoTPlugin.getIP(); // fetch connected IP
  Navigator.of(context).pop(hotspotIp ?? wifiData['ssid']); // return IP or SSID
} else {
        setState(() => status = "❌ Failed to connect. Try manually.");
        _scanned = false;
      }
    } catch (e) {
      Navigator.of(context).pop();
      setState(() {
        status = "❌ Error: $e";
        _scanned = false;
      });
    }
  }

  Map<String, String> _parseWifiQr(String qrText) {
    final ssid = RegExp(r'S:([^;]+)').firstMatch(qrText)?.group(1) ?? '';
    final password = RegExp(r'P:([^;]+)').firstMatch(qrText)?.group(1) ?? '';
    final type = RegExp(r'T:([^;]+)').firstMatch(qrText)?.group(1) ?? 'WPA';
    return {'ssid': ssid, 'password': password, 'type': type};
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
              // Custom AppBar
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
                        'Scan Hotspot QR',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isFlashOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() => _isFlashOn = !_isFlashOn);
                          controller.toggleTorch();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Scanner Container
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        MobileScanner(onDetect: _onDetect, controller: controller),
                        
                        // Scanning Frame
                        Center(
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Status Container
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      status.startsWith('✅')
                          ? Icons.check_circle
                          : status.startsWith('❌')
                              ? Icons.error
                              : Icons.qr_code_scanner,
                      size: 48,
                      color: status.startsWith('✅')
                          ? Colors.green
                          : status.startsWith('❌')
                              ? Colors.red
                              : const Color(0xFF667eea),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1a1f36),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _scanned = false;
                            status = "Scan a hotspot QR code";
                          });
                          controller.start();
                        },
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.restart_alt, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Scan Again',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
