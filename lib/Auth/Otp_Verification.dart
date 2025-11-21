// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:yoga/navBar/bottom_navbar.dart';
// import 'package:yoga/utils/Button.dart';
// import 'package:yoga/utils/app_assests.dart';
// import 'package:yoga/utils/colors.dart';
// import 'package:yoga/utils/snacbar_message.dart';

// class MobileOTPScreen extends StatefulWidget {
//   final String phoneNumber;
//   final String email;
//   final String userId;

//   const MobileOTPScreen({
//     Key? key,
//     required this.phoneNumber,
//     required this.email,
//     required this.userId,
//   }) : super(key: key);

//   @override
//   State<MobileOTPScreen> createState() => _MobileOTPScreenState();
// }

// class _MobileOTPScreenState extends State<MobileOTPScreen> {
//   final List<TextEditingController> _otpControllers = List.generate(
//     6,
//     (index) => TextEditingController(),
//   );

//   bool _isLoading = false;
//   bool _isResending = false;
//   bool _isTestMode = false;
//   String _testOTP = "123456";
//   final supabase = Supabase.instance.client;

//   @override
//   void initState() {
//     super.initState();
//     _checkIfNumberExists();
//     print('\n🔐 ========== OTP SCREEN OPENED ==========');
//     print('📱 Phone: ${widget.phoneNumber}');
//     print('📧 Email: ${widget.email}');
//     print('🆔 User ID: ${widget.userId}');
//     print('=========================================\n');
//   }

//   // IMPROVED: Check if phone number exists in database
//   Future<void> _checkIfNumberExists() async {
//     try {
//       print('\n🔍 ========== CHECKING NUMBER IN DATABASE ==========');
//       print('📱 Searching for: ${widget.phoneNumber}');

//       // Try multiple queries to find the number
//       var response =
//           await supabase
//               .from('Users')
//               .select('id, mobile_number')
//               .eq('mobile_number', widget.phoneNumber)
//               .maybeSingle();

//       // If not found, also try without country code
//       if (response == null && widget.phoneNumber.startsWith('+91')) {
//         String numberWithoutCode = widget.phoneNumber.substring(3);
//         print('🔍 Also trying without country code: $numberWithoutCode');

//         response =
//             await supabase
//                 .from('Users')
//                 .select('id, mobile_number')
//                 .eq('mobile_number', numberWithoutCode)
//                 .maybeSingle();
//       }

//       // Check if user exists by ID
//       if (response == null) {
//         print('🔍 Checking by User ID: ${widget.userId}');
//         response =
//             await supabase
//                 .from('Users')
//                 .select('id, mobile_number')
//                 .eq('id', widget.userId)
//                 .maybeSingle();
//       }

//       if (response != null) {
//         setState(() {
//           _isTestMode = true;
//         });
//         print('✅ USER FOUND IN DATABASE!');
//         print('📱 Stored number: ${response['mobile_number']}');
//         print('🧪 TEST MODE ENABLED - Use OTP: $_testOTP');

//         // Show snackbar after build
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           showSnackBar(context, "🧪 Test Mode: Use OTP $_testOTP");
//         });
//       } else {
//         setState(() {
//           _isTestMode = false;
//         });
//         print('❌ User NOT found in database');
//         print('📲 Real OTP will be sent');
//       }
//       print('=============================================\n');
//     } catch (e) {
//       print('⚠️ Error checking number: $e');
//       // Default to test mode on error for better UX
//       setState(() {
//         _isTestMode = true;
//       });
//       print('⚠️ Defaulting to TEST MODE due to error');
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         showSnackBar(context, "🧪 Test Mode: Use OTP $_testOTP");
//       });
//     }
//   }
//   Future<void> _verifyOTP() async {
//   String otp = _otpControllers.map((e) => e.text).join();

//   if (otp.length != 6) {
//     showSnackBar(context, "Please enter 6-digit OTP");
//     return;
//   }

//   print('\n🔍 ========== VERIFYING OTP ==========');
//   print('📱 Entered OTP: $otp');
//   print('📱 Phone: ${widget.phoneNumber}');
//   print('🧪 Test Mode: Any OTP will work');

//   setState(() {
//     _isLoading = true;
//   });

//   // Simulate verification delay
//   await Future.delayed(Duration(milliseconds: 500));

//   print('✅ OTP Accepted (Testing Mode)');

//   // ONLY UPDATE verification status (data already exists!)
//   try {
//     final updateResult = await supabase
//         .from('Users')
//         .update({
//           'phone_verified': true,
//           'email_verified': true,
//           'updated_at': DateTime.now().toIso8601String(),
//         })
//         .eq('id', widget.userId)
//         .select();

//     print('✅ Verification status updated in database');
//     print('📊 Updated record: $updateResult');
//   } catch (e) {
//     print('⚠️ Could not update verification status: $e');
//     // Continue anyway since data is already saved
//   }

//   setState(() {
//     _isLoading = false;
//   });

//   print('🎉 Verification completed!');
//   print('=====================================\n');

//   // Show success and navigate
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     isDismissible: false,
//     builder: (context) => const _OtpSuccessSheet(),
//   );
// }

