import 'package:flutter/material.dart';

class PostListingScreen extends StatelessWidget {
  const PostListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Listing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildOptionCard(
              context,
              title: 'Buy / Sell',
              icon: Icons.shopping_bag_outlined,
            ),

            const SizedBox(height: 16),

            _buildOptionCard(
              context,
              title: 'Rent Room',
              icon: Icons.home_work_outlined,
            ),

            const SizedBox(height: 16),

            _buildOptionCard(
              context,
              title: 'Job Listing',
              icon: Icons.work_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios_rounded),
        onTap: () {},
      ),
    );
  }
}