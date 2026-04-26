// lib/screens/citizen/leaderboard_screen.dart

import 'package:flutter/material.dart';
import '../../services/leaderboard_service.dart';
import '../../services/AuthService.dart';
import 'all_rankings_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final LeaderboardService _leaderboardService = LeaderboardService();
  final AuthService _authService = AuthService();

  List<dynamic> _topCitizens = [];
  Map<String, dynamic>? _userRank;
  bool _isLoading = true;
  bool _isLoadingUserRank = true;
  String? _errorMessage;
  String _selectedPeriod = 'monthly';

  final List<String> _periods = ['weekly', 'monthly', 'all'];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
    _loadUserRank();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    try {
      final leaderboard = await _leaderboardService.getCitizenLeaderboard(
        period: _selectedPeriod,
        top: 10,
      );

      print('📊 Leaderboard data: $leaderboard'); // Debug print

      setState(() {
        _topCitizens = leaderboard;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserRank() async {
    setState(() => _isLoadingUserRank = true);

    try {
      final userId = await _getCurrentUserId();
      if (userId != null && userId.isNotEmpty) {
        final rank = await _leaderboardService.getUserRank(userId);
        print('📊 User rank data: $rank'); // Debug print
        setState(() {
          _userRank = rank;
          _isLoadingUserRank = false;
        });
      } else {
        print('⚠️ No user ID found for rank lookup');
        setState(() {
          _isLoadingUserRank = false;
        });
      }
    } catch (e) {
      print('Error loading user rank: $e');
      setState(() {
        _isLoadingUserRank = false;
      });
    }
  }

  Future<String?> _getCurrentUserId() async {
    try {
      final userId = await _authService.getUserId();
      print('📱 Current User ID: $userId');
      return userId;
    } catch (e) {
      print('❌ Error getting user ID: $e');
      return null;
    }
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadLeaderboard();
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[800]!;
      case 2:
        return Colors.grey[600]!;
      case 3:
        return Colors.orange[800]!;
      default:
        return Colors.blue;
    }
  }

  Color _getMedalColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.orange;
      default:
        return Colors.transparent;
    }
  }

  String _getBadgeIcon(String? badgeLevel) {
    switch (badgeLevel?.toLowerCase()) {
      case 'gold':
        return '🥇';
      case 'silver':
        return '🥈';
      case 'bronze':
        return '🥉';
      default:
        return '⭐';
    }
  }

  Color _getBadgeColor(String? badgeLevel) {
    switch (badgeLevel?.toLowerCase()) {
      case 'gold':
        return Colors.amber;
      case 'silver':
        return Colors.grey;
      case 'bronze':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

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
          'Citizen Leaderboard',
          style: TextStyle(color: Colors.grey[900]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: () {
              _loadLeaderboard();
              _loadUserRank();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLeaderboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blue[800]!,
                    Colors.blue[600]!,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Top Contributors',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Citizens making our city better',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Period Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _periods.map((period) {
                      final isSelected = _selectedPeriod == period;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(
                            period[0].toUpperCase() + period.substring(1),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.blue[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) => _changePeriod(period),
                          backgroundColor: Colors.white,
                          selectedColor: Colors.blue[700],
                          checkmarkColor: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // User Rank Card
                  if (!_isLoadingUserRank && _userRank != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _getBadgeColor(_userRank?['Badge']),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _getBadgeIcon(_userRank?['Badge']),
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userRank?['UserName'] ?? 'Your Rank',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '#${_userRank?['Rank'] ?? '?'}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${_userRank?['ContributionScore'] ?? 0} points',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Top ${_userRank?['TopPercent'] ?? '0'}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (!_isLoadingUserRank && _userRank == null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white70),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Login to see your rank',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Leaderboard List
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Top Contributors',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _selectedPeriod[0].toUpperCase() + _selectedPeriod.substring(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_topCitizens.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No data available'),
                      ),
                    )
                  else
                    ..._topCitizens.asMap().entries.map((entry) {
                      final index = entry.key;
                      final citizen = entry.value;
                      // FIXED: Use PascalCase field names from backend
                      return _buildLeaderboardItem({
                        'rank': citizen['Rank'] ?? index + 1,
                        'name': citizen['FullName'] ?? 'Unknown',
                        'score': citizen['ContributionScore'] ?? 0,
                        'reports': citizen['ApprovedComplaints'] ?? 0,
                        'resolved': citizen['ResolvedComplaints'] ?? 0,
                        'badge': citizen['BadgeLevel'] ?? 'Newcomer',
                        'avatarColor': _getRankColor(citizen['Rank'] ?? index + 1),
                      });
                    }),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AllRankingsScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('View All Rankings'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> citizen) {
    final rank = citizen['rank'] as int;
    final badge = citizen['badge'] ?? 'Newcomer';
    final badgeColor = _getBadgeColor(badge);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _getRankColor(rank),
                shape: BoxShape.circle,
              ),
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Avatar with Badge
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: citizen['avatarColor'] as Color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white.withOpacity(0.9),
                    size: 24,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        _getBadgeIcon(badge),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    citizen['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${citizen['score']} pts',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Icon(Icons.report, size: 12, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            '${citizen['reports']} reports',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, size: 12, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            '${citizen['resolved']} resolved',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Medal for top 3
            if (rank <= 3)
              Icon(
                Icons.emoji_events,
                color: _getMedalColor(rank),
                size: 32,
              ),
          ],
        ),
      ),
    );
  }
}