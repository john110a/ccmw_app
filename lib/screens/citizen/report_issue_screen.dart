import 'package:flutter/material.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  String? selectedCategory;

  final List<Map<String, dynamic>> categories = [
    // Garbage related
    {'name': 'Garbage', 'icon': Icons.delete_outline, 'color': Colors.green},
    {'name': 'Garbage Collection', 'icon': Icons.delete, 'color': Colors.green},
    {'name': 'Illegal Dumping', 'icon': Icons.warning, 'color': Colors.red},

    // Road related
    {'name': 'Road Damage', 'icon': Icons.construction, 'color': Colors.orange},
    {'name': 'Road Potholes', 'icon': Icons.circle, 'color': Colors.brown},
    {'name': 'Pothole Repair', 'icon': Icons.hardware, 'color': Colors.brown},

    // Street Light related
    {'name': 'Street Light', 'icon': Icons.light_mode, 'color': Colors.yellow},
    {'name': 'Street Light Issue', 'icon': Icons.lightbulb_outline, 'color': Colors.amber},
    {'name': 'Street Light Out', 'icon': Icons.lightbulb, 'color': Colors.orange},

    // Water related
    {'name': 'Water Supply', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'name': 'Water Supply Issue', 'icon': Icons.water, 'color': Colors.lightBlue},
    {'name': 'Water Leakage', 'icon': Icons.plumbing, 'color': Colors.cyan},

    // Sewerage related
    {'name': 'Sewerage', 'icon': Icons.water_damage, 'color': Colors.brown},
    {'name': 'Sewerage Blockage', 'icon': Icons.cleaning_services, 'color': Colors.brown},

    // Park related
    {'name': 'Parks', 'icon': Icons.park, 'color': Colors.lightGreen},
    {'name': 'Park Maintenance', 'icon': Icons.grass, 'color': Colors.green},
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Report Issue',
          style: TextStyle(color: Colors.grey[900]),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                _buildProgressCircle(1, true),
                Expanded(child: Container(height: 2, color: Colors.grey[300])),
                _buildProgressCircle(2, false),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Issue Category',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the type of issue you want to report',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = selectedCategory == category['name'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = category['name'];
                          });
                        },
                        child: Card(
                          elevation: isSelected ? 4 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF2196F3) : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: category['color'].withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  category['icon'],
                                  size: 30,
                                  color: category['color'],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                category['name'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? const Color(0xFF2196F3) : Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedCategory == null
                    ? null
                    : () {
                  Navigator.pushNamed(
                    context,
                    '/issue-details',
                    arguments: selectedCategory,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCircle(int step, bool active) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2196F3) : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: active ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
