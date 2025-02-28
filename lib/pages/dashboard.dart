import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/color_button.dart';
import '../components/nav_drawer.dart';
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
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
            title: const Text('Admin Dashboard'),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 700 ? 3 : 1;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFirestoreSection('Found Items', 'lost_items', context, crossAxisCount),
                  _buildFirestoreSection('Reported Items', 'alerts', context, crossAxisCount),
                  _buildFirestoreSection('Collected Items', 'collected_items', context, crossAxisCount),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _showNotification(context),
            child: const Icon(Icons.notifications),
            tooltip: 'New Report Notification',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => _addNewItem(context),
            child: const Icon(Icons.add),
            tooltip: 'Add Found Item',
          ),
        ],
      ),
    );
  }
  Widget _buildFirestoreSection(String title, String collection, BuildContext context, int crossAxisCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection(collection).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No items found"));
            }

            final items = snapshot.data!.docs;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 3,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                var item = items[index].data() as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () => _openItemDetails(context, item, collection),
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(item['name'] ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      subtitle: Text(item['category'] ?? 'No category'),
                      trailing: item['imageUrl'] != null && item['imageUrl'].isNotEmpty
                          ? Image.network(item['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                          : null, // Show image if exists
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // Widget _buildFirestoreSection(String title, String collection, BuildContext context, int crossAxisCount) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.all(8.0),
  //         child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
  //       ),
  //       StreamBuilder<QuerySnapshot>(
  //         stream: _firestore.collection(collection).snapshots(),
  //         builder: (context, snapshot) {
  //           if (snapshot.connectionState == ConnectionState.waiting) {
  //             return const Center(child: CircularProgressIndicator());
  //           }
  //           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
  //             return const Center(child: Text("No items found"));
  //           }
  //
  //           final items = snapshot.data!.docs;
  //
  //           return GridView.builder(
  //             shrinkWrap: true,
  //             physics: const NeverScrollableScrollPhysics(),
  //             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  //               crossAxisCount: crossAxisCount,
  //               childAspectRatio: 3,
  //             ),
  //             itemCount: items.length,
  //             itemBuilder: (context, index) {
  //               var item = items[index].data() as Map<String, dynamic>;
  //               return GestureDetector(
  //                 onTap: () => _openItemDetails(context, item),
  //                 child: Card(
  //                   elevation: 4,
  //                   margin: const EdgeInsets.all(8),
  //                   child: Padding(
  //                     padding: const EdgeInsets.all(8.0),
  //                     child: Column(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(item['name'] ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  //                         Text('Date: ${item['date'] ?? 'N/A'}'),
  //                         Text('Location: ${item['location'] ?? 'N/A'}'),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //               );
  //             },
  //           );
  //         },
  //       ),
  //     ],
  //   );
  // }

  // void _openItemDetails(BuildContext context, Map<String, dynamic> item) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => ItemDetailsPage(item: item),
  //     ),
  //   );
  // }

  void _openItemDetails(BuildContext context, Map<String, dynamic> item, String collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailsPage(item: item, status: collection),
      ),
    );
  }

  void _showNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New lost item reported!')),
    );
  }

  void _addNewItem(BuildContext context) {
    context.go("/add_item");
    // Open a form to add a new found item
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(content: Text('Feature to add new items coming soon!')),
    // );
  }
}

// class ItemDetailsPage extends StatelessWidget {
//   final Map<String, dynamic> item;
//   const ItemDetailsPage({super.key, required this.item});

class ItemDetailsPage extends StatelessWidget {
  final Map<String, dynamic> item;
  final String status; // Found, Reported, or Collected

  const ItemDetailsPage({super.key, required this.item, required this.status});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'lost_items':
        return Colors.green; // Found Items
      case 'alerts_items':
        return Colors.red; // Reported Items
      case 'collected_items':
        return Colors.blue; // Collected Items
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item['name'] ?? 'Item Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item['imageUrl'] != null && item['imageUrl'].isNotEmpty)
                Center(
                  child: Image.network(item['imageUrl'], height: 300, width: double.infinity, fit: BoxFit.cover),
                ),
              const SizedBox(height: 10),
              Text('Item Name: ${item['name'] ?? 'Unknown'}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Category: ${item['category'] ?? 'N/A'}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Text('Reported Date: ${item['date_added'] ?? 'N/A'}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Text('Found Location: ${item['place_found'] ?? 'N/A'}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Text('Color(s): ${item['color'] ?? 'N/A'}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(status),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'lost_items':
        return 'Found Item';
      case 'alerts_items':
        return 'Reported Item';
      case 'collected_items':
        return 'Collected Item';
      default:
        return 'Unknown Status';
    }
  }
}

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: Text(item['name'] ?? 'Item Details')),
  //     body: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text('Item Name: ${item['name'] ?? 'Unknown'}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
  //           const SizedBox(height: 10),
  //           Text('Reported Date: ${item['date'] ?? 'N/A'}', style: const TextStyle(fontSize: 18)),
  //           const SizedBox(height: 10),
  //           Text('Found Location: ${item['location'] ?? 'N/A'}', style: const TextStyle(fontSize: 18)),
  //         ],
  //       ),
  //     ),
  //   );
  // }
//}
