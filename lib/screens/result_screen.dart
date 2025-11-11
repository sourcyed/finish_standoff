import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultScreen extends StatelessWidget {
  final bool win;
  final String opponentName;

  const ResultScreen({
    super.key,
    required this.win,
    required this.opponentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Duel Result")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              win
                  ? "🎉 You killed $opponentName!"
                  : "😢 $opponentName killed you!",
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => context.go('/lobby'),
              child: const Text("Back to Lobby"),
            ),
          ],
        ),
      ),
    );
  }
}
