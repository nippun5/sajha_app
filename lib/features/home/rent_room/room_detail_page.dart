import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/room_model.dart';

class RoomDetailPage extends StatelessWidget {
  final RoomModel room;

  const RoomDetailPage({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room Image
            SizedBox(
              height: 250,
              width: double.infinity,
              child: room.imageUrl != null
                  ? Image.network(
                      room.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppColors.rentRoom.withOpacity(.1),
                      child: const Icon(
                        Icons.home_work_outlined,
                        size: 80,
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '\$${room.weeklyRent.toStringAsFixed(0)} / week',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.rentRoom,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(room.locationDisplay),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _FeatureItem(
                        icon: Icons.bed_outlined,
                        label: '${room.bedrooms} Beds',
                      ),
                      _FeatureItem(
                        icon: Icons.bathtub_outlined,
                        label: '${room.bathrooms} Baths',
                      ),
                      _FeatureItem(
                        icon: Icons.weekend_outlined,
                        label:
                            room.furnished ? 'Furnished' : 'Unfurnished',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(room.description),

                  const SizedBox(height: 24),

                  const Text(
                    'Amenities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: room.amenities
                        .map(
                          (e) => Chip(label: Text(e)),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Owner Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(room.ownerName),
                    subtitle: Text(room.ownerPhone),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.message_outlined),
                      label: const Text('Message Owner'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 6),
        Text(label),
      ],
    );
  }
}