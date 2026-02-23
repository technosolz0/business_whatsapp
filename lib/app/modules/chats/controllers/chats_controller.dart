import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:business_whatsapp/app/Utilities/responsive.dart';
import 'package:business_whatsapp/app/modules/chats/widgets/chat_admin_assignment_popup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/app/Utilities/network_utilities.dart';
import 'package:dio/dio.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../Utilities/utilities.dart';
import '../../../common widgets/common_snackbar.dart';
import '../../../../main.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../../../../app/Utilities/subscription_guard.dart';
import '../../../data/models/admins_model.dart';

class ChatsController extends GetxController {
  ScrollController scrollController = ScrollController();
  final chats = <ChatModel>[].obs;
  final selectedChat = Rxn<ChatModel>();
  final messages = <MessageModel>[].obs;
  final isTyping = false.obs;
  final searchQuery = ''.obs;
  final activeFilter = 'all'.obs;
  final isSendingMessage = false.obs;
  final uploadProgress = 0.0.obs;
  final RxBool showConversation = false.obs;
  StreamSubscription? messagesSub;
  StreamSubscription? newMessagesSub; // For real-time new messages only
  StreamSubscription? chatsSub;

  // Chat List Lazy Loading
  ScrollController chatListScrollController = ScrollController();
  final chatLimit = 100.obs;
  final isLoadingMoreChats = false.obs;
  final hasMoreChats = true.obs;

  // Lazy loading variables
  final int pageSize = 10; // Load 15 messages at a time
  final isLoadingMore = false.obs;
  final hasMoreMessages = true.obs;
  DocumentSnapshot? lastMessageDoc; // For pagination
  String? currentChatId; // Track current chat for pagination

  // Track if this is the first time loading messages for a chat
  bool _isFirstMessageLoad = true;

  bool get canSendMessage {
    if (!SubscriptionGuard.canEdit()) return false;

    final chat = selectedChat.value;
    if (chat == null) return false;

    // if (chat.userLastMessageTime != null) {
    //   final difference = DateTime.now().difference(chat.userLastMessageTime!);
    //   if (difference.inHours >= 24) {
    //     return false;
    //   }
    // }
    return true;
  }

  List<String> assignedContactIds = [];

  @override
  void onInit() {
    super.onInit();
    chatListScrollController.addListener(_chatListScrollListener);

    _initChatAccess();
  }

  Future<void> _initChatAccess() async {
    if (!isAllChats.value) {
      await _fetchAssignedContacts();
    }
    listenToChats();
  }

  Future<void> _fetchAssignedContacts() async {
    if (adminID.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(clientID)
          .collection('data')
          .where('assigned_admin', arrayContains: adminID)
          .get();
      if (doc.docs.isNotEmpty) {
        assignedContactIds = doc.docs.map((doc) => doc.id).toList();
      }
    } catch (e) {
      debugPrint('Error fetching assigned contacts: $e');
    }
  }

  @override
  void onClose() {
    messagesSub?.cancel();
    newMessagesSub?.cancel();
    chatsSub?.cancel();
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    chatListScrollController.removeListener(_chatListScrollListener);
    chatListScrollController.dispose();
    super.onClose();
  }

