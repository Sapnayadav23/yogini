// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:yoga/Auth/Forgot_Password_Enter_Otp.dart';
// import 'package:yoga/utils/Button.dart';
// import 'package:yoga/utils/Common_Input_Field.dart';
// import 'package:yoga/utils/app_assests.dart';
// import 'package:yoga/utils/colors.dart';
// import 'package:yoga/utils/snacbar_message.dart';

// class ForgotPasswordScreenEnterMobileNumber extends StatefulWidget {
//   const ForgotPasswordScreenEnterMobileNumber({super.key});

//   @override
//   State<ForgotPasswordScreenEnterMobileNumber> createState() =>
//       _ForgotPasswordScreenEnterMobileNumberState();
// }

// class _ForgotPasswordScreenEnterMobileNumberState
//     extends State<ForgotPasswordScreenEnterMobileNumber> {
//   final TextEditingController _phoneController = TextEditingController();
//   final supabase = Supabase.instance.client;
//   bool _loading = false;

//   /// ✅ Check if number exists in the database
//   Future<void> checkPhoneNumber() async {
//     final phone = _phoneController.text.trim();

//     if (phone.isEmpty || phone.length != 10) {
//       showSnackBar(context, "Enter valid 10-digit phone number");
//       return;
//     }

//     setState(() => _loading = true);

//     try {
//       final fullPhone = "+91$phone"; // assuming India number format

//       // ✅ Query your Supabase table (replace 'users' and 'phone' with your actual table/column names)
//       final response =
//           await supabase
//               .from('Users')
//               .select()
//               .eq('mobile_number', fullPhone)
//               .maybeSingle();

//       setState(() => _loading = false);

//       if (response != null) {
//         // ✅ Phone exists — navigate to next screen (without sending OTP)
//         showSnackBar(context, "Your OTP: 123456");
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder:
//                 (context) => ForgotPasswordScreenEnterOtp(
//                   phoneNumber: fullPhone,
//                 ),
//           ),
//         );
//       } else {
//         // ❌ Phone does not exist
//         showSnackBar(context, "This phone number is not registered");
//       }
//     } catch (e) {
//       setState(() => _loading = false);
//       showSnackBar(context, "Error checking number: ${e.toString()}");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.primary,
//       body: SafeArea(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 40),
//             Padding(
//                padding: const EdgeInsets.only(left: 20),
//               child: Image.asset(AppAssets.yogaGirl, height: 60),
//             ),

//             const SizedBox(height: 5),
//             Padding(
//               padding: const EdgeInsets.only(left: 20),
//               child: Text(
//                 "Forgot Password",
//                 style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
//               ),
//             ),
//             const SizedBox(height: 20),

//             Expanded(
//               child: Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//                 ),
//                 child: Column(
//                   children: [
//                     CommonInputField(
//                       controller: _phoneController,
//                       label: "Phone Number",
//                       hintText: "Enter phone number",
//                     ),
//                     const SizedBox(height: 25),
//                     CommonButton(
//                       text: _loading ? "Checking..." : "Next",
//                       onTap: checkPhoneNumber,
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
// }
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yoga/Auth/Forgot_Password_Enter_Otp.dart';
import 'package:yoga/Auth/Registration_Screen.dart'; // Import for OTPService
import 'package:yoga/utils/Button.dart';
import 'package:yoga/utils/Common_Input_Field.dart';
import 'package:yoga/utils/app_assests.dart';
import 'package:yoga/utils/colors.dart';
import 'package:yoga/utils/snacbar_message.dart';

class ForgotPasswordScreenEnterMobileNumber extends StatefulWidget {
  const ForgotPasswordScreenEnterMobileNumber({super.key});

  @override
  State<ForgotPasswordScreenEnterMobileNumber> createState() =>
      _ForgotPasswordScreenEnterMobileNumberState();
}

class _ForgotPasswordScreenEnterMobileNumberState
    extends State<ForgotPasswordScreenEnterMobileNumber> {
  final TextEditingController _phoneController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _loading = false;

  /// ✅ Check if number exists and send OTP
  Future<void> checkPhoneNumberAndSendOTP() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length != 10) {
      showSnackBar(context, "Enter valid 10-digit phone number");
      return;
    }

    setState(() => _loading = true);

    try {
      final fullPhone = "+91$phone";

      print('\n🔍 ========== CHECKING PHONE NUMBER ==========');
      print('📱 Phone: $fullPhone');

      // ✅ Check if phone exists in database
      final response =
          await supabase
              .from('Users')
              .select()
              .eq('mobile_number', fullPhone)
              .maybeSingle();

      if (response == null) {
        setState(() => _loading = false);
        print('❌ Phone number not registered');
        print('=============================================\n');
        showSnackBar(context, "This phone number is not registered");
        return;
      }

      print('✅ Phone number found in database');
      print('👤 User: ${response['name']}');

      // ✅ Send OTP using OTPService
      print('\n📲 ========== SENDING OTP ==========');
      final otpResult = await OTPService.sendOTP(fullPhone);

      setState(() => _loading = false);

      if (otpResult['success']) {
        print('✅ OTP sent successfully!');
        print('🔢 OTP: ${otpResult['otp']}'); // For testing
        print('====================================\n');

        // Show OTP in snackbar for testing
        showSnackBar(context, "🧪 Test OTP: ${otpResult['otp']}");

        // Navigate to OTP verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    ForgotPasswordScreenEnterOtp(phoneNumber: fullPhone),
          ),
        );
      } else {
        print('❌ Failed to send OTP: ${otpResult['error']}');
        print('====================================\n');
        showSnackBar(context, otpResult['error'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      setState(() => _loading = false);
      print('❌ Error: $e');
      print('=============================================\n');
      showSnackBar(context, "Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Image.asset(AppAssets.yogaGirl, height: 60),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                "Forgot Password",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      CommonInputField(
                        controller: _phoneController,
                        label: "Phone Number",
                        hintText: "Enter phone number",
                      ),
                      const SizedBox(height: 25),
                      CommonButton(
                        text: _loading ? "Sending OTP..." : "Next",
                        onTap: _loading ? () {} : checkPhoneNumberAndSendOTP,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
