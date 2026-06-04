import 'package:flutter/material.dart';
import 'post_buysell_screen.dart';
// import 'post_room_screen.dart';
// import 'post_job_screen.dart';

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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PostBuySellScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            _buildOptionCard(
              context,
              title: 'Rent Room',
              icon: Icons.home_work_outlined,
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => const PostRoomScreen(),
                //   ),
                // );
              },
            ),

            const SizedBox(height: 16),

            _buildOptionCard(
              context,
              title: 'Job Listing',
              icon: Icons.work_outline,
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => const PostJobScreen(),
                //   ),
                // );
              },
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
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios_rounded),
        onTap: onTap,
      ),
    );
  }
}