import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'package:http/http.dart' as http;

import '../../components/managelost.dart';
import '../../components/viewusercreen.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  void _navigateToUsersScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ViewUsersScreen()),
    );
  }

  void _navigateToLostItemsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ManageLostItemsScreen()),
    );
  }

  void _navigateToAddLostItemScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddLostItemScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Dashboard")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _navigateToUsersScreen,
              child: Text("View Registered Users"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateToLostItemsScreen,
              child: Text("Manage Lost Items"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateToAddLostItemScreen,
              child: Text("Add Lost Item"),
            ),
          ],
        ),
      ),
    );
  }
}

class AddLostItemScreen extends StatefulWidget {
  @override
  _AddLostItemScreenState createState() => _AddLostItemScreenState();
}

class _AddLostItemScreenState extends State<AddLostItemScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;
  final String uploadUrl = "https://files-kvpe.onrender.com/upload";
  final String saveUrl = "https://files-kvpe.onrender.com/files";
  final Dio dio = Dio();

  Future<void> _pickImage(bool fromCamera) async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
        });
        print("✅ Image selected: ${result.files.single.name}");
        await _analyzeImage(_selectedImage!);
      } else {
        print("⚠️ No image selected.");
      }
    } else {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxHeight: 800, // Resize for better performance
        maxWidth: 800,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        print("✅ Image selected: ${image.path}");
        await _analyzeImage(_selectedImage!);
      } else {
        print("⚠️ No image selected.");
      }
    }
  }


  Future<void> _analyzeImage(File imageFile) async {
    setState(() {
      _nameController.text = "Detecting...";
      _colorController.text = "Detecting...";
      _categoryController.text = "Detecting...";
    });

    try {
      String apiKey = "AIzaSyAZOhKQaJLCH21qg0rzizsayymN_zcc1Sg";
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      var request = {
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "LABEL_DETECTION", "maxResults": 3},
              {"type": "IMAGE_PROPERTIES"},
            ]
          }
        ]
      };

      var response = await http.post(
        Uri.parse("https://vision.googleapis.com/v1/images:annotate?key=$apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request),
      );

      print("🔍 AI Response: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var labels = data['responses'][0]['labelAnnotations'];
        var colors = data['responses'][0]['imagePropertiesAnnotation']['dominantColors']['colors'];

        if (labels != null && labels.isNotEmpty) {
          setState(() {
            _nameController.text = labels[0]['description'];
            _categoryController.text = labels.length > 1 ? labels[1]['description'] : "";
          });
        }
        if (colors != null && colors.isNotEmpty) {
          setState(() {
            _colorController.text = colors[0]['color'].toString();
          });
        }
      } else {
        print("❌ AI Processing Failed: ${response.statusCode}");
        setState(() {
          _nameController.text = "";
          _colorController.text = "";
          _categoryController.text = "";
        });
      }
    } catch (e) {
      print("❌ AI Error: $e");
    }
  }


  Future<void> _uploadLostItem() async {
    if (_nameController.text.isEmpty ||
        _colorController.text.isEmpty ||
        _categoryController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("All fields are required!")));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String? imageUrl = await _uploadImage(_selectedImage!);
      if (imageUrl == null) throw "Image upload failed!";

      await FirebaseFirestore.instance.collection('lost_items').add({
        'name': _nameController.text,
        'color': _colorController.text,
        'category': _categoryController.text,
        'description': _descriptionController.text,
        'image_url': imageUrl,
        'contact': "0700742362",
        'keywords': [
          _nameController.text.toLowerCase(),
          _colorController.text.toLowerCase(),
          _categoryController.text.toLowerCase(),
          _descriptionController.text.toLowerCase()
        ],
        'date_added': Timestamp.now(),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(imageUrl),duration: Duration(seconds: 8),));
print(imageUrl);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lost item added successfully!")));

      setState(() {
        _isUploading = false;
        _nameController.clear();
        _colorController.clear();
        _categoryController.clear();
        _descriptionController.clear();
        _selectedImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() {
        _isUploading = false;
      });
    }
  }
  // Future<String?> _uploadImage(File file) async {
  //   try {
  //     String fileName = file.path.split("/").last;
  //
  //     FormData data;
  //     if (kIsWeb) {
  //       Uint8List fileBytes = await file.readAsBytes();
  //       data = FormData.fromMap({
  //         "file": MultipartFile.fromBytes(fileBytes, filename: fileName),
  //       });
  //     } else {
  //       data = FormData.fromMap({
  //         "file": await MultipartFile.fromFile(file.path, filename: fileName),
  //       });
  //     }
  //
  //     var response = await dio.post(uploadUrl, data: data);
  //
  //     if (response.statusCode == 200) {
  //       print("✅ Image uploaded successfully: ${saveUrl}/files/$fileName");
  //       return "${uploadUrl}/files/$fileName"; // Ensure correct URL format
  //     } else {
  //       print("⚠️ Image upload failed: ${response.statusCode}");
  //       return null;
  //     }
  //   } catch (e) {
  //     print("❌ Error uploading image: $e");
  //     return null;
  //   }
  // }


  Future<String?> _uploadImage(File file) async {
    try {
      String fileName = file.path.split("/").last;

      FormData data;

      if (kIsWeb) {
        Uint8List? fileBytes = await file.readAsBytes();
        data = FormData.fromMap({
          "file": MultipartFile.fromBytes(fileBytes, filename: fileName),
        });
      } else {
        data = FormData.fromMap({
          "file": await MultipartFile.fromFile(file.path, filename: fileName),
        });
      }

      var response = await dio.post(uploadUrl, data: data);

      if (response.statusCode == 200) {
        print("✅ Image uploaded successfully: ${response.data}");
        return "$saveUrl/$fileName";

      } else {
        print("⚠️ Image upload failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error uploading image: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Lost Item")),



      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 10),
            _selectedImage != null
                ? kIsWeb
                ? Image.network(_selectedImage!.path, height: 100) // Web uses network image
                : Image.file(_selectedImage!, height: 100) // Mobile uses File image
                : Text("No image selected", style: TextStyle(color: Colors.red)),
            SizedBox(height: 10),

            TextField(controller: _nameController, decoration: InputDecoration(labelText: "Item Name")),
            TextField(controller: _colorController, decoration: InputDecoration(labelText: "Color")),
            TextField(controller: _categoryController, decoration: InputDecoration(labelText: "Category")),
            TextField(controller: _descriptionController, decoration: InputDecoration(labelText: "Description")),
            SizedBox(height: 10),
            ElevatedButton(onPressed: () => _pickImage(false), child: Text("Upload Image")),
            ElevatedButton(onPressed: () => _pickImage(true), child: Text("Capture Image")),
            SizedBox(height: 10),
            _selectedImage != null ? Image.file(_selectedImage!, height: 100) : Container(),
            SizedBox(height: 10),
            _isUploading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _uploadLostItem,
              child: Text("Save Lost Item"),
            ),
          ],
        ),
      ),
    );
  }
}
