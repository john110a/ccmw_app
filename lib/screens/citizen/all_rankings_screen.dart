import 'package:flutter/material.dart';

class AllRankingsScreen extends StatelessWidget {
  const AllRankingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Rankings'),
      ),
      body: const Center(
        child: Text('All Rankings Screen'),
      ),
    );
  }
}