//   // Resend OTP
//   Future<void> _resendOTP() async {
//     setState(() {
//       _isResending = true;
//     });

//     print('\n🔄 ========== RESENDING OTP ==========');

//     // If test mode, just show the static OTP again
//     if (_isTestMode) {
//       await Future.delayed(Duration(seconds: 1));
//       setState(() {
//         _isResending = false;
//       });
//       print('🧪 TEST MODE - OTP: $_testOTP');
//       showSnackBar(context, "🧪 Test OTP: $_testOTP");
//       print('=====================================\n');
//       return;
//     }

//     try {
//       // Resend to phone
//       await supabase.auth.signInWithOtp(phone: widget.phoneNumber);
//       print('📲 Mobile OTP resent to ${widget.phoneNumber}');

//       // Also resend to email
//       await supabase.auth.signInWithOtp(email: widget.email);
//       print('📧 Email OTP resent to ${widget.email}');

//       setState(() {
//         _isResending = false;
//       });

//       print('✅ OTP resent successfully!');
//       print('=====================================\n');

//       showSnackBar(context, "OTP resent successfully!");
//     } catch (e) {
//       setState(() {
//         _isResending = false;
//       });
//       print('❌ Resend failed: $e');
//       print('💡 Switching to TEST MODE');

//       // Switch to test mode if resend fails
//       setState(() {
//         _isTestMode = true;
//       });
//       showSnackBar(context, "🧪 Using Test OTP: $_testOTP");
//       print('=====================================\n');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFD6ECB4),
//       body: SafeArea(
//         child: Column(
//           children: [
//             const SizedBox(height: 20),

//             Padding(
//               padding: const EdgeInsets.only(left: 25),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Image.asset(AppAssets.yogaGirl, height: 60),
//               ),
//             ),

//             const SizedBox(height: 20),

//             Padding(
//               padding: const EdgeInsets.only(left: 25),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   "OTP Verification",
//                   style: TextStyle(
//                     fontSize: 28,
//                     color: Colors.black,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 6),

//             Padding(
//               padding: const EdgeInsets.only(left: 25, right: 25),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "OTP sent to:",
//                       style: TextStyle(fontSize: 14, color: Colors.black87),
//                     ),
//                     Text(
//                       "📱 ${widget.phoneNumber}",
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.black,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       "📧 ${widget.email}",
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.black,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     // Show test mode indicator
//                     if (_isTestMode)
//                       Container(
//                         margin: const EdgeInsets.only(top: 10),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.orange.shade100,
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(color: Colors.orange, width: 1),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(Icons.science, size: 16, color: Colors.orange),
//                             SizedBox(width: 5),
//                             Text(
//                               "🧪 TEST MODE - OTP: $_testOTP",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.orange.shade900,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 40),

