import 'package:flutter/material.dart';
import 'package:sajha_app/features/post_listing/post_job_screen.dart';
import 'package:sajha_app/features/post_listing/post_rent_room_screen.dart';
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
                  Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PostRentRoomScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            _buildOptionCard(
              context,
              title: 'Job Listing',
              icon: Icons.work_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PostJobScreen(),
                  ),
                );
              },
            ),
              const SizedBox(height: 16),
Stack(
  clipBehavior: Clip.none,
  children: [
    Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), 
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withAlpha(45),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: _buildOptionCard(
        context,
        title: 'Business Directory',
        icon: Icons.business,
        onTap: () {
          // Navigator.push(...);
        },
      ),
    ),
    Positioned(
      top: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const BoxDecoration(
          color: Color(0xFFFFD700), 
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(12), 
            bottomLeft: Radius.circular(8),
          ),
        ),
        child: const Text(
          'PRO',
          style: TextStyle(
            color: Colors.black,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    ),
  ],
) 
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