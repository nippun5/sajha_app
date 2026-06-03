import 'package:flutter/material.dart';
import 'package:sajha_app/business_directory/business_detail_page.dart';
import 'package:sajha_app/shared/data/dummy_data.dart';


class BusinessDirectoryScreen extends StatelessWidget {
  const BusinessDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final businesses = DummyData.businesses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Directory'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: businesses.length,
        itemBuilder: (context, index) {
          final business = businesses[index];

          return InkWell(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessDetailPage(
          business: business,
        ),
      ),
    );
  },
         child:  Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Image.network(
                  business.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(business.description),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                          ),

                          const SizedBox(width: 6),

                          Text(business.address),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ));
        },
      ),
    );
  }
}