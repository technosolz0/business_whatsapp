import 'package:business_whatsapp/app/Utilities/network_utilities.dart';
import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';
import 'package:business_whatsapp/app/modules/contacts/services/import_service.dart';
import 'package:business_whatsapp/app/utilities/utilities.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../../../data/models/contact_model.dart';
import '../../../data/models/tag_model.dart';
import '../../../data/services/contact_service.dart';
import '../../../data/services/tag_service.dart';
import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/app/Utilities/webutils.dart';

import 'package:file_saver/file_saver.dart';

class ContactsController extends GetxController {
  final ContactsService _contactService = ContactsService.instance;
  final TagService _tagService = TagService();

  // Observable lists
  final contacts = <ContactModel>[].obs;
  final filteredContacts = <ContactModel>[].obs;
  final tags = <TagModel>[].obs;

  // Selected contact
  final selectedContact = Rx<ContactModel?>(null);

  // Search & filter
  final searchQuery = ''.obs;
  final selectedTag = 'All'.obs;
  final selectedStatus = 'All'.obs;

  // Pagination
  final currentPage = 1.obs;
  final itemsPerPage = 20;

  // Loading
  final isLoading = false.obs;

  // Add/Edit contact
  final isAddingContact = false.obs;
  final isEditingContact = false.obs;
  final contactToEdit = Rx<ContactModel?>(null);

  // Subscriptions
  StreamSubscription<List<ContactModel>>? _contactsSubscription;
  StreamSubscription<List<TagModel>>? _tagsSubscription;
  final searchController = TextEditingController();

  String currentClientId = '';

  @override
  void onInit() {
    super.onInit();

    // read current client id set during login
    currentClientId = WebUtils.readCookie('currentClientId') ?? '';

    loadContacts();
    loadTags();

    // Use debounce for API search to avoid excessive calls
    debounce(
      searchQuery,
      (query) => searchContacts(query),
      time: const Duration(milliseconds: 500),
    );
    ever(selectedTag, (_) => loadContactsByTag());
    ever(selectedStatus, (_) => filterContacts());
  }

  @override
  void onClose() {
    _contactsSubscription?.cancel();
    _tagsSubscription?.cancel();
    super.onClose();
  }

  String? formatDateMonth(DateTime? date) {
    if (date == null) return null;

    // Option 1: "3 November"
    // return DateFormat('d MMMM').format(date);

    // Option 2: "03 09"
    return DateFormat('dd MM').format(date);
  }

  // Load tags
  void loadTags() {
    _tagsSubscription = _tagService.getTagsStream().listen((tagsList) {
      // Tags are already scoped by clientID in the service
      tags.value = tagsList;
    });
  }

  // Load contacts by tag filter
  void loadContactsByTag() {
    if (selectedTag.value == 'All') {
      loadContacts();
    } else {
      final tag = tags.firstWhereOrNull((t) => t.name == selectedTag.value);
      if (tag != null) {
        isLoading.value = true;
        _contactsSubscription?.cancel();

        _contactsSubscription = _contactService
            .getContactsByTagIdStream(tag.name)
            .listen((contactsList) {
              // Contacts are already scoped by clientID in the service
              contacts.value = contactsList;

              filterContacts();
              isLoading.value = false;
            });
      }
    }
  }

  // Load all contacts
  void loadContacts() {
    isLoading.value = true;

    _contactsSubscription = _contactService.getContactsStream().listen(
      (contactsList) {
        // Contacts are already scoped by clientID in the service
        contacts.value = contactsList;

        filterContacts();
        isLoading.value = false;
      },
      onError: (error) {
        //print('Error loading contacts: $error');
        Utilities.showSnackbar(SnackType.ERROR, 'Failed to load contacts');

        isLoading.value = false;
      },
    );
  }

  // Search Contacts using Typesense
  Future<void> searchContacts(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      _applyLocalFilter();
      return;
    }

