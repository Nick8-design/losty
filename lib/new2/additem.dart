import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/color_button.dart';
import '../components/nav_drawer.dart';
import '../components/theme_button.dart';
import '../components/wavyappbarclipper.dart';
import '../constants.dart';
import '../data/providers.dart';

class AddItemPage extends ConsumerStatefulWidget {
  AddItemPage({
    super.key,
    required this.changeTheme,
    required this.changeColor,
    required this.colorSelected,
  } );


final ColorSelection colorSelected;
final void Function(bool useLightMode) changeTheme;
final void Function(int value) changeColor;

@override
ConsumerState<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends ConsumerState<AddItemPage> {
  Uint8List? _imageBytes;
  String? _imageUrl;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _placeFoundController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _imageBytes = result.files.first.bytes;
      });
      await _analyzeImage(_imageBytes!);
    }
  }

  Future<void> _analyzeImage(Uint8List imageBytes) async {
    try {
      String apiKey = "AIzaSyAZOhKQaJLCH21qg0rzizsayymN_zcc1Sg";
      String base64Image = base64Encode(imageBytes);

      var request = {
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "LABEL_DETECTION", "maxResults": 3},
              {"type": "IMAGE_PROPERTIES"}
            ]
          }
        ]
      };

      var response = await Dio().post(
        "https://vision.googleapis.com/v1/images:annotate?key=$apiKey",
        options: Options(headers: {"Content-Type": "application/json"}),
        data: jsonEncode(request),
      );

      if (response.statusCode == 200) {
        var data = response.data;
        var labels = data['responses'][0]['labelAnnotations'];
        var colors = data['responses'][0]['imagePropertiesAnnotation']['dominantColors']['colors'];

        setState(() {
          _nameController.text = labels.isNotEmpty ? labels[0]['description'] : "";
          _categoryController.text = labels.length > 1 ? labels[1]['description'] : "";
          _colorController.text = colors.isNotEmpty ? colors[0]['color'].toString() : "";
          _descriptionController.text = labels.length > 2 ? labels[2]['description'] : "";
        });
      } else {
        print("AI Processing Failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Error analyzing image: $e");
    }
  }

  Future<void> _uploadImage() async {
    if (_imageBytes == null) return;

    try {
      var formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(_imageBytes!, filename: 'upload.png'),
      });

      var response = await Dio().post("https://files-kvpe.onrender.com/upload", data: formData);

      if (response.statusCode == 200) {
        setState(() {
          _imageUrl =    response.data['url'];
        });
      }

    } catch (e) {
      print("Error uploading image: $e");
    }
  }


  Future<void> _saveToFirebase() async {
 //   if (_imageUrl == null) return;

    try {
      await FirebaseFirestore.instance.collection('lost_items').add({
        'name': _nameController.text,
        'category': _categoryController.text,
        'color': _colorController.text,
        'description': _descriptionController.text,
        'place_found': _placeFoundController.text,
        'contact': _contactController.text,
        'image_url': _imageUrl,
        'keywords': [
          _nameController.text.toLowerCase(),
          _categoryController.text.toLowerCase(),
          _colorController.text.toLowerCase(),
          _descriptionController.text.toLowerCase(),
        ],
        'date_added': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Item added successfully!")),
      );
    } catch (e) {
      print("Error saving to Firebase: $e");
    }
  }

  Future<void> _handleSubmit() async {
    await _uploadImage();
    await _saveToFirebase();
  }

  @override
  Widget build(BuildContext context) {
    final userDao = ref.watch(userDaoProvider);
    return Scaffold(
      drawer: NavDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: ClipPath(
          clipper: WavyAppBarClipper(),
          child: AppBar(
            title: const Text('Add Item'),
            elevation: 8.0,
            backgroundColor: Colors.blueAccent,
            actions: [
              ThemeButton(changeThemeMode: widget.changeTheme),
              ColorButton(changeColor: widget.changeColor, colorSelected: widget.colorSelected),
              IconButton(
                onPressed: () async {
                  userDao.logout();
                  await Future.delayed(const Duration(milliseconds: 1));
                  context.go('/login');
                },
                icon: const Icon(Icons.logout_sharp),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Logged in as Admin"),
                      duration: Duration(milliseconds: 500),
                    ),
                  );
                },
                icon: const Icon(Icons.account_circle_outlined, size: 50, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(controller: _categoryController, decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(controller: _colorController, decoration: InputDecoration(labelText: 'Color', border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(controller: _descriptionController, decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(controller: _placeFoundController, decoration: InputDecoration(labelText: 'Place Found', border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(controller: _contactController, decoration: InputDecoration(labelText: 'Contact', border: OutlineInputBorder())),
            SizedBox(height: 10),
            ElevatedButton(onPressed: _pickImage, child: Text('Upload Image')),
            if (_imageBytes != null) Padding(padding: const EdgeInsets.all(10.0), child: Image.memory(_imageBytes!, height: 150)),
            SizedBox(height: 10),
            ElevatedButton(onPressed: _handleSubmit, child: Text('Submit')),
          ],
        ),
      ),
    );
  }
}
