class ApiEndpoints {
  // Base URL for the new FastAPI backend
  // In development, this might be 'http://localhost:8000' or similar
  static const String serverUrl = 'https://bw.serwex.in';

  // Chat Endpoints
  static const String login = "$serverUrl/auth/login";
  static const String getClientDetails = "$serverUrl/clients/getClientDetails";
  static const String getCharges = "$serverUrl/clients/getCharges";
  static const String sendMessage = "$serverUrl/sendWhatsAppMessage";
  static const String uploadMediaForChat =
      "$serverUrl/uploadMediaForChat"; // Corrected name
  static const String updateMessageStatus = '$serverUrl/updateMessageStatus';
  static const String getDailyStats = '$serverUrl/getDailyStats';
  static const String getChats = '$serverUrl/getChats';
  static const String getMessages = '$serverUrl/getMessages';
  static const String updateChat = '$serverUrl/updateChat';
  static const String patchChat = '$serverUrl/patchChat';
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
  static const String createChat = '$serverUrl/createChat';
  static const String deleteChat = '$serverUrl/deleteChat';

  // Profile Endpoints
  static const String updateProfile =
      "$serverUrl/updateWhatsAppBusinessProfile";
  static const String patchProfile = "$serverUrl/patchWhatsAppBusinessProfile";
  static const String getProfile = "$serverUrl/getWhatsAppBusinessProfile";

  // Analytics Endpoints
  static const String getAnalytics =
      "$serverUrl/analytics/getConversationAnalytics";

  // Template Endpoints
  static const String createTemplate = "$serverUrl/createInteraktTemplate";
  static const String getTemplates = "$serverUrl/getInteraktTemplates";
  static const String deleteTemplate = "$serverUrl/deleteInteraktTemplate";
  static const String getApprovedTemplates = "$serverUrl/getApprovedTemplates";

  // Broadcast & Media Endpoints
  static const String uploadMediaToInterakt =
      "$serverUrl/uploadMediaToInterakt";
  static const String uploadBroadcastMedia = "$serverUrl/uploadMedia";
  static const String sendTemplateMessage = "$serverUrl/sendTemplateMessage";
  static const String queueBroadcast = "$serverUrl/queueBroadcast";
  static const String patchBroadcast = "$serverUrl/patchBroadcast";
  static const String deleteScheduledBroadcast =
      "$serverUrl/deleteScheduledBroadcast";

  // Milestones
  static const String getApprovedMediaTemplates =
      "$serverUrl/getApprovedMediaTemplates";
  static const String createMilestone = "$serverUrl/createMilestone";
  static const String updateMilestone = "$serverUrl/updateMilestone";
  static const String patchMilestoneScheduler =
      "$serverUrl/patchMilestoneScheduler";
  static const String pauseMilestone = "$serverUrl/pauseMilestone";
  static const String resumeMilestone = "$serverUrl/resumeMilestone";
  static const String deleteMilestone = "$serverUrl/deleteMilestone";

  // Integrations
  static const String generateZohoToken =
      '$serverUrl/generateZohoAccessAndRefreshToken';
  static const String exportToZoho = '$serverUrl/exportToZoho';

  // Chatbot Endpoints
  static const String createChatbotStore = "$serverUrl/chatbot/create";
  static const String uploadChatbotDoc = "$serverUrl/chatbot/upload";
  static const String updateChatbotDoc = "$serverUrl/chatbot/update";
  static const String deleteChatbotDoc = "$serverUrl/chatbot/delete";
  static const String listChatbotDocs = "$serverUrl/chatbot/list";
  static const String updateChatbotQuestion = "$serverUrl/chatbot/questions/update";
  static const String deleteChatbotQuestion = "$serverUrl/chatbot/questions/delete";

  // Other
  static const String getPhoneNumber = '$serverUrl/getPhoneNumber';

  // Typesense Endpoints
  static const String typesenseBaseUrl = 'https://typesense.anjitait.com';
  static const String typesenseApiKey = 'AIS.Typesense@2026';
  static String searchContacts(String collectionName) =>
      '$typesenseBaseUrl/collections/$collectionName/documents/search';
}
