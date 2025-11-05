import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credits'),
        leading: IconButton(
          onPressed: () => {context.go('/')},
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: const Center(
        child: Text('Made by YED', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
