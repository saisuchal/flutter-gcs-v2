import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gcs/src/provider/provider.dart';

Future<void> sendWithFeedback({
  required WidgetRef ref,
  required BuildContext context,
  required String message,
}) async {
  try {
    final commandService = ref.read(commandTcpServiceProvider);
    await commandService.send(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📤 "$message" sent to DroneKit server'),
        duration: const Duration(seconds: 2),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Failed to send "$message": $e'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
