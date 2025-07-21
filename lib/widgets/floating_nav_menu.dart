// lib/widgets/floating_nav_menu.dart
import 'package:flutter/material.dart';
import 'package:flutter_gcs/screens/map_screen/map_screen.dart';
import 'package:flutter_gcs/screens/plan_screen/plan_screen.dart';
import 'package:flutter_gcs/screens/quick_commands_screen/quick_commands_screen.dart';

class FloatingNavMenu extends StatefulWidget {
  const FloatingNavMenu({super.key});

  @override
  State<FloatingNavMenu> createState() => _FloatingNavMenuState();
}

class _FloatingNavMenuState extends State<FloatingNavMenu> {
  bool expanded = false;

  void _toggle() => setState(() => expanded = !expanded);

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      bottom: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (expanded)
            ...[
              _navButton(context, Icons.map, "Map View", MapScreen()),
              _navButton(context, Icons.flight_takeoff, "Quick Commands", QuickCommandsScreen()),
              _navButton(context, Icons.send, "Planner", PlanScreen()),
              const SizedBox(height: 8),
            ],
          FloatingActionButton(
            heroTag: 'nav_toggle',
            onPressed: _toggle,
            child: Icon(expanded ? Icons.close : Icons.menu),
          ),
        ],
      ),
    );
  }

  Widget _navButton(BuildContext context, IconData icon, String label, Widget screen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FloatingActionButton.extended(
        heroTag: label,
        onPressed: () => _navigateTo(context, screen),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
