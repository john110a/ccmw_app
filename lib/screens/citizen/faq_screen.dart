import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFaqItem(
            'How do I report an issue?',
            'You can report an issue by clicking the "Report New Issue" button on the dashboard. Follow the steps to provide details and location.',
          ),
          _buildFaqItem(
            'How can I track my complaint?',
            'Go to "My Complaints" from the menu to see the status of all your reported issues.',
          ),
          _buildFaqItem(
            'What is the leaderboard?',
            'The leaderboard ranks citizens based on their contributions to keeping the city clean. Reporting valid issues and getting them resolved earns you points.',
          ),
          _buildFaqItem(
            'Is my personal information safe?',
            'Yes, we take your privacy seriously. Your details are only used for verification and communication regarding your reports.',
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.blue.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
