import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class MpesaService {
  static const String consumerKey = "fYGoe4lz1jXlAxWVsriCBALe2GXx51AMguzu6pxRZStNFj6x";
  static const String consumerSecret = "mu6XG0MNTCKAiKvPdZusSRLGgMvpoNFZiw42d7bHbc1haMfpvBWt0GA5VOVGguid";
  static const String shortcode = "174379";
  static const String passkey = "bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919";
  static const String callbackUrl = "https://your-callback-url.com";

  // Generate OAuth Token
  static Future<String> getAccessToken() async {
    String credentials = base64Encode(utf8.encode("$consumerKey:$consumerSecret"));

    var response = await http.get(
      Uri.parse("https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"),
      headers: {"Authorization": "Basic $credentials"},
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      throw Exception("Failed to get access token");
    }
  }

  // Initiate STK Push
  // static Future<void> stkPush(String phoneNumber, double amount) async {
  //   String accessToken = await getAccessToken();
  //
  //   String timestamp = DateTime.now().toUtc().toString().replaceAll(RegExp(r'[^0-9]'), '').substring(0, 14);
  //   String password = base64Encode(utf8.encode("$shortcode$passkey$timestamp"));
  //
  //   var requestBody = {
  //     "BusinessShortCode": shortcode,
  //     "Password": password,
  //     "Timestamp": timestamp,
  //     "TransactionType": "CustomerPayBillOnline",
  //     "Amount": amount.toInt(),
  //     "PartyA": phoneNumber,
  //     "PartyB": shortcode,
  //     "PhoneNumber": phoneNumber,
  //     "CallBackURL": callbackUrl,
  //     "AccountReference": "Lost & Found",
  //     "TransactionDesc": "Payment for collected item"
  //   };
  //
  //   var response = await http.post(
  //     Uri.parse("https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest"),
  //     headers: {
  //       "Authorization": "Bearer $accessToken",
  //       "Content-Type": "application/json"
  //     },
  //     body: jsonEncode(requestBody),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     var responseBody = jsonDecode(response.body);
  //     print("STK Push Sent: ${responseBody['ResponseDescription']}");
  //   } else {
  //     print("STK Push Failed: ${response.body}");
  //   }
  // }

  static Future<void> stkPush(String phoneNumber, double amount, String itemId) async {
    String accessToken = await getAccessToken();

      String timestamp = DateTime.now().toUtc().toString().replaceAll(RegExp(r'[^0-9]'), '').substring(0, 14);
      String password = base64Encode(utf8.encode("$shortcode$passkey$timestamp"));

      var requestBody = {
        "BusinessShortCode": shortcode,
        "Password": password,
        "Timestamp": timestamp,
        "TransactionType": "CustomerPayBillOnline",
        "Amount": amount.toInt(),
        "PartyA": phoneNumber,
        "PartyB": shortcode,
        "PhoneNumber": phoneNumber,
        "CallBackURL": callbackUrl,
        "AccountReference": "Lost & Found",
        "TransactionDesc": "Payment for collected item"
      };

      var response = await http.post(
        Uri.parse("https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json"
        },
        body: jsonEncode(requestBody),
      );

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);

      // Check if the response is successful
      if (responseBody['ResponseCode'] == '0') {
        // Move item to "collected_items" in Firestore
        FirebaseFirestore.instance.collection("found_items").doc(itemId).get().then((doc) {
          if (doc.exists) {
            FirebaseFirestore.instance.collection("collected_items").doc(itemId).set(doc.data()!);
            FirebaseFirestore.instance.collection("found_items").doc(itemId).delete();
          }
        });
      }
    }
  }

}
