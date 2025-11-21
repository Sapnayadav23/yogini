// import 'package:flutter/material.dart';
// import 'package:yoga/Auth/Forgot_Password_Screen.dart';
// import 'package:yoga/Auth/Registration_Screen.dart';
// import 'package:yoga/utils/Button.dart';
// import 'package:yoga/utils/app_assests.dart';
// import 'package:yoga/utils/colors.dart';
// import 'package:yoga/utils/snacbar_message.dart';

// class ForgotPasswordScreenEnterOtp extends StatefulWidget {
//   final String phoneNumber;
//   const ForgotPasswordScreenEnterOtp({required this.phoneNumber, Key? key})
//     : super(key: key);

//   @override
//   State<ForgotPasswordScreenEnterOtp> createState() =>
//       _ForgotPasswordScreenEnterOtpState();
// }

// class _ForgotPasswordScreenEnterOtpState
//     extends State<ForgotPasswordScreenEnterOtp> {
//   final List<TextEditingController> _otpControllers = List.generate(
//     6,
//     (index) => TextEditingController(),
//   );
//   final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
//   Future<void> resendOTP() async {
//     final otpResult = await OTPService.sendOTP(widget.phoneNumber);

//     if (otpResult['success']) {
//       showSnackBar(context, "New OTP Sent: ${otpResult['otp']}");
//       print("New OTP = ${otpResult['otp']}");
//     } else {
//       showSnackBar(context, otpResult['error'] ?? "Failed to resend OTP");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFD6ECB4), // Light Green Background
//       body: SafeArea(
//         child: Column(
//           children: [
//             const SizedBox(height: 20),

//             // Logo
//             Padding(
//               padding: const EdgeInsets.only(left: 25),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Image.asset(
//                   AppAssets.yogaGirl, // Change based on your asset
//                   height: 60,
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Title
//             Padding(
//               padding: const EdgeInsets.only(left: 25),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   "OTP Verifications",
//                   style: TextStyle(
//                     fontSize: 28,
//                     color: Colors.black,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 6),

//             // Subtext
//             Padding(
//               padding: const EdgeInsets.only(left: 25),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   "OTP has been sent to your registered mobile number",
//                   style: TextStyle(fontSize: 14, color: Colors.black87),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 40),

//             // White Box Container
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
//                           return AnimatedContainer(
//                             duration: const Duration(milliseconds: 150),
//                             curve: Curves.easeInOut,
//                             width: 50,
//                             height: 55,
//                             decoration: BoxDecoration(
//                               color:
//                                   _focusNodes[index].hasFocus
//                                       ? Colors.white
//                                       : Colors.grey.shade100,
//                               borderRadius: BorderRadius.circular(10),
//                               border: Border.all(
//                                 color:
//                                     _focusNodes[index].hasFocus
//                                         ? AppColors.primary
//                                         : Colors.grey.shade400,
//                                 width: _focusNodes[index].hasFocus ? 2 : 1,
//                               ),
//                             ),

//                             child: TextField(
//                               controller: _otpControllers[index],
//                               focusNode: _focusNodes[index],
//                               maxLength: 1,
//                               keyboardType: TextInputType.number,
//                               textAlign: TextAlign.center,
//                               style: const TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               decoration: const InputDecoration(
//                                 counterText: "",
//                                 border: InputBorder.none,
//                                 contentPadding: EdgeInsets.zero,
//                               ),

//                               // 👉 Correct forward/backward movement
//                               onChanged: (value) {
//                                 if (value.length == 1) {
//                                   // next box
//                                   if (index < 5) {
//                                     FocusScope.of(
//                                       context,
//                                     ).requestFocus(_focusNodes[index + 1]);
//                                   } else {
//                                     FocusScope.of(context).unfocus();
//                                   }
//                                 } else if (value.isEmpty) {
//                                   // backspace → previous box
//                                   if (index > 0) {
//                                     FocusScope.of(
//                                       context,
//                                     ).requestFocus(_focusNodes[index - 1]);
//                                   }
//                                 }

//                                 setState(() {}); // animate
//                               },
//                             ),
//                           );
//                         }),
//                       ),
//                     ),

