import 'package:flutter/material.dart';

class PrivacyAndSecurityScreen extends StatefulWidget {
  const PrivacyAndSecurityScreen({super.key});

  @override
  State<PrivacyAndSecurityScreen> createState() => _PrivacyAndSecurityScreenState();
}

class _PrivacyAndSecurityScreenState extends State<PrivacyAndSecurityScreen> {
  bool _isProfilePublic = true;
  bool _allowLocation = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy & Security',
          style: TextStyle(color: Colors.grey[900]),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Make my profile public'),
              value: _isProfilePublic,
              onChanged: (value) {
                setState(() {
                  _isProfilePublic = value;
                });
              },
              activeColor: const Color(0xFF2196F3),
            ),
            SwitchListTile(
              title: const Text('Allow location tracking'),
              value: _allowLocation,
              onChanged: (value) {
                setState(() {
                  _allowLocation = value;
                });
              },
              activeColor: const Color(0xFF2196F3),
            ),
            ListTile(
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Navigate to Change Password Screen'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
