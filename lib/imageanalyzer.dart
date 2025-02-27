import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<String> _analyzeImage(File imageFile) async {
  String apiKey = "e5b7f47b959deb8dbc2232c0dfaf5801488dde3f";  // Replace with your API Key

  // Convert image to base64
  List<int> imageBytes = await imageFile.readAsBytes();
  String base64Image = base64Encode(imageBytes);

  // Create JSON request
  var request = {
    "requests": [
      {
        "image": {"content": base64Image},
        "features": [{"type": "LABEL_DETECTION", "maxResults": 5}]
      }
    ]
  };

  // Send request to Google Vision API
  var response = await http.post(
    Uri.parse("https://vision.googleapis.com/v1/images:annotate?key=$apiKey"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(request),
  );

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    var labels = data['responses'][0]['labelAnnotations'];

    if (labels != null && labels.isNotEmpty) {
      return labels.map((label) => label['description']).join(", ");
    } else {
      return "No objects detected";
    }
  } else {
    return "Error processing image";
  }
}
