import 'package:flutter/material.dart';
import 'package:flutter_gcs/screens/map_screen/map_screen.dart';
import 'package:flutter_gcs/widgets/floating_nav_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gcs/bottom_navigation_bar.dart';
import 'package:flutter_gcs/src/provider/provider.dart';
import 'package:flutter_gcs/src/services/tcp_command_service.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final ipController = TextEditingController(text: '10.10.53.121');
  final portController = TextEditingController(text: '5762');
  bool isWireless = true;

  @override
  void dispose() {
    ipController.dispose();
    portController.dispose();
    super.dispose();
  }

  Future<void> onPressed() async {
    final selected = ref.read(selectedProtocolProvider);

    try {
      switch (selected) {
        case SelectedProtocol.tcp:
          final ip = ipController.text.trim();
          final port = int.tryParse(portController.text.trim()) ?? 5762;

          if (ip.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("⚠️ Please enter a valid IP address")),
            );
            return;
          }

          // Store inputs in providers
          ref.read(tcpHostProvider.notifier).state = ip;
          ref.read(tcpPortProvider.notifier).state = port;
          ref.read(isWirelessProvider.notifier).state = isWireless;

          print('📡 Connecting telemetry to $ip:$port');
          await ref.read(telemetryTcpServiceProvider).connect(host: ip, port: port);

          print('📡 Connecting command service (wireless: $isWireless)');
          await ref.read(commandTcpServiceProvider).connectFromRef(ref);
          break;

        case SelectedProtocol.udp:
          await ref.read(udpServiceProvider).connect(port: 14550);
          break;

        case SelectedProtocol.usb:
          await ref.read(usbServiceProvider).connect();
          final status = ref.read(usbConnectionStatusProvider);
          if (status != 'connected') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("❌ USB connection failed")),
            );
            return;
          }
          break;

        default:
          throw Exception("Unsupported protocol");
      }

      // Navigate after successful connection
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MapScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Connection error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedProtocolProvider);

    return Scaffold(
        body: Padding(
        padding: const EdgeInsets.only(left: 100, right: 100, top: 16, bottom:16),
        child: ListView(
          children: [
            const Text("Flutter GCS",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
            const SizedBox(height: 30),

            const Text("Select Connection Protocol:", textAlign: TextAlign.center),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
              Expanded(child: _buildRadioOption("SITL (USB)", SelectedProtocol.usb)),
              Expanded(child: _buildRadioOption("SITL (TCP)", SelectedProtocol.tcp)),
              Expanded(child: _buildRadioOption("SITL (UDP)", SelectedProtocol.udp)),
              ],
            ),

            if (selected == SelectedProtocol.tcp) ...[
              const SizedBox(height: 20),
              TextField(
                controller: ipController,
                decoration: const InputDecoration(
                  labelText: 'Telemetry IP Address',
                  hintText: 'e.g. 192.168.1.100',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Telemetry Port',
                  hintText: 'e.g. 5762',
                  border: OutlineInputBorder(),
                ),
              ),
              CheckboxListTile(
                title: const Text("Connect from physical device (Wireless TCP)"),
                value: isWireless,
                onChanged: (val) => setState(() => isWireless = val ?? false),
              ),
            ],

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: onPressed,
              child: const Text("Connect"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String title, SelectedProtocol value) {
    final selected = ref.watch(selectedProtocolProvider);
    return ListTile(
      title: Text(title),
      leading: Radio<SelectedProtocol>(
        value: value,
        groupValue: selected,
        onChanged: (val) =>
            ref.read(selectedProtocolProvider.notifier).state = val!,
      ),
    );
  }
}
