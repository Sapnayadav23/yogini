// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:yoga/Auth/login_screen.dart';
// import 'package:yoga/utils/Button.dart';
// import 'package:yoga/utils/Common_Input_Field.dart';
// import 'package:yoga/utils/app_assests.dart';
// import 'package:yoga/utils/colors.dart';

// class ForgotPasswordScreen extends StatefulWidget {
//   final String phone;
//   const ForgotPasswordScreen({required this.phone, Key? key}) : super(key: key);

//   @override
//   State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
// }

// class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
//   bool _isPasswordVisible1 = false;
//   bool _isPasswordVisible2 = false;

//   final TextEditingController _newPassController = TextEditingController();
//   final TextEditingController _confirmPassController = TextEditingController();
//   final supabase = Supabase.instance.client;

//   bool _isLoading = false;

//   Future<Map<String, dynamic>?> _getUserByPhone(String phone) async {
//     try {
//       final response =
//           await supabase
//               .from('Users')
//               .select()
//               .eq('mobile_number', phone)
//               .maybeSingle();

//       if (response == null) {
//         print("❌ No user found with phone: $phone");
//         return null;
//       } else {
//         print("✅ User found: $response");
//         return response;
//       }
//     } catch (e) {
//       print("❌ Error fetching user by phone: $e");
//       rethrow;
//     }
//   }

//   Future<void> updateForgottenPassword(
//     String newPassword,
//     String confirmPassword,
//   ) async {
//     if (newPassword.isEmpty || confirmPassword.isEmpty) {
//       throw Exception("Please fill in all fields");
//     }

//     if (newPassword != confirmPassword) {
//       throw Exception("Passwords do not match");
//     }

//     if (newPassword.length < 6) {
//       throw Exception("Password must be at least 6 characters");
//     }

//     try {
//       final user = await _getUserByPhone(widget.phone);

//       if (user == null) {
//         throw Exception("Phone number not registered in database");
//       }

//       final userId = user['id'];
//       print("🧠 Found user ID: $userId for phone: ${widget.phone}");

//       final response =
//           await supabase
//               .from('Users')
//               .update({'password': newPassword})
//               .eq('id', userId)
//               .select();

//       print("🔄 Supabase update response: $response");

//       if (response.isEmpty) {
//         throw Exception("Failed to update password. Try again.");
//       }

