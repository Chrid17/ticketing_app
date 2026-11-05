import 'package:flutter/material.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Lightweight toast helper backed by the app-wide ScaffoldMessenger.
void notify(String message, {String? actionLabel, VoidCallback? onAction, bool error = false}) {
  final messenger = scaffoldMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: error ? const Color(0xFFB91C1C) : const Color(0xFF1E293B),
        width: MediaQuery.sizeOf(messenger.context).width > 560 ? 440 : null,
        duration: Duration(seconds: onAction != null ? 5 : 3),
        action: onAction != null
            ? SnackBarAction(label: actionLabel ?? 'Undo', textColor: const Color(0xFFA5B4FC), onPressed: onAction)
            : null,
      ),
    );
}