  void listenToChats() {
    chatsSub?.cancel();

    // If regular user has no assigned contacts, show empty list
    if (!isAllChats.value && assignedContactIds.isEmpty) {
      chats.clear();
      hasMoreChats.value = false;
      if (isLoadingMoreChats.value) {
        isLoadingMoreChats.value = false;
      }
      return;
    }

    Query query = FirebaseFirestore.instance
        .collection('chats')
        .doc(clientID)
        .collection('data');

    // Apply assigned contacts filter
    if (!isAllChats.value && assignedContactIds.isNotEmpty) {
      query = query.where(FieldPath.documentId, whereIn: assignedContactIds);
    }

    if (activeFilter.value == 'unRead') {
      query = query.where('unRead', isEqualTo: true);
    } else if (activeFilter.value == 'isFavourite') {
      query = query.where('isFavourite', isEqualTo: true);
    }

    // If filter is active, fetch all (or a very large number) to avoid pagination issues
    if (activeFilter.value == 'all') {
      query = query.limit(chatLimit.value);
    }

    chatsSub = query
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            chats.value = snapshot.docs.map((doc) {
              return ChatModel.fromFirestore(doc);
            }).toList();

            // Check if we have loaded all available chats (only relevant for 'all' filter with limit)
            if (activeFilter.value == 'all') {
              if (snapshot.docs.length < chatLimit.value) {
                hasMoreChats.value = false;
              } else {
                hasMoreChats.value = true;
              }
            } else {
              // When filtering, we essentially fetch all, so no "more" chats to load via pagination
              hasMoreChats.value = false;
            }

            // If we received data, stop loading state
            if (isLoadingMoreChats.value) {
              isLoadingMoreChats.value = false;
            }
          },
          onError: (error) {
            // debugPrint('Error loading chats: $error');
            if (isLoadingMoreChats.value) {
              isLoadingMoreChats.value = false;
            }
          },
        );
  }

  void _chatListScrollListener() {
    if (chatListScrollController.hasClients) {
      for (final position in chatListScrollController.positions) {
        if (position.hasContentDimensions &&
            position.pixels >= position.maxScrollExtent - 200 &&
            !isLoadingMoreChats.value &&
            hasMoreChats.value) {
          loadMoreChats();
          break;
        }
      }
    }
  }

  void loadMoreChats() {
    // If already loading or no more chats, don't trigger
    if (isLoadingMoreChats.value || !hasMoreChats.value) return;

    isLoadingMoreChats.value = true;
    chatLimit.value += 10; // Load next 10
    listenToChats();
  }

  // void resetScrollController() {
  //   // Don't dispose here, let the framework handle it
  //   // scrollController = ScrollController();
  // }

  void selectChat(ChatModel chat) async {
    // Set previous chat isActive to false
    if (selectedChat.value != null) {
      await updateChatActiveStatus(selectedChat.value!.id, false);
    }

    selectedChat.value = chat;

    // Set current chat as active and unread to false
    await updateChatActiveStatus(chat.id, true);
    await updateChatUnreadStatus(chat.id, false);

    _isFirstMessageLoad = true; // Reset flag when selecting new chat

    // Reset pagination state for new chat
    currentChatId = chat.id;
    lastMessageDoc = null;
    hasMoreMessages.value = true;
    isLoadingMore.value = false;

    // Set up scroll listener for lazy loading
    scrollController.removeListener(_scrollListener);
    scrollController.addListener(_scrollListener);

    loadInitialMessages(chat.id);

    // DEVICE CHECK
    bool isMobile = Responsive.isMobile(Get.context!);

    if (isMobile) {
      // Navigate to conversation page
      showConversation.value = true;
    }
  }

  // Lazy Loading Implementation
  Future<void> loadInitialMessages(String chatId) async {
    // Cancel any existing subscriptions
    messagesSub?.cancel();
    newMessagesSub?.cancel();

    messages.clear();
    isLoadingMore.value = true;

    try {
      // Load initial batch of messages (most recent)
      final querySnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(clientID)
          .collection('data')
          .doc(chatId)
          .collection('messages')
          .orderBy(
            'timestamp',
            descending: true,
          ) // Most recent first for pagination
          .limit(pageSize)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Keep in Newest -> Oldest order for reversed ListView
        final loadedMessages = querySnapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList();

        messages.addAll(loadedMessages);
        lastMessageDoc =
            querySnapshot.docs.last; // Oldest message for next pagination

        // Check if there are more messages
        hasMoreMessages.value = querySnapshot.docs.length == pageSize;

        // Reset scroll position for new chat (bottom)
        if (_isFirstMessageLoad) {
          _isFirstMessageLoad = false;
          // With reversed list, 0 is bottom. No explicit scroll needed usually but ensuring it:
          // scrollToBottom(); // Wait, scrollToBottom is now scrollToTop/0.0
        }
      } else {
        hasMoreMessages.value = false;
      }

      // Set up real-time listener for new messages and updates to recently loaded messages
      DateTime? oldestLoadedMessageTime;
      if (querySnapshot.docs.isNotEmpty) {
        final lastDoc = querySnapshot.docs.last;
        try {
          final timestamp = lastDoc.get('timestamp');
          if (timestamp is Timestamp) {
            oldestLoadedMessageTime = timestamp.toDate();
          }
        } catch (e) {
          // debugPrint('Error getting timestamp from last doc: $e');
        }
      }

      _setupNewMessagesListener(
        chatId,
        startTimestamp: oldestLoadedMessageTime,
      );
    } catch (e) {
      // debugPrint('Error loading initial messages: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMoreMessages() async {
    if (!hasMoreMessages.value ||
        isLoadingMore.value ||
        currentChatId == null ||
        lastMessageDoc == null) {
      // debugPrint(
      //   '❌ Cannot load more: hasMore=${hasMoreMessages.value}, loading=${isLoadingMore.value}, chatId=$currentChatId, lastDoc=${lastMessageDoc != null}',
      // );
      return;
    }

    isLoadingMore.value = true;
    // debugPrint(
    //   '🔄 Starting to load more messages... Current count: ${messages.length}',
    // );

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(clientID)
          .collection('data')
          .doc(currentChatId!)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .startAfterDocument(lastMessageDoc!)
          .limit(pageSize)
          .get();

      // debugPrint('📊 Query returned ${querySnapshot.docs.length} documents');

      if (querySnapshot.docs.isNotEmpty) {
        // Convert for chronological order
        final olderMessages = querySnapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList();

        // debugPrint(
        //   '📝 Appending ${olderMessages.length} older messages to the end',
        // );

        // Append older messages to the end (Newest -> Oldest list)
        messages.addAll(olderMessages);
        lastMessageDoc = querySnapshot.docs.last;

        // Check if there are more messages
        hasMoreMessages.value = querySnapshot.docs.length == pageSize;

        // debugPrint(
        //   '✅ Successfully loaded ${olderMessages.length} messages. Total: ${messages.length}. Has more: ${hasMoreMessages.value}',
        // );
      } else {
        hasMoreMessages.value = false;
        // debugPrint('ℹ️ No more messages to load');
      }
    } catch (e) {
      // debugPrint('❌ Error loading more messages: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _setupNewMessagesListener(String chatId, {DateTime? startTimestamp}) {
    // Listen for messages from the provided startTimestamp
    // If startTimestamp is null, fall back to the most recent message or now
    final subscriptionStartTimestamp =
        startTimestamp ??
        (messages.isNotEmpty ? messages.last.timestamp : DateTime.now());

    newMessagesSub = FirebaseFirestore.instance
        .collection('chats')
        .doc(clientID)
        .collection('data')
        .doc(chatId)
        .collection('messages')
        .where('timestamp', isGreaterThanOrEqualTo: subscriptionStartTimestamp)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
          for (final docChange in snapshot.docChanges) {
            final messageData = MessageModel.fromFirestore(docChange.doc);

            if (docChange.type == DocumentChangeType.added) {
              // Check if message already exists to verify duplication from the query overlap
              final index = messages.indexWhere((m) => m.id == messageData.id);
              if (index == -1) {
                // Insert new message at the beginning (Bottom of view)
                messages.insert(0, messageData);

                // Mark as unread if not from me and chat is not active
                if (!messageData.isFromMe &&
                    (selectedChat.value?.id != chatId ||
                        selectedChat.value?.isActive == false)) {
                  updateChatUnreadStatus(chatId, true);
                }

                // Auto-scroll to bottom (0) if we are near bottom
                scrollToBottom();
              }
            } else if (docChange.type == DocumentChangeType.modified) {
              // Handle status updates (sent -> delivered -> read)
              final index = messages.indexWhere((m) => m.id == messageData.id);
              if (index != -1) {
                messages[index] = messageData;
                messages.refresh(); // Trigger GetX update
              }
            }
          }
        });
  }

  void _scrollListener() {
    bool shouldLoad = false;
    if (scrollController.hasClients) {
      for (final position in scrollController.positions) {
        // reversed: true, so maxScrollExtent is the visual TOP (history)
        if (position.hasContentDimensions &&
            position.pixels >= position.maxScrollExtent - 200) {
          shouldLoad = true;
          break;
        }
      }
    }

    if (shouldLoad && hasMoreMessages.value && !isLoadingMore.value) {
      // debugPrint('🚀 Triggering lazy load - Loading more messages...');
      loadMoreMessages();
    }
  }

  // Keep the old method for backward compatibility (can be removed later)
  void loadMessages(String chatId) {
    loadInitialMessages(chatId);
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        for (final position in scrollController.positions) {
          if (position.hasContentDimensions) {
            // reversed: true -> 0.0 is Bottom
            position.animateTo(
              0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      }
    });
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || selectedChat.value == null || !canSendMessage)
      return;

    final chat = selectedChat.value!;
    isSendingMessage.value = true;
    // debugPrint('Sending message to ${chat.phoneNumber}');

    // Create a new document reference to get the ID beforehand
    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(clientID)
        .collection('data')
        .doc(chat.id)
        .collection('messages')
        .doc();

    final String messageId = messageRef.id;

    try {
      // Optimistically save message to Firestore
      await messageRef.set({
        'content': content.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isFromMe': true,
        'senderName': adminName.value.isNotEmpty ? adminName.value : 'Admin',
        'senderAvatar': null,
        'status': "invocationSucceeded",
        'whatsappMessageId': null,
        'messageType': 'text',
        'mediaUrl': null,
        'fileName': null,
        'caption': null,
      });

      // Update last message in chat document
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(clientID)
          .collection('data')
          .doc(chat.id)
          .update({
            'lastMessage': content.trim(),
            'lastMessageTime': FieldValue.serverTimestamp(),
          });

      final dio = NetworkUtilities.getDioClient();
      final response = await dio.post(
        ApiEndpoints.sendMessage,
        data: {
          'clientId': clientID,
          'phoneNumber': chat.phoneNumber,
          'message': content.trim(),
          'chatId': chat.id,
          'messageId': messageId,
          'messageType': 'text',
          'adminName': adminName.value.isNotEmpty ? adminName.value : 'Admin',
        },
      );

      final data = response.data;

      if (response.statusCode == 200 && data['success'] == true) {
        // Utilities.showSnackbar(SnackType.SUCCESS, 'Message sent successfully');
      } else {
        throw Exception(data['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Failed to send message: ${e.toString()}',
      );
    } finally {
      isSendingMessage.value = false;
    }
  }

  Future<void> pickAndSendImage() async {
    if (selectedChat.value == null || !canSendMessage) {
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true, // Allow multiple files
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      // Show preview with all selected files
      showImagePreview(result.files);
    } catch (e) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Failed to pick image: ${e.toString()}',
      );
    }
  }

  Future<void> pickAndSendDocument() async {
    if (selectedChat.value == null || !canSendMessage) {
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
        allowMultiple: true, // Allow multiple files
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      // Show preview with all selected files
      showDocumentPreview(result.files);
    } catch (e) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Failed to pick document: ${e.toString()}',
      );
    }
  }

  // WhatsApp-style Full-screen Image Preview with Multiple Files
  void showImagePreview(List<PlatformFile> files) {
    final currentIndex = 0.obs;
    final selectedFiles = files.obs;

    Get.dialog(
      // ignore: deprecated_member_use
      WillPopScope(
        onWillPop: () async => false,
        child: Material(
          color: Colors.black,
          child: Obx(
            () => Stack(
              children: [
                // Image preview (full screen with zoom)
                Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: Get.width * 0.9,
                      maxHeight: Get.height * 0.9,
                    ),
                    child: selectedFiles[currentIndex.value].bytes != null
                        ? InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.memory(
                              selectedFiles[currentIndex.value].bytes!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 64,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Failed to load image',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Text(
                              'No image data',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                  ),
                ),

                // Top bar with close button and file info
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            Get.back();
                          },
                          tooltip: 'Close',
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedFiles[currentIndex.value].name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (selectedFiles.length > 1)
                                Text(
                                  '${currentIndex.value + 1} of ${selectedFiles.length}',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Add more files button
                        IconButton(
                          icon: Icon(
                            Icons.add_photo_alternate,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform
                                .pickFiles(
                                  type: FileType.image,
                                  allowMultiple: true,
                                );

                            if (result != null && result.files.isNotEmpty) {
                              selectedFiles.addAll(result.files);
                              Utilities.showSnackbar(
                                SnackType.SUCCESS,
                                '${result.files.length} file(s) added',
                              );
                            }
                          },
                          tooltip: 'Add more files',
                        ),
                      ],
                    ),
                  ),
                ),

                // Navigation arrows (if multiple files)
                if (selectedFiles.length > 1) ...[
                  // Left arrow
                  if (currentIndex.value > 0)
                    Positioned(
                      left: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () => currentIndex.value--,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Right arrow
                  if (currentIndex.value < selectedFiles.length - 1)
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () => currentIndex.value++,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],

                // Bottom bar with thumbnails and send button
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Thumbnails (if multiple files)
                        if (selectedFiles.length > 1)
                          Container(
                            height: 80,
                            margin: EdgeInsets.only(bottom: 16),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedFiles.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () => currentIndex.value = index,
                                  child: Container(
                                    width: 80,
                                    margin: EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: currentIndex.value == index
                                            ? Colors.white
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child:
                                              selectedFiles[index].bytes != null
                                              ? Image.memory(
                                                  selectedFiles[index].bytes!,
                                                  fit: BoxFit.cover,
                                                )
                                              : Icon(
                                                  Icons.image,
                                                  color: Colors.white54,
                                                ),
                                        ),
                                        // Remove button
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () {
                                              if (selectedFiles.length > 1) {
                                                selectedFiles.removeAt(index);
                                                if (currentIndex.value >=
                                                    selectedFiles.length) {
                                                  currentIndex.value =
                                                      selectedFiles.length - 1;
                                                }
                                              }
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        // Send button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 300,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  Get.back();

                                  // Send all files
                                  for (var file in selectedFiles) {
                                    if (file.bytes != null) {
                                      await _sendMediaMessage(
                                        bytes: file.bytes!,
                                        messageType: MessageType.image,
                                        fileName: file.name,
                                      );
                                    }
                                  }
                                },
                                icon: Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                label: Text(
                                  'Send ${selectedFiles.length} Image${selectedFiles.length > 1 ? "s" : ""}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF25D366),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // WhatsApp-style Document Preview with Multiple Files
  void showDocumentPreview(List<PlatformFile> files) {
    final currentIndex = 0.obs;
    final selectedFiles = files.obs;

    Get.dialog(
      Material(
        color: Colors.black,
        child: Obx(
          () => Stack(
            children: [
              // Document preview area
              Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 500),
                  margin: EdgeInsets.symmetric(horizontal: 32),
                  padding: EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getDocumentIconFromName(
                          selectedFiles[currentIndex.value].name,
                        ),
                        size: 140,
                        color: Colors.white,
                      ),
                      SizedBox(height: 32),
                      Text(
                        selectedFiles[currentIndex.value].name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatFileSize(
                            selectedFiles[currentIndex.value].size,
                          ),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (selectedFiles.length > 1) ...[
                        SizedBox(height: 16),
                        Text(
                          '${currentIndex.value + 1} of ${selectedFiles.length}',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Get.back(),
                        tooltip: 'Close',
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Document Preview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.white, size: 28),
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform
                              .pickFiles(
                                type: FileType.custom,
                                allowedExtensions: [
                                  'pdf',
                                  'doc',
                                  'docx',
                                  'xls',
                                  'xlsx',
                                  'txt',
                                ],
                                allowMultiple: true,
                              );

                          if (result != null && result.files.isNotEmpty) {
                            selectedFiles.addAll(result.files);
                            Utilities.showSnackbar(
                              SnackType.SUCCESS,
                              '${result.files.length} file${result.files.length > 1 ? "s" : ""} added',
                            );
                          }
                        },
                        tooltip: 'Add more files',
                      ),
                    ],
                  ),
                ),
              ),

              // Navigation arrows
              if (selectedFiles.length > 1) ...[
                if (currentIndex.value > 0)
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () => currentIndex.value--,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                if (currentIndex.value < selectedFiles.length - 1)
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () => currentIndex.value++,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
              ],

              // Bottom bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // File list
                      if (selectedFiles.length > 1)
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          constraints: BoxConstraints(maxHeight: 120),
                          child: ListView.builder(
                            itemCount: selectedFiles.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: currentIndex.value == index
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getDocumentIconFromName(
                                        selectedFiles[index].name,
                                      ),
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selectedFiles[index].name,
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            _formatFileSize(
                                              selectedFiles[index].size,
                                            ),
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.visibility,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () =>
                                          currentIndex.value = index,
                                    ),
                                    if (selectedFiles.length > 1)
                                      IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          selectedFiles.removeAt(index);
                                          if (currentIndex.value >=
                                              selectedFiles.length) {
                                            currentIndex.value =
                                                selectedFiles.length - 1;
                                          }
                                        },
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      // Send button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 300,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Get.back();

                                // Send all files
                                for (var file in selectedFiles) {
                                  if (file.bytes != null) {
                                    await _sendMediaMessage(
                                      bytes: file.bytes!,
                                      messageType: MessageType.document,
                                      fileName: file.name,
                                    );
                                  }
                                }
                              },
                              icon: Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                              label: Text(
                                'Send ${selectedFiles.length} Document${selectedFiles.length > 1 ? "s" : ""}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF25D366),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  IconData _getDocumentIconFromName(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _sendMediaMessage({
    required Uint8List bytes,
    required MessageType messageType,
    required String fileName,
    String? caption,
  }) async {
    final chat = selectedChat.value!;
    isSendingMessage.value = true;
    uploadProgress.value = 0.0;

    try {
      // Step 1: Upload to Firebase Storage
      uploadProgress.value = 0.2;
      final base64File = base64Encode(bytes);
      final mimeType = _getMimeType(fileName);

      final dio = NetworkUtilities.getDioClient();
      final uploadResponse = await dio.post(
        ApiEndpoints.uploadMediaForChat,
        data: {
          'clientId': clientID,
          'fileName': fileName,
          'mimeType': mimeType,
          'base64File': base64File,
        },
        options: Options(
          receiveTimeout: Duration(seconds: 60),
          sendTimeout: Duration(seconds: 60),
        ),
      );

      if (uploadResponse.statusCode != 200) {
        throw Exception(
          'Failed to upload media to storage: ${uploadResponse.data}',
        );
      }

      uploadProgress.value = 0.5;

      final uploadData = uploadResponse.data;
      final mediaUrl = uploadData['url'];

      if (mediaUrl == null) {
        throw Exception('No media ID returned from upload');
      }

      // Step 2: Send WhatsApp message with media ID
      uploadProgress.value = 0.7;

      String displayContent = '';
      if (messageType == MessageType.image) {
        displayContent = caption ?? '📷 Image';
      } else if (messageType == MessageType.document) {
        displayContent = caption ?? '📄 $fileName';
      }

      final response = await dio.post(
        ApiEndpoints.sendMessage,
        data: {
          'clientId': clientID,
          'phoneNumber': chat.phoneNumber,
          'chatId': chat.id,
          'messageType': messageType.name,
          'mediaUrl': mediaUrl,
          'fileName': fileName,
          'caption': caption,
          'message': displayContent,
          'adminName': adminName.value.isNotEmpty ? adminName.value : 'Admin',
        },
        options: Options(
          receiveTimeout: Duration(seconds: 30),
          sendTimeout: Duration(seconds: 30),
        ),
      );

      uploadProgress.value = 1.0;

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          Utilities.showSnackbar(SnackType.SUCCESS, 'Media sent successfully');
        } else {
          throw Exception(data['message'] ?? 'Failed to send media');
        }
      } else {
        throw Exception(
          'Server error: ${response.statusCode} - ${response.data}',
        );
      }
    } catch (e) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Failed to send media: ${e.toString()}',
      );
    } finally {
      isSendingMessage.value = false;
      uploadProgress.value = 0.0;
    }
  }

  Future<void> retryMessage(MessageModel message) async {
    if (message.status != MessageStatus.failed) return;

    if (message.messageType == MessageType.text) {
      await sendMessage(message.content);
    } else {
      Utilities.showSnackbar(SnackType.INFO, 'Please resend the media file');
    }
  }

  List<ChatModel> get filteredChats {
    if (searchQuery.value.isEmpty) {
      return chats;
    }
    return chats.where((chat) {
      return chat.name.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          ) ||
          chat.phoneNumber.contains(searchQuery.value);
    }).toList();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  Future<void> createChatFromContact(String contactId) async {
    try {
      final contactDoc = await FirebaseFirestore.instance
          .collection('contacts')
          .doc(clientID)
          .collection('data')
          .doc(contactId)
          .get();

      if (!contactDoc.exists) {
        Utilities.showSnackbar(SnackType.ERROR, 'Contact not found');
        return;
      }

      final contactData = contactDoc.data()!;
      final fullName =
          '${contactData['fName'] ?? ''} ${contactData['lName'] ?? ''}'.trim();
      final phoneNumber =
          '${contactData['countryCallingCode'] ?? contactData['countryCode'] ?? ''}${contactData['phoneNumber'] ?? ''}';

      final existingChat = chats.firstWhereOrNull(
        (chat) => chat.phoneNumber == phoneNumber,
      );

      if (existingChat != null) {
        selectChat(existingChat);
        Utilities.showSnackbar(SnackType.INFO, 'Chat already exists');
        return;
      }

      final chatRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(clientID)
          .collection('data')
          .doc(contactId);

      await chatRef.set({
        'name': fullName.isNotEmpty ? fullName : phoneNumber,
        'phoneNumber': phoneNumber,
        'avatarUrl': null,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'campaignName': null,
        'isOnline': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Utilities.showSnackbar(SnackType.SUCCESS, 'Chat created successfully');
    } catch (e) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Failed to create chat: ${e.toString()}',
      );
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(clientID)
          .collection('data')
          .doc(chatId)
          .collection('messages')
          .get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(clientID)
          .collection('data')
          .doc(chatId)
          .delete();

      if (selectedChat.value?.id == chatId) {
        selectedChat.value = null;
        messages.clear();
      }

      Utilities.showSnackbar(SnackType.SUCCESS, 'Chat deleted');
    } catch (e) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Failed to delete chat: ${e.toString()}',
      );
    }
  }

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    final mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'txt': 'text/plain',
    };

    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  void showMediaOptions() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Media',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.blue, size: 32),
              title: Text('Choose Image', style: TextStyle(fontSize: 16)),
              subtitle: Text('JPG, PNG, GIF'),
              onTap: () {
                Get.back();
                pickAndSendImage();
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.attach_file, color: Colors.orange, size: 32),
              title: Text('Choose Document', style: TextStyle(fontSize: 16)),
              subtitle: Text('PDF, DOC, XLS, TXT'),
              onTap: () {
                Get.back();
                pickAndSendDocument();
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  // Scroll to bottom immediately (for first load)
  // void scrollToBottomImmediately() {
  //   if (!scrollController.hasClients) return;

  //   // Use addPostFrameCallback to ensure layout is complete
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (scrollController.hasClients) {
  //       scrollController.jumpTo(scrollController.position.maxScrollExtent);
  //     }
  //   });
  // }

  void scrollToBottomImmediately() {
    // if (!scrollController.hasClients) {}

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        for (final position in scrollController.positions) {
          if (position.hasContentDimensions) {
            position.jumpTo(position.maxScrollExtent);
          }
        }

        // Second frame callback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            for (final position in scrollController.positions) {
              if (position.hasContentDimensions) {
                position.jumpTo(position.maxScrollExtent);
              }
            }
          }
        });
      }
    });
  }

  // Update chat active status
  Future<void> updateChatActiveStatus(String chatId, bool isActive) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(clientID)
          .collection('data')
          .doc(chatId)
          .update({'isActive': isActive});
    } catch (e) {
      // debugPrint('Error updating chat active status: $e');
    }
  }

  // Update chat unread status
  Future<void> updateChatUnreadStatus(String chatId, bool unRead) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(clientID)
          .collection('data')
          .doc(chatId)
          .update({'unRead': unRead});
    } catch (e) {
      // debugPrint('Error updating chat unread status: $e');
    }
  }

  // Get unread chats count
  int get unreadChatsCount {
    return chats.where((chat) => chat.unRead).length;
  }

  // Scroll to bottom with animation (for new messages after first load)

  // Group messages by date for WhatsApp-style date separators
  List<dynamic> get messagesWithDateSeparators {
    if (messages.isEmpty) return [];

    final groupedMessages = <dynamic>[];

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      groupedMessages.add(message);

      // Check if we need a separator after this message (visually above in reversed list)
      // logic: If next message (older) has different date, separator belongs to CURRENT message's date.
      bool needSeparator = false;

      if (i == messages.length - 1) {
        // Last item (Oldest). Always show separator above it.
        needSeparator = true;
      } else {
        final nextMessage = messages[i + 1]; // Older message
        final messageDate = DateTime(
          message.timestamp.year,
          message.timestamp.month,
          message.timestamp.day,
        );
        final nextMessageDate = DateTime(
          nextMessage.timestamp.year,
          nextMessage.timestamp.month,
          nextMessage.timestamp.day,
        );

        if (!messageDate.isAtSameMomentAs(nextMessageDate)) {
          needSeparator = true;
        }
      }

      if (needSeparator) {
        final separatorDate = DateTime(
          message.timestamp.year,
          message.timestamp.month,
          message.timestamp.day,
        );
        groupedMessages.add(DateSeparator(separatorDate));
      }
    }

    return groupedMessages;
  }

  Future<void> updateChatFavouriteStatus(
    String chatId,
    bool isFavourite,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(clientID)
          .collection('data')
          .doc(chatId)
          .update({'isFavourite': isFavourite});
    } catch (e) {
      // debugPrint('Error updating chat favourite status: $e');
    }
  }

  void updateFilter(String filter) {
    if (activeFilter.value == filter) return;

    activeFilter.value = filter;

    // Deselect chat when changing filters
    selectedChat.value = null;
    showConversation.value = false;

    // Only reset limit when returning to 'all'
    if (filter == 'all') {
      chatLimit.value = 100;
      hasMoreChats.value = true;
    }

    chats.clear();
    isLoadingMoreChats.value = true;
    listenToChats();
  }

  bool validateAdminSelection() {
    return true;
  }

  void assignContacts() {
    if (!validateAdminSelection()) return;

    Get.dialog(
      ChatAdminAssignmentPopup(controller: this),
      barrierDismissible: false,
    );
  }

  // Admin Assignment Logic Helpers
  RxString adminSearch = "".obs;
  RxList<AdminsModel> allAdmins = <AdminsModel>[].obs;
  RxList<AdminsModel> selectedChatAdmins = <AdminsModel>[].obs;
  RxList<String> availableTags = <String>[].obs;
  RxList<String> selectedTags = <String>[].obs;

  // Pagination for admins
  RxBool isLoadingAdmins = false.obs;
  RxBool hasMoreAdmins = true.obs;
  RxBool isLoadingMoreAdmins = false.obs;
  int currentAdminsPage = 1;
  static const int adminsPageSize = 50;
  DocumentSnapshot? _lastAdminDoc;

  void updateAdminSearch(String value) {
    adminSearch.value = value;
  }

  List<AdminsModel> get filteredAdmins {
    List<AdminsModel> list = allAdmins;
    if (adminSearch.value.isNotEmpty) {
      final query = adminSearch.value.toLowerCase();
      list = list.where((a) {
        final fName = a.firstName?.toLowerCase() ?? '';
        final lName = a.lastName?.toLowerCase() ?? '';
        final email = a.email?.toLowerCase() ?? '';
        return fName.contains(query) ||
            lName.contains(query) ||
            email.contains(query);
      }).toList();
    }
    return list;
  }

  void toggleAdminSelection(AdminsModel admin) {
    if (selectedChatAdmins.any((a) => a.id == admin.id)) {
      selectedChatAdmins.removeWhere((a) => a.id == admin.id);
    } else {
      selectedChatAdmins.add(admin);
    }
  }

  Future<void> loadAdminsForAssignment() async {
    isLoadingAdmins.value = true;
    allAdmins.clear();
    currentAdminsPage = 1;
    _lastAdminDoc = null;

    try {
      // Initialize selectedAdmins from current chat's assignedAdmin IDs
      final chat = selectedChat.value;
      if (chat != null && chat.assignedAdmin != null) {
        selectedChatAdmins.assignAll(
          chat.assignedAdmin!.map(
            (id) => AdminsModel(id, null, null, null, null, null, 1, null),
          ),
        );
      } else {
        selectedChatAdmins.clear();
      }

      await _fetchAdminsPage();
    } catch (e) {
      debugPrint('Failed to load admins: $e');
      Utilities.showSnackbar(SnackType.ERROR, "Failed to load admins: $e");
    } finally {
      isLoadingAdmins.value = false;
    }
  }

  Future<void> loadMoreAdmins() async {
    if (!hasMoreAdmins.value || isLoadingMoreAdmins.value) return;
    isLoadingMoreAdmins.value = true;
    try {
      await _fetchAdminsPage();
    } finally {
      isLoadingMoreAdmins.value = false;
    }
  }

  Future<void> _fetchAdminsPage() async {
    var query = FirebaseFirestore.instance
        .collection('admins')
        .where('client_id', isEqualTo: clientID)
        .where('isAllChats', isEqualTo: false);

    if (_lastAdminDoc != null) {
      query = query.startAfterDocument(_lastAdminDoc!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastAdminDoc = snapshot.docs.last;
      allAdmins.addAll(
        snapshot.docs.map((doc) => AdminsModel.fromFirestore(doc)).toList(),
      );
      if (snapshot.docs.length < adminsPageSize) {
        hasMoreAdmins.value = false;
      }
    } else {
      hasMoreAdmins.value = false;
    }
  }

  Future<void> updateChatAdmins() async {
    final chat = selectedChat.value;
    if (chat == null) return;

    try {
      Utilities.showOverlayLoadingDialog();

      final newAdminIds = selectedChatAdmins.map((e) => e.id!).toList();
      final oldAdminIds = chat.assignedAdmin ?? [];

      final batch = FirebaseFirestore.instance.batch();

      // 1. Update Chat document's assigned_admin array
      final chatRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(clientID)
          .collection('data')
          .doc(chat.id);
      batch.update(chatRef, {'assigned_admin': newAdminIds});

      // 2. Identify admins to add/remove this chat from
      final toAdd = newAdminIds
          .where((id) => !oldAdminIds.contains(id))
          .toList();
      final toRemove = oldAdminIds
          .where((id) => !newAdminIds.contains(id))
          .toList();

      // 3. Update each Admin's assigned_contacts array
      for (var adminId in toAdd) {
        final adminRef = FirebaseFirestore.instance
            .collection('admins')
            .doc(adminId);
        batch.update(adminRef, {
          'assigned_contacts': FieldValue.arrayUnion([chat.id]),
        });
      }

      for (var adminId in toRemove) {
        final adminRef = FirebaseFirestore.instance
            .collection('admins')
            .doc(adminId);
        batch.update(adminRef, {
          'assigned_contacts': FieldValue.arrayRemove([chat.id]),
        });
      }

      await batch.commit();

      // Update local chat object
      selectedChat.value = chat.copyWith(assignedAdmin: newAdminIds);

      Utilities.hideCustomLoader(Get.context!);
      Utilities.showSnackbar(
        SnackType.SUCCESS,
        "Admins assigned to chat successfully",
      );
    } catch (e) {
      Utilities.hideCustomLoader(Get.context!);
      Utilities.showSnackbar(SnackType.ERROR, "Failed to assign admins: $e");
    }
  }
}
