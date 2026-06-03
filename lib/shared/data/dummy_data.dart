import 'package:sajha_app/models/product_model.dart';
import '/models/business_model.dart';
import '../../models/room_model.dart';
import '../../models/job_model.dart';

class DummyData {
  static List<ProductModel> buySellListings = [
  ProductModel(
    id: '1',

    title: 'iPhone 14 Pro Max',

    description: '256GB Deep Purple in excellent condition.',

    price: 950,

    category: 'Electronics',

    condition: ProductCondition.likeNew,

    imageUrls: [
      'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9',
    ],

    sellerName: 'John Doe',

    sellerId: 'seller_1',

    location: 'Sydney',

    isNegotiable: true,

    isAvailable: true,

    postedAt: DateTime.now(), 
    
    sellerPhone: '0412345678',

    
  ),

  ProductModel(
    id: '2',

    title: 'Gaming Laptop',

    description: 'RTX 4060 gaming laptop with 16GB RAM.',

    price: 1200,

    category: 'Electronics',

    condition: ProductCondition.good,

    imageUrls: [
      'https://images.unsplash.com/photo-1496181133206-80ce9b88a853',
    ],

    sellerName: 'Michael Smith',

    sellerId: 'seller_2',

    location: 'Melbourne',

    isNegotiable: false,

    isAvailable: true,

    postedAt: DateTime.now(),

    sellerPhone: '0412345678',
  ),
];

static List<RoomModel> roomListings = [
  RoomModel(
    id: '1',
    title: 'Modern Master Bedroom',
    weeklyRent: 320,
    imageUrl:
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85',
    suburb: 'Parramatta',
    state: 'NSW',
    postcode: '2150',
    bedrooms: 2,
    bathrooms: 1,
    furnished: true,
    description:
        'Fully furnished master bedroom near station and shops.',
    availableFrom: DateTime.now(),
    postedAt: DateTime.now(),
    landlordName: 'John Smith',
    amenities: [
      'WiFi',
      'Parking',
      'Air Conditioning',
    ],
    billsIncluded: true, 
    ownerName: 'John Doe', 
    ownerPhone: '+977 9843255977', 
    preferredGender: 'Male',
  ),

  RoomModel(
    id: '2',
    title: 'Shared Apartment Room',
    weeklyRent: 250,
    imageUrl:
        'https://images.unsplash.com/photo-1494526585095-c41746248156',
    suburb: 'Melbourne CBD',
    state: 'VIC',
    postcode: '3000',
    bedrooms: 3,
    bathrooms: 2,
    furnished: false,
    description:
        'Close to university and tram stop.',
    availableFrom: DateTime.now(),
    postedAt: DateTime.now(),
    landlordName: 'Sarah Lee',
    amenities: [
      'Gym',
      'Laundry',
    ],
    billsIncluded: false, 
    ownerName: 'Another Owner', 
    ownerPhone: '+1 9373999333',
    preferredGender: 'Female',
  ),
];

static List<JobModel> jobListings = [
  JobModel(
    id: '1',
    title: 'Flutter Developer',
    company: 'Sajha Tech',
    companyLogoUrl:
        'https://images.unsplash.com/photo-1549924231-f129b911e442',
    location: 'Sydney, NSW',
    salaryMin: 45,
    salaryMax: 60,
    salaryCycle: 'hourly',
    jobType: JobType.fullTime,
    description:
        'Looking for experienced Flutter developer for mobile app projects.',
    requirements: [
      'Flutter',
      'Firebase',
      'REST APIs',
    ],
    postedAt: DateTime.now(),
    isRemote: true,
    employerName: 'John Smith',
    employerPhone: '+19373999333',
  ),

  JobModel(
    id: '2',
    title: 'Delivery Driver',
    company: 'QuickMove',
    companyLogoUrl:
        'https://images.unsplash.com/photo-1504384308090-c894fdcc538d',
    location: 'Melbourne, VIC',
    salaryMin: 28,
    salaryMax: 35,
    salaryCycle: 'hourly',
    jobType: JobType.partTime,
    description:
        'Part-time delivery driver needed for local deliveries.',
    requirements: [
      'Valid License',
      'Own Vehicle',
    ],
    postedAt: DateTime.now(),
    isRemote: false,
    employerName: 'John Smith',
    employerPhone: '+19373999333',
  ),

  JobModel(
    id: '3',
    title: 'Marketing Intern',
    company: 'Creative Agency',
    companyLogoUrl:
        'https://images.unsplash.com/photo-1552664730-d307ca884978',
    location: 'Brisbane, QLD',
    salaryMin: 800,
    salaryMax: 1200,
    salaryCycle: 'monthly',
    jobType: JobType.internship,
    description:
        'Internship opportunity for social media marketing students.',
    requirements: [
      'Social Media Knowledge',
      'Communication Skills',
    ],
    postedAt: DateTime.now(),
    isRemote: true,
    employerName: 'John Smith',
    employerPhone: '+19373999333',
    
  ),
];

  static List<BusinessModel> businesses = [
 BusinessModel(
  id: '1',
  name: 'Everest Grocery',

  imageUrl:
      'https://images.unsplash.com/photo-1542838132-92c53300491e',

  description:
      'Nepali & Asian grocery store with fresh vegetables, spices and frozen foods.',

  address: '123 Main Street, Sydney NSW',

  phone: '+61 412 345 678',

  website: 'www.everestgrocery.com.au',

  category: 'Grocery Store',

  rating: 4.6,

  reviewCount: 125,

  openingHours: {
    'Monday': '8:00 AM - 8:00 PM',
    'Tuesday': '8:00 AM - 8:00 PM',
    'Wednesday': '8:00 AM - 8:00 PM',
    'Thursday': '8:00 AM - 8:00 PM',
    'Friday': '8:00 AM - 9:00 PM',
    'Saturday': '8:00 AM - 9:00 PM',
    'Sunday': '9:00 AM - 6:00 PM',
  }, 
),
BusinessModel(
  id: '2',
  name: 'Himalayan Cafe',

  imageUrl:
      'https://images.unsplash.com/photo-1555396273-367ea4eb4db5',

  description:
      'Authentic Nepali food and momo.',

  address: 'Melbourne, Australia',

  phone: '+61 412 345 678',

  website: 'www.himalayaneverest.com.au',

  category: 'Restaurent',

  rating: 4.9,

  reviewCount: 125,

  openingHours: {
    'Monday': '8:00 AM - 8:00 PM',
    'Tuesday': '8:00 AM - 8:00 PM',
    'Wednesday': '8:00 AM - 8:00 PM',
    'Thursday': '8:00 AM - 8:00 PM',
    'Friday': '8:00 AM - 9:00 PM',
    'Saturday': '8:00 AM - 9:00 PM',
    'Sunday': '9:00 AM - 6:00 PM',
  },
  
)
  ];
}