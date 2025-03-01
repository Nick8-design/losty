import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatService {
  final String apiKey = "AIzaSyBGFC9cnNJEC822NAKicHbX4PJsE1PGn4c";
  final String model = "gemini-2.0-flash";
  int conversationStage = 0;
  String userName = "";
  String itemType = "";
  String itemDescription = "";
  String location = "";
  String nearestAdmin = "";
  String finderContact = "";

  Future<String> sendMessage(String userInput) async {
    userInput = userInput.toLowerCase();

    // Restart if user wants to report another item
    if (userInput == "yes") {
      conversationStage = 1;
      return "Great! Did you lose an item or find an item?";
    } else if (userInput == "no") {
      return "Okay, feel free to return if you need assistance.";
    }

    conversationStage++;

    if (conversationStage == 1) {
      userName = userInput;
      return "Hi $userName! Did you lose an item or find an item?";
    }
    else if (conversationStage == 2) {
      itemType = userInput;
      if (itemType == "lost" || itemType == "nimepoteza" || itemType == "i have lost" || itemType == "a") {
        return "Okay, what did you lose?";
      } else if (itemType == "found" || itemType == "b" || itemType == "i have found") {
        return "Great! What item did you find?";
      } else {
        conversationStage--;
        return "Please say 'lost' or 'found'.";
      }
    }
    else if (conversationStage == 3) {
      itemDescription = userInput;

      if (itemType == "lost") {
        return "Can you describe the $itemDescription in more detail? Also, where did you last have it?";
      } else {
        return "Can you describe the $itemDescription in more detail? Also, where did you find it?";
      }
    }
    else if (conversationStage == 4) {
      location = userInput;

      if (itemType == "lost") {
        // 🔍 Search lost item in database
        return await handleLostItem();
      } else {
        return "Thank you! What is the nearest school administration office to you?";
      }
    }
    else if (conversationStage == 5 && itemType == "found") {
      nearestAdmin = userInput;
      return "Great! Please take the $itemDescription to the $nearestAdmin office so the owner can collect it.\n\n"
          "Before you go, please enter your phone number. This will be used to send you an appreciation reward when the owner collects the item.";
    }
    else if (conversationStage == 6 && itemType == "found") {
      finderContact = userInput;
      await storeFoundItem(userName, itemDescription, location, nearestAdmin, finderContact);
      return "Thank you for your honesty! The item has been recorded. If someone claims it, they will be directed to the $nearestAdmin office and can send you appreciation.";
    }

    return "Let me know how else I can assist you.";
  }

  // 🛠️ Handle Lost Items: Search in Database
  Future<String> handleLostItem() async {
    String foundItem = await searchDatabase(itemDescription, location);
    if (foundItem.isNotEmpty) {
      return "Searching the database... I found a match: $foundItem.\nDo you have another item that you have lost?";
    } else {
      await storeAlertRequest(userName, itemDescription, location);
      return "Sorry, no matches found. I have saved your request, and you will be alerted when a matching item is found.\nWould you like to report another lost item? (yes/no)";
    }
  }

  // 🔍 Search in Firebase for Lost Items
  Future<String> searchDatabase(String item, String location) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('lost_items')
        .where('name', isEqualTo: item)
        .where('place_found', isEqualTo: location)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var doc = snapshot.docs.first.data() as Map<String, dynamic>;
      String mapUrl = "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(doc['location'])}";
      return "${doc['item']} found at ${doc['location']}. Contact: ${doc['contact']}.\n\n"
          "👉 [Click here to view on Google Maps]($mapUrl)";
    }
    return "";
  }

  // 🔔 Store request to alert user when item is found
  Future<void> storeAlertRequest(String name, String item, String location) async {
    await FirebaseFirestore.instance.collection('alerts').add({
      'user': name,
      'name': item,
      'place': location,
      "descriptions": item,
      'notified': false,
      'date': DateTime.now(),
      "color": ""
    });
  }

  // 📝 Store Found Item in Database
  Future<void> storeFoundItem(String name, String item, String location, String adminOffice, String contact) async {
    await FirebaseFirestore.instance.collection('found_items').add({
      'finder_name': name,
      'item_name': item,
      'found_location': location,
      'admin_office': adminOffice,
      'finder_contact': contact,
      'date': DateTime.now(),
    });
  }

  // 🌍 Open Google Maps for location
  Future<void> openGoogleMaps(String location) async {
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
