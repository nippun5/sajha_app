import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/business_model.dart';

class BusinessDetailPage extends StatefulWidget {
  final BusinessModel business;

  const BusinessDetailPage({
    super.key,
    required this.business,
  });

  @override
  State<BusinessDetailPage> createState() =>
      _BusinessDetailPageState();
}

class _BusinessDetailPageState
    extends State<BusinessDetailPage> {
  double userRating = 0;

   Future<void> _callBusiness(String phone) async {
  final Uri uri = Uri.parse('tel:$phone');

  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  } else {
    debugPrint('Could not launch call');
  }
}

  Future<void> _openWebsite() async {
    final Uri uri =
        Uri.parse('https://${widget.business.website}');

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _openMaps() async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.business.address)}',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final business = widget.business;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Details'),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              /// Cover Image
              Image.network(
                business.imageUrl,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
        
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    /// Name
                    Text(
                      business.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
        
                    const SizedBox(height: 8),
        
                    /// Rating
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
        
                        const SizedBox(width: 4),
        
                        Text(
                          '${business.rating}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
        
                        const SizedBox(width: 6),
        
                        Text(
                          '(${business.reviewCount} reviews)',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
        
                    const SizedBox(height: 12),
        
                    Chip(
                      label: Text(
                        business.category,
                      ),
                    ),
        
                    const SizedBox(height: 20),
        
                    /// Address
                    ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading: const Icon(
                        Icons.location_on,
                      ),
                      title: Text(
                        business.address,
                      ),
                      trailing: TextButton(
                        onPressed: _openMaps,
                        child: const Text(
                          'Directions',
                        ),
                      ),
                    ),
        
                    /// Phone
                    ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading: const Icon(
                        Icons.phone,
                      ),
                      title: Text(
                        business.phone,
                      ),
                      onTap:(){
                         _callBusiness(business.phone);
                      },
                    ),
        
                    /// Website
                    ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading: const Icon(
                        Icons.language,
                      ),
                      title: Text(
                        business.website,
                      ),
                      onTap: _openWebsite,
                    ),
        
                    const SizedBox(height: 24),
        
                    /// About
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
        
                    const SizedBox(height: 10),
        
                    Text(
                      business.description,
                      style: const TextStyle(
                        height: 1.5,
                      ),
                    ),
        
                    const SizedBox(height: 24),
        
                    /// Opening Hours
                    const Text(
                      'Opening Hours',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
        
                    const SizedBox(height: 12),
        
                    Container(
                      padding:
                          const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                      child: Column(
                        children: business
                            .openingHours.entries
                            .map(
                              (entry) => Padding(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        entry.key,
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        entry.value,
                                        textAlign:
                                            TextAlign
                                                .right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
        
                    const SizedBox(height: 24),
        
                    /// User Rating
                    const Text(
                      'Rate This Business',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
        
                    const SizedBox(height: 10),
        
                    Row(
                      children: List.generate(
                        5,
                        (index) => IconButton(
                          onPressed: () {
                            setState(() {
                              userRating =
                                  index + 1.0;
                            });
                          },
                          icon: Icon(
                            index < userRating
                                ? Icons.star
                                : Icons
                                    .star_border,
                            color:
                                Colors.amber,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
        
                    const SizedBox(height: 10),
        
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(
                                context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              'You rated ${userRating.toInt()} stars',
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Submit Review',
                      ),
                    ),
        
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}