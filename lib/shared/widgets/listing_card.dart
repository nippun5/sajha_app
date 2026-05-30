import 'package:flutter/material.dart';
import 'package:sajha_app/models/product_model.dart';



class ListingCard extends StatelessWidget {
  // Change the type here from ListingModel to ProductModel
  final ProductModel listing; 
  final VoidCallback onTap;

  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Column(
          children: [
            // Since imageUrls is a List<String> in ProductModel, 
            // make sure you pull the first image out safely:
            if (listing.imageUrls.isNotEmpty)
              Image.network(listing.imageUrls.first)
            else
              const Placeholder(),
              
            Text(listing.title),
            Text('\$${listing.price}'),
          ],
        ),
      ),
    );
  }
}