import 'package:flutter/material.dart';

class ContractorProfileScreen extends StatelessWidget {
  const ContractorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> companyInfo = {
      'companyName': 'Clean City Services Pvt Ltd',
      'contractorId': 'CTR-001',
      'email': 'contact@cleancity.com',
      'phone': '0300-1234567',
      'totalZones': 3,
      'overallPerformance': 88,
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Profile'),backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.business, size: 50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    companyInfo['companyName'],
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${companyInfo['contractorId']}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(companyInfo['email']),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Phone'),
              subtitle: Text(companyInfo['phone']),
            ),
            ListTile(
              leading: const Icon(Icons.location_city),
              title: const Text('Assigned Zones'),
              subtitle: Text('${companyInfo['totalZones']} zones'),
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Overall Performance'),
              subtitle: Text('${companyInfo['overallPerformance']}%'),
            ),
          ],
        ),
      ),
    );
  }
}
