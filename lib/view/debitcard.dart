// import 'package:dd_grab/view/simpleappbar.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class DebitCardPage extends StatelessWidget {
//   const DebitCardPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       bottomNavigationBar: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.black,
//               padding: const EdgeInsets.symmetric(vertical: 14),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             onPressed: () {},
//             child: Text(
//               'Pay ₹9,499.00 Securely',
//               style: GoogleFonts.poppins(color: Colors.white),
//             ),
//           ),
//         ),
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SimpleAppBar(), // <-- Added here
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Card Details",
//                     style: GoogleFonts.poppins(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     "Enter Card Details",
//                     style: GoogleFonts.poppins(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w300,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   _inputField("Name of Card Holder"),
//                   _inputField("Card Number"),
//                   Row(
//                     children: [
//                       Expanded(child: _inputField("CVV")),
//                       const SizedBox(width: 10),
//                       Expanded(child: _inputField("Expiry Date")),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _inputField(String label) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextField(
//         decoration: InputDecoration(
//           hintText: label,
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 14,
//             vertical: 14,
//           ),
//         ),
//       ),
//     );
//   }
// }