//                     // Container(
//                     //   color: Colors.grey.shade50,
//                     //   child: Row(
//                     //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     //     children: List.generate(6, (index) {
//                     //       return SizedBox(
//                     //         width: 50,
//                     //         child: Padding(
//                     //           padding: const EdgeInsets.only(
//                     //             top: 8.0,
//                     //             bottom: 8.0,
//                     //           ),
//                     //           // child: TextField(
//                     //           //   controller: _otpControllers[index],
//                     //           //   maxLength: 1,
//                     //           //   keyboardType: TextInputType.number,
//                     //           //   textAlign: TextAlign.center,
//                     //           //   style: const TextStyle(
//                     //           //     fontSize: 18,
//                     //           //     fontWeight: FontWeight.bold,
//                     //           //   ),
//                     //           //   decoration: InputDecoration(
//                     //           //     counterText: "",
//                     //           //     filled: true,
//                     //           //     fillColor: Colors.white,
//                     //           //     enabledBorder: OutlineInputBorder(
//                     //           //       borderRadius: BorderRadius.circular(10),
//                     //           //       borderSide: BorderSide(
//                     //           //         color: Colors.grey.shade400,
//                     //           //         width: 1,
//                     //           //       ),
//                     //           //     ),
//                     //           //     focusedBorder: OutlineInputBorder(
//                     //           //       borderRadius: BorderRadius.circular(10),
//                     //           //       borderSide: BorderSide(
//                     //           //         color:
//                     //           //             AppColors
//                     //           //                 .primary, // ✅ Focus hone par primary color
//                     //           //         width: 2,
//                     //           //       ),
//                     //           //     ),
//                     //           //   ),
//                     //           //   onChanged: (value) {
//                     //           //     if (value.isNotEmpty && index < 5) {
//                     //           //       FocusScope.of(context).nextFocus();
//                     //           //     }
//                     //           //   },
//                     //           // ),
//                     //           child: Row(
//                     //             mainAxisAlignment:
//                     //                 MainAxisAlignment.spaceEvenly,
//                     //             children: List.generate(6, (index) {
//                     //               return AnimatedContainer(
//                     //                 duration: const Duration(milliseconds: 150),
//                     //                 curve: Curves.easeInOut,
//                     //                 width: 50,
//                     //                 height: 55,
//                     //                 decoration: BoxDecoration(
//                     //                   color:
//                     //                       _focusNodes[index].hasFocus
//                     //                           ? Colors.white
//                     //                           : Colors.grey.shade100,
//                     //                   borderRadius: BorderRadius.circular(10),
//                     //                   border: Border.all(
//                     //                     color:
//                     //                         _focusNodes[index].hasFocus
//                     //                             ? AppColors.primary
//                     //                             : Colors.grey.shade400,
//                     //                     width:
//                     //                         _focusNodes[index].hasFocus ? 2 : 1,
//                     //                   ),
//                     //                 ),

//                     //                 child: TextField(
//                     //                   controller: _otpControllers[index],
//                     //                   focusNode: _focusNodes[index],
//                     //                   maxLength: 1,
//                     //                   keyboardType: TextInputType.number,
//                     //                   textAlign: TextAlign.center,
//                     //                   style: const TextStyle(
//                     //                     fontSize: 18,
//                     //                     fontWeight: FontWeight.bold,
//                     //                   ),
//                     //                   decoration: const InputDecoration(
//                     //                     counterText: "",
//                     //                     border: InputBorder.none,
//                     //                     contentPadding: EdgeInsets.zero,
//                     //                   ),

//                     //                   // 👇 Smooth forward + backward movement
//                     //                   onChanged: (value) {
//                     //                     if (value.length == 1) {
//                     //                       // Move to next box
//                     //                       if (index < 5) {
//                     //                         FocusScope.of(context).requestFocus(
//                     //                           _focusNodes[index + 1],
//                     //                         );
//                     //                       } else {
//                     //                         FocusScope.of(context).unfocus();
//                     //                       }
//                     //                     } else if (value.isEmpty) {
//                     //                       // Move to previous box
//                     //                       if (index > 0) {
//                     //                         FocusScope.of(context).requestFocus(
//                     //                           _focusNodes[index - 1],
//                     //                         );
//                     //                       }
//                     //                     }

//                     //                     setState(() {}); // update animation
//                     //                   },
//                     //                 ),
//                     //               );
//                     //             }),
//                     //           ),
//                     //         ),
//                     //       );
//                     //     }),
//                     //   ),
//                     // ),
//                     const SizedBox(height: 40),

//                     // Verify Button
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
//                         onPressed: () {
//                           String otp =
//                               _otpControllers.map((e) => e.text).join();
//                           print("Entered OTP: $otp");

//                           Navigator.pushReplacement(
//                             context,
//                             MaterialPageRoute(
//                               builder:
//                                   (context) => ForgotPasswordScreen(
//                                     phone: widget.phoneNumber,
//                                   ),
//                             ),
//                           );
//                         },

//                         child: const Text(
//                           "Verify",
//                           style: TextStyle(color: Colors.black, fontSize: 18),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     // Resend
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Text("Didn't get the OTP? "),
//                         GestureDetector(
//                           onTap: () {
//                             resendOTP();
//                           },
//                           child: const Text(
//                             "Resend OTP",
//                             style: TextStyle(
//                               color: Colors.green,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
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
// }
import 'package:flutter/material.dart';
import 'package:yoga/Auth/Forgot_Password_Screen.dart';
import 'package:yoga/Auth/Registration_Screen.dart';
import 'package:yoga/utils/Button.dart';
import 'package:yoga/utils/app_assests.dart';
import 'package:yoga/utils/colors.dart';
import 'package:yoga/utils/snacbar_message.dart';