//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(25),
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(25),
//                     topRight: Radius.circular(25),
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Container(
//                       color: Colors.grey.shade50,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: List.generate(6, (index) {
//                           return SizedBox(
//                             width: 45,
//                             child: Padding(
//                               padding: const EdgeInsets.only(
//                                 top: 8.0,
//                                 bottom: 8.0,
//                               ),
//                               child: TextField(
//                                 controller: _otpControllers[index],
//                                 maxLength: 1,
//                                 keyboardType: TextInputType.number,
//                                 textAlign: TextAlign.center,
//                                 style: const TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                                 decoration: InputDecoration(
//                                   counterText: "",
//                                   filled: true,
//                                   fillColor: Colors.white,
//                                   enabledBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide: BorderSide(
//                                       color: Colors.grey.shade400,
//                                       width: 1,
//                                     ),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide: BorderSide(
//                                       color: AppColors.primary,
//                                       width: 2,
//                                     ),
//                                   ),
//                                 ),
//                                 onChanged: (value) {
//                                   if (value.isNotEmpty && index < 5) {
//                                     FocusScope.of(context).nextFocus();
//                                   } else if (value.isEmpty && index > 0) {
//                                     FocusScope.of(context).previousFocus();
//                                   }
//                                 },
//                               ),
//                             ),
//                           );
//                         }),
//                       ),
//                     ),

//                     const SizedBox(height: 40),

//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFD6ECB4),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         onPressed: _isLoading ? null : _verifyOTP,
//                         child:
//                             _isLoading
//                                 ? const SizedBox(
//                                   height: 20,
//                                   width: 20,
//                                   child: CircularProgressIndicator(
//                                     color: Colors.black,
//                                     strokeWidth: 2,
//                                   ),
//                                 )
//                                 : const Text(
//                                   "Verify",
//                                   style: TextStyle(
//                                     color: Colors.black,
//                                     fontSize: 18,
//                                   ),
//                                 ),
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Text("Didn't get the OTP? "),
//                         GestureDetector(
//                           onTap: _isResending ? null : _resendOTP,
//                           child:
//                               _isResending
//                                   ? const SizedBox(
//                                     height: 14,
//                                     width: 14,
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 2,
//                                       color: Colors.green,
//                                     ),
//                                   )
//                                   : const Text(
//                                     "Resend OTP",
//                                     style: TextStyle(
//                                       color: Colors.green,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     for (var controller in _otpControllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }
// }

// class _OtpSuccessSheet extends StatelessWidget {
//   const _OtpSuccessSheet({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(25),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(25),
//           topRight: Radius.circular(25),
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const SizedBox(height: 20),

//           Container(
//             padding: const EdgeInsets.all(15),
//             decoration: const BoxDecoration(
//               color: Color(0xFF4CAF50),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.check, color: Colors.white, size: 40),
//           ),

//           const SizedBox(height: 20),

//           const Text(
//             "Congratulations!",
//             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//           ),

//           const SizedBox(height: 5),

//           const Text(
//             "You have completed your registration.",
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.black54,
//               fontWeight: FontWeight.w600,
//             ),
//           ),

//           const SizedBox(height: 30),

//           CommonButton(
//             text: "Let's Start",
//             onTap: () {
//               Navigator.pushAndRemoveUntil(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => MainNavbar(),
//                 ), // Replace with your home screen
//                 (route) => false,
//               );
//             },
//           ),

//           const SizedBox(height: 25),
//         ],
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:yoga/Auth/Registration_Screen.dart';
// import 'package:yoga/navBar/bottom_navbar.dart';
// import 'package:yoga/utils/Button.dart';
// import 'package:yoga/utils/app_assests.dart';
// import 'package:yoga/utils/colors.dart';
// import 'package:yoga/utils/snacbar_message.dart';

// class MobileOTPScreen extends StatefulWidget {
//   final String phoneNumber;
//   final String email;
//   final String userId;

//   const MobileOTPScreen({
//     Key? key,
//     required this.phoneNumber,
//     required this.email,
//     required this.userId,
//   }) : super(key: key);

//   @override
//   State<MobileOTPScreen> createState() => _MobileOTPScreenState();
// }

// class _MobileOTPScreenState extends State<MobileOTPScreen> {
//   final List<TextEditingController> _otpControllers = List.generate(
//     6,
//     (index) => TextEditingController(),
//   );

//   bool _isLoading = false;
//   bool _isResending = false;
//   String? _generatedOTP; // Store OTP for testing display
//   final supabase = Supabase.instance.client;

//   @override
//   void initState() {
//     super.initState();
//     _sendOTP();
//     print('\n🔐 ========== OTP SCREEN OPENED ==========');
//     print('📱 Phone: ${widget.phoneNumber}');
//     print('📧 Email: ${widget.email}');
//     print('🆔 User ID: ${widget.userId}');
//     print('=========================================\n');
//   }

//   // 📲 Send OTP using database
//   Future<void> _sendOTP() async {
//     try {
//       print('\n📲 ========== SENDING OTP ==========');

//       final result = await OTPService.sendOTP(widget.phoneNumber);

//       if (result['success']) {
//         setState(() {
//           _generatedOTP = result['otp']; // Store for display
//         });

//         print('✅ OTP sent successfully!');
//         print('🔢 OTP: ${result['otp']}'); // For testing
//         print('====================================\n');

//         // Show OTP in snackbar for testing
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           showSnackBar(context, "🧪 Test OTP: ${result['otp']}");
//         });
//       } else {
//         print('❌ Failed to send OTP: ${result['error']}');
//         showSnackBar(context, result['error'] ?? 'Failed to send OTP');
//       }
//     } catch (e) {
//       print('❌ Error sending OTP: $e');
//       showSnackBar(context, 'Failed to send OTP');
//     }
//   }

//   // ✅ Verify OTP using database
//   Future<void> _verifyOTP() async {
//     String otp = _otpControllers.map((e) => e.text).join();

//     if (otp.length != 6) {
//       showSnackBar(context, "Please enter 6-digit OTP");
//       return;
//     }

//     print('\n🔍 ========== VERIFYING OTP ==========');
//     print('📱 Entered OTP: $otp');
//     print('📱 Phone: ${widget.phoneNumber}');

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Verify OTP using database
//       final result = await OTPService.verifyOTP(widget.phoneNumber, otp);

//       if (result['success']) {
//         print('✅ OTP Verified Successfully!');

//         // Update verification status in Users table
//         try {
//           final updateResult = await supabase
//               .from('Users')
//               .update({
//                 'phone_verified': true,
//                 'email_verified': true,
//                 'updated_at': DateTime.now().toIso8601String(),
//               })
//               .eq('id', widget.userId)
//               .select();

//           print('✅ Verification status updated in database');
//           print('📊 Updated record: $updateResult');
//         } catch (e) {
//           print('⚠️ Could not update verification status: $e');
//           // Continue anyway
//         }

//         setState(() {
//           _isLoading = false;
//         });

//         print('🎉 Verification completed!');
//         print('=====================================\n');

//         // Show success modal
//         showModalBottomSheet(
//           context: context,
//           isScrollControlled: true,
//           backgroundColor: Colors.transparent,
//           isDismissible: false,
//           builder: (context) => const _OtpSuccessSheet(),
//         );
//       } else {
//         setState(() {
//           _isLoading = false;
//         });

//         print('❌ OTP Verification Failed: ${result['error']}');
//         print('=====================================\n');

//         showSnackBar(context, result['error'] ?? 'Invalid OTP');
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });

//       print('❌ Error verifying OTP: $e');
//       print('=====================================\n');

