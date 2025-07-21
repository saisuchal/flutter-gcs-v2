import 'package:flutter/material.dart';
import 'package:flutter_gcs/screens/map_screen/map_screen.dart';
import 'package:flutter_gcs/screens/plan_screen/plan_screen.dart';
import 'package:flutter_gcs/screens/quick_commands_screen/quick_commands_screen.dart';
import 'package:flutter_gcs/screens/telemetry_screen/telemetry.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  State<CustomBottomNavigationBar> createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int selectedIndex = 0;
  List<Widget> get Screens => [
    MapScreen(),
    TelemetryView(),
    QuickCommandsScreen(),
    PlanScreen()
    ];

  void onTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Screens[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.wifi_protected_setup_rounded), label: "Live Data"),
          BottomNavigationBarItem(icon: Icon(Icons.flight_takeoff), label: "Quick Commands"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Plan Mission"),
        ],
        onTap: onTapped,
      ),
    );
  }
}