class ForgotPasswordScreenEnterOtp extends StatefulWidget {
  final String phoneNumber;
  const ForgotPasswordScreenEnterOtp({required this.phoneNumber, Key? key})
    : super(key: key);

  @override
  State<ForgotPasswordScreenEnterOtp> createState() =>
      _ForgotPasswordScreenEnterOtpState();
}

class _ForgotPasswordScreenEnterOtpState
    extends State<ForgotPasswordScreenEnterOtp> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  // ✅ Expected OTP (ye aapke OTPService se match karna hai)
  String? expectedOtp;
  bool isLoading = false;

  // ✅ Check if all 6 digits are entered
  bool get isOtpComplete {
    return _otpControllers.every((controller) => controller.text.isNotEmpty);
  }

  @override
  void initState() {
    super.initState();
    // Get the expected OTP from your service
    _getExpectedOtp();
  }

  Future<void> _getExpectedOtp() async {
    // Agar aapke pass stored OTP hai to yaha set karo
    // Ya OTPService se fetch karo
    final otpResult = await OTPService.sendOTP(widget.phoneNumber);
    if (otpResult['success']) {
      setState(() {
        expectedOtp = otpResult['otp'].toString();
      });
      print("Expected OTP: $expectedOtp");
    }
  }

  Future<void> resendOTP() async {
    final otpResult = await OTPService.sendOTP(widget.phoneNumber);

    if (otpResult['success']) {
      setState(() {
        expectedOtp = otpResult['otp'].toString();
      });
      showSnackBar(context, "New OTP Sent: ${otpResult['otp']}");
      print("New OTP = ${otpResult['otp']}");
    } else {
      showSnackBar(context, otpResult['error'] ?? "Failed to resend OTP");
    }
  }

  // ✅ Verify OTP function
  void verifyOTP() {
    setState(() {
      isLoading = true;
    });

    String enteredOtp = _otpControllers.map((e) => e.text).join();
    print("Entered OTP: $enteredOtp");
    print("Expected OTP: $expectedOtp");

    // Check if OTP matches
    if (enteredOtp == expectedOtp) {
      // ✅ Correct OTP - Navigate
      setState(() {
        isLoading = false;
      });

      showSnackBar(context, "OTP Verified Successfully!");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ForgotPasswordScreen(phone: widget.phoneNumber),
        ),
      );
    } else {
      // ❌ Wrong OTP - Show error
      setState(() {
        isLoading = false;
      });

      showSnackBar(context, "Invalid OTP! Please try again.");

      // Clear all fields
      for (var controller in _otpControllers) {
        controller.clear();
      }

      // Focus on first field
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6ECB4), // Light Green Background
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Logo
            Padding(
              padding: const EdgeInsets.only(left: 25),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(AppAssets.yogaGirl, height: 60),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Padding(
              padding: const EdgeInsets.only(left: 25),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "OTP Verifications",
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Subtext
            Padding(
              padding: const EdgeInsets.only(left: 25),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "OTP has been sent to your registered mobile number",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // White Box Container
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
                    // OTP Input Fields
                    Container(
                      color: Colors.grey.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            width: 50,
                            height: 55,
                            decoration: BoxDecoration(
                              color:
                                  _focusNodes[index].hasFocus
                                      ? Colors.white
                                      : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    _focusNodes[index].hasFocus
                                        ? AppColors.primary
                                        : Colors.grey.shade400,
                                width: _focusNodes[index].hasFocus ? 2 : 1,
                              ),
                            ),
                            child: TextField(
                              controller: _otpControllers[index],
                              focusNode: _focusNodes[index],
                              maxLength: 1,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                counterText: "",
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) {
                                if (value.length == 1) {
                                  // Move to next box
                                  if (index < 5) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_focusNodes[index + 1]);
                                  } else {
                                    FocusScope.of(context).unfocus();
                                  }
                                } else if (value.isEmpty) {
                                  // Move to previous box on backspace
                                  if (index > 0) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_focusNodes[index - 1]);
                                  }
                                }
                                setState(() {}); // Refresh UI
                              },
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Verify Button - ✅ Only enabled when OTP is complete
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isOtpComplete
                                  ? const Color(0xFFD6ECB4)
                                  : Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed:
                            isOtpComplete && !isLoading
                                ? verifyOTP
                                : null, // Button disabled if OTP incomplete or loading
                        child:
                            isLoading
                                ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                )
                                : Text(
                                  "Verify",
                                  style: TextStyle(
                                    color:
                                        isOtpComplete
                                            ? Colors.black
                                            : Colors.grey.shade600,
                                    fontSize: 18,
                                  ),
                                ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Resend OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Didn't get the OTP? "),
                        GestureDetector(
                          onTap: () {
                            resendOTP();
                          },
                          child: const Text(
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
}
