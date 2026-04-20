// lib/services/auth_service.dart - FULLY FIXED VERSION

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import 'api_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // ========== STORAGE KEYS ==========

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userTypeKey = 'user_type';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';
  static const String _userCnicKey = 'user_cnic';
  static const String _userAddressKey = 'user_address';
  static const String _zoneIdKey = 'zone_id';
  static const String _zoneNameKey = 'zone_name';
  static const String _profilePhotoKey = 'profile_photo';
  static const String _isVerifiedKey = 'is_verified';
  static const String _lastLoginKey = 'last_login';

  // Statistics Keys
  static const String _totalComplaintsKey = 'total_complaints';
  static const String _resolvedComplaintsKey = 'resolved_complaints';
  static const String _pendingComplaintsKey = 'pending_complaints';
  static const String _approvedComplaintsKey = 'approved_complaints';
  static const String _badgeLevelKey = 'badge_level';
  static const String _leaderboardRankKey = 'leaderboard_rank';
  static const String _contributionScoreKey = 'contribution_score';

  // Staff Specific Keys
  static const String _staffIdKey = 'staff_id';
  static const String _departmentIdKey = 'department_id';
  static const String _departmentNameKey = 'department_name';
  static const String _roleKey = 'role';
  static const String _employeeIdKey = 'employee_id';

  // Contractor Specific Keys
  static const String _contractorIdKey = 'contractor_id';
  static const String _companyNameKey = 'company_name';
  static const String _contractorPerformanceKey = 'contractor_performance';

  // ========== CURRENT USER STATE ==========
  String? _currentUserId;
  String? _currentUserType;
  String? _currentUserName;
  String? _currentUserEmail;
  String? _currentUserPhone;
  String? _currentProfilePhoto;
  String? _staffId;
  String? _departmentId;
  String? _departmentName;
  String? _role;

  // Contractor state variables
  String? _currentContractorId;
  String? _currentCompanyName;
  String? _currentContractorPerformance;

  // Full user object cache
  User? _currentUser;

  // ========== GETTERS ==========
  String? get currentUserId => _currentUserId;
  String? get currentUserType => _currentUserType;
  String? get currentUserName => _currentUserName;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserPhone => _currentUserPhone;
  String? get currentProfilePhoto => _currentProfilePhoto;
  User? get currentUser => _currentUser;
  String? get currentContractorId => _currentContractorId;
  String? get currentCompanyName => _currentCompanyName;

  // ========== LOGIN ==========
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔐 Attempting login to: ${ApiConfig.baseUrl}/user/login');

      final request = LoginRequest(
        email: email.trim(),
        passwordHash: password,
      );

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/user/login'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(request.toJson()),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Login successful for: ${data['fullName'] ?? data['FullName']}');

        await _saveUserSession(data);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Login error: $e');
      rethrow;
    }
  }

  // ========== STAFF LOGIN ==========
  Future<Map<String, dynamic>> staffLogin(String email, String password) async {
    try {
      print('🔐 Attempting staff login to: ${ApiConfig.baseUrl}/user/staff/login');

      final request = LoginRequest(
        email: email.trim(),
        passwordHash: password,
      );

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/user/staff/login'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(request.toJson()),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Staff login successful for: ${data['fullName'] ?? data['FullName']}');
        print('📋 UserType: ${data['UserType']}');

        // Debug: Print staff info if available
        if (data['StaffInfo'] != null) {
          print('📋 StaffInfo: ${data['StaffInfo']}');
        }
        if (data['AdminInfo'] != null) {
          print('📋 AdminInfo: ${data['AdminInfo']}');
        }

        await _saveUserSession(data);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Staff login error: $e');
      rethrow;
    }
  }

  // ========== REGISTER ==========
  Future<Map<String, dynamic>> register(RegisterRequest request) async {
    try {
      print('📝 Attempting registration for: ${request.email}');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/user/register'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(request.toJson()),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Registration successful! UserId: ${data['UserId']}');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['Message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('❌ Registration error: $e');
      rethrow;
    }
  }

  // ========== SAVE COMPREHENSIVE USER SESSION (FIXED) ==========
  Future<void> _saveUserSession(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    // ===== BASIC USER INFO =====
    _currentUserId = userData['UserId']?.toString() ??
        userData['userId']?.toString() ?? '';
    _currentUserType = userData['UserType']?.toString() ??
        userData['userType']?.toString() ?? '';
    _currentUserName = userData['fullName']?.toString() ??
        userData['FullName']?.toString() ?? '';
    _currentUserEmail = userData['email']?.toString() ??
        userData['Email']?.toString() ?? '';
    _currentUserPhone = userData['phoneNumber']?.toString() ??
        userData['PhoneNumber']?.toString() ?? '';
    _currentProfilePhoto = userData['profilePhotoUrl']?.toString() ??
        userData['ProfilePhotoUrl']?.toString();

    // Save basic info
    await prefs.setString(_userIdKey, _currentUserId!);
    await prefs.setString(_userTypeKey, _currentUserType!);
    await prefs.setString(_userNameKey, _currentUserName!);
    await prefs.setString(_userEmailKey, _currentUserEmail ?? '');
    await prefs.setString(_userPhoneKey, _currentUserPhone ?? '');

    if (_currentProfilePhoto != null) {
      await prefs.setString(_profilePhotoKey, _currentProfilePhoto!);
    }

    // ===== ADDITIONAL USER FIELDS =====
    final cnic = userData['CNIC']?.toString() ?? userData['cnic']?.toString();
    if (cnic != null) await prefs.setString(_userCnicKey, cnic);

    final address = userData['Address']?.toString() ?? userData['address']?.toString();
    if (address != null) await prefs.setString(_userAddressKey, address);

    final isVerified = userData['IsVerified'] ?? userData['isVerified'] ?? false;
    await prefs.setBool(_isVerifiedKey, isVerified);

    final lastLogin = userData['LastLogin']?.toString() ??
        userData['lastLogin']?.toString() ??
        DateTime.now().toIso8601String();
    await prefs.setString(_lastLoginKey, lastLogin);

    // ===== ZONE INFO =====
    if (userData.containsKey('Zone')) {
      final zone = userData['Zone'];
      if (zone != null) {
        final zoneId = zone['zoneId']?.toString() ?? zone['ZoneId']?.toString();
        final zoneName = zone['zoneName']?.toString() ?? zone['ZoneName']?.toString();
        if (zoneId != null) await prefs.setString(_zoneIdKey, zoneId);
        if (zoneName != null) await prefs.setString(_zoneNameKey, zoneName);
      }
    }

    // ===== CITIZEN PROFILE STATISTICS =====
    if (userData.containsKey('CitizenProfile') || userData.containsKey('Statistics')) {
      final stats = userData['CitizenProfile'] ?? userData['Statistics'] ?? {};
      await prefs.setInt(_totalComplaintsKey, stats['total_complaints'] ?? stats['TotalComplaints'] ?? 0);
      await prefs.setInt(_resolvedComplaintsKey, stats['resolved_complaints'] ?? stats['ResolvedComplaints'] ?? 0);
      await prefs.setInt(_pendingComplaintsKey, stats['pending_complaints'] ?? stats['PendingComplaints'] ?? 0);
      await prefs.setInt(_approvedComplaintsKey, stats['approved_complaints'] ?? stats['ApprovedComplaints'] ?? 0);
      await prefs.setString(_badgeLevelKey, stats['badge_level'] ?? stats['BadgeLevel'] ?? 'Newcomer');
      await prefs.setInt(_leaderboardRankKey, stats['leaderboard_rank'] ?? stats['LeaderboardRank'] ?? 0);
      await prefs.setInt(_contributionScoreKey, stats['contribution_score'] ?? stats['ContributionScore'] ?? 0);
    }

    // ===== STAFF PROFILE INFO (FIXED - Now handles both StaffInfo and AdminInfo) =====

    // First, try to get from StaffInfo (for Field Staff)
    if (userData.containsKey('StaffInfo') && userData['StaffInfo'] != null) {
      final staff = userData['StaffInfo'];
      print('📋 Saving StaffInfo: $staff');

      final staffId = staff['staffId']?.toString() ?? staff['StaffId']?.toString();
      final departmentId = staff['departmentId']?.toString() ?? staff['DepartmentId']?.toString();
      final departmentName = staff['departmentName']?.toString() ?? staff['DepartmentName']?.toString();
      final role = staff['role']?.toString() ?? staff['Role']?.toString();
      final employeeId = staff['employeeId']?.toString() ?? staff['EmployeeId']?.toString();

      _staffId = staffId;
      _departmentId = departmentId;
      _departmentName = departmentName;
      _role = role;

      if (staffId != null) await prefs.setString(_staffIdKey, staffId);
      if (departmentId != null) await prefs.setString(_departmentIdKey, departmentId);
      if (departmentName != null) await prefs.setString(_departmentNameKey, departmentName);
      if (role != null) await prefs.setString(_roleKey, role);
      if (employeeId != null) await prefs.setString(_employeeIdKey, employeeId);

      print('✅ Saved StaffInfo - Department: $departmentName ($departmentId)');
    }

    // Also check for AdminInfo (for Department Admin - contains department info)
    if (userData.containsKey('AdminInfo') && userData['AdminInfo'] != null) {
      final adminInfo = userData['AdminInfo'];
      print('📋 Saving AdminInfo: $adminInfo');

      final adminDeptId = adminInfo['departmentId']?.toString() ?? adminInfo['DepartmentId']?.toString();
      final adminDeptName = adminInfo['departmentName']?.toString() ?? adminInfo['DepartmentName']?.toString();

      // Only save if not already set or if this provides more info
      if (adminDeptId != null) {
        _departmentId = adminDeptId;
        await prefs.setString(_departmentIdKey, adminDeptId);
        print('✅ Saved department ID from AdminInfo: $adminDeptId');
      }
      if (adminDeptName != null) {
        _departmentName = adminDeptName;
        await prefs.setString(_departmentNameKey, adminDeptName);
        print('✅ Saved department name from AdminInfo: $adminDeptName');
      }
    }

    // Also check StaffProfile (alternative location)
    if (userData.containsKey('StaffProfile') && userData['StaffProfile'] != null) {
      final staff = userData['StaffProfile'];
      print('📋 Saving StaffProfile: $staff');

      final staffId = staff['staffId']?.toString() ?? staff['StaffId']?.toString();
      final departmentId = staff['departmentId']?.toString() ?? staff['DepartmentId']?.toString();
      final departmentName = staff['departmentName']?.toString() ?? staff['DepartmentName']?.toString();

      if (staffId != null && _staffId == null) {
        _staffId = staffId;
        await prefs.setString(_staffIdKey, staffId);
      }
      if (departmentId != null && _departmentId == null) {
        _departmentId = departmentId;
        await prefs.setString(_departmentIdKey, departmentId);
      }
      if (departmentName != null && _departmentName == null) {
        _departmentName = departmentName;
        await prefs.setString(_departmentNameKey, departmentName);
      }
    }

    // ===== CONTRACTOR PROFILE INFO =====
    if (userData.containsKey('ContractorProfile') ||
        userData.containsKey('ContractorInfo') ||
        _currentUserType?.toLowerCase() == 'contractor') {
      final contractor = userData['ContractorProfile'] ?? userData['ContractorInfo'] ?? {};
      _currentContractorId = _currentUserId;
      _currentCompanyName = _currentUserName;

      final contractorId = contractor['contractorId']?.toString() ??
          contractor['ContractorId']?.toString() ?? _currentUserId;
      final companyName = contractor['companyName']?.toString() ??
          contractor['CompanyName']?.toString() ?? _currentUserName;
      final performance = contractor['performanceScore'] ??
          contractor['PerformanceScore'] ?? 0;

      if (contractorId != null) {
        await prefs.setString(_contractorIdKey, contractorId);
        _currentContractorId = contractorId;
      }
      if (companyName != null) {
        await prefs.setString(_companyNameKey, companyName);
        _currentCompanyName = companyName;
      }
      await prefs.setDouble(_contractorPerformanceKey, performance.toDouble());
      _currentContractorPerformance = performance.toString();
    }

    // ===== AUTH TOKEN =====
    if (userData.containsKey('Token') || userData.containsKey('token')) {
      final token = userData['Token']?.toString() ?? userData['token']?.toString();
      if (token != null) await prefs.setString(_tokenKey, token);
    }

    _currentUser = User.fromJson(userData);

    // Debug: Print final saved department info
    print('📱 FINAL SAVED - Department ID: $_departmentId, Department Name: $_departmentName');
  }

  // ========== LOAD SAVED SESSION (FIXED) ==========
  Future<void> loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();

    _currentUserId = prefs.getString(_userIdKey);
    _currentUserType = prefs.getString(_userTypeKey);
    _currentUserName = prefs.getString(_userNameKey);
    _currentUserEmail = prefs.getString(_userEmailKey);
    _currentUserPhone = prefs.getString(_userPhoneKey);
    _currentProfilePhoto = prefs.getString(_profilePhotoKey);

    // Staff info
    _staffId = prefs.getString(_staffIdKey);
    _departmentId = prefs.getString(_departmentIdKey);
    _departmentName = prefs.getString(_departmentNameKey);
    _role = prefs.getString(_roleKey);

    // Contractor data
    _currentContractorId = prefs.getString(_contractorIdKey);
    _currentCompanyName = prefs.getString(_companyNameKey);

    print('📱 Loaded session - Department ID: $_departmentId, Department Name: $_departmentName');
    print('📱 User Type: $_currentUserType, Staff ID: $_staffId');
  }

  // ========== GET COMPLETE USER DATA ==========
  Future<Map<String, dynamic>> getAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(_userIdKey),
      'userType': prefs.getString(_userTypeKey),
      'userName': prefs.getString(_userNameKey),
      'userEmail': prefs.getString(_userEmailKey),
      'userPhone': prefs.getString(_userPhoneKey),
      'userCnic': prefs.getString(_userCnicKey),
      'userAddress': prefs.getString(_userAddressKey),
      'profilePhoto': prefs.getString(_profilePhotoKey),
      'isVerified': prefs.getBool(_isVerifiedKey),
      'lastLogin': prefs.getString(_lastLoginKey),
      'zoneId': prefs.getString(_zoneIdKey),
      'zoneName': prefs.getString(_zoneNameKey),
      'totalComplaints': prefs.getInt(_totalComplaintsKey) ?? 0,
      'resolvedComplaints': prefs.getInt(_resolvedComplaintsKey) ?? 0,
      'pendingComplaints': prefs.getInt(_pendingComplaintsKey) ?? 0,
      'approvedComplaints': prefs.getInt(_approvedComplaintsKey) ?? 0,
      'badgeLevel': prefs.getString(_badgeLevelKey) ?? 'Newcomer',
      'leaderboardRank': prefs.getInt(_leaderboardRankKey) ?? 0,
      'contributionScore': prefs.getInt(_contributionScoreKey) ?? 0,
      'staffId': prefs.getString(_staffIdKey),
      'departmentId': prefs.getString(_departmentIdKey),
      'departmentName': prefs.getString(_departmentNameKey),
      'role': prefs.getString(_roleKey),
      'employeeId': prefs.getString(_employeeIdKey),
      'contractorId': prefs.getString(_contractorIdKey),
      'companyName': prefs.getString(_companyNameKey),
      'contractorPerformance': prefs.getDouble(_contractorPerformanceKey),
      'authToken': prefs.getString(_tokenKey),
    };
  }

  // ========== UPDATE SPECIFIC USER DATA ==========
  Future<void> updateUserData(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
    switch (key) {
      case _userNameKey: _currentUserName = value as String?; break;
      case _userEmailKey: _currentUserEmail = value as String?; break;
      case _userPhoneKey: _currentUserPhone = value as String?; break;
      case _profilePhotoKey: _currentProfilePhoto = value as String?; break;
      case _departmentIdKey: _departmentId = value as String?; break;
      case _departmentNameKey: _departmentName = value as String?; break;
      case _contractorIdKey: _currentContractorId = value as String?; break;
      case _companyNameKey: _currentCompanyName = value as String?; break;
    }
  }

  // ========== GET SPECIFIC USER DATA ==========
  Future<String?> getUserName() async {
    if (_currentUserName != null) return _currentUserName;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<String?> getUserEmail() async {
    if (_currentUserEmail != null) return _currentUserEmail;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  Future<String?> getUserPhone() async {
    if (_currentUserPhone != null) return _currentUserPhone;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey);
  }

  Future<String?> getProfilePhoto() async {
    if (_currentProfilePhoto != null) return _currentProfilePhoto;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profilePhotoKey);
  }

  Future<String?> getZoneName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_zoneNameKey);
  }

  Future<String?> getBadgeLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_badgeLevelKey);
  }

  Future<int> getLeaderboardRank() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_leaderboardRankKey) ?? 0;
  }

  // ========== STAFF GETTERS (FIXED) ==========

  Future<String?> getStaffId() async {
    if (_staffId != null) return _staffId;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_staffIdKey);
  }

  Future<String?> getDepartmentId() async {
    if (_departmentId != null) {
      print('📱 Returning cached department ID: $_departmentId');
      return _departmentId;
    }
    final prefs = await SharedPreferences.getInstance();
    final deptId = prefs.getString(_departmentIdKey);
    print('📱 Loaded department ID from prefs: $deptId');
    return deptId;
  }

  Future<String?> getDepartmentName() async {
    if (_departmentName != null) {
      print('📱 Returning cached department name: $_departmentName');
      return _departmentName;
    }
    final prefs = await SharedPreferences.getInstance();
    final deptName = prefs.getString(_departmentNameKey);
    print('📱 Loaded department name from prefs: $deptName');
    return deptName;
  }

  Future<String?> getRole() async {
    if (_role != null) return _role;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<String?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_employeeIdKey);
  }

  // ========== CONTRACTOR GETTERS ==========

  Future<String?> getContractorId() async {
    if (_currentContractorId != null) return _currentContractorId;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_contractorIdKey);
  }

  Future<String?> getCompanyName() async {
    if (_currentCompanyName != null) return _currentCompanyName;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_companyNameKey);
  }

  Future<double?> getContractorPerformance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_contractorPerformanceKey);
  }

  // ========== CHECK USER STATUS ==========
  Future<bool> isLoggedIn() async {
    await loadSavedSession();
    return _currentUserId != null && _currentUserId!.isNotEmpty;
  }

  Future<String?> getUserId() async {
    if (_currentUserId != null) return _currentUserId;
    await loadSavedSession();
    return _currentUserId;
  }

  Future<String?> getUserType() async {
    if (_currentUserType != null) return _currentUserType;
    await loadSavedSession();
    return _currentUserType;
  }

  Future<bool> isCitizen() async {
    final type = await getUserType();
    return type?.toLowerCase() == 'citizen';
  }

  Future<bool> isStaff() async {
    final type = await getUserType();
    return type?.toLowerCase() == 'field_staff' ||
        type?.toLowerCase() == 'department_admin';
  }

  Future<bool> isAdmin() async {
    final type = await getUserType();
    return type?.toLowerCase() == 'system_admin' ||
        type?.toLowerCase() == 'department_admin';
  }

  Future<bool> isContractor() async {
    final type = await getUserType();
    return type?.toLowerCase() == 'contractor';
  }

  // ========== LOGOUT ==========
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _currentUserId = null;
    _currentUserType = null;
    _currentUserName = null;
    _currentUserEmail = null;
    _currentUserPhone = null;
    _currentProfilePhoto = null;
    _currentUser = null;
    _staffId = null;
    _departmentId = null;
    _departmentName = null;
    _role = null;
    _currentContractorId = null;
    _currentCompanyName = null;
    _currentContractorPerformance = null;
  }

  // ========== GET AUTH TOKEN ==========
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ========== DEBUG ==========
  Future<void> debugPrintAllData() async {
    final data = await getAllUserData();
    print('\n📱 SHARED PREFERENCES DATA:');
    data.forEach((key, value) {
      print('   $key: $value');
    });
  }
}