//       showSnackBar(context, 'Verification failed. Please try again.');
//     }
//   }

//   // 🔄 Resend OTP
//   Future<void> _resendOTP() async {
//     setState(() {
//       _isResending = true;
//     });

//     print('\n🔄 ========== RESENDING OTP ==========');

//     try {
//       final result = await OTPService.resendOTP(widget.phoneNumber);

//       setState(() {
//         _isResending = false;
//       });

//       if (result['success']) {
//         setState(() {
//           _generatedOTP = result['otp']; // Update displayed OTP
//         });

//         // Clear OTP fields
//         for (var controller in _otpControllers) {
//           controller.clear();
//         }

//         print('✅ OTP resent successfully!');
//         print('🔢 New OTP: ${result['otp']}'); // For testing
//         print('=====================================\n');

//         showSnackBar(context, "🧪 New OTP: ${result['otp']}");
//       } else {
//         print('❌ Resend failed: ${result['error']}');
//         print('=====================================\n');

//         showSnackBar(context, result['error'] ?? 'Failed to resend OTP');
//       }
//     } catch (e) {
//       setState(() {
//         _isResending = false;
//       });

//       print('❌ Error resending OTP: $e');
//       print('=====================================\n');

//       showSnackBar(context, 'Failed to resend OTP');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFD6ECB4),
//       body: SafeArea(
//         child: Column(
//           children: [
//             const SizedBox(height: 20),

//             Padding(
//               padding: const EdgeInsets.only(left: 25),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Image.asset(AppAssets.yogaGirl, height: 60),
//               ),
//             ),

//             const SizedBox(height: 20),

//             Padding(
//               padding: const EdgeInsets.only(left: 25),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   "OTP Verification",
//                   style: TextStyle(
//                     fontSize: 28,
//                     color: Colors.black,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 6),

//             Padding(
//               padding: const EdgeInsets.only(left: 25, right: 25),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "OTP sent to:",
//                       style: TextStyle(fontSize: 14, color: Colors.black87),
//                     ),
//                     Text(
//                       "📱 ${widget.phoneNumber}",
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.black,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       "📧 ${widget.email}",
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.black,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     // 🔥 Show generated OTP for testing
//                     if (_generatedOTP != null)
//                       Container(
//                         margin: const EdgeInsets.only(top: 10),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 8,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.orange.shade100,
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(color: Colors.orange, width: 2),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(Icons.science, size: 18, color: Colors.orange),
//                             SizedBox(width: 8),
//                             Text(
//                               "🧪 TEST OTP: $_generatedOTP",
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 color: Colors.orange.shade900,
//                                 fontWeight: FontWeight.bold,
//                                 letterSpacing: 1,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 40),