    try {
      isLoading.value = true;
      final dio = NetworkUtilities.getDioClient();
      final collectionName = 'contacts_$currentClientId';
      final url = ApiEndpoints.searchContacts(collectionName);

      final response = await dio.get(
        url,
        queryParameters: {
          'q': trimmedQuery,
          'query_by': 'fName,lName,countryCode,countryCallingCode,phoneNumber',
        },
        options: Options(
          headers: {'X-TYPESENSE-API-KEY': ApiEndpoints.typesenseApiKey},
        ),
      );

      if (response.statusCode == 200) {
        final List hits = response.data['hits'] ?? [];
        final List<ContactModel> searchResults = hits.map((hit) {
          final doc = hit['document'] as Map<String, dynamic>;
          // Ensure 'id' is present if provided in hit but not document
          if (!doc.containsKey('id') && hit.containsKey('id')) {
            doc['id'] = hit['id'];
          }
          return ContactModel.fromJson(doc);
        }).toList();

        filteredContacts.value = searchResults;
      }
    } catch (e) {
      // debugPrint('Typesense search error: $e');
      // Fallback to local filter if API fails
      _applyLocalFilter();
    } finally {
      isLoading.value = false;
    }
  }

  // Filter contacts
  void filterContacts() {
    // If search query is present, we rely on searchContacts (API)
    // unless this is called from loadContacts (stream update) and we want to preserve search results?
    // For now, if query is active, we skip local overwrite.
    if (searchQuery.value.trim().isNotEmpty) {
      return;
    }
    _applyLocalFilter();
  }

  void _applyLocalFilter() {
    final query = searchQuery.value.toLowerCase().trim();

    var filtered = contacts.where((contact) {
      // Normalized fields
      final first = contact.fName!.toLowerCase();
      final last = contact.lName!.toLowerCase();
      final full = "$first $last";
      final fullNoSpace = "$first$last";

      // Search filter (Local fallback)
      final matchesSearch =
          query.isEmpty ||
          first.contains(query) ||
          last.contains(query) ||
          full.contains(query) ||
          fullNoSpace.contains(query) ||
          contact.phoneNumber.toLowerCase().contains(query) ||
          (contact.email?.toLowerCase().contains(query) ?? false);

      return matchesSearch;
    }).toList();

    filteredContacts.value = filtered;
  }

  void selectContact(ContactModel contact) {
    // If contacts list is empty, clear selection safely
    if (contacts.isEmpty) {
      selectedContact.value = null;
      return;
    }

    // Find the contact inside the list
    final matchIndex = contacts.indexWhere((c) => c.id == contact.id);

    // If found → select it
    if (matchIndex != -1) {
      selectedContact.value = contacts[matchIndex];
    } else {
      // If not found → avoid crash and clear selection
      selectedContact.value = null;
    }
  }

  void clearSelection() => selectedContact.value = null;

  void updateSearchQuery(String q) {
    searchQuery.value = q;
    currentPage.value = 1;
  }

  void updateTagFilter(String tag) {
    selectedTag.value = tag;
    currentPage.value = 1;
  }

  void updateStatusFilter(String status) {
    selectedStatus.value = status;
    currentPage.value = 1;
  }

  List<String> get allTags => ['All', ...tags.map((t) => t.name)];

  // Pagination
  List<ContactModel> get paginatedContacts {
    final filtered = filteredContacts;
    final start = (currentPage.value - 1) * itemsPerPage;
    final end = start + itemsPerPage;
    if (start >= filtered.length) return [];
    return filtered.sublist(
      start,
      end > filtered.length ? filtered.length : end,
    );
  }

  int get totalPages => filteredContacts.isEmpty
      ? 1
      : (filteredContacts.length / itemsPerPage).ceil();

  int get startItem =>
      filteredContacts.isEmpty ? 0 : (currentPage.value - 1) * itemsPerPage + 1;

  int get endItem {
    if (filteredContacts.isEmpty) return 0;
    final end = currentPage.value * itemsPerPage;
    return end > filteredContacts.length ? filteredContacts.length : end;
  }

  void goToPage(int p) => currentPage.value = p;
  void goToPreviousPage() {
    if (currentPage.value > 1) currentPage.value--;
  }

  void goToNextPage() {
    if (currentPage.value < totalPages) currentPage.value++;
  }

  // Status counters
  int get subscribedCount => contacts.where((c) => c.status == 1).length;
  int get unsubscribedCount => contacts.where((c) => c.status == 0).length;
  int get totalCount => contacts.length;

  // Add contact — DO NOT SET STATUS HERE
  Future<void> addContact(ContactModel contact) async {
    try {
      isLoading.value = true;

      // Set month fields based on dates
      final updatedContact = contact.copyWith(
        birthdateMonth: contact.birthdate != null
            ? formatDateMonth(contact.birthdate)
            : null,
        anniversaryDateMonth: contact.anniversaryDt != null
            ? formatDateMonth(contact.anniversaryDt)
            : null,
        workAnniversaryDateMonth: contact.workAnniversaryDt != null
            ? formatDateMonth(contact.workAnniversaryDt)
            : null,
      );

      await _contactService.addContact(updatedContact);

      isAddingContact.value = false;
      Utilities.showSnackbar(SnackType.SUCCESS, 'Contact added successfully!');
    } catch (e) {
      final msg = e.toString();

      // Duplicate phone
      if (msg.contains("DUPLICATE_PHONE")) {
        final p = msg.split(":");
        final number = p[1];
        final existingName = p[2];
        Utilities.showSnackbar(
          SnackType.ERROR,
          'Phone $number already exists for $existingName',
        );

        return;
      }

      // Duplicate email
      if (msg.contains("DUPLICATE_EMAIL")) {
        final p = msg.split(":");
        final email = p[1];
        final existingName = p[2];
        Utilities.showSnackbar(
          SnackType.ERROR,
          'Email $email already exists for $existingName',
        );

        return;
      }
      Utilities.showSnackbar(SnackType.ERROR, 'Failed to add contact');
    } finally {
      isLoading.value = false;
    }
  }

  // Update contact - FIXED: Now calculates month fields
  Future<void> updateContact(String id, ContactModel contact) async {
    try {
      isLoading.value = true;

      // Calculate month fields based on dates (same as addContact)
      final updatedContact = contact.copyWith(
        birthdateMonth: contact.birthdate != null
            ? formatDateMonth(contact.birthdate)
            : null,
        anniversaryDateMonth: contact.anniversaryDt != null
            ? formatDateMonth(contact.anniversaryDt)
            : null,
        workAnniversaryDateMonth: contact.workAnniversaryDt != null
            ? formatDateMonth(contact.workAnniversaryDt)
            : null,
      );

      await _contactService.updateContact(id, updatedContact);
      Utilities.showSnackbar(
        SnackType.SUCCESS,
        'Contact updated successfully!',
      );
    } catch (e) {
      Utilities.showSnackbar(SnackType.ERROR, 'Failed to update contact');
    } finally {
      isLoading.value = false;
    }
  }

  // Delete contact
  Future<void> deleteContact(String id) async {
    try {
      isLoading.value = true;
      await _contactService.deleteContact(id);
      clearSelection();
      Utilities.showSnackbar(SnackType.SUCCESS, 'Contact deleted');
    } catch (e) {
      Utilities.showSnackbar(SnackType.ERROR, 'Failed to delete');
    } finally {
      isLoading.value = false;
    }
  }

  // Update status (manual only)
  Future<void> updateContactStatus(String id, int? status) async {
    try {
      final contact = await _contactService.getContactById(id);
      if (contact == null) return;

      final updated = contact.copyWith(status: status);
      await _contactService.updateContact(id, updated);
      Utilities.showSnackbar(SnackType.SUCCESS, 'Status updated');
    } catch (e) {
      Utilities.showSnackbar(SnackType.ERROR, 'Failed to update status');
    }
  }

  // UI form control
  void showAddContactForm() {
    contactToEdit.value = null;
    isEditingContact.value = false;
    isAddingContact.value = true;
  }

  void showEditContactForm(ContactModel contact) {
    contactToEdit.value = contact;
    isEditingContact.value = true;
    isAddingContact.value = true;
  }

  void cancelAddContact() {
    isAddingContact.value = false;
    isEditingContact.value = false;
    contactToEdit.value = null;
  }

  // Download sample CSV (NO STATUS)
  void downloadSampleCsv() async {
    final rows = [
      [
        "First Name",
        "Last Name",
        "Country Code", // ISO
        "Calling Code", // +91, +1
        "Phone Number",
        "Email",
        "Company",
        "Tags",
        "Notes",
        "Birthdate",
        "Anniversary",
        "Work Anniversary",
        "Birthdate Month",
        "Anniversary Month",
        "Work Anniversary Month",
      ],

      [
        "Ritika",
        "Sharma",
        "IN",
        "+91",
        "9876543210",
        "ritika.sharma@test.com",
        "BlueBridge",
        "new",
        "Lead",
        "1995-04-18",
        "2020-02-10",
        "2021-05-01",
        "18 04",
        "10 02",
        "01 05",
      ],
      [
        "Amit",
        "Verma",
        "IN",
        "+91",
        "9123456789",
        "amit.verma@test.com",
        "UrbanEdge",
        "priority",
        "Follow-up",
        "1992-09-07",
        "",
        "2019-08-15",
        "07 09",
        "",
        "15 08",
      ],
      [
        "John",
        "Doe",
        "US",
        "+1",
        "2025550123",
        "john.doe@test.com",
        "Global Tech",
        "international",
        "US Lead",
        "1990-01-01",
        "",
        "",
        "01 01",
        "",
        "",
      ],
      [
        "Pooja",
        "Mehta",
        "IN",
        "+91",
        "9988776655",
        "pooja.mehta@infomatrix.in",
        "InfoMatrix Technologies",
        "vip",
        "Requested product demo – high intent",
        "1991-01-25",
        "2017-12-12",
        "",
        "25 01",
        "12 12",
        "",
      ],
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csv);

    await FileSaver.instance.saveFile(
      name: "sample_contacts",
      bytes: bytes,
      fileExtension: "csv",
      mimeType: MimeType.csv,
    );
  }

  // Simple one-line import
  void importContacts() {
    CsvImportService.importContactsFromCsv(
      requireNames: true,
      onLoadingChanged: (loading) => isLoading.value = loading,
      onContactsParsed: (contacts) async {
        for (var data in contacts) {
          try {
            await _addContactFromImport(data);
          } catch (e) {
            continue;
          }
        }
      },
      onComplete: (imported, skipped) {
        imported = imported;
        skipped = skipped;
      },
    );
  }

  // Adapter method to convert ContactImportData to your ContactModel
  Future<void> _addContactFromImport(ContactImportData data) async {
    // debugPrint(
    //   'DATES → birth: ${data.birthdate}, '
    //   'anniv: ${data.anniversaryDt}, '
    //   'work: ${data.workAnniversaryDt}',
    // );

    final contact = ContactModel(
      id: '',
      fName: data.firstName,
      lName: data.lastName,
      phoneNumber: data.phoneNumber,
      isoCountryCode: data.isoCountryCode,
      countryCallingCode: data.countryCallingCode,
      email: data.email,
      company: data.company,
      tags: data.tags,
      notes: data.notes,
      status: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      birthdate: data.birthdate,
      anniversaryDt: data.anniversaryDt,
      workAnniversaryDt: data.workAnniversaryDt,
      birthdateMonth: formatDateMonth(data.birthdate),
      anniversaryDateMonth: formatDateMonth(data.anniversaryDt),
      workAnniversaryDateMonth: formatDateMonth(data.workAnniversaryDt),
    );

    await _contactService.addContact(contact);
  }
}
