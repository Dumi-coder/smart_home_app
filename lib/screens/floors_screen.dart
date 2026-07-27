import '../services/seed_data.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'floor_detail_screen.dart';

class FloorsScreen extends StatelessWidget {
  FloorsScreen({super.key});

  final FirestoreService _service = FirestoreService();

  void _addFloorDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Floor'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Floor name (e.g. Ground Floor)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _service.addFloor(name: controller.text.trim());
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Smart Home Monitor')),
      appBar: AppBar(
        title: const Text('Smart Home Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Seed sample data',
            onPressed: () async {
              await SeedData.seedDatabase();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sample data seeded!')),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.streamFloors(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final floors = snapshot.data!.docs;
          if (floors.isEmpty) {
            return const Center(
              child: Text('No floors yet. Tap + to add one.'),
            );
          }
          return ListView.builder(
            itemCount: floors.length,
            itemBuilder: (context, index) {
              final doc = floors[index];
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.layers),
                title: Text(data['name'] ?? 'Unnamed Floor'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FloorDetailScreen(
                        floorId: doc.id,
                        floorName: data['name'] ?? 'Unnamed Floor',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addFloorDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}