//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(25),
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(25),
//                     topRight: Radius.circular(25),
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Container(
//                       color: Colors.grey.shade50,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: List.generate(6, (index) {
//                           return SizedBox(
//                             width: 45,
//                             child: Padding(
//                               padding: const EdgeInsets.only(
//                                 top: 8.0,
//                                 bottom: 8.0,
//                               ),
//                               child: TextField(
//                                 controller: _otpControllers[index],
//                                 maxLength: 1,
//                                 keyboardType: TextInputType.number,
//                                 textAlign: TextAlign.center,
//                                 style: const TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                                 decoration: InputDecoration(
//                                   counterText: "",
//                                   filled: true,
//                                   fillColor: Colors.white,
//                                   enabledBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide: BorderSide(
//                                       color: Colors.grey.shade400,
//                                       width: 1,
//                                     ),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide: BorderSide(
//                                       color: AppColors.primary,
//                                       width: 2,
//                                     ),
//                                   ),
//                                 ),
//                                 onChanged: (value) {
//                                   if (value.isNotEmpty && index < 5) {
//                                     FocusScope.of(context).nextFocus();
//                                   } else if (value.isEmpty && index > 0) {
//                                     FocusScope.of(context).previousFocus();
//                                   }
//                                 },
//                               ),
//                             ),
//                           );
//                         }),
//                       ),
//                     ),

//                     const SizedBox(height: 40),

//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFD6ECB4),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         onPressed: _isLoading ? null : _verifyOTP,
//                         child: _isLoading
//                             ? const SizedBox(
//                                 height: 20,
//                                 width: 20,
//                                 child: CircularProgressIndicator(
//                                   color: Colors.black,
//                                   strokeWidth: 2,
//                                 ),
//                               )
//                             : const Text(
//                                 "Verify",
//                                 style: TextStyle(
//                                   color: Colors.black,
//                                   fontSize: 18,
//                                 ),
//                               ),
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Text("Didn't get the OTP? "),
//                         GestureDetector(
//                           onTap: _isResending ? null : _resendOTP,
//                           child: _isResending
//                               ? const SizedBox(
//                                   height: 14,
//                                   width: 14,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2,
//                                     color: Colors.green,
//                                   ),
//                                 )
//                               : const Text(
//                                   "Resend OTP",
//                                   style: TextStyle(
//                                     color: Colors.green,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     for (var controller in _otpControllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }
// }

// class _OtpSuccessSheet extends StatelessWidget {
//   const _OtpSuccessSheet({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(25),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(25),
//           topRight: Radius.circular(25),
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const SizedBox(height: 20),

//           Container(
//             padding: const EdgeInsets.all(15),
//             decoration: const BoxDecoration(
//               color: Color(0xFF4CAF50),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.check, color: Colors.white, size: 40),
//           ),

//           const SizedBox(height: 20),

//           const Text(
//             "Congratulations!",
//             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//           ),

//           const SizedBox(height: 5),

//           const Text(
//             "You have completed your registration.",
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.black54,
//               fontWeight: FontWeight.w600,
//             ),
//           ),

//           const SizedBox(height: 30),

//           CommonButton(
//             text: "Let's Start",
//             onTap: () {
//               Navigator.pushAndRemoveUntil(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => MainNavbar(),
//                 ),
//                 (route) => false,
//               );
//             },
//           ),

//           const SizedBox(height: 25),
//         ],
//       ),
//     );
//   }
// }
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yoga/Auth/Registration_Screen.dart';
import 'package:yoga/navBar/bottom_navbar.dart';
import 'package:yoga/utils/Button.dart';
import 'package:yoga/utils/app_assests.dart';
import 'package:yoga/utils/colors.dart';
import 'package:yoga/utils/snacbar_message.dart';

class MobileOTPScreen extends StatefulWidget {
  final String phoneNumber;
  final String? email;
  final String? userId; // optional
  final String? name;
  final String? password; // encrypted password
  final bool isRegistration;
  final String? localOtp; // NEW: local otp passed from registration

  const MobileOTPScreen({
    Key? key,
    required this.phoneNumber,
    this.email,
    this.userId,
    this.name,
    this.password,
    this.isRegistration = false,
    this.localOtp,
  }) : super(key: key);

  @override
  State<MobileOTPScreen> createState() => _MobileOTPScreenState();
}

class _MobileOTPScreenState extends State<MobileOTPScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  bool _isLoading = false;
  bool _isResending = false;
  String? _generatedOTP; // show OTP in UI for testing
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    // If local OTP was passed from registration, use it (testing)
    if (widget.localOtp != null && widget.localOtp!.isNotEmpty) {
      _generatedOTP = widget.localOtp!;
      // show test OTP in snackbar after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showSnackBar(context, "🧪 Test OTP: $_generatedOTP");
      });
    } else {
      // fallback: generate a local OTP here (shouldn't generally happen)
      _generatedOTP = _generateLocalOTP();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showSnackBar(context, "🧪 Test OTP: $_generatedOTP");
      });
    }

    print('\n🔐 ========== OTP SCREEN OPENED ==========');
    print('📱 Phone: ${widget.phoneNumber}');
    print('📧 Email: ${widget.email ?? "Not provided"}');
    print('🆔 User ID: ${widget.userId ?? "Will be generated"}');
    print('🔄 Is Registration: ${widget.isRegistration}');
    print('🔢 OTP (dev): $_generatedOTP');
    print('=========================================\n');
  }

  String _generateLocalOTP() {
    final rnd = DateTime.now().millisecondsSinceEpoch % 900000;
    final code = 100000 + (rnd % 900000);
    return code.toString().padLeft(6, '0');
  }

  Future<void> _verifyOTP() async {
    String otp = _otpControllers.map((e) => e.text).join();

    if (otp.length != 6) {
      showSnackBar(context, "Please enter 6-digit OTP");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // If using local OTP flow: compare with _generatedOTP
      if (_generatedOTP != null) {
        if (otp == _generatedOTP) {
          // Correct OTP
          if (widget.isRegistration) {
            await _completeRegistration();
          } else {
            await _completeVerification();
          }
          return;
        } else {
          setState(() => _isLoading = false);
          showSnackBar(context, "Invalid OTP");
          return;
        }
      } else {
        // Safety fallback: invalid state
        setState(() => _isLoading = false);
        showSnackBar(context, "OTP not available. Please resend.");
        return;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Error verifying OTP locally: $e');
      showSnackBar(context, 'Verification failed. Please try again.');
    }
  }

  Future<void> _completeRegistration() async {
    try {
      print('🔍 Completing registration after OTP verification...');
      print('📱 Phone: ${widget.phoneNumber}');
      print('👤 Name: ${widget.name}');
      print('📧 Email: ${widget.email ?? "Not provided"}');

      // Generate unique user ID
      // String userId = DateTime.now().millisecondsSinceEpoch.toString();
      final fcmToken = await FirebaseMessaging.instance.getToken();
      // Insert into Users table
      await supabase.from('Users').insert({
        'id': widget.userId,
        'email': widget.email?.isNotEmpty == true ? widget.email : null,
        'name': widget.name,
        'mobile_number': widget.phoneNumber,
        'fcm_token': fcmToken,
        'password': widget.password, // encrypted password
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ User Profile Saved in Database!');

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', widget.userId.toString());
      if (widget.name != null) await prefs.setString('name', widget.name!);
      if (widget.email != null && widget.email!.isNotEmpty) {
        await prefs.setString('email', widget.email!);
      }
      await prefs.setString('mobile_number', widget.phoneNumber);
      await prefs.setBool('is_logged_in', true);

      setState(() {
        _isLoading = false;
      });

      print('🎉 REGISTRATION COMPLETE!');
      print('=====================================\n');

      // Navigate to app / show success sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        builder: (context) => const _OtpSuccessSheet(),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Error completing registration: $e');
      showSnackBar(context, 'Registration failed. Please try again.');
    }
  }

  Future<void> _completeVerification() async {
    try {
      // In your flow, update verification flag for existing user
      final updateResult =
          await supabase
              .from('Users')
              .update({'updated_at': DateTime.now().toIso8601String()})
              .eq('id', widget.userId.toString())
              .select();

      print('✅ Verification status updated in database');
      print('📊 Updated record: $updateResult');

      setState(() {
        _isLoading = false;
      });

      // success sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        builder: (context) => const _OtpSuccessSheet(),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('⚠️ Could not update verification status: $e');
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        builder: (context) => const _OtpSuccessSheet(),
      );
    }
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isResending = true;
    });

    try {
      // For local OTP flow, generate new OTP and show it
      setState(() {
        _generatedOTP = _generateLocalOTP();
        _isResending = false;
      });

      // Clear OTP fields
      for (var controller in _otpControllers) {
        controller.clear();
      }

      print('✅ OTP resent (local). New OTP: $_generatedOTP');
      showSnackBar(context, "🧪 New OTP: $_generatedOTP");
    } catch (e) {
      setState(() {
        _isResending = false;
      });
      print('❌ Error resending OTP: $e');
      showSnackBar(context, 'Failed to resend OTP');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6ECB4),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.only(left: 25),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(AppAssets.yogaGirl, height: 60),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.only(left: 25),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "OTP Verification",
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "OTP sent to:",
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    Text(
                      "📱 ${widget.phoneNumber}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.email != null && widget.email!.isNotEmpty)
                      Text(
                        "📧 ${widget.email}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    // show generated OTP for testing
                    if (_generatedOTP != null)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.science, size: 18, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              "🧪 TEST OTP: $_generatedOTP",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      color: Colors.grey.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 45,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                bottom: 8.0,
                              ),
                              child: TextField(
                                controller: _otpControllers[index],
                                maxLength: 1,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  counterText: "",
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade400,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    if (index < 5) {
                                      FocusScope.of(context).nextFocus();
                                    } else {
                                      FocusScope.of(context).unfocus();
                                    }
                                  } else {
                                    if (index > 0) {
                                      FocusScope.of(context).previousFocus();
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD6ECB4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _verifyOTP,
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  "Verify",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                  ),
                                ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Didn't get the OTP? "),
                        GestureDetector(
                          onTap: _isResending ? null : _resendOTP,
                          child:
                              _isResending
                                  ? const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.green,
                                    ),
                                  )
                                  : const Text(
                                    "Resend OTP",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:yoga/Auth/Registration_Screen.dart';
// import 'package:yoga/navBar/bottom_navbar.dart';
// import 'package:yoga/utils/Button.dart';
// import 'package:yoga/utils/app_assests.dart';
// import 'package:yoga/utils/colors.dart';
// import 'package:yoga/utils/snacbar_message.dart';

// class MobileOTPScreen extends StatefulWidget {
//   final String phoneNumber;
//   final String? email; // Made optional
//   final String? userId; // Made optional for new registration flow
//   final String? name; // For new registration
//   final String? password; // Encrypted password for new registration
//   final bool isRegistration; // Flag to indicate registration vs login

//   const MobileOTPScreen({
//     Key? key,
//     required this.phoneNumber,
//     this.email,
//     this.userId,
//     this.name,
//     this.password,
//     this.isRegistration = false,
//   }) : super(key: key);

//   @override
//   State<MobileOTPScreen> createState() => _MobileOTPScreenState();
// }

// class _MobileOTPScreenState extends State<MobileOTPScreen> {
//   final List<TextEditingController> _otpControllers = List.generate(
//     6,
//     (index) => TextEditingController(),
//   );

//   bool _isLoading = false;
//   bool _isResending = false;
//   String? _generatedOTP; // Store OTP for testing display
//   final supabase = Supabase.instance.client;

//   @override
//   void initState() {
//     super.initState();
//     _sendOTP();
//     print('\n🔐 ========== OTP SCREEN OPENED ==========');
//     print('📱 Phone: ${widget.phoneNumber}');
//     print('📧 Email: ${widget.email ?? "Not provided"}');
//     print('🆔 User ID: ${widget.userId ?? "New registration"}');
//     print('🔄 Is Registration: ${widget.isRegistration}');
//     print('=========================================\n');
//   }

//   // 📲 Send OTP using database
//   Future<void> _sendOTP() async {
//     try {
//       print('\n📲 ========== SENDING OTP ==========');

//       final result = await OTPService.sendOTP(widget.phoneNumber);

//       if (result['success']) {
//         setState(() {
//           _generatedOTP = result['otp']; // Store for display
//         });

//         print('✅ OTP sent successfully!');
//         print('🔢 OTP: ${result['otp']}'); // For testing
//         print('====================================\n');

//         // Show OTP in snackbar for testing
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           showSnackBar(context, "🧪 Test OTP: ${result['otp']}");
//         });
//       } else {
//         print('❌ Failed to send OTP: ${result['error']}');
//         showSnackBar(context, result['error'] ?? 'Failed to send OTP');
//       }
//     } catch (e) {
//       print('❌ Error sending OTP: $e');
//       showSnackBar(context, 'Failed to send OTP');
//     }
//   }

//   // ✅ Verify OTP using database
//   Future<void> _verifyOTP() async {
//     String otp = _otpControllers.map((e) => e.text).join();

//     if (otp.length != 6) {
//       showSnackBar(context, "Please enter 6-digit OTP");
//       return;
//     }

//     print('\n🔍 ========== VERIFYING OTP ==========');
//     print('📱 Entered OTP: $otp');
//     print('📱 Phone: ${widget.phoneNumber}');

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Verify OTP using database
//       final result = await OTPService.verifyOTP(widget.phoneNumber, otp);

//       if (result['success']) {
//         print('✅ OTP Verified Successfully!');

//         // Check if this is a new registration
//         if (widget.isRegistration) {
//           await _completeRegistration();
//         } else {
//           await _completeVerification();
//         }
//       } else {
//         setState(() {
//           _isLoading = false;
//         });

//         print('❌ OTP Verification Failed: ${result['error']}');
//         print('=====================================\n');

//         showSnackBar(context, result['error'] ?? 'Invalid OTP');
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });

//       print('❌ Error verifying OTP: $e');
//       print('=====================================\n');

//       showSnackBar(context, 'Verification failed. Please try again.');
//     }
//   }

//   // Complete registration after OTP verification (WITHOUT Supabase Auth)
//   Future<void> _completeRegistration() async {
//     try {
//       print('🔍 Completing registration after OTP verification...');
//       print('📱 Phone: ${widget.phoneNumber}');
//       print('👤 Name: ${widget.name}');
//       print('📧 Email: ${widget.email ?? "Not provided"}');

//       // Generate unique user ID
//       String userId = DateTime.now().millisecondsSinceEpoch.toString();

//       print('🆔 Generated User ID: ${widget.userId}');

//       // STEP 1: Create user directly in Users table (NO Supabase Auth)
//       await supabase.from('Users').insert({
//         'id': widget.userId,
//         'email': widget.email?.isNotEmpty == true ? widget.email : null,
//         'name': widget.name,
//         'mobile_number': widget.phoneNumber,
//         'password': widget.password, // Encrypted password
//         'created_at': DateTime.now().toIso8601String(),
//       });

//       print('✅ User Profile Saved in Database!');

//       // STEP 2: Save to local storage
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('user_id', userId);
//       await prefs.setString('name', widget.name!);
//       if (widget.email != null && widget.email!.isNotEmpty) {
//         await prefs.setString('email', widget.email!);
//       }
//       await prefs.setString('mobile_number', widget.phoneNumber);
//       await prefs.setBool('is_logged_in', true);

//       print('💾 User data saved locally');

//       setState(() {
//         _isLoading = false;
//       });

//       print('🎉 REGISTRATION COMPLETE!');
//       print('=====================================\n');

//       // Show success modal
//       showModalBottomSheet(
//         context: context,
//         isScrollControlled: true,
//         backgroundColor: Colors.transparent,
//         isDismissible: false,
//         builder: (context) => const _OtpSuccessSheet(),
//       );
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       print('❌ Error completing registration: $e');
//       showSnackBar(context, 'Registration failed. Please try again.');
//     }
//   }

//   // Complete verification for existing users (login flow)
//   Future<void> _completeVerification() async {
//     try {
//       // Update verification status in Users table
//       final updateResult =
//           await supabase
//               .from('Users')
//               .update({'updated_at': DateTime.now().toIso8601String()})
//               .eq('id', widget.userId!)
//               .select();

//       print('✅ Verification status updated in database');
//       print('📊 Updated record: $updateResult');

//       setState(() {
//         _isLoading = false;
//       });

//       print('🎉 Verification completed!');
//       print('=====================================\n');

//       // Show success modal
//       showModalBottomSheet(
//         context: context,
//         isScrollControlled: true,
//         backgroundColor: Colors.transparent,
//         isDismissible: false,
//         builder: (context) => const _OtpSuccessSheet(),
//       );
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       print('⚠️ Could not update verification status: $e');
//       // Continue anyway
//       showModalBottomSheet(
//         context: context,
//         isScrollControlled: true,
//         backgroundColor: Colors.transparent,
//         isDismissible: false,
//         builder: (context) => const _OtpSuccessSheet(),
//       );
//     }
//   }

//   // 🔄 Resend OTP
//   Future<void> _resendOTP() async {
//     setState(() {
//       _isResending = true;
//     });

//     print('\n🔄 ========== RESENDING OTP ==========');

//     try {
//       final result = await OTPService.resendOTP(widget.phoneNumber);

//       setState(() {
//         _isResending = false;
//       });

//       if (result['success']) {
//         setState(() {
//           _generatedOTP = result['otp']; // Update displayed OTP
//         });

//         // Clear OTP fields
//         for (var controller in _otpControllers) {
//           controller.clear();
//         }

//         print('✅ OTP resent successfully!');
//         print('🔢 New OTP: ${result['otp']}'); // For testing
//         print('=====================================\n');

//         showSnackBar(context, "🧪 New OTP: ${result['otp']}");
//       } else {
//         print('❌ Resend failed: ${result['error']}');
//         print('=====================================\n');

//         showSnackBar(context, result['error'] ?? 'Failed to resend OTP');
//       }
//     } catch (e) {
//       setState(() {
//         _isResending = false;
//       });

//       print('❌ Error resending OTP: $e');
//       print('=====================================\n');

//       showSnackBar(context, 'Failed to resend OTP');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFD6ECB4),
//       body: SafeArea(
//         child: Column(
//           children: [
//             const SizedBox(height: 20),

//             Padding(
//               padding: const EdgeInsets.only(left: 25),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Image.asset(AppAssets.yogaGirl, height: 60),
//               ),
//             ),

//             const SizedBox(height: 20),

//             Padding(
//               padding: const EdgeInsets.only(left: 25),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   "OTP Verification",
//                   style: TextStyle(
//                     fontSize: 28,
//                     color: Colors.black,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 6),

//             Padding(
//               padding: const EdgeInsets.only(left: 25, right: 25),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "OTP sent to:",
//                       style: TextStyle(fontSize: 14, color: Colors.black87),
//                     ),
//                     Text(
//                       "📱 ${widget.phoneNumber}",
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.black,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     // Only show email if provided
//                     if (widget.email != null && widget.email!.isNotEmpty)
//                       Text(
//                         "📧 ${widget.email}",
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.black,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     // 🔥 Show generated OTP for testing
//                     if (_generatedOTP != null)
//                       Container(
//                         margin: const EdgeInsets.only(top: 10),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 8,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.orange.shade100,
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(color: Colors.orange, width: 2),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(Icons.science, size: 18, color: Colors.orange),
//                             SizedBox(width: 8),
//                             Text(
//                               "🧪 TEST OTP: $_generatedOTP",
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 color: Colors.orange.shade900,
//                                 fontWeight: FontWeight.bold,
//                                 letterSpacing: 1,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 40),

//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(25),
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(25),
//                     topRight: Radius.circular(25),
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Container(
//                       color: Colors.grey.shade50,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: List.generate(6, (index) {
//                           return SizedBox(
//                             width: 45,
//                             child: Padding(
//                               padding: const EdgeInsets.only(
//                                 top: 8.0,
//                                 bottom: 8.0,
//                               ),
//                               child: TextField(
//                                 controller: _otpControllers[index],
//                                 maxLength: 1,
//                                 keyboardType: TextInputType.number,
//                                 textAlign: TextAlign.center,
//                                 style: const TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                                 decoration: InputDecoration(
//                                   counterText: "",
//                                   filled: true,
//                                   fillColor: Colors.white,
//                                   enabledBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide: BorderSide(
//                                       color: Colors.grey.shade400,
//                                       width: 1,
//                                     ),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide: BorderSide(
//                                       color: AppColors.primary,
//                                       width: 2,
//                                     ),
//                                   ),
//                                 ),
//                                 onChanged: (value) {
//                                   if (value.isNotEmpty) {
//                                     // Jab digit enter ho to next field mein jao
//                                     if (index < 5) {
//                                       FocusScope.of(context).nextFocus();
//                                     } else {
//                                       // Last field hai to keyboard hide karo
//                                       FocusScope.of(context).unfocus();
//                                     }
//                                   } else {
//                                     // Agar field empty ho gayi (backspace se) to previous field mein jao
//                                     if (index > 0) {
//                                       FocusScope.of(context).previousFocus();
//                                     }
//                                   }
//                                 },
//                               ),
//                             ),
//                           );
//                         }),
//                       ),
//                     ),

//                     const SizedBox(height: 40),

//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFD6ECB4),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         onPressed: _isLoading ? null : _verifyOTP,
//                         child:
//                             _isLoading
//                                 ? const SizedBox(
//                                   height: 20,
//                                   width: 20,
//                                   child: CircularProgressIndicator(
//                                     color: Colors.black,
//                                     strokeWidth: 2,
//                                   ),
//                                 )
//                                 : const Text(
//                                   "Verify",
//                                   style: TextStyle(
//                                     color: Colors.black,
//                                     fontSize: 18,
//                                   ),
//                                 ),
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Text("Didn't get the OTP? "),
//                         GestureDetector(
//                           onTap: _isResending ? null : _resendOTP,
//                           child:
//                               _isResending
//                                   ? const SizedBox(
//                                     height: 14,
//                                     width: 14,
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 2,
//                                       color: Colors.green,
//                                     ),
//                                   )
//                                   : const Text(
//                                     "Resend OTP",
//                                     style: TextStyle(
//                                       color: Colors.green,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     for (var controller in _otpControllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }
// }

class _OtpSuccessSheet extends StatelessWidget {
  const _OtpSuccessSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 40),
          ),

          const SizedBox(height: 20),

          const Text(
            "Congratulations!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          const Text(
            "You have completed your registration.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 30),

          CommonButton(
            text: "Let's Start",
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => MainNavbar()),
                (route) => false,
              );
            },
          ),

          const SizedBox(height: 25),
        ],
      ),
    );
  }
}
