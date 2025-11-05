import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

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
            Image(image: AssetImage('assets/revolvers.png')),
            ElevatedButton(
              onPressed: () => {context.go('/lobby')},
              child: Text('Lobby'),
            ),
            ElevatedButton(
              onPressed: () => {context.go('/credits')},
              child: Text('Credits'),
            ),
          ],
        ),
      ),
    );
  }
}
