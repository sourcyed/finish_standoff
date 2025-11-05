import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DuelScreen extends StatelessWidget {
  const DuelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Center(
      child: SafeArea(
        child: Column(
          children: [
            Text('Finish Standoff', style: textStyle),
            ElevatedButton(
              onPressed: () => {context.go('/result')},
              child: Text('See results'),
            ),
          ],
        ),
      ),
    );
  }
}
