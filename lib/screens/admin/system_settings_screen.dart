import 'package:flutter/material.dart';
import '../../services/settings_service.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final SettingsService _settingsService = SettingsService();

  bool _notificationsEnabled = true;
  bool _autoAssignmentEnabled = false;
  bool _maintenanceMode = false;
  int _escalationHours = 48;
  String _defaultPriority = 'Medium';

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _settingsService.getSystemSettings();
      setState(() {
        _notificationsEnabled = settings['notificationsEnabled'] ?? true;
        _autoAssignmentEnabled = settings['autoAssignmentEnabled'] ?? false;
        _maintenanceMode = settings['maintenanceMode'] ?? false;
        _escalationHours = settings['escalationHours'] ?? 48;
        _defaultPriority = settings['defaultPriority'] ?? 'Medium';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await _settingsService.updateSystemSettings({
        'notificationsEnabled': _notificationsEnabled,
        'autoAssignmentEnabled': _autoAssignmentEnabled,
        'maintenanceMode': _maintenanceMode,
        'escalationHours': _escalationHours,
        'defaultPriority': _defaultPriority,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('System Settings', style: TextStyle(color: Colors.grey[900])),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('System Settings', style: TextStyle(color: Colors.grey[900])),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadSettings, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('System Settings', style: TextStyle(color: Colors.grey[900])),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadSettings,
          ),
        ],
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Send notifications to users and staff'),
            value: _notificationsEnabled,
            onChanged: _isSaving ? null : (value) => setState(() => _notificationsEnabled = value),
            activeColor: const Color(0xFF2196F3),
          ),
          const Divider(),

          SwitchListTile(
            title: const Text('Auto Assignment'),
            subtitle: const Text('Automatically assign complaints to available staff'),
            value: _autoAssignmentEnabled,
            onChanged: _isSaving ? null : (value) => setState(() => _autoAssignmentEnabled = value),
            activeColor: const Color(0xFF2196F3),
          ),
          const Divider(),

          SwitchListTile(
            title: const Text('Maintenance Mode'),
            subtitle: const Text('Disable new complaint submissions'),
            value: _maintenanceMode,
            onChanged: _isSaving ? null : (value) => setState(() => _maintenanceMode = value),
            activeColor: Colors.red,
          ),
          const Divider(),

          ListTile(
            title: const Text('Escalation Hours'),
            subtitle: Text('Auto-escalate complaints after $_escalationHours hours'),
            trailing: SizedBox(
              width: 100,
              child: DropdownButtonFormField<int>(
                value: _escalationHours,
                items: [24, 48, 72].map((hours) {
                  return DropdownMenuItem(value: hours, child: Text('$hours hours'));
                }).toList(),
                onChanged: _isSaving ? null : (value) => setState(() => _escalationHours = value!),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
          ),
          const Divider(),

          ListTile(
            title: const Text('Default Priority'),
            subtitle: Text('Default priority for new complaints'),
            trailing: SizedBox(
              width: 120,
              child: DropdownButtonFormField<String>(
                value: _defaultPriority,
                items: ['Low', 'Medium', 'High', 'Critical'].map((priority) {
                  return DropdownMenuItem(value: priority, child: Text(priority));
                }).toList(),
                onChanged: _isSaving ? null : (value) => setState(() => _defaultPriority = value!),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
          ),
          const Divider(),

          ListTile(
            title: const Text('Manage Complaint Categories'),
            subtitle: const Text('Add, edit, or remove complaint categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _isSaving ? null : () {
              // Navigate to categories management
            },
          ),
          const Divider(),

          ListTile(
            title: const Text('Backup & Restore'),
            subtitle: const Text('Backup system data or restore from backup'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _isSaving ? null : () {
              // Navigate to backup/restore
            },
          ),
        ],
      ),
    );
  }
}