// import 'package:flutter/material.dart';
// // import 'package:jaket_mobile/app_module/data/model/service_entry.dart';

// // Reusable Star Rating Widget
// class StarRating extends StatelessWidget {
//   final double rating;
//   final double size;
//   final Color color;

//   const StarRating({
//     Key? key,
//     required this.rating,
//     this.size = 16.0,
//     this.color = Colors.amber,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     int fullStars = rating.floor();
//     int halfStar = (rating % 1 >= 0.5) ? 1 : 0;
//     int emptyStars = 5 - fullStars - halfStar;

//     List<Widget> stars = [];
//     for (int i = 0; i < fullStars; i++) {
//       stars.add(Icon(Icons.star, color: color, size: size));
//     }
//     if (halfStar == 1) {
//       stars.add(Icon(Icons.star_half, color: color, size: size));
//     }
//     for (int i = 0; i < emptyStars; i++) {
//       stars.add(Icon(Icons.star_border, color: color, size: size));
//     }
//     return Row(mainAxisSize: MainAxisSize.min, children: stars);
//   }
// }

// // Function to filter and sort service centers
// List<ServiceCenter> filterAndSortData({
//   required List<ServiceCenter> data,
//   required String query,
//   required String selectedSortOption,
// }) {
//   List<ServiceCenter> filtered = data.where((product) {
//     return product.fields.name.toLowerCase().contains(query);
//   }).toList();

//   switch (selectedSortOption) {
//     case 'Alphabetical\n(A-Z)':
//       filtered.sort((a, b) => a.fields.name.compareTo(b.fields.name));
//       break;
//     case 'Alphabetical\n(Z-A)':
//       filtered.sort((a, b) => b.fields.name.compareTo(a.fields.name));
//       break;
//     case 'Best\nRating':
//       filtered.sort((a, b) =>
//           double.parse(b.fields.rating).compareTo(double.parse(a.fields.rating)));
//       break;
//     case 'Most\nReviews':
//       filtered.sort((a, b) =>
//           b.fields.totalReviews.compareTo(a.fields.totalReviews));
//       break;
//     default:
//       break;
//   }

//   return filtered;
// }

// // Function to build dropdown menu items
// List<DropdownMenuItem<String>> buildDropdownItems({
//   required List<String> sortOptions,
// }) {
//   return sortOptions.map((option) {
//     if (option.contains('\n')) {
//       final lines = option.split('\n');
//       return DropdownMenuItem<String>(
//         value: option,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: lines.map((line) {
//             return Text(
//               line,
//               textAlign: TextAlign.center,
//               softWrap: true,
//               style: const TextStyle(fontSize: 10.0, color: Colors.white),
//             );
//           }).toList(),
//         ),
//       );
//     } else {
//       return DropdownMenuItem<String>(
//         value: option,
//         child: Text(
//           option,
//           textAlign: TextAlign.center,
//           softWrap: true,
//           style: const TextStyle(fontSize: 12.0, color: Colors.white),
//         ),
//       );
//     }
//   }).toList();
// }
