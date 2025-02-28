import 'dart:convert';
import 'dart:io';
import 'package:finder/pages/user/matching_description_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../components/color_button.dart';
import '../components/nav_drawer.dart';
import '../components/profile.dart';
import '../components/theme_button.dart';
import '../components/wavyappbarclipper.dart';
import '../constants.dart';
import '../data/providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({
    super.key,
    required this.changeTheme,
    required this.changeColor,
    required this.colorSelected,
  });

  final ColorSelection colorSelected;
  final void Function(bool useLightMode) changeTheme;
  final void Function(int value) changeColor;

  @override
  ConsumerState<DashboardScreen>  createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;
  String? _detectedName; // Stores AI-detected name
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _detectedName = null; // Reset detected name when new image is picked
      });

      // Run AI analysis on the selected image
      await _analyzeImage(_selectedImage!);
    }
  }
  Future<void> _analyzeImage(File imageFile) async {
    setState(() {
      _isLoading = true;
      _detectedName = "Processing image...";
    });

    String apiKey = "AIzaSyAZOhKQaJLCH21qg0rzizsayymN_zcc1Sg";
    List<int> imageBytes = await imageFile.readAsBytes();
    String base64Image = base64Encode(imageBytes);

    var request = {
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [{"type": "LABEL_DETECTION", "maxResults": 3}]
        }
      ]
    };

    var response = await http.post(
      Uri.parse("https://vision.googleapis.com/v1/images:annotate?key=$apiKey"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(request),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var labels = data['responses'][0]['labelAnnotations'];

      if (labels != null && labels.isNotEmpty) {
        String detectedText = labels.map((label) => label['description']).join(", ");
        setState(() {
          _detectedName = detectedText;
          _descriptionController.text = detectedText; // Auto-fill description field
        });
      } else {
        setState(() {
          _detectedName = "No objects detected.";
        });
      }
    } else {
      setState(() {
        _detectedName = "Error processing image.";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }



  //
  // Future<void> _analyzeImage(File imageFile) async {
  //   setState(() {
  //     _isLoading = true;
  //     _detectedName = "Processing image..."; // Temporary message while loading
  //   });
  //
  //   String apiKey = "AIzaSyAZOhKQaJLCH21qg0rzizsayymN_zcc1Sg"; // Replace with your API key
  //   List<int> imageBytes = await imageFile.readAsBytes();
  //   String base64Image = base64Encode(imageBytes);
  //
  //   var request = {
  //     "requests": [
  //       {
  //         "image": {"content": base64Image},
  //         "features": [{"type": "LABEL_DETECTION", "maxResults": 3}]
  //       }
  //     ]
  //   };
  //
  //   var response = await http.post(
  //     Uri.parse("https://vision.googleapis.com/v1/images:annotate?key=$apiKey"),
  //     headers: {"Content-Type": "application/json"},
  //     body: jsonEncode(request),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     var data = jsonDecode(response.body);
  //     var labels = data['responses'][0]['labelAnnotations'];
  //
  //     if (labels != null && labels.isNotEmpty) {
  //       setState(() {
  //         _detectedName = labels.map((label) => label['description']).join(", ");
  //       });
  //     } else {
  //       setState(() {
  //         _detectedName = "No objects detected.";
  //       });
  //     }
  //   } else {
  //     setState(() {
  //       _detectedName = "Error processing image.";
  //     });
  //   }
  //
  //   setState(() {
  //     _isLoading = false;
  //   });
  // }

  // Future<void> _processSearch() async {
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //   String searchQuery = _descriptionController.text.trim();
  //   if (_selectedImage != null && _detectedName != null && _detectedName != "Processing image...") {
  //     searchQuery = _detectedName!;
  //   }
  //
  //   if (searchQuery.isEmpty) {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     _showMessage("Please provide details or upload an image.");
  //     return;
  //   }
  //
  //   QuerySnapshot querySnapshot = await FirebaseFirestore.instance
  //       .collection('lost_items')
  //       .get(); // Fetch all lost items
  //
  //   List<DocumentSnapshot> matchingItems = querySnapshot.docs.where((doc) {
  //     String itemName = (doc['name'] ?? "").toLowerCase();
  //     String itemDescription = (doc['description'] ?? "").toLowerCase();
  //     return itemName.contains(searchQuery.toLowerCase()) || itemDescription.contains(searchQuery.toLowerCase());
  //   }).toList();
  //
  //   setState(() {
  //     _isLoading = false;
  //   });
  //
  //   if (matchingItems.isEmpty) {
  //     _showMessage("No matching items found.");
  //   } else {
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => MatchingItemsScreen(matchingItems: matchingItems),
  //       ),
  //     );
  //   }
  // }

  Future<void> _processSearch() async {
    setState(() {
      _isLoading = true;
    });

    String searchQuery = _descriptionController.text.trim().toLowerCase();

    if (_selectedImage != null && _detectedName != null && _detectedName != "Processing image...") {
      searchQuery = _detectedName!.toLowerCase();
      _descriptionController.text = _detectedName!; // Auto-fill input field
    }

    if (searchQuery.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      _showMessage("Please provide details or upload an image.");
      return;
    }

    // 🔍 Fetch all lost items
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('lost_items').get();

    // 🔍 Manually filter results using substring matching
    List<DocumentSnapshot> matchingItems = querySnapshot.docs.where((doc) {
      var data = doc.data() as Map<String, dynamic>? ?? {};
      List<String> keywords = List<String>.from(data['keywords'] ?? []);

    print(keywords);
      return keywords.any((keyword) => keyword.contains(searchQuery));
    }).toList();

    print("✅ Found ${matchingItems.length} matching items");

    setState(() {
      _isLoading = false;
    });

    // if (matchingItems.isEmpty) {
    //   _showMessage("No matching items found.");
    // } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MatchingDescriptionScreen(foundItems: matchingItems),
        ),
      );
   // }
  }




  // void _showResultsDialog(List<String> items) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Text("Matching Items"),
  //         content: items.isNotEmpty
  //             ? Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: items.map((item) => Text(item)).toList(),
  //         )
  //             : Text("No matching items found."),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: Text("OK"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userDao = ref.watch(userDaoProvider);

    return Scaffold(
      drawer: NavDrawer(),
      appBar:  PreferredSize(
        preferredSize: Size.fromHeight(120),
        child: ClipPath(
          clipper: WavyAppBarClipper(),
          child: AppBar(
            title: Text('Lost & Found Recognition'),
            elevation: 8.0,
            backgroundColor: Colors.blueAccent,
            actions: [
              ThemeButton(changeThemeMode: widget.changeTheme),
              ColorButton(changeColor: widget.changeColor, colorSelected: widget.colorSelected),
              IconButton(
                onPressed: () async {
                  userDao.logout();
                  await Future.delayed(Duration(milliseconds: 1));
                  context.go('/login');
                },
                icon: Icon(Icons.logout_sharp),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Logged in as user"),
                      duration: Duration(milliseconds: 500),
                    ),
                  );
                },
                icon: Icon(Icons.account_circle_outlined, size: 50, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Upload or Take a Picture", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera_alt),
                  label: Text("Take Picture"),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: Icon(Icons.photo_library),
                  label: Text("Upload"),
                ),
              ],
            ),
            SizedBox(height: 20),
            _selectedImage != null
                ? Column(
              children: [
                Image.file(_selectedImage!, height: 150, fit: BoxFit.cover),
                SizedBox(height: 10),
                Text("Detected: ${_detectedName ?? 'Processing...'}"),
              ],
            )
                : Container(),
            SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "Describe the lost item",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Center(
              child: ElevatedButton(
                onPressed: _processSearch,
                child: Text("Search for Matches"),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
