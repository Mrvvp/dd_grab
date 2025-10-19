import 'package:flutter/material.dart';

class Help extends StatelessWidget {
  const Help({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help'),
        backgroundColor: Colors.yellow.shade600,
        surfaceTintColor: Colors.yellow.shade600,
      ),
      body: Center(child: Text('No data Available')),
    );
  }
}
