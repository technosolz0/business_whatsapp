class ApiEndpoints {
  // Base URL for the new FastAPI backend
  // In development, this might be 'http://localhost:8000' or similar
  static const String serverUrl = 'https://bw.serwex.in';

  // Chat Endpoints
  static const String login = "$serverUrl/auth/login";
  static const String getClientDetails = "$serverUrl/clients/getClientDetails";
  static const String getCharges = "$serverUrl/clients/getCharges";
  static const String sendMessage = "$serverUrl/chat/sendWhatsAppMessage";
  static const String uploadMediaForChat =
      "$serverUrl/chat/uploadMediaForChat"; // Corrected name
  static const String updateMessageStatus =
      '$serverUrl/chat/updateMessageStatus';
  static const String getDailyStats = '$serverUrl/chat/getDailyStats';
  static const String getChats = '$serverUrl/chat/getChats';
  static const String getMessages = '$serverUrl/chat/getMessages';
  static const String updateChat = '$serverUrl/chat/updateChat';
  static const String patchChat = '$serverUrl/chat/patchChat';
  static const String getAdmins = '$serverUrl/admins/getAdmins';
  static const String getAdminById = '$serverUrl/admins/getAdminById';
  static const String addAdmin = '$serverUrl/admins/addAdmin';
  static const String updateAdmin = '$serverUrl/admins/updateAdmin';
  static const String patchAdmin = '$serverUrl/admins/patchAdmin';
  static const String deleteAdmin = '$serverUrl/admins/deleteAdmin';
  static const String getRoles = '$serverUrl/roles/getRoles';
  static const String addRole = '$serverUrl/roles/addRole';
  static const String updateRole = '$serverUrl/roles/updateRole';
  static const String patchRole = '$serverUrl/roles/patchRole';
  static const String deleteRole = '$serverUrl/roles/deleteRole';
  static const String getAllClients = '$serverUrl/clients/get_all_clients';
  static const String addClient = '$serverUrl/clients/addClient';
  static const String updateClient = '$serverUrl/clients/updateClient';
  static const String patchClient = '$serverUrl/clients/patchClient';
  static const String deleteClient = '$serverUrl/clients/deleteClient';
  static const String createChat = '$serverUrl/chat/createChat';
  static const String deleteChat = '$serverUrl/chat/deleteChat';

  // WebSocket URL
  static String wsUrl(String clientId) =>
      "wss://bw.serwex.in/chat/ws/$clientId"; // Using wss for production

  // Profile Endpoints
  static const String updateProfile =
      "$serverUrl/profile/updateWhatsAppBusinessProfile";
  static const String patchProfile =
      "$serverUrl/profile/patchWhatsAppBusinessProfile";
  static const String getProfile =
      "$serverUrl/profile/getWhatsAppBusinessProfile";

  // Analytics Endpoints
  static const String getAnalytics =
      "$serverUrl/analytics/getConversationAnalytics";

  // Template Endpoints
  static const String createTemplate =
      "$serverUrl/templates/createInteraktTemplate";
  static const String getTemplates =
      "$serverUrl/templates/getInteraktTemplates";
  static const String deleteTemplate =
      "$serverUrl/templates/deleteInteraktTemplate";
  static const String getApprovedTemplates =
      "$serverUrl/templates/getApprovedTemplates";

  // Broadcast & Media Endpoints
  static const String uploadMediaToInterakt =
      "$serverUrl/templates/uploadMediaToInterakt";
  static const String uploadBroadcastMedia = "$serverUrl/chat/uploadMedia";
  static const String sendTemplateMessage =
      "$serverUrl/broadcasts/sendTemplateMessage";
  static const String queueBroadcast = "$serverUrl/broadcasts/queueBroadcast";
  static const String patchBroadcast = "$serverUrl/broadcasts/patchBroadcast";
  static const String deleteScheduledBroadcast =
      "$serverUrl/broadcasts/deleteScheduledBroadcast";

  // Milestones
  static const String getApprovedMediaTemplates =
      "$serverUrl/milestones/getApprovedMediaTemplates";
  static const String createMilestone = "$serverUrl/milestones/createMilestone";
  static const String updateMilestone = "$serverUrl/milestones/updateMilestone";
  static const String patchMilestoneScheduler =
      "$serverUrl/scheduler/patchMilestoneScheduler";
  static const String pauseMilestone = "$serverUrl/milestones/pauseMilestone";
  static const String resumeMilestone = "$serverUrl/milestones/resumeMilestone";
  static const String deleteMilestone = "$serverUrl/milestones/deleteMilestone";

  // Integrations
  static const String generateZohoToken =
      '$serverUrl/integrations/generateZohoAccessAndRefreshToken';
  static const String exportToZoho = '$serverUrl/integrations/exportToZoho';

  // Other
  static const String getPhoneNumber = '$serverUrl/getPhoneNumber';

  // Typesense Endpoints
  static const String typesenseBaseUrl = 'https://typesense.anjitait.com';
  static const String typesenseApiKey = 'AIS.Typesense@2026';
  static String searchContacts(String collectionName) =>
      '$typesenseBaseUrl/collections/$collectionName/documents/search';
}
