import 'package:finder/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'new2/chart_screen.dart';
// Replace with actual admin login screen file

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/see/.png"), // Add this image in your assets
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Dark Overlay for Better Visibility
          Container(
            color: Colors.black.withOpacity(0.5),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo (Optional)
                CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage("assets/see/oneeyepic1.png"), // Add a logo in assets
                ),
                SizedBox(height: 20),

                // App Title
                Text(
                  "Lost & Found",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),

                // Subtitle
                Text(
                  "Find your lost items or help others!",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),

                // User Chat Button
                ElevatedButton.icon(
                  icon: Icon(Icons.chat_bubble, color: Colors.white),
                  label: Text("Enter Chat"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    context.go("/talk_to_us");
                  },
                ),
                SizedBox(height: 15),

                // Admin Login Button
                ElevatedButton.icon(
                  icon: Icon(Icons.lock, color: Colors.white),
                  label: Text("Admin Login"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                   context.go("/login");
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
