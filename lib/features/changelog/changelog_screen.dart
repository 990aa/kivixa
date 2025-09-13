import 'package:flutter/material.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Changelog')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: const [
          Text(
            'What’s New',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.star, color: Colors.amber),
            title: Text('Brand new onboarding experience'),
          ),
          ListTile(
            leading: Icon(Icons.bolt, color: Colors.blue),
            title: Text('Performance improvements and bug fixes'),
          ),
          ListTile(
            leading: Icon(Icons.palette, color: Colors.purple),
            title: Text('Material 3 visual polish'),
          ),
          ListTile(
            leading: Icon(Icons.security, color: Colors.green),
            title: Text('Enhanced offline support'),
          ),
        ],
      ),
    );
  }
}
