import 'package:flutter/material.dart';
import '../screens/Contractor/ContractorLoginScreen.dart';
import '../screens/Contractor/contractor_dashboard_screen.dart';
import '../screens/Contractor/contractor_photos_screen.dart';
import '../screens/Contractor/contractor_profile_screen.dart';
import '../screens/Contractor/contractor_reports_screen.dart';
import '../screens/Contractor/contractor_tasks_screen.dart';
import '../screens/Contractor/contractor_zone_detail_screen.dart';
import '../screens/admin/admin_complaints_screen.dart';
import '../screens/admin/compare_duplicates_screen.dart';
import '../screens/admin/complaint_approval_screen.dart';
import '../screens/admin/department_management_screen.dart';
import '../screens/admin/detect_duplicates_screen.dart';
import '../screens/admin/duplicate_notifications_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/terms_and_conditions_screen.dart';
import '../screens/citizen/home_screen.dart';
import '../screens/citizen/report_issue_screen.dart';
import '../screens/citizen/issue_details_screen.dart';
import '../screens/citizen/my_complaints_screen.dart';
import '../screens/citizen/complaint_detail_screen.dart';
import '../screens/citizen/community_map_screen.dart';
import '../screens/citizen/profile_screen.dart';
import '../screens/citizen/leaderboard_screen.dart';
import '../screens/citizen/public_complaints_screen.dart';
import '../screens/citizen/approval_status_screen.dart';
import '../screens/citizen/notifications_screen.dart';
import '../screens/citizen/personal_information_screen.dart';
import '../screens/citizen/address_and_zones_screen.dart';
import '../screens/citizen/notifications_settings_screen.dart';
import '../screens/citizen/privacy_and_security_screen.dart';
import '../screens/citizen/help_and_support_screen.dart';
import '../screens/citizen/about_screen.dart';
import '../screens/staff/resolution_upload_screen.dart';
import '../screens/staff/role_selection_screen.dart';
import '../screens/staff/admin_login_screen.dart';
import '../screens/staff/department_login_screen.dart';
import '../screens/staff/field_staff_login_screen.dart';
import '../screens/staff/staff_dashboard_screen.dart';
import '../screens/staff/complaint_view_screen.dart';
import '../screens/staff/my_tasks_screen.dart';
import '../screens/staff/staff_map_screen.dart';
import '../screens/staff/staff_profile_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/merge_duplicates_screen.dart';
import '../screens/admin/department_dashboard_screen.dart';
import '../screens/admin/routing_screen.dart';
import '../screens/admin/resolution_detection_screen.dart';
import '../screens/admin/zone_management_screen.dart';
import '../screens/admin/escalation_workflow_screen.dart';
import '../screens/admin/privatization_management_screen.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/system_settings_screen.dart';
import '../screens/admin/reports_screen.dart';
import '../screens/admin/staff_management_screen.dart';
import '../screens/staff/task_detail_screen.dart';
import '../screens/zone/zone_details_screen.dart';
import '../screens/citizen/complaint_status_history_screen.dart';

class Routes {
  // Citizen route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String termsAndConditions = '/terms-and-conditions';
  static const String home = '/home';
  static const String reportIssue = '/report-issue';
  static const String issueDetails = '/issue-details';
  static const String myComplaints = '/my-complaints';
  static const String complaintDetail = '/complaint-detail';
  static const String communityMap = '/community-map';
  static const String profile = '/profile';
  static const String leaderboard = '/leaderboard';
  static const String publicComplaints = '/public-complaints';
  static const String approvalStatus = '/approval-status';
  static const String notifications = '/notifications';
  static const String personalInformation = '/personal-information';
  static const String addressAndZones = '/address-and-zones';
  static const String notificationSettings = '/notification-settings';
  static const String privacyAndSecurity = '/privacy-and-security';
  static const String helpAndSupport = '/help-and-support';
  static const String about = '/about';
  static const String complaintStatusHistory = '/complaint-status-history';

  // Staff route names
  static const String staffRoleSelection = '/staff-role-selection';
  static const String adminLogin = '/admin-login';
  static const String departmentLogin = '/department-login';
  static const String fieldStaffLogin = '/field-staff-login';
  static const String staffDashboard = '/staff-dashboard';
  static const String staffComplaintView = '/staff-complaint-view';
  static const String myTasks = '/my-tasks';
  static const String staffMap = '/staff-map';
  static const String staffProfile = '/staff-profile';

  // Admin route names
  static const String adminDashboard = '/admin-dashboard';
  static const String userManagement = '/user-management';
  static const String systemSettings = '/system-settings';
  static const String reports = '/reports';
  static const String staffManagement = '/staff-management';
  static const String mergeDuplicates = '/merge-duplicates';
  static const String departmentDashboard = '/department-dashboard';
  static const String complaintRouting = '/complaint-routing';
  static const String resolutionDetection = '/resolution-detection';
  static const String zoneManagement = '/zone-management';
  static const String escalationWorkflow = '/escalation-workflow';
  static const String privatizationManagement = '/privatization-management';
  static const String detectDuplicates = '/detect-duplicates';
  static const String duplicateNotifications = '/duplicate-notifications';
  static const String adminComplaints = '/admin-complaints';
  static const String complaintApproval = '/complaint-approval';

