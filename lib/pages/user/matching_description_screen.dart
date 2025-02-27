import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class MatchingDescriptionScreen extends StatelessWidget {
  final List<DocumentSnapshot> foundItems;

  MatchingDescriptionScreen({required this.foundItems});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Matching Items")),
        body: foundItems.isEmpty
            ? Center(child: Text("No matching items found."))
            : ListView.builder(
          itemCount: foundItems.length,
          itemBuilder: (context, index) {
            var item = foundItems[index].data() as Map<String, dynamic>? ?? {};

            return Card(
              margin: EdgeInsets.all(10),
              child: Column(
                children: [
                  item['image_url'] != null
                      ? Image.network(
                    item['image_url'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                      : Icon(Icons.image, size: 100, color: Colors.grey),
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['name'] ?? "Unknown Item",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text("Color: ${item['color'] ?? "Unknown"}",
                            style: TextStyle(fontSize: 18)),
                        Text("Category: ${item['category'] ?? "Unknown"}",
                            style: TextStyle(fontSize: 18)),
                        Text("Description: ${item['description'] ?? "No description available"}",
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              icon: Icon(Icons.call),
                              label: Text("Call Owner"),
                              onPressed: () => _callOwner(item['contact'] ?? ""),
                            ),
                            ElevatedButton.icon(
                              icon: Icon(Icons.message),
                              label: Text("Text Owner"),
                              onPressed: () => _textOwner(item['contact'] ?? "", item['name'] ?? "your lost item"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ));
  }

  void _callOwner(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      print("⚠️ No phone number available.");
      return;
    }
    final Uri callUri = Uri.parse("tel:$phoneNumber");
   // if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);

  }

  void _textOwner(String phoneNumber, String itemName) async {
    if (phoneNumber.isEmpty) {
      print("⚠️ No phone number available.");
      return;
    }

    String message = Uri.encodeComponent(
        "Hello, I saw a lost $itemName on the Lost & Found site. "
            "How do I proceed to retrieve it? Please let me know. Thank you!");

    final Uri smsUri = Uri.parse("sms:$phoneNumber?body=$message");


      await launchUrl(smsUri);

  }
}
