import 'package:flutter/material.dart';
import 'package:flutter_gcs/widgets/floating_nav_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gcs/src/utils/command_sender.dart';
import 'package:flutter_gcs/src/provider/provider.dart';

class QuickCommandsScreen extends ConsumerWidget {
  const QuickCommandsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Commands'),
        backgroundColor: Colors.grey[100],
      ),
      body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 4,
                childAspectRatio: 2.5,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      ref.read(showMissionOverlayProvider.notifier).state =
                          true;
                      sendWithFeedback(
                        ref: ref,
                        context: context,
                        message: "START_MISSION",
                      );
                    },
                    child: const Text("START MISSION"),
                  ),
                  ElevatedButton(
                    onPressed: () => sendWithFeedback(
                      ref: ref,
                      context: context,
                      message: "TAKEOFF",
                    ),
                    child: const Text("TAKEOFF"),
                  ),
                  ElevatedButton(
                    onPressed: () => sendWithFeedback(
                      ref: ref,
                      context: context,
                      message: "LAND",
                    ),
                    child: const Text("LAND"),
                  ),
                  ElevatedButton(
                    onPressed: () => sendWithFeedback(
                      ref: ref,
                      context: context,
                      message: "RTL",
                    ),
                    child: const Text("RTL"),
                  ),
                  ElevatedButton(
                    onPressed: () => sendWithFeedback(
                      ref: ref,
                      context: context,
                      message: "STABILIZE",
                    ),
                    child: const Text("STABILIZE"),
                  ),
                  ElevatedButton(
                    onPressed: () => sendWithFeedback(
                      ref: ref,
                      context: context,
                      message: "AUTO",
                    ),
                    child: const Text("AUTO"),
                  ),
                  ElevatedButton(
                    onPressed: () => sendWithFeedback(
                      ref: ref,
                      context: context,
                      message: "ARM",
                    ),
                    child: const Text("ARM"),
                  ),
                  ElevatedButton(
                    onPressed: () => sendWithFeedback(
                      ref: ref,
                      context: context,
                      message: "DISARM",
                    ),
                    child: const Text("DISARM"),
                  ),
                ],
              ),
            ),
            const Positioned(left: 16, bottom: 16, child: FloatingNavMenu()),
          ],
        ),
      );
  }
}
