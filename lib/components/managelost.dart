import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageLostItemsScreen extends StatefulWidget {
  @override
  _ManageLostItemsScreenState createState() => _ManageLostItemsScreenState();
}

class _ManageLostItemsScreenState extends State<ManageLostItemsScreen> {
  String searchQuery = "";
  String selectedCategory = "All";

  void _deleteItem(String itemId) {
    FirebaseFirestore.instance.collection('lost_items').doc(itemId).delete();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Item Deleted")));
  }

  void _editItem(BuildContext context, DocumentSnapshot item) {
    TextEditingController nameController = TextEditingController(text: item['name']);
    TextEditingController colorController = TextEditingController(text: item['color']);
    TextEditingController categoryController = TextEditingController(text: item['category']);
    TextEditingController descriptionController = TextEditingController(text: item['description']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Lost Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Item Name")),
              TextField(controller: colorController, decoration: InputDecoration(labelText: "Color")),
              TextField(controller: categoryController, decoration: InputDecoration(labelText: "Category")),
              TextField(controller: descriptionController, decoration: InputDecoration(labelText: "Description")),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('lost_items').doc(item.id).update({
                  'name': nameController.text,
                  'color': colorController.text,
                  'category': categoryController.text,
                  'description': descriptionController.text,
                });
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Lost Items"),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: LostItemSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedCategory,
              items: ["All", "Electronics", "Clothing", "Accessories"]
                  .map((String category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('lost_items').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                var items = snapshot.data!.docs.where((doc) {
                  return selectedCategory == "All" || doc['category'] == selectedCategory;
                }).toList();

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var item = items[index];

                    return Card(
                      child: ListTile(

                        leading: item['image_url'] != null
                            ? Builder(
                          builder: (context) {
                            print("Image URL: ${item['image_url']}"); // Debugging
                            return Image.network(
                              item['image_url'],
                              width: 100,
                              height: 100,
                              fit: BoxFit.fill,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print("❌ Failed to load image: $error");
                                return Icon(Icons.broken_image, size: 50, color: Colors.red);
                              },
                            );
                          },
                        )
                            : Icon(Icons.image),


                        title: Text(item['name']),
                        subtitle: Text("Color: ${item['color']}  |  Category: ${item['category']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editItem(context, item),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteItem(item.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LostItemSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () => query = "",
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, ""),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('lost_items').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        var results = snapshot.data!.docs.where((doc) {
          return doc['name'].toLowerCase().contains(query.toLowerCase()) ||
              doc['color'].toLowerCase().contains(query.toLowerCase()) ||
              doc['category'].toLowerCase().contains(query.toLowerCase());
        }).toList();

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            var item = results[index];
            return ListTile(
              title: Text(item['name']),
              subtitle: Text("Color: ${item['color']} | Category: ${item['category']}"),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
