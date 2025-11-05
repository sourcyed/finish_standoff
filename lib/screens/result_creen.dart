import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SafeArea(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => {context.go('/')},
              child: Text('Back to main menu'),
            ),
          ],
        ),
      ),
    );
  }
}