//       print("✅ Password updated successfully in Supabase");
//     } catch (error) {
//       print("❌ Error updating password: $error");
//       rethrow;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       backgroundColor: AppColors.primary,
//       body: GestureDetector(
//         onTap: () => FocusScope.of(context).unfocus(),
//         child: SafeArea(
//           child: SingleChildScrollView(
//             padding: EdgeInsets.only(
//               bottom: MediaQuery.of(context).viewInsets.bottom,
//             ),
//             child: ConstrainedBox(
//               constraints: BoxConstraints(
//                 minHeight:
//                     MediaQuery.of(context).size.height -
//                     MediaQuery.of(context).padding.top,
//               ),
//               child: IntrinsicHeight(
//                 child: Column(
//                   children: [
//                     const SizedBox(height: 40),
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: Padding(
//                         padding: const EdgeInsets.only(left: 25),
//                         child: Image.asset(AppAssets.yogaGirl, height: 60),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     Padding(
//                       padding: const EdgeInsets.only(left: 25),
//                       child: Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           'Reset Password',
//                           style: const TextStyle(
//                             fontSize: 28,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 5),
//                     Padding(
//                       padding: const EdgeInsets.only(left: 25),
//                       child: Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           "Enter your new password",
//                           style: TextStyle(
//                             color: Colors.black87,
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 30),
//                     // Use Flexible instead of Expanded inside IntrinsicHeight + ConstrainedBox
//                     Flexible(
//                       child: Container(
//                         width: double.infinity,
//                         decoration: const BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.only(
//                             topLeft: Radius.circular(25),
//                             topRight: Radius.circular(25),
//                           ),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(18.0),
//                           child: Column(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(18),
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey.shade200,
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     CommonInputField(
//                                       controller: _newPassController,
//                                       label: "New Password",
//                                       hintText: "Enter new password",
//                                       onToggle: () {
//                                         setState(() {
//                                           _isPasswordVisible1 =
//                                               !_isPasswordVisible1;
//                                         });
//                                       },
//                                     ),
//                                     const SizedBox(height: 20),
//                                     CommonInputField(
//                                       controller: _confirmPassController,
//                                       label: "Confirm Password",
//                                       hintText: "Confirm new password",
//                                       onToggle: () {
//                                         setState(() {
//                                           _isPasswordVisible2 =
//                                               !_isPasswordVisible2;
//                                         });
//                                       },
//                                     ),
//                                     const SizedBox(height: 25),
//                                     CommonButton(
//                                       text:
//                                           _isLoading
//                                               ? "Updating..."
//                                               : "Update Password",
//                                       onTap: () async {
//                                         setState(() => _isLoading = true);
//                                         try {
//                                           await updateForgottenPassword(
//                                             _newPassController.text.trim(),
//                                             _confirmPassController.text.trim(),
//                                           );

//                                           if (!mounted) return;

//                                           ScaffoldMessenger.of(
//                                             context,
//                                           ).showSnackBar(
//                                             const SnackBar(
//                                               content: Text(
//                                                 'Password updated successfully!',
//                                               ),
//                                               backgroundColor: Colors.green,
//                                             ),
//                                           );

//                                           Navigator.pushAndRemoveUntil(
//                                             context,
//                                             MaterialPageRoute(
//                                               builder:
//                                                   (context) =>
//                                                       const LoginScreen(),
//                                             ),
//                                             (route) => false,
//                                           );
//                                         } catch (e) {
//                                           if (!mounted) return;
//                                           ScaffoldMessenger.of(
//                                             context,
//                                           ).showSnackBar(
//                                             SnackBar(
//                                               content: Text(e.toString()),
//                                               backgroundColor: Colors.red,
//                                             ),
//                                           );
//                                         } finally {
//                                           if (mounted)
//                                             setState(() => _isLoading = false);
//                                         }
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _newPassController.dispose();
//     _confirmPassController.dispose();
//     super.dispose();
//   }
// }
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:yoga/Auth/login_screen.dart';
import 'package:yoga/utils/Button.dart';
import 'package:yoga/utils/Common_Input_Field.dart';
import 'package:yoga/utils/app_assests.dart';
import 'package:yoga/utils/colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String phone;
  const ForgotPasswordScreen({required this.phone, Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool _isPasswordVisible1 = false;
  bool _isPasswordVisible2 = false;

  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  final supabase = Supabase.instance.client;

  bool _isLoading = false;

  /// 🔐 Encrypt password using SHA256
  String _encryptPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<Map<String, dynamic>?> _getUserByPhone(String phone) async {
    try {
      final response = await supabase
          .from('Users')
          .select()
          .eq('mobile_number', phone)
          .maybeSingle();

      if (response == null) {
        print("❌ No user found with phone: $phone");
        return null;
      } else {
        print("✅ User found: $response");
        return response;
      }
    } catch (e) {
      print("❌ Error fetching user by phone: $e");
      rethrow;
    }
  }

  Future<void> updateForgottenPassword(
    String newPassword,
    String confirmPassword,
  ) async {
    print('\n🔐 ========== UPDATING PASSWORD ==========');
    
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      throw Exception("Please fill in all fields");
    }

    if (newPassword != confirmPassword) {
      throw Exception("Passwords do not match");
    }

    if (newPassword.length < 6) {
      throw Exception("Password must be at least 6 characters");
    }

    try {
      final user = await _getUserByPhone(widget.phone);

      if (user == null) {
        throw Exception("Phone number not registered in database");
      }

      final userId = user['id'];
      print("🧠 Found user ID: $userId for phone: ${widget.phone}");

      // 🔐 Encrypt the new password
      final encryptedPassword = _encryptPassword(newPassword);
      print("🔒 Original Password: $newPassword");
      print("🔐 Encrypted Password: $encryptedPassword");

      final response = await supabase
          .from('Users')
          .update({
            'password': encryptedPassword,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select();

      print("🔄 Supabase update response: $response");

      if (response.isEmpty) {
        throw Exception("Failed to update password. Try again.");
      }

      print("✅ Password updated successfully in Supabase");
      print("=========================================\n");
    } catch (error) {
      print("❌ Error updating password: $error");
      print("=========================================\n");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.primary,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 25),
                        child: Image.asset(AppAssets.yogaGirl, height: 60),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 25),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Reset Password',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.only(left: 25),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Enter your new password",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Flexible(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CommonInputField(
                                      controller: _newPassController,
                                      label: "New Password",
                                      hintText: "Enter new password",
                                      onToggle: () {
                                        setState(() {
                                          _isPasswordVisible1 =
                                              !_isPasswordVisible1;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    CommonInputField(
                                      controller: _confirmPassController,
                                      label: "Confirm Password",
                                      hintText: "Confirm new password",
                                      onToggle: () {
                                        setState(() {
                                          _isPasswordVisible2 =
                                              !_isPasswordVisible2;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 25),
                                    CommonButton(
                                      text: _isLoading
                                          ? "Updating..."
                                          : "Update Password",
                                      onTap: _isLoading
                                          ? () {}
                                          : () async {
                                              setState(() => _isLoading = true);
                                              try {
                                                await updateForgottenPassword(
                                                  _newPassController.text.trim(),
                                                  _confirmPassController.text
                                                      .trim(),
                                                );

                                                if (!mounted) return;

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Password updated successfully!',
                                                    ),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );

                                                Navigator.pushAndRemoveUntil(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const LoginScreen(),
                                                  ),
                                                  (route) => false,
                                                );
                                              } catch (e) {
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content:
                                                        Text(e.toString()),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              } finally {
                                                if (mounted) {
                                                  setState(
                                                    () => _isLoading = false,
                                                  );
                                                }
                                              }
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }
}