  // Contractor route names
  static const String contractorLogin = '/contractor-login';
  static const String contractorDashboard = '/contractor-dashboard';
  static const String contractorZoneDetails = '/contractor-zone-details';
  static const String contractorTasks = '/contractor-tasks';
  static const String contractorPhotos = '/contractor-photos';
  static const String contractorReports = '/contractor-reports';
  static const String contractorProfile = '/contractor-profile';

  // New routes
  static const String departmentManagement = '/department-management';
  static const String taskDetail = '/task-detail';
  static const String resolutionUpload = '/resolution-upload';
  static const String contractorZoneDetail = '/contractor-zone-detail';

  // Add these with your other admin route names (around line 70-80)
  static const String compareDuplicates = '/compare-duplicates';

  static Map<String, WidgetBuilder> get allRoutes {
    return {
      // Citizen routes
      splash: (context) => const SplashScreen(),
      onboarding: (context) => const OnboardingScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      termsAndConditions: (context) => const TermsAndConditionsScreen(),
      home: (context) => const HomeScreen(),
      reportIssue: (context) => const ReportIssueScreen(),
      issueDetails: (context) => const IssueDetailsScreen(),
      myComplaints: (context) => const MyComplaintsScreen(),
      complaintDetail: (context) => const ComplaintDetailScreen(),
      communityMap: (context) => const CommunityMapScreen(),
      profile: (context) => const ProfileScreen(),
      leaderboard: (context) => const LeaderboardScreen(),
      publicComplaints: (context) => const PublicComplaintsScreen(),
      approvalStatus: (context) => const ApprovalStatusScreen(),
      notifications: (context) => const NotificationsScreen(),
      personalInformation: (context) => const PersonalInformationScreen(),
      addressAndZones: (context) => const AddressAndZonesScreen(),
      notificationSettings: (context) => const NotificationsSettingsScreen(),
      privacyAndSecurity: (context) => const PrivacyAndSecurityScreen(),
      helpAndSupport: (context) => const HelpAndSupportScreen(),
      about: (context) => const AboutScreen(),
      complaintStatusHistory: (context) => const ComplaintStatusHistoryScreen(),

      // Staff routes
      staffRoleSelection: (context) => const StaffRoleSelectionScreen(),
      adminLogin: (context) => const AdminLoginScreen(),
      departmentLogin: (context) => const DepartmentLoginScreen(),
      fieldStaffLogin: (context) => const FieldStaffLoginScreen(),
      staffDashboard: (context) => const StaffDashboardScreen(),
      staffComplaintView: (context) => const StaffComplaintViewScreen(),
      myTasks: (context) => const MyTasksScreen(),
      staffMap: (context) => const StaffMapScreen(),
      staffProfile: (context) => const StaffProfileScreen(),
      // Add in Staff routes section
      taskDetail: (context) => const TaskDetailScreen(),
      resolutionUpload: (context) => const ResolutionUploadScreen(),

      // Admin routes
      adminDashboard: (context) => const AdminDashboardScreen(),
      userManagement: (context) => const UserManagementScreen(),
      systemSettings: (context) => const SystemSettingsScreen(),
      reports: (context) => const ReportsScreen(),
      staffManagement: (context) => const StaffManagementScreen(),
      mergeDuplicates: (context) => const MergeDuplicatesScreen(),
      departmentDashboard: (context) => const DepartmentDashboardScreen(),
      complaintRouting: (context) => const ComplaintRoutingScreen(),
      resolutionDetection: (context) => const ResolutionDetectionScreen(),
      zoneManagement: (context) => const ZoneManagementScreen(),
      escalationWorkflow: (context) => const EscalationWorkflowScreen(),
      privatizationManagement: (context) => const PrivatizationManagementScreen(),
      detectDuplicates: (context) => const DetectDuplicatesScreen(),
      duplicateNotifications: (context) => const DuplicateNotificationsScreen(),
      adminComplaints: (context) => const AdminComplaintsScreen(),
      complaintApproval: (context) => const ComplaintApprovalScreen(),
      departmentManagement: (context) => const DepartmentManagementScreen(),
      // Add this line in the admin routes section of allRoutes
      compareDuplicates: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
        return CompareDuplicatesScreen(
          complaintId1: args['complaintId1']!,
          complaintId2: args['complaintId2']!,
        );
      },

      // Contractor routes
      contractorLogin: (context) => const ContractorLoginScreen(),
      contractorDashboard: (context) => const ContractorDashboardScreen(),
      contractorZoneDetails: (context) => const ZoneDetailsScreen(),
      contractorTasks: (context) => const ContractorTasksScreen(),
      contractorPhotos: (context) => const ContractorPhotosScreen(),
      contractorReports: (context) => const ContractorReportsScreen(),
      contractorProfile: (context) => const ContractorProfileScreen(),
      contractorZoneDetail: (context) => const ContractorZoneDetailScreen(),
    };
  }
}

// Helper function to navigate to TaskDetailScreen with arguments
Future<T?> navigateToTaskDetail<T>(BuildContext context, Map<String, dynamic> arguments) {
  return Navigator.pushNamed(
    context,
    Routes.taskDetail,
    arguments: arguments,
  );
}

// Helper function to navigate to ResolutionUploadScreen with arguments
Future<T?> navigateToResolutionUpload<T>(
    BuildContext context, {
      required String assignmentId,
      required String staffId,
      required String complaintTitle,
    }) {
  return Navigator.pushNamed(
    context,
    Routes.resolutionUpload,
    arguments: {
      'assignmentId': assignmentId,
      'staffId': staffId,
      'complaintTitle': complaintTitle,
    },
  );
}