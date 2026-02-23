class ApiEndpoints {
  // Base URL for the new FastAPI backend
  // In development, this might be 'http://localhost:8000' or similar
  static const String serverUrl = 'https://bw-backend.example.com';

  // Chat Endpoints
  static const String sendMessage = "$serverUrl/chat/sendWhatsAppMessage";
  static const String uploadMediaForChat = "$serverUrl/chat/uploadMedia";
  static const String updateMessageStatus =
      '$serverUrl/chat/updateMessageStatus';
  static const String getDailyStats = '$serverUrl/chat/getDailyStats';

  // Profile Endpoints
  static const String updateProfile =
      "$serverUrl/profile/updateWhatsAppBusinessProfile";
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
  static const String deleteScheduledBroadcast =
      "$serverUrl/broadcasts/deleteScheduledBroadcast";

  // Milestones
  static const String getApprovedMediaTemplates =
      "$serverUrl/milestones/getApprovedMediaTemplates";
  static const String createMilestone = "$serverUrl/milestones/createMilestone";
  static const String updateMilestone = "$serverUrl/milestones/updateMilestone";
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
