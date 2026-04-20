import 'package:flutter/material.dart';
import '../../config/routes.dart'; // Make sure this import is correct

class StaffRoleSelectionScreen extends StatelessWidget {
  const StaffRoleSelectionScreen({super.key});

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
          'Staff & Contractor Login', // Updated title
          style: TextStyle(color: Colors.grey[900]),
        ),
      ),
      body: SafeArea(
        // FIX: Wrap with SingleChildScrollView to prevent overflow
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Header
                Text(
                  'Select Your Role',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your role to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),

                // System Administrator Card
                _buildRoleCard(
                  context,
                  title: 'System Administrator',
                  description: 'Manage users, zones, and system settings',
                  icon: Icons.admin_panel_settings,
                  color: Colors.purple,
                  route: Routes.adminLogin, // Using Routes constant
                ),
                const SizedBox(height: 16),

                // Department Admin Card
                _buildRoleCard(
                  context,
                  title: 'Department Admin',
                  description: 'Review complaints and assign to field staff',
                  icon: Icons.business,
                  color: Colors.blue,
                  route: Routes.departmentLogin, // Using Routes constant
                ),
                const SizedBox(height: 16),

                // Field Staff Card
                _buildRoleCard(
                  context,
                  title: 'Field Staff',
                  description: 'Resolve complaints and update status',
                  icon: Icons.engineering,
                  color: Colors.green,
                  route: Routes.fieldStaffLogin, // Using Routes constant
                ),

                const SizedBox(height: 16),

                // =====================================================
                // NEW: Contractor Card
                // =====================================================
                _buildRoleCard(
                  context,
                  title: 'Contractor',
                  description: 'Manage assigned zones and contracts',
                  icon: Icons.business_center,
                  color: Colors.orange,
                  route: Routes.contractorLogin, // Using Routes constant
                ),

                const SizedBox(height: 32),

                const Divider(),
                const SizedBox(height: 16),

                // Back to Citizen Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Citizen? ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, Routes.login); // Using Routes constant
                      },
                      child: const Text(
                        'Go to Citizen Login',
                        style: TextStyle(
                          color: Color(0xFF2196F3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // Add extra bottom padding for scrolling
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
      BuildContext context, {
        required String title,
        required String description,
        required IconData icon,
        required Color color,
        required String route,
      }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}