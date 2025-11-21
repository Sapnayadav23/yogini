// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // import 'package:yoga/Auth/Otp_Verification.dart';
// // // // // import 'package:yoga/Auth/login_screen.dart';
// // // // // import 'package:yoga/utils/Common_Input_Field.dart';
// // // // // import 'package:yoga/utils/app_assests.dart';
// // // // // import 'package:yoga/utils/colors.dart';
// // // // // import 'package:yoga/utils/snacbar_message.dart';

// // // // // class RegistrationScreen extends StatefulWidget {
// // // // //   const RegistrationScreen({Key? key}) : super(key: key);

// // // // //   @override
// // // // //   State<RegistrationScreen> createState() => _RegistrationScreenState();
// // // // // }

// // // // // class _RegistrationScreenState extends State<RegistrationScreen> {
// // // // //   final TextEditingController _nameController = TextEditingController();
// // // // //   final TextEditingController _mobileController = TextEditingController();
// // // // //   final TextEditingController _emailController = TextEditingController();
// // // // //   final TextEditingController _passwordController = TextEditingController();
// // // // //   final TextEditingController _confirmPassController = TextEditingController();

// // // // //   bool _obscurePassword = true;
// // // // //   bool _obscureConfirmPassword = true;
// // // // //   bool _isLoading = false;

// // // // //   final supabase = Supabase.instance.client;

// // // // //   // Register User Function
// // // // //   Future<void> _registerUser() async {
// // // // //     // Validation
// // // // //     if (_nameController.text.trim().isEmpty ||
// // // // //         _mobileController.text.trim().isEmpty ||
// // // // //         _emailController.text.trim().isEmpty ||
// // // // //         _passwordController.text.trim().isEmpty) {
// // // // //       showSnackBar(context, "Please fill all fields!");
// // // // //       return;
// // // // //     }

// // // // //     if (_passwordController.text.trim() != _confirmPassController.text.trim()) {
// // // // //       showSnackBar(context, "Passwords do not match!");
// // // // //       return;
// // // // //     }

// // // // //     if (_passwordController.text.trim().length < 6) {
// // // // //       showSnackBar(context, "Password must be at least 6 characters!");
// // // // //       return;
// // // // //     }

// // // // //     // Email validation
// // // // //     final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
// // // // //     if (!emailRegex.hasMatch(_emailController.text.trim())) {
// // // // //       showSnackBar(context, "Please enter a valid email!");
// // // // //       return;
// // // // //     }

// // // // //     // Mobile validation
// // // // //     String mobileNumber = _mobileController.text.trim();
// // // // //     if (mobileNumber.length != 10) {
// // // // //       showSnackBar(context, "Please enter a valid 10-digit mobile number!");
// // // // //       return;
// // // // //     }

// // // // //     setState(() {
// // // // //       _isLoading = true;
// // // // //     });

// // // // //     try {
// // // // //       // Format phone number with country code
// // // // //       String phoneNumber = '+91$mobileNumber';

// // // // //       print('📱 ========== REGISTRATION STARTED ==========');
// // // // //       print('📧 Email: ${_emailController.text.trim()}');
// // // // //       print('📱 Phone: $phoneNumber');
// // // // //       print('👤 Name: ${_nameController.text.trim()}');

// // // // //       // STEP 1: Sign up with Email & Password
// // // // //       final AuthResponse emailResponse = await supabase.auth.signUp(
// // // // //         email: _emailController.text.trim(),
// // // // //         password: _passwordController.text.trim(),
// // // // //         data: {
// // // // //           'name': _nameController.text.trim(),
// // // // //           'mobile_number': phoneNumber,
// // // // //         },
// // // // //         emailRedirectTo: null,
// // // // //       );

// // // // //       print('✅ Email signup successful!');
// // // // //       print('🆔 User ID: ${emailResponse.user?.id}');

// // // // //       if (emailResponse.user != null) {
// // // // //         // STEP 2: Send OTP to Mobile Number
// // // // //         try {
// // // // //           await supabase.auth.signInWithOtp(phone: phoneNumber);
// // // // //           print('📲 Mobile OTP sent successfully to $phoneNumber');
// // // // //         } catch (e) {
// // // // //           print('⚠️ Mobile OTP error: $e');
// // // // //           print('📧 Continuing with email OTP only...');
// // // // //         }

// // // // //         // STEP 3: Save user data to Users table
// // // // //         try {
// // // // //           await supabase.from('Users').insert({
// // // // //             'id': emailResponse.user!.id,
// // // // //             'email': _emailController.text.trim(),
// // // // //             'name': _nameController.text.trim(),
// // // // //             'mobile_number': phoneNumber,
// // // // //             'created_at': DateTime.now().toIso8601String(),
// // // // //             'password': _passwordController.text.trim(),
// // // // //             'c_password': _confirmPassController.text.trim(),
// // // // //           });
// // // // //           print('💾 User data saved to database');
// // // // //         } catch (e) {
// // // // //           print('⚠️ Database insert error: $e');
// // // // //         }

// // // // //         setState(() {
// // // // //           _isLoading = false;
// // // // //         });

// // // // //         print('🎉 Registration completed!');
// // // // //         print('📱 Check your phone for OTP');
// // // // //         print('📧 Check your email for OTP');
// // // // //         print('============================================\n');

// // // // //         showSnackBar(context, "OTP sent to your mobile number and email!");

// // // // //         // Navigate to Mobile OTP Screen
// // // // //         Navigator.pushReplacement(
// // // // //           context,
// // // // //           MaterialPageRoute(
// // // // //             builder:
// // // // //                 (context) => MobileOTPScreen(
// // // // //                   phoneNumber: phoneNumber,
// // // // //                   email: _emailController.text.trim(),
// // // // //                   userId: emailResponse.user!.id,
// // // // //                 ),
// // // // //           ),
// // // // //         );
// // // // //       }
// // // // //     } on AuthException catch (e) {
// // // // //       setState(() {
// // // // //         _isLoading = false;
// // // // //       });
// // // // //       print('❌ Auth Error: ${e.message}');
// // // // //       showSnackBar(context, e.message);
// // // // //     } catch (e) {
// // // // //       setState(() {
// // // // //         _isLoading = false;
// // // // //       });
// // // // //       print('❌ Error: ${e.toString()}');
// // // // //       showSnackBar(context, "Error: ${e.toString()}");
// // // // //     }
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Scaffold(
// // // // //       backgroundColor: AppColors.primary,
// // // // //       body: SafeArea(
// // // // //         child: Column(
// // // // //           children: [
// // // // //             const SizedBox(height: 40),

// // // // //             // Logo
// // // // //             Align(
// // // // //               alignment: Alignment.centerLeft,
// // // // //               child: Padding(
// // // // //                 padding: const EdgeInsets.only(left: 25),
// // // // //                 child: Image.asset(AppAssets.yogaGirl, height: 60),
// // // // //               ),
// // // // //             ),

// // // // //             const SizedBox(height: 20),

// // // // //             // Title
// // // // //             Padding(
// // // // //               padding: const EdgeInsets.only(left: 25),
// // // // //               child: Align(
// // // // //                 alignment: Alignment.centerLeft,
// // // // //                 child: Text(
// // // // //                   'Register',
// // // // //                   style: const TextStyle(
// // // // //                     fontSize: 28,
// // // // //                     fontWeight: FontWeight.bold,
// // // // //                   ),
// // // // //                 ),
// // // // //               ),
// // // // //             ),

// // // // //             const SizedBox(height: 5),

// // // // //             // Already have account
// // // // //             Padding(
// // // // //               padding: const EdgeInsets.only(left: 25),
// // // // //               child: Align(
// // // // //                 alignment: Alignment.centerLeft,
// // // // //                 child: GestureDetector(
// // // // //                   onTap: () {
// // // // //                     Navigator.pushReplacement(
// // // // //                       context,
// // // // //                       MaterialPageRoute(builder: (context) => LoginScreen()),
// // // // //                     );
// // // // //                   },
// // // // //                   child: RichText(
// // // // //                     text: const TextSpan(
// // // // //                       text: "Already have an account? ",
// // // // //                       style: TextStyle(
// // // // //                         color: Colors.black,
// // // // //                         fontWeight: FontWeight.w400,
// // // // //                       ),
// // // // //                       children: [
// // // // //                         TextSpan(
// // // // //                           text: "LOGIN",
// // // // //                           style: TextStyle(
// // // // //                             color: Colors.black,
// // // // //                             fontWeight: FontWeight.bold,
// // // // //                           ),
// // // // //                         ),
// // // // //                       ],
// // // // //                     ),
// // // // //                   ),
// // // // //                 ),
// // // // //               ),
// // // // //             ),

// // // // //             const SizedBox(height: 30),

// // // // //             Expanded(
// // // // //               child: Container(
// // // // //                 width: double.infinity,
// // // // //                 decoration: const BoxDecoration(
// // // // //                   color: Colors.white,
// // // // //                   borderRadius: BorderRadius.only(
// // // // //                     topLeft: Radius.circular(25),
// // // // //                     topRight: Radius.circular(25),
// // // // //                   ),
// // // // //                 ),
// // // // //                 child: Padding(
// // // // //                   padding: const EdgeInsets.all(18.0),
// // // // //                   child: SingleChildScrollView(
// // // // //                     child: Container(
// // // // //                       padding: const EdgeInsets.all(18),
// // // // //                       decoration: BoxDecoration(
// // // // //                         color: Colors.grey.shade200,
// // // // //                         borderRadius: BorderRadius.circular(12),
// // // // //                       ),
// // // // //                       child: Column(
// // // // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // // // //                         children: [
// // // // //                           CommonInputField(
// // // // //                             controller: _nameController,
// // // // //                             label: "Full Name",
// // // // //                             hintText: "John Doe",
// // // // //                           ),
// // // // //                           const SizedBox(height: 20),

// // // // //                           CommonInputField(
// // // // //                             controller: _mobileController,
// // // // //                             label: "Mobile Number",
// // // // //                             hintText: "9876543210",
// // // // //                           ),
// // // // //                           const SizedBox(height: 20),

// // // // //                           CommonInputField(
// // // // //                             controller: _emailController,
// // // // //                             label: "Email",
// // // // //                             hintText: "example@gmail.com",
// // // // //                           ),
// // // // //                           const SizedBox(height: 20),

// // // // //                           CommonInputField(
// // // // //                             controller: _passwordController,
// // // // //                             label: "Password",
// // // // //                             hintText: "********",
// // // // //                             isPassword: _obscurePassword,
// // // // //                             onToggle: () {
// // // // //                               setState(() {
// // // // //                                 _obscurePassword = !_obscurePassword;
// // // // //                               });
// // // // //                             },
// // // // //                           ),
// // // // //                           const SizedBox(height: 20),

// // // // //                           CommonInputField(
// // // // //                             controller: _confirmPassController,
// // // // //                             label: "Confirm Password",
// // // // //                             hintText: "********",
// // // // //                             isPassword: _obscureConfirmPassword,
// // // // //                             onToggle: () {
// // // // //                               setState(() {
// // // // //                                 _obscureConfirmPassword =
// // // // //                                     !_obscureConfirmPassword;
// // // // //                               });
// // // // //                             },
// // // // //                           ),

// // // // //                           const SizedBox(height: 30),

// // // // //                           SizedBox(
// // // // //                             width: double.infinity,
// // // // //                             height: 50,
// // // // //                             child: ElevatedButton(
// // // // //                               style: ElevatedButton.styleFrom(
// // // // //                                 backgroundColor: const Color(0xFFD6ECB4),
// // // // //                                 shape: RoundedRectangleBorder(
// // // // //                                   borderRadius: BorderRadius.circular(12),
// // // // //                                 ),
// // // // //                               ),
// // // // //                               onPressed: _isLoading ? null : _registerUser,
// // // // //                               child:
// // // // //                                   _isLoading
// // // // //                                       ? const CircularProgressIndicator(
// // // // //                                         color: Colors.black,
// // // // //                                       )
// // // // //                                       : const Text(
// // // // //                                         'Register',
// // // // //                                         style: TextStyle(
// // // // //                                           fontSize: 18,
// // // // //                                           color: Colors.black,
// // // // //                                         ),
// // // // //                                       ),
// // // // //                             ),
// // // // //                           ),
// // // // //                         ],
// // // // //                       ),
// // // // //                     ),
// // // // //                   ),
// // // // //                 ),
// // // // //               ),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   @override
// // // // //   void dispose() {
// // // // //     _nameController.dispose();
// // // // //     _mobileController.dispose();
// // // // //     _emailController.dispose();
// // // // //     _passwordController.dispose();
// // // // //     _confirmPassController.dispose();
// // // // //     super.dispose();
// // // // //   }
// // // // // }
// // // // import 'package:flutter/material.dart';
// // // // import 'package:shared_preferences/shared_preferences.dart';
// // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // import 'package:yoga/Auth/Otp_Verification.dart';
// // // // import 'package:yoga/Auth/login_screen.dart';
// // // // import 'package:yoga/navBar/bottom_navbar.dart';
// // // // import 'package:yoga/utils/Common_Input_Field.dart';
// // // // import 'package:yoga/utils/app_assests.dart';
// // // // import 'package:yoga/utils/colors.dart';
// // // // import 'package:yoga/utils/snacbar_message.dart';

// // // // class RegistrationScreen extends StatefulWidget {
// // // //   const RegistrationScreen({Key? key}) : super(key: key);

// // // //   @override
// // // //   State<RegistrationScreen> createState() => _RegistrationScreenState();
// // // // }

// // // // class _RegistrationScreenState extends State<RegistrationScreen> {
// // // //   final TextEditingController _nameController = TextEditingController();
// // // //   final TextEditingController _mobileController = TextEditingController();
// // // //   final TextEditingController _emailController = TextEditingController();
// // // //   final TextEditingController _passwordController = TextEditingController();
// // // //   final TextEditingController _confirmPassController = TextEditingController();

// // // //   bool _obscurePassword = true;
// // // //   bool _obscureConfirmPassword = true;
// // // //   bool _isLoading = false;

// // // //   final supabase = Supabase.instance.client;

// // // // //   Future<void> _registerUser() async {
// // // // //   if (_nameController.text.trim().isEmpty ||
// // // // //       _mobileController.text.trim().isEmpty ||
// // // // //       _emailController.text.trim().isEmpty ||
// // // // //       _passwordController.text.trim().isEmpty) {
// // // // //     showSnackBar(context, "Please fill all fields!");
// // // // //     return;
// // // // //   }

// // // // //   if (_passwordController.text.trim() != _confirmPassController.text.trim()) {
// // // // //     showSnackBar(context, "Passwords do not match!");
// // // // //     return;
// // // // //   }

// // // // //   if (_passwordController.text.trim().length < 6) {
// // // // //     showSnackBar(context, "Password must be at least 6 characters!");
// // // // //     return;
// // // // //   }

// // // // //   final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
// // // // //   if (!emailRegex.hasMatch(_emailController.text.trim())) {
// // // // //     showSnackBar(context, "Please enter a valid email!");
// // // // //     return;
// // // // //   }

// // // // //   String mobileNumber = _mobileController.text.trim();
// // // // //   if (mobileNumber.length != 10) {
// // // // //     showSnackBar(context, "Please enter a valid 10-digit mobile number!");
// // // // //     return;
// // // // //   }

// // // // //   setState(() {
// // // // //     _isLoading = true;
// // // // //   });

// // // // //   try {
// // // // //     String phoneNumber = '+91$mobileNumber';
// // // // //     print('📱 ========== REGISTRATION STARTED ==========');
// // // // //     print('📧 Email: ${_emailController.text.trim()}');
// // // // //     print('📱 Phone: $phoneNumber');
// // // // //     print('👤 Name: ${_nameController.text.trim()}');

// // // // //     final AuthResponse emailResponse = await supabase.auth.signUp(
// // // // //       email: _emailController.text.trim(),
// // // // //       password: _passwordController.text.trim(),
// // // // //       data: {
// // // // //         'name': _nameController.text.trim(),
// // // // //         'mobile_number': phoneNumber,
// // // // //       },
// // // // //     );

// // // // //     if (emailResponse.user != null) {
// // // // //       // ✅ Save user data to Users table
// // // // //       await supabase.rpc('create_user_profile', params: {
// // // // //         'user_id': emailResponse.user!.id,
// // // // //         'user_email': _emailController.text.trim(),
// // // // //         'user_name': _nameController.text.trim(),
// // // // //         'user_mobile': phoneNumber,
// // // // //         'user_password': _passwordController.text.trim(),
// // // // //         'user_c_password': _confirmPassController.text.trim(),
// // // // //       });

// // // // //       // ✅ Save user data locally (same as in login)
// // // // //       final prefs = await SharedPreferences.getInstance();
// // // // //       await prefs.setString('user_id', emailResponse.user!.id);
// // // // //       await prefs.setString('name', _nameController.text.trim());
// // // // //       await prefs.setString('email', _emailController.text.trim());
// // // // //       await prefs.setString('password', _passwordController.text.trim());
// // // // //       await prefs.setString('mobile_number', phoneNumber);

// // // // //       print('💾 Complete user data saved locally (after registration)');

// // // // //       showSnackBar(context, "Registration successful! Welcome, ${_nameController.text.trim()}");

// // // // //       // ✅ Navigate directly to Main Screen (optional)
// // // // //       Navigator.pushReplacement(
// // // // //         context,
// // // // //         MaterialPageRoute(builder: (_) => const MainNavbar()),
// // // // //       );
// // // // //     }
// // // // //   } on AuthException catch (e) {
// // // // //     setState(() => _isLoading = false);
// // // // //     print('❌ Auth Error: ${e.message}');
// // // // //     if (e.message.contains('already registered')) {
// // // // //       showSnackBar(context, "Email already registered. Please login.");
// // // // //     } else {
// // // // //       showSnackBar(context, e.message);
// // // // //     }
// // // // //   } catch (e) {
// // // // //     setState(() => _isLoading = false);
// // // // //     print('❌ Error: ${e.toString()}');
// // // // //     showSnackBar(context, "Registration failed. Please try again.");
// // // // //   } finally {
// // // // //     setState(() => _isLoading = false);
// // // // //   }
// // // // // }

// // // //   Future<void> _registerUser() async {
// // // //     // Validation
// // // //     if (_nameController.text.trim().isEmpty ||
// // // //         _mobileController.text.trim().isEmpty ||
// // // //         _emailController.text.trim().isEmpty ||
// // // //         _passwordController.text.trim().isEmpty) {
// // // //       showSnackBar(context, "Please fill all fields!");
// // // //       return;
// // // //     }

// // // //     if (_passwordController.text.trim() != _confirmPassController.text.trim()) {
// // // //       showSnackBar(context, "Passwords do not match!");
// // // //       return;
// // // //     }

// // // //     if (_passwordController.text.trim().length < 6) {
// // // //       showSnackBar(context, "Password must be at least 6 characters!");
// // // //       return;
// // // //     }

// // // //     // Email validation
// // // //     final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
// // // //     if (!emailRegex.hasMatch(_emailController.text.trim())) {
// // // //       showSnackBar(context, "Please enter a valid email!");
// // // //       return;
// // // //     }

// // // //     // Mobile validation
// // // //     String mobileNumber = _mobileController.text.trim();
// // // //     if (mobileNumber.length != 10) {
// // // //       showSnackBar(context, "Please enter a valid 10-digit mobile number!");
// // // //       return;
// // // //     }

// // // //     setState(() {
// // // //       _isLoading = true;
// // // //     });

// // // //     try {
// // // //       // Format phone number with country code
// // // //       String phoneNumber = '+91$mobileNumber';

// // // //       print('📱 ========== REGISTRATION STARTED ==========');
// // // //       print('📧 Email: ${_emailController.text.trim()}');
// // // //       print('📱 Phone: $phoneNumber');
// // // //       print('👤 Name: ${_nameController.text.trim()}');

// // // //       // STEP 1: Sign up with Email & Password (Auto-confirmed)
// // // //       final AuthResponse emailResponse = await supabase.auth.signUp(
// // // //         email: _emailController.text.trim(),
// // // //         password: _passwordController.text.trim(),
// // // //         data: {
// // // //           'name': _nameController.text.trim(),
// // // //           'mobile_number': phoneNumber,
// // // //         },
// // // //       );

// // // //       print('✅ Email signup successful!');
// // // //       print('🆔 User ID: ${emailResponse.user?.id}');
// // // //       print('📧 Email Auto-Confirmed: ${emailResponse.user?.emailConfirmedAt != null}');

// // // //       if (emailResponse.user != null) {
// // // //         // STEP 2: Store user data in Users table using RPC function
// // // //         try {
// // // //           print('💾 Saving user data to database...');

// // // //           final result = await supabase.rpc('create_user_profile', params: {
// // // //             'user_id': emailResponse.user!.id,
// // // //             'user_email': _emailController.text.trim(),
// // // //             'user_name': _nameController.text.trim(),
// // // //             'user_mobile': phoneNumber,
// // // //             'user_password': _passwordController.text.trim(),
// // // //             'user_c_password': _confirmPassController.text.trim(),
// // // //           });

// // // //           print('📊 RPC Result: $result');
// // // //              // ✅ Save user data locally (same as in login)
// // // //       final prefs = await SharedPreferences.getInstance();
// // // //       await prefs.setString('user_id', emailResponse.user!.id);
// // // //       await prefs.setString('name', _nameController.text.trim());
// // // //       await prefs.setString('email', _emailController.text.trim());
// // // //       await prefs.setString('password', _passwordController.text.trim());
// // // //       await prefs.setString('mobile_number', phoneNumber);

// // // //           if (result != null && result['success'] == true) {
// // // //             print('💾 ✅ User data saved to Users table successfully!');
// // // //           } else {
// // // //             throw Exception(result?['error'] ?? 'Unknown error');
// // // //           }
// // // //         } catch (e) {
// // // //           setState(() {
// // // //             _isLoading = false;
// // // //           });
// // // //           print('❌ Database insert failed: $e');

// // // //           // Show detailed error
// // // //           if (e.toString().contains('PGRST204')) {
// // // //             showSnackBar(context, "Database error: Missing columns. Please run SQL setup.");
// // // //           } else if (e.toString().contains('23505')) {
// // // //             showSnackBar(context, "User already exists!");
// // // //           } else {
// // // //             showSnackBar(context, "Failed to save user data: ${e.toString()}");
// // // //           }
// // // //           return;
// // // //         }

// // // //         // STEP 3: Send OTP (optional - for phone verification)
// // // //         try {
// // // //           await supabase.auth.signInWithOtp(phone: phoneNumber);
// // // //           print('📲 Mobile OTP sent to $phoneNumber');
// // // //         } catch (e) {
// // // //           print('⚠️ Mobile OTP error (continuing anyway): $e');
// // // //         }

// // // //         setState(() {
// // // //           _isLoading = false;
// // // //         });

// // // //         print('🎉 Registration completed!');
// // // //         print('✅ Email auto-verified');
// // // //         print('📊 Data saved to database');
// // // //         print('📱 Navigating to OTP screen...');
// // // //         print('============================================\n');

// // // //         showSnackBar(context, "Registration successful! Verify OTP");

// // // //         // STEP 4: Navigate to OTP Screen
// // // //         Navigator.pushReplacement(
// // // //           context,
// // // //           MaterialPageRoute(
// // // //             builder: (context) => MobileOTPScreen(
// // // //               phoneNumber: phoneNumber,
// // // //               email: _emailController.text.trim(),
// // // //               userId: emailResponse.user!.id,
// // // //             ),
// // // //           ),
// // // //         );
// // // //       }
// // // //     } on AuthException catch (e) {
// // // //       setState(() {
// // // //         _isLoading = false;
// // // //       });
// // // //       print('❌ Auth Error: ${e.message}');

// // // //       // Show user-friendly error messages
// // // //       if (e.message.contains('already registered')) {
// // // //         showSnackBar(context, "Email already registered. Please login.");
// // // //       } else {
// // // //         showSnackBar(context, e.message);
// // // //       }
// // // //     } catch (e) {
// // // //       setState(() {
// // // //         _isLoading = false;
// // // //       });
// // // //       print('❌ Error: ${e.toString()}');
// // // //       showSnackBar(context, "Registration failed. Please try again.");
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       backgroundColor: AppColors.primary,
// // // //       body: SafeArea(
// // // //         child: Column(
// // // //           children: [
// // // //             const SizedBox(height: 40),

// // // //             // Logo
// // // //             Align(
// // // //               alignment: Alignment.centerLeft,
// // // //               child: Padding(
// // // //                 padding: const EdgeInsets.only(left: 25),
// // // //                 child: Image.asset(AppAssets.yogaGirl, height: 60),
// // // //               ),
// // // //             ),

// // // //             const SizedBox(height: 20),

// // // //             // Title
// // // //             Padding(
// // // //               padding: const EdgeInsets.only(left: 25),
// // // //               child: Align(
// // // //                 alignment: Alignment.centerLeft,
// // // //                 child: Text(
// // // //                   'Register',
// // // //                   style: const TextStyle(
// // // //                     fontSize: 28,
// // // //                     fontWeight: FontWeight.bold,
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ),

// // // //             const SizedBox(height: 5),

// // // //             // Already have account
// // // //             Padding(
// // // //               padding: const EdgeInsets.only(left: 25),
// // // //               child: Align(
// // // //                 alignment: Alignment.centerLeft,
// // // //                 child: GestureDetector(
// // // //                   onTap: () {
// // // //                     Navigator.pushReplacement(
// // // //                       context,
// // // //                       MaterialPageRoute(builder: (context) => LoginScreen()),
// // // //                     );
// // // //                   },
// // // //                   child: RichText(
// // // //                     text: const TextSpan(
// // // //                       text: "Already have an account? ",
// // // //                       style: TextStyle(
// // // //                         color: Colors.black,
// // // //                         fontWeight: FontWeight.w400,
// // // //                       ),
// // // //                       children: [
// // // //                         TextSpan(
// // // //                           text: "LOGIN",
// // // //                           style: TextStyle(
// // // //                             color: Colors.black,
// // // //                             fontWeight: FontWeight.bold,
// // // //                           ),
// // // //                         ),
// // // //                       ],
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ),

// // // //             const SizedBox(height: 30),

// // // //             Expanded(
// // // //               child: Container(
// // // //                 width: double.infinity,
// // // //                 decoration: const BoxDecoration(
// // // //                   color: Colors.white,
// // // //                   borderRadius: BorderRadius.only(
// // // //                     topLeft: Radius.circular(25),
// // // //                     topRight: Radius.circular(25),
// // // //                   ),
// // // //                 ),
// // // //                 child: Padding(
// // // //                   padding: const EdgeInsets.all(18.0),
// // // //                   child: SingleChildScrollView(
// // // //                     child: Container(
// // // //                       padding: const EdgeInsets.all(18),
// // // //                       decoration: BoxDecoration(
// // // //                         color: Colors.grey.shade200,
// // // //                         borderRadius: BorderRadius.circular(12),
// // // //                       ),
// // // //                       child: Column(
// // // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // // //                         children: [
// // // //                           CommonInputField(
// // // //                             controller: _nameController,
// // // //                             label: "Full Name",
// // // //                             hintText: "John Doe",
// // // //                           ),
// // // //                           const SizedBox(height: 20),

// // // //                           CommonInputField(
// // // //                             controller: _mobileController,
// // // //                             label: "Mobile Number",
// // // //                             hintText: "9876543210",
// // // //                           ),
// // // //                           const SizedBox(height: 20),

// // // //                           CommonInputField(
// // // //                             controller: _emailController,
// // // //                             label: "Email",
// // // //                             hintText: "example@gmail.com",
// // // //                           ),
// // // //                           const SizedBox(height: 20),

// // // //                           CommonInputField(
// // // //                             controller: _passwordController,
// // // //                             label: "Password",
// // // //                             hintText: "********",
// // // //                             isPassword: _obscurePassword,
// // // //                             onToggle: () {
// // // //                               setState(() {
// // // //                                 _obscurePassword = !_obscurePassword;
// // // //                               });
// // // //                             },
// // // //                           ),
// // // //                           const SizedBox(height: 20),

// // // //                           CommonInputField(
// // // //                             controller: _confirmPassController,
// // // //                             label: "Confirm Password",
// // // //                             hintText: "********",
// // // //                             isPassword: _obscureConfirmPassword,
// // // //                             onToggle: () {
// // // //                               setState(() {
// // // //                                 _obscureConfirmPassword =
// // // //                                     !_obscureConfirmPassword;
// // // //                               });
// // // //                             },
// // // //                           ),

// // // //                           const SizedBox(height: 30),

// // // //                           SizedBox(
// // // //                             width: double.infinity,
// // // //                             height: 50,
// // // //                             child: ElevatedButton(
// // // //                               style: ElevatedButton.styleFrom(
// // // //                                 backgroundColor: const Color(0xFFD6ECB4),
// // // //                                 shape: RoundedRectangleBorder(
// // // //                                   borderRadius: BorderRadius.circular(12),
// // // //                                 ),
// // // //                               ),
// // // //                               onPressed: _isLoading ? null : _registerUser,
// // // //                               child: _isLoading
// // // //                                   ? const CircularProgressIndicator(
// // // //                                       color: Colors.black,
// // // //                                     )
// // // //                                   : const Text(
// // // //                                       'Register',
// // // //                                       style: TextStyle(
// // // //                                         fontSize: 18,
// // // //                                         color: Colors.black,
// // // //                                       ),
// // // //                                     ),
// // // //                             ),
// // // //                           ),
// // // //                         ],
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     _nameController.dispose();
// // // //     _mobileController.dispose();
// // // //     _emailController.dispose();
// // // //     _passwordController.dispose();
// // // //     _confirmPassController.dispose();
// // // //     super.dispose();
// // // //   }
// // // // }
// // // import 'package:flutter/material.dart';
// // // import 'package:shared_preferences/shared_preferences.dart';
// // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // import 'package:yoga/Auth/Otp_Verification.dart';
// // // import 'package:yoga/Auth/login_screen.dart';
// // // import 'package:yoga/utils/Common_Input_Field.dart';
// // // import 'package:yoga/utils/app_assests.dart';
// // // import 'package:yoga/utils/colors.dart';
// // // import 'package:yoga/utils/snacbar_message.dart';

// // // class RegistrationScreen extends StatefulWidget {
// // //   const RegistrationScreen({Key? key}) : super(key: key);

// // //   @override
// // //   State<RegistrationScreen> createState() => _RegistrationScreenState();
// // // }

// // // class _RegistrationScreenState extends State<RegistrationScreen> {
// // //   final TextEditingController _nameController = TextEditingController();
// // //   final TextEditingController _mobileController = TextEditingController();
// // //   final TextEditingController _emailController = TextEditingController();
// // //   final TextEditingController _passwordController = TextEditingController();
// // //   final TextEditingController _confirmPassController = TextEditingController();

// // //   bool _obscurePassword = true;
// // //   bool _obscureConfirmPassword = true;
// // //   bool _isLoading = false;

// // //   final supabase = Supabase.instance.client;

// // //   Future<void> _registerUser() async {
// // //     // ✅ Validation
// // //     if (_nameController.text.trim().isEmpty ||
// // //         _mobileController.text.trim().isEmpty ||
// // //         _emailController.text.trim().isEmpty ||
// // //         _passwordController.text.trim().isEmpty) {
// // //       showSnackBar(context, "Please fill all fields!");
// // //       return;
// // //     }

// // //     if (_passwordController.text.trim() != _confirmPassController.text.trim()) {
// // //       showSnackBar(context, "Passwords do not match!");
// // //       return;
// // //     }

// // //     if (_passwordController.text.trim().length < 6) {
// // //       showSnackBar(context, "Password must be at least 6 characters!");
// // //       return;
// // //     }

// // //     final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
// // //     if (!emailRegex.hasMatch(_emailController.text.trim())) {
// // //       showSnackBar(context, "Please enter a valid email!");
// // //       return;
// // //     }

// // //     String mobileNumber = _mobileController.text.trim();
// // //     if (mobileNumber.length != 10) {
// // //       showSnackBar(context, "Please enter a valid 10-digit mobile number!");
// // //       return;
// // //     }

// // //     setState(() => _isLoading = true);

// // //     try {
// // //       String phoneNumber = '+91$mobileNumber';

// // //       print('📱 ========== REGISTRATION STARTED ==========');
// // //       print('📧 Email: ${_emailController.text.trim()}');
// // //       print('📱 Phone: $phoneNumber');
// // //       print('👤 Name: ${_nameController.text.trim()}');

// // //       // 🔐 STEP 1: Supabase Auth Signup (Password encrypted automatically)
// // //       final AuthResponse response = await supabase.auth.signUp(
// // //         email: _emailController.text.trim(),
// // //         password: _passwordController.text.trim(),
// // //         data: {
// // //           'name': _nameController.text.trim(),
// // //           'mobile_number': phoneNumber,
// // //         },
// // //       );

// // //       print('✅ Supabase Auth Signup Successful!');
// // //       print('🆔 User ID: ${response.user?.id}');
// // //       print('📧 Email: ${response.user?.email}');

// // //       if (response.user == null) {
// // //         throw Exception('Signup failed: No user returned');
// // //       }

// // //       // 🔍 STEP 2: Verify user was created in database (auto-trigger should handle this)
// // //       // Wait a moment for trigger to execute
// // //       await Future.delayed(const Duration(seconds: 1));

// // //       final dbUser =
// // //           await supabase
// // //               .from('Users')
// // //               .select()
// // //               .eq('id', response.user!.id)
// // //               .maybeSingle();

// // //       print('📊 Database User: $dbUser');

// // //       if (dbUser == null) {
// // //         print('⚠️ Auto-trigger failed, manually creating profile...');

// // //         // Manually create profile if trigger failed
// // //         final result = await supabase.rpc(
// // //           'create_user_profile',
// // //           params: {
// // //             'user_id': response.user!.id,
// // //             'user_email': _emailController.text.trim(),
// // //             'user_name': _nameController.text.trim(),
// // //             'user_mobile': phoneNumber,
// // //           },
// // //         );

// // //         if (result == null || result['success'] != true) {
// // //           throw Exception('Failed to create user profile: ${result?['error']}');
// // //         }
// // //       }

// // //       // 💾 STEP 3: Save to local storage (for offline access)
// // //       final prefs = await SharedPreferences.getInstance();
// // //       await prefs.setString('user_id', response.user!.id);
// // //       await prefs.setString('name', _nameController.text.trim());
// // //       await prefs.setString('email', _emailController.text.trim());
// // //       await prefs.setString('mobile_number', phoneNumber);
// // //       await prefs.setBool('is_logged_in', true);

// // //       print('💾 User data saved locally');

// // //       // 📱 STEP 4: Send OTP for phone verification (optional)
// // //       try {
// // //         await supabase.auth.signInWithOtp(phone: phoneNumber);
// // //         print('📲 OTP sent to $phoneNumber');
// // //       } catch (e) {
// // //         print('⚠️ OTP send failed (continuing): $e');
// // //       }

// // //       setState(() => _isLoading = false);

// // //       print('🎉 REGISTRATION COMPLETE!');
// // //       print('============================================\n');

// // //       showSnackBar(context, "Registration successful! Verify OTP");

// // //       // 🚀 STEP 5: Navigate to OTP Screen
// // //       Navigator.pushReplacement(
// // //         context,
// // //         MaterialPageRoute(
// // //           builder:
// // //               (context) => MobileOTPScreen(
// // //                 phoneNumber: phoneNumber,
// // //                 email: _emailController.text.trim(),
// // //                 userId: response.user!.id,
// // //               ),
// // //         ),
// // //       );
// // //     } on AuthException catch (e) {
// // //       setState(() => _isLoading = false);
// // //       print('❌ Auth Error: ${e.message}');

// // //       if (e.message.contains('already registered') ||
// // //           e.message.contains('User already registered')) {
// // //         showSnackBar(context, "Email already registered. Please login.");
// // //       } else if (e.message.contains('Invalid email')) {
// // //         showSnackBar(context, "Please enter a valid email address.");
// // //       } else {
// // //         showSnackBar(context, e.message);
// // //       }
// // //     } catch (e) {
// // //       setState(() => _isLoading = false);
// // //       print('❌ Unexpected Error: $e');
// // //       showSnackBar(context, "Registration failed. Please try again.");
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: AppColors.primary,
// // //       body: SafeArea(
// // //         child: Column(
// // //           children: [
// // //             const SizedBox(height: 40),

// // //             // Logo
// // //             Align(
// // //               alignment: Alignment.centerLeft,
// // //               child: Padding(
// // //                 padding: const EdgeInsets.only(left: 25),
// // //                 child: Image.asset(AppAssets.yogaGirl, height: 60),
// // //               ),
// // //             ),

// // //             const SizedBox(height: 20),

// // //             // Title
// // //             Padding(
// // //               padding: const EdgeInsets.only(left: 25),
// // //               child: Align(
// // //                 alignment: Alignment.centerLeft,
// // //                 child: Text(
// // //                   'Register',
// // //                   style: const TextStyle(
// // //                     fontSize: 28,
// // //                     fontWeight: FontWeight.bold,
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),

// // //             const SizedBox(height: 5),

// // //             // Already have account
// // //             Padding(
// // //               padding: const EdgeInsets.only(left: 25),
// // //               child: Align(
// // //                 alignment: Alignment.centerLeft,
// // //                 child: GestureDetector(
// // //                   onTap: () {
// // //                     Navigator.pushReplacement(
// // //                       context,
// // //                       MaterialPageRoute(builder: (context) => LoginScreen()),
// // //                     );
// // //                   },
// // //                   child: RichText(
// // //                     text: const TextSpan(
// // //                       text: "Already have an account? ",
// // //                       style: TextStyle(
// // //                         color: Colors.black,
// // //                         fontWeight: FontWeight.w400,
// // //                       ),
// // //                       children: [
// // //                         TextSpan(
// // //                           text: "LOGIN",
// // //                           style: TextStyle(
// // //                             color: Colors.black,
// // //                             fontWeight: FontWeight.bold,
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),

// // //             const SizedBox(height: 30),

// // //             Expanded(
// // //               child: Container(
// // //                 width: double.infinity,
// // //                 decoration: const BoxDecoration(
// // //                   color: Colors.white,
// // //                   borderRadius: BorderRadius.only(
// // //                     topLeft: Radius.circular(25),
// // //                     topRight: Radius.circular(25),
// // //                   ),
// // //                 ),
// // //                 child: Padding(
// // //                   padding: const EdgeInsets.all(18.0),
// // //                   child: SingleChildScrollView(
// // //                     child: Container(
// // //                       padding: const EdgeInsets.all(18),
// // //                       decoration: BoxDecoration(
// // //                         color: Colors.grey.shade200,
// // //                         borderRadius: BorderRadius.circular(12),
// // //                       ),
// // //                       child: Column(
// // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // //                         children: [
// // //                           CommonInputField(
// // //                             controller: _nameController,
// // //                             label: "Full Name",
// // //                             hintText: "John Doe",
// // //                           ),
// // //                           const SizedBox(height: 20),

// // //                           CommonInputField(
// // //                             controller: _mobileController,
// // //                             label: "Mobile Number",
// // //                             hintText: "9876543210",
// // //                           ),
// // //                           const SizedBox(height: 20),

// // //                           CommonInputField(
// // //                             controller: _emailController,
// // //                             label: "Email",
// // //                             hintText: "example@gmail.com",
// // //                           ),
// // //                           const SizedBox(height: 20),

// // //                           CommonInputField(
// // //                             controller: _passwordController,
// // //                             label: "Password",
// // //                             hintText: "********",
// // //                             isPassword: _obscurePassword,
// // //                             onToggle: () {
// // //                               setState(() {
// // //                                 _obscurePassword = !_obscurePassword;
// // //                               });
// // //                             },
// // //                           ),
// // //                           const SizedBox(height: 20),

// // //                           CommonInputField(
// // //                             controller: _confirmPassController,
// // //                             label: "Confirm Password",
// // //                             hintText: "********",
// // //                             isPassword: _obscureConfirmPassword,
// // //                             onToggle: () {
// // //                               setState(() {
// // //                                 _obscureConfirmPassword =
// // //                                     !_obscureConfirmPassword;
// // //                               });
// // //                             },
// // //                           ),

// // //                           const SizedBox(height: 30),

// // //                           SizedBox(
// // //                             width: double.infinity,
// // //                             height: 50,
// // //                             child: ElevatedButton(
// // //                               style: ElevatedButton.styleFrom(
// // //                                 backgroundColor: const Color(0xFFD6ECB4),
// // //                                 shape: RoundedRectangleBorder(
// // //                                   borderRadius: BorderRadius.circular(12),
// // //                                 ),
// // //                               ),
// // //                               onPressed: _isLoading ? null : _registerUser,
// // //                               child:
// // //                                   _isLoading
// // //                                       ? const CircularProgressIndicator(
// // //                                         color: Colors.black,
// // //                                       )
// // //                                       : const Text(
// // //                                         'Register',
// // //                                         style: TextStyle(
// // //                                           fontSize: 18,
// // //                                           color: Colors.black,
// // //                                         ),
// // //                                       ),
// // //                             ),
// // //                           ),
// // //                         ],
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _nameController.dispose();
// // //     _mobileController.dispose();
// // //     _emailController.dispose();
// // //     _passwordController.dispose();
// // //     _confirmPassController.dispose();
// // //     super.dispose();
// // //   }
// // // }
// // import 'package:flutter/material.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import 'package:crypto/crypto.dart';
// // import 'dart:convert';
// // import 'package:yoga/Auth/Otp_Verification.dart';
// // import 'package:yoga/Auth/login_screen.dart';
// // import 'package:yoga/utils/Common_Input_Field.dart';
// // import 'package:yoga/utils/app_assests.dart';
// // import 'package:yoga/utils/colors.dart';
// // import 'package:yoga/utils/snacbar_message.dart';

// // class RegistrationScreen extends StatefulWidget {
// //   const RegistrationScreen({Key? key}) : super(key: key);

// //   @override
// //   State<RegistrationScreen> createState() => _RegistrationScreenState();
// // }

// // class _RegistrationScreenState extends State<RegistrationScreen> {
// //   final TextEditingController _nameController = TextEditingController();
// //   final TextEditingController _mobileController = TextEditingController();
// //   final TextEditingController _emailController = TextEditingController();
// //   final TextEditingController _passwordController = TextEditingController();
// //   final TextEditingController _confirmPassController = TextEditingController();

// //   bool _obscurePassword = true;
// //   bool _obscureConfirmPassword = true;
// //   bool _isLoading = false;

// //   final supabase = Supabase.instance.client;

// //   // 🔐 Password Encryption Function
// //   String encryptPassword(String password) {
// //     final bytes = utf8.encode(password);
// //     final hash = sha256.convert(bytes);
// //     return hash.toString();
// //   }

// //   // Future<void> _registerUser() async {
// //   //   // ✅ Validation
// //   //   if (_nameController.text.trim().isEmpty ||
// //   //       _mobileController.text.trim().isEmpty ||
// //   //       // _emailController.text.trim().isEmpty ||
// //   //       _passwordController.text.trim().isEmpty) {
// //   //     showSnackBar(context, "Please fill all fields!");
// //   //     return;
// //   //   }

// //   //   if (_passwordController.text.trim() != _confirmPassController.text.trim()) {
// //   //     showSnackBar(context, "Passwords do not match!");
// //   //     return;
// //   //   }

// //   //   if (_passwordController.text.trim().length < 6) {
// //   //     showSnackBar(context, "Password must be at least 6 characters!");
// //   //     return;
// //   //   }

// //   //   // final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
// //   //   // if (!emailRegex.hasMatch(_emailController.text.trim())) {
// //   //   //   showSnackBar(context, "Please enter a valid email!");
// //   //   //   return;
// //   //   // }

// //   //   String mobileNumber = _mobileController.text.trim();
// //   //   if (mobileNumber.length != 10) {
// //   //     showSnackBar(context, "Please enter a valid 10-digit mobile number!");
// //   //     return;
// //   //   }

// //   //   setState(() => _isLoading = true);

// //   //   try {
// //   //     String phoneNumber = '+91$mobileNumber';
// //   //     String encryptedPassword = encryptPassword(
// //   //       _passwordController.text.trim(),
// //   //     );

// //   //     print('📱 ========== REGISTRATION STARTED ==========');
// //   //     print('📧 Email: ${_emailController.text.trim()}');
// //   //     print('📱 Phone: $phoneNumber');
// //   //     print('👤 Name: ${_nameController.text.trim()}');
// //   //     print('🔐 Password Hash: $encryptedPassword');

// //   //     // 🔐 STEP 1: Supabase Auth Signup
// //   //     final AuthResponse response = await supabase.auth.signUp(
// //   //       email: _emailController.text.trim(),
// //   //       password: _passwordController.text.trim(),
// //   //       data: {
// //   //         'name': _nameController.text.trim(),
// //   //         'mobile_number': phoneNumber,
// //   //       },
// //   //     );

// //   //     print('✅ Supabase Auth Signup Successful!');
// //   //     print('🆔 User ID: ${response.user?.id}');

// //   //     if (response.user == null) {
// //   //       throw Exception('Signup failed: No user returned');
// //   //     }

// //   //     // 🔍 STEP 2: Wait for auto-trigger
// //   //     await Future.delayed(const Duration(seconds: 2));

// //   //     print('🔍 Checking if user exists in Users table...');

// //   //     // Check if user exists
// //   //     final existingUser =
// //   //         await supabase
// //   //             .from('Users')
// //   //             .select()
// //   //             .eq('id', response.user!.id)
// //   //             .maybeSingle();

// //   //     print('📊 Existing User Data: $existingUser');

// //   //     if (existingUser != null) {
// //   //       // User exists, update with password hash
// //   //       print('✅ User found in table, updating password_hash...');

// //   //       final updateResult =
// //   //           await supabase
// //   //               .from('Users')
// //   //               .update({
// //   //                 'password': encryptedPassword, // Changed to 'password' field
// //   //               })
// //   //               .eq('id', response.user!.id)
// //   //               .select();

// //   //       print('📊 Update Result: $updateResult');

// //   //       if (updateResult.isEmpty) {
// //   //         throw Exception('Failed to update password in database');
// //   //       }

// //   //       print('✅ Password saved successfully!');
// //   //     } else {
// //   //       // User doesn't exist, create manually
// //   //       print('⚠️ User not found in table, creating profile...');

// //   //       final insertResult =
// //   //           await supabase.from('Users').insert({
// //   //             'id': response.user!.id,
// //   //             'email': _emailController.text.trim(),
// //   //             'name': _nameController.text.trim(),
// //   //             'mobile_number': phoneNumber,
// //   //             'password': encryptedPassword, // Changed to 'password' field
// //   //             'created_at': DateTime.now().toIso8601String(),
// //   //           }).select();

// //   //       print('📊 Insert Result: $insertResult');

// //   //       if (insertResult.isEmpty) {
// //   //         throw Exception('Failed to create user profile in database');
// //   //       }

// //   //       print('✅ User profile created with password!');
// //   //     }

// //   //     // 💾 STEP 4: Save to local storage (DON'T save password)
// //   //     final prefs = await SharedPreferences.getInstance();
// //   //     await prefs.setString('user_id', response.user!.id);
// //   //     await prefs.setString('name', _nameController.text.trim());
// //   //     await prefs.setString('email', _emailController.text.trim());
// //   //     await prefs.setString('mobile_number', phoneNumber);
// //   //     await prefs.setBool('is_logged_in', true);

// //   //     print('💾 User data saved locally');

// //   //     // 📱 STEP 5: Send OTP
// //   //     try {
// //   //       final otpResult = await OTPService.sendOTP(phoneNumber);
// //   //       if (otpResult['success']) {
// //   //         print('📲 OTP sent to $phoneNumber');
// //   //         print('🔢 OTP: ${otpResult['otp']}');
// //   //       } else {
// //   //         print('⚠️ OTP send failed: ${otpResult['error']}');
// //   //       }
// //   //     } catch (e) {
// //   //       print('⚠️ OTP send error (continuing): $e');
// //   //     }

// //   //     setState(() => _isLoading = false);

// //   //     print('🎉 REGISTRATION COMPLETE!');
// //   //     print('============================================\n');

// //   //     showSnackBar(context, "Registration successful! Verify OTP");

// //   //     // 🚀 STEP 6: Navigate to OTP Screen
// //   //     Navigator.pushReplacement(
// //   //       context,
// //   //       MaterialPageRoute(
// //   //         builder:
// //   //             (context) => MobileOTPScreen(
// //   //               phoneNumber: phoneNumber,
// //   //               email: _emailController.text.trim(),
// //   //               userId: response.user!.id,
// //   //             ),
// //   //       ),
// //   //     );
// //   //   } on AuthException catch (e) {
// //   //     setState(() => _isLoading = false);
// //   //     print('❌ Auth Error: ${e.message}');

// //   //     if (e.message.contains('already registered') ||
// //   //         e.message.contains('User already registered')) {
// //   //       showSnackBar(context, "Email already registered. Please login.");
// //   //     } else if (e.message.contains('Invalid email')) {
// //   //       showSnackBar(context, "Please enter a valid email address.");
// //   //     } else {
// //   //       showSnackBar(context, e.message);
// //   //     }
// //   //   } catch (e) {
// //   //     setState(() => _isLoading = false);
// //   //     print('❌ Unexpected Error: $e');
// //   //     showSnackBar(context, "Registration failed. Please try again.");
// //   //   }
// //   // }
// //   Future<void> _registerUser() async {
// //     // ✅ Validation
// //     if (_nameController.text.trim().isEmpty ||
// //         _mobileController.text.trim().isEmpty ||
// //         _passwordController.text.trim().isEmpty) {
// //       showSnackBar(context, "Please fill all required fields!");
// //       return;
// //     }

// //     if (_passwordController.text.trim() != _confirmPassController.text.trim()) {
// //       showSnackBar(context, "Passwords do not match!");
// //       return;
// //     }

// //     if (_passwordController.text.trim().length < 6) {
// //       showSnackBar(context, "Password must be at least 6 characters!");
// //       return;
// //     }

// //     String mobileNumber = _mobileController.text.trim();
// //     if (mobileNumber.length != 10) {
// //       showSnackBar(context, "Please enter a valid 10-digit mobile number!");
// //       return;
// //     }

// //     setState(() => _isLoading = true);

// //     try {
// //       String phoneNumber = '+91$mobileNumber';
// //       String encryptedPassword = encryptPassword(
// //         _passwordController.text.trim(),
// //       );
// //       final AuthResponse response = await supabase.auth.signUp(
// //         // email: _emailController.text.trim(),
// //         phone: phoneNumber,
// //         password: _passwordController.text.trim(),
// //         data: {
// //           'name': _nameController.text.trim(),
// //           'mobile_number': phoneNumber,
// //         },
// //       );
// //       print('📱 ========== REGISTRATION STARTED ==========');
// //       print('📱 Phone: $phoneNumber');
// //       print('👤 Name: ${_nameController.text.trim()}');
// //       print('🔐 Password Hash: $encryptedPassword');

// //       // 📱 STEP 1: Send OTP first
// //       try {
// //         final otpResult = await OTPService.sendOTP(phoneNumber);
// //         if (otpResult['success']) {
// //           print('📲 OTP sent to $phoneNumber');
// //           print('🔢 OTP: ${otpResult['otp']}');
// //         } else {
// //           throw Exception('Failed to send OTP: ${otpResult['error']}');
// //         }
// //       } catch (e) {
// //         throw Exception('OTP send error: $e');
// //       }

// //       setState(() => _isLoading = false);

// //       print('🎉 OTP SENT - VERIFY TO COMPLETE REGISTRATION!');
// //       print('============================================\n');

// //       showSnackBar(context, "OTP sent! Verify to register");

// //       // 🚀 STEP 2: Navigate to OTP Screen with registration data
// //       Navigator.pushReplacement(
// //         context,
// //         MaterialPageRoute(
// //           builder:
// //               (context) => MobileOTPScreen(
// //                 phoneNumber: phoneNumber,
// //                 userId: response.user!.id,
// //                 name: _nameController.text.trim(),
// //                 email:
// //                     _emailController.text.trim().isEmpty
// //                         ? null
// //                         : _emailController.text.trim(),
// //                 password: encryptedPassword,
// //                 isRegistration: true, // Flag to indicate this is registration
// //               ),
// //         ),
// //       );
// //     } on AuthException catch (e) {
// //       setState(() => _isLoading = false);
// //       print('❌ Auth Error: ${e.message}');
// //       showSnackBar(context, e.message);
// //     } catch (e) {
// //       setState(() => _isLoading = false);
// //       print('❌ Unexpected Error: $e');
// //       showSnackBar(context, "Registration failed. Please try again.");
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: AppColors.primary,
// //       body: SafeArea(
// //         child: Column(
// //           children: [
// //             const SizedBox(height: 40),

// //             // Logo
// //             Align(
// //               alignment: Alignment.centerLeft,
// //               child: Padding(
// //                 padding: const EdgeInsets.only(left: 25),
// //                 child: Image.asset(AppAssets.yogaGirl, height: 60),
// //               ),
// //             ),

// //             const SizedBox(height: 20),

// //             // Title
// //             Padding(
// //               padding: const EdgeInsets.only(left: 25),
// //               child: Align(
// //                 alignment: Alignment.centerLeft,
// //                 child: Text(
// //                   'Register',
// //                   style: const TextStyle(
// //                     fontSize: 28,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //               ),
// //             ),

// //             const SizedBox(height: 5),

// //             // Already have account
// //             Padding(
// //               padding: const EdgeInsets.only(left: 25),
// //               child: Align(
// //                 alignment: Alignment.centerLeft,
// //                 child: GestureDetector(
// //                   onTap: () {
// //                     Navigator.pushReplacement(
// //                       context,
// //                       MaterialPageRoute(builder: (context) => LoginScreen()),
// //                     );
// //                   },
// //                   child: RichText(
// //                     text: const TextSpan(
// //                       text: "Already have an account? ",
// //                       style: TextStyle(
// //                         color: Colors.black,
// //                         fontWeight: FontWeight.w400,
// //                       ),
// //                       children: [
// //                         TextSpan(
// //                           text: "LOGIN",
// //                           style: TextStyle(
// //                             color: Colors.black,
// //                             fontWeight: FontWeight.bold,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),

// //             const SizedBox(height: 30),

// //             Expanded(
// //               child: Container(
// //                 width: double.infinity,
// //                 decoration: const BoxDecoration(
// //                   color: Colors.white,
// //                   borderRadius: BorderRadius.only(
// //                     topLeft: Radius.circular(25),
// //                     topRight: Radius.circular(25),
// //                   ),
// //                 ),
// //                 child: Padding(
// //                   padding: const EdgeInsets.all(18.0),
// //                   child: SingleChildScrollView(
// //                     child: Container(
// //                       padding: const EdgeInsets.all(18),
// //                       decoration: BoxDecoration(
// //                         color: Colors.grey.shade200,
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           CommonInputField(
// //                             controller: _nameController,
// //                             label: "Full Name",
// //                             hintText: "John Doe",
// //                           ),
// //                           const SizedBox(height: 20),

// //                           CommonInputField(
// //                             controller: _mobileController,
// //                             label: "Mobile Number",
// //                             hintText: "9876543210",
// //                           ),
// //                           const SizedBox(height: 20),

// //                           CommonInputField(
// //                             controller: _emailController,
// //                             label: "Email(Optional)",
// //                             hintText: "example@gmail.com",
// //                           ),
// //                           const SizedBox(height: 20),

// //                           CommonInputField(
// //                             controller: _passwordController,
// //                             label: "Password",
// //                             hintText: "********",
// //                             isPassword: _obscurePassword,
// //                             onToggle: () {
// //                               setState(() {
// //                                 _obscurePassword = !_obscurePassword;
// //                               });
// //                             },
// //                           ),
// //                           const SizedBox(height: 20),

// //                           CommonInputField(
// //                             controller: _confirmPassController,
// //                             label: "Confirm Password",
// //                             hintText: "********",
// //                             isPassword: _obscureConfirmPassword,
// //                             onToggle: () {
// //                               setState(() {
// //                                 _obscureConfirmPassword =
// //                                     !_obscureConfirmPassword;
// //                               });
// //                             },
// //                           ),

// //                           const SizedBox(height: 30),

// //                           SizedBox(
// //                             width: double.infinity,
// //                             height: 50,
// //                             child: ElevatedButton(
// //                               style: ElevatedButton.styleFrom(
// //                                 backgroundColor: const Color(0xFFD6ECB4),
// //                                 shape: RoundedRectangleBorder(
// //                                   borderRadius: BorderRadius.circular(12),
// //                                 ),
// //                               ),
// //                               onPressed: _isLoading ? null : _registerUser,
// //                               child:
// //                                   _isLoading
// //                                       ? const CircularProgressIndicator(
// //                                         color: Colors.black,
// //                                       )
// //                                       : const Text(
// //                                         'Register',
// //                                         style: TextStyle(
// //                                           fontSize: 18,
// //                                           color: Colors.black,
// //                                         ),
// //                                       ),
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _nameController.dispose();
// //     _mobileController.dispose();
// //     _emailController.dispose();
// //     _passwordController.dispose();
// //     _confirmPassController.dispose();
// //     super.dispose();
// //   }
// // }
// import 'dart:convert';
// import 'dart:math';

// import 'package:crypto/crypto.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:yoga/Auth/Otp_Verification.dart';
// import 'package:yoga/Auth/login_screen.dart';
// import 'package:yoga/utils/Common_Input_Field.dart';
// import 'package:yoga/utils/app_assests.dart';
// import 'package:yoga/utils/colors.dart';
// import 'package:yoga/utils/snacbar_message.dart';

// class OTPService {
//   static final supabase = Supabase.instance.client;

//   static Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
//     try {
//       print('📱 ========== GENERATING OTP ==========');
//       print('📞 Phone: $phoneNumber');

//       final response = await supabase.rpc(
//         'generate_otp',
//         params: {'p_phone_number': phoneNumber},
//       );

//       print('📊 Response: $response');

//       if (response != null && response['success'] == true) {
//         print('✅ OTP Generated: ${response['otp']}');
//         print('🆔 OTP ID: ${response['otp_id']}');
//         print('============================================\n');

//         return {
//           'success': true,
//           'otp': response['otp'],
//           'message': response['message'],
//         };
//       } else {
//         print('❌ Failed to generate OTP');
//         return {
//           'success': false,
//           'error': response?['error'] ?? 'Unknown error',
//         };
//       }
//     } catch (e) {
//       print('❌ Error sending OTP: $e');
//       return {'success': false, 'error': e.toString()};
//     }
//   }

//   static Future<Map<String, dynamic>> verifyOTP(
//     String phoneNumber,
//     String otpCode,
//   ) async {
//     try {
//       print('🔍 ========== VERIFYING OTP ==========');
//       print('📞 Phone: $phoneNumber');
//       print('🔢 OTP: $otpCode');

//       final response = await supabase.rpc(
//         'verify_otp',
//         params: {'p_phone_number': phoneNumber, 'p_otp_code': otpCode},
//       );

//       print('📊 Response: $response');

//       if (response != null && response['success'] == true) {
//         print('✅ OTP Verified Successfully!');
//         print('============================================\n');

//         return {'success': true, 'message': response['message']};
//       } else {
//         print('❌ OTP Verification Failed');
//         print('============================================\n');

//         return {'success': false, 'error': response?['error'] ?? 'Invalid OTP'};
//       }
//     } catch (e) {
//       print('❌ Error verifying OTP: $e');
//       return {'success': false, 'error': e.toString()};
//     }
//   }

//   static Future<Map<String, dynamic>> resendOTP(String phoneNumber) async {
//     print('🔄 Resending OTP...');
//     return await sendOTP(phoneNumber);
//   }
// }

// class RegistrationScreen extends StatefulWidget {
//   const RegistrationScreen({Key? key}) : super(key: key);

//   @override
//   State<RegistrationScreen> createState() => _RegistrationScreenState();
// }

// class _RegistrationScreenState extends State<RegistrationScreen> {
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _mobileController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _confirmPassController = TextEditingController();

//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//   bool _isLoading = false;

//   final supabase = Supabase.instance.client;

//   // Password Encryption Function (SHA256)
//   String encryptPassword(String password) {
//     final bytes = utf8.encode(password);
//     final hash = sha256.convert(bytes);
//     return hash.toString();
//   }

//   // Local 6-digit OTP generator
//   String generateLocalOTP() {
//     final rnd = Random.secure();
//     final code = 100000 + rnd.nextInt(900000);
//     return code.toString();
//   }

//   Future<void> _registerUser() async {
//     // Validation
//     if (_nameController.text.trim().isEmpty ||
//         _mobileController.text.trim().isEmpty ||
//         _passwordController.text.trim().isEmpty) {
//       showSnackBar(context, "Please fill all required fields!");
//       return;
//     }

//     if (_passwordController.text.trim() != _confirmPassController.text.trim()) {
//       showSnackBar(context, "Passwords do not match!");
//       return;
//     }

//     if (_passwordController.text.trim().length < 6) {
//       showSnackBar(context, "Password must be at least 6 characters!");
//       return;
//     }

//     String mobileNumber = _mobileController.text.trim();
//     if (mobileNumber.length != 10) {
//       showSnackBar(context, "Please enter a valid 10-digit mobile number!");
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       String phoneNumber = '+91$mobileNumber';
//       String encryptedPassword = encryptPassword(
//         _passwordController.text.trim(),
//       );

//       // Generate local OTP (no Twilio)
//       final String localOtp = generateLocalOTP();

//       print('📱 ========== REGISTRATION STARTED (LOCAL OTP) ==========');
//       print('📱 Phone: $phoneNumber');
//       print('👤 Name: ${_nameController.text.trim()}');
//       print('🔐 Password Hash: $encryptedPassword');
//       print('🔢 LOCAL OTP: $localOtp');
//       print('========================================================\n');

//       setState(() => _isLoading = false);

//       // Show snackbar with test OTP (for dev/testing)
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         showSnackBar(context, "🧪 Test OTP: $localOtp");
//       });

//       // Navigate to OTP Screen passing local OTP and registration data
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder:
//               (context) => MobileOTPScreen(
//                 phoneNumber: phoneNumber,
//                 userId: null, // will be created after OTP verification
//                 name: _nameController.text.trim(),
//                 email:
//                     _emailController.text.trim().isEmpty
//                         ? null
//                         : _emailController.text.trim(),
//                 password: encryptedPassword,
//                 isRegistration: true,
//                 localOtp: localOtp,
//               ),
//         ),
//       );
//     } catch (e) {
//       setState(() => _isLoading = false);
//       print('❌ Unexpected Error: $e');
//       showSnackBar(context, "Registration failed. Please try again.");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.primary,
//       body: SafeArea(
//         child: Column(
//           children: [
//             const SizedBox(height: 40),

//             // Logo
//             Align(
//               alignment: Alignment.centerLeft,
//               child: Padding(
//                 padding: const EdgeInsets.only(left: 25),
//                 child: Image.asset(AppAssets.yogaGirl, height: 60),
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Title
//             Padding(
//               padding: const EdgeInsets.only(left: 25),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   'Register',
//                   style: const TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 5),

//             // Already have account
//             Padding(
//               padding: const EdgeInsets.only(left: 25),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: GestureDetector(
//                   onTap: () {
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(builder: (context) => LoginScreen()),
//                     );
//                   },
//                   child: RichText(
//                     text: const TextSpan(
//                       text: "Already have an account? ",
//                       style: TextStyle(
//                         color: Colors.black,
//                         fontWeight: FontWeight.w400,
//                       ),
//                       children: [
//                         TextSpan(
//                           text: "LOGIN",
//                           style: TextStyle(
//                             color: Colors.black,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 30),

//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(25),
//                     topRight: Radius.circular(25),
//                   ),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(18.0),
//                   child: SingleChildScrollView(
//                     child: Container(
//                       padding: const EdgeInsets.all(18),
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade200,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           CommonInputField(
//                             controller: _nameController,
//                             label: "Full Name",
//                             hintText: "John Doe",
//                           ),
//                           const SizedBox(height: 20),

//                           CommonInputField(
//                             controller: _mobileController,
//                             label: "Mobile Number",
//                             hintText: "9876543210",
//                           ),
//                           const SizedBox(height: 20),

//                           CommonInputField(
//                             controller: _emailController,
//                             label: "Email(Optional)",
//                             hintText: "example@gmail.com",
//                           ),
//                           const SizedBox(height: 20),

//                           CommonInputField(
//                             controller: _passwordController,
//                             label: "Password",
//                             hintText: "********",
//                             isPassword: _obscurePassword,
//                             onToggle: () {
//                               setState(() {
//                                 _obscurePassword = !_obscurePassword;
//                               });
//                             },
//                           ),
//                           const SizedBox(height: 20),

//                           CommonInputField(
//                             controller: _confirmPassController,
//                             label: "Confirm Password",
//                             hintText: "********",
//                             isPassword: _obscureConfirmPassword,
//                             onToggle: () {
//                               setState(() {
//                                 _obscureConfirmPassword =
//                                     !_obscureConfirmPassword;
//                               });
//                             },
//                           ),

//                           const SizedBox(height: 30),

//                           SizedBox(
//                             width: double.infinity,
//                             height: 50,
//                             child: ElevatedButton(
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xFFD6ECB4),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               onPressed: _isLoading ? null : _registerUser,
//                               child:
//                                   _isLoading
//                                       ? const CircularProgressIndicator(
//                                         color: Colors.black,
//                                       )
//                                       : const Text(
//                                         'Register',
//                                         style: TextStyle(
//                                           fontSize: 18,
//                                           color: Colors.black,
//                                         ),
//                                       ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
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
//     _nameController.dispose();
//     _mobileController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPassController.dispose();
//     super.dispose();
//   }
// }
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:yoga/Auth/Otp_Verification.dart';
import 'package:yoga/Auth/login_screen.dart';
import 'package:yoga/utils/Common_Input_Field.dart';
import 'package:yoga/utils/app_assests.dart';
import 'package:yoga/utils/colors.dart';
import 'package:yoga/utils/snacbar_message.dart';

class OTPService {
  static final supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    try {
      print('📱 ========== GENERATING OTP ==========');
      print('📞 Phone: $phoneNumber');

      final response = await supabase.rpc(
        'generate_otp',
        params: {'p_phone_number': phoneNumber},
      );

      print('📊 Response: $response');

      if (response != null && response['success'] == true) {
        print('✅ OTP Generated: ${response['otp']}');
        print('🆔 OTP ID: ${response['otp_id']}');
        print('============================================\n');

        return {
          'success': true,
          'otp': response['otp'],
          'message': response['message'],
        };
      } else {
        print('❌ Failed to generate OTP');
        return {
          'success': false,
          'error': response?['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      print('❌ Error sending OTP: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> verifyOTP(
    String phoneNumber,
    String otpCode,
  ) async {
    try {
      print('🔍 ========== VERIFYING OTP ==========');
      print('📞 Phone: $phoneNumber');
      print('🔢 OTP: $otpCode');

      final response = await supabase.rpc(
        'verify_otp',
        params: {'p_phone_number': phoneNumber, 'p_otp_code': otpCode},
      );

      print('📊 Response: $response');

      if (response != null && response['success'] == true) {
        print('✅ OTP Verified Successfully!');
        print('============================================\n');

        return {'success': true, 'message': response['message']};
      } else {
        print('❌ OTP Verification Failed');
        print('============================================\n');

        return {'success': false, 'error': response?['error'] ?? 'Invalid OTP'};
      }
    } catch (e) {
      print('❌ Error verifying OTP: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> resendOTP(String phoneNumber) async {
    print('🔄 Resending OTP...');
    return await sendOTP(phoneNumber);
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  // 🔐 Password Encryption Function
  String encryptPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // ===============================================================
  // ⭐ FINAL WORKING REGISTER FUNCTION — SUPABASE TEST MODE
  // ===============================================================
  Future<void> _registerUser() async {
    if (_nameController.text.trim().isEmpty ||
        _mobileController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      showSnackBar(context, "Please fill all required fields!");
      return;
    }

    if (_passwordController.text.trim() != _confirmPassController.text.trim()) {
      showSnackBar(context, "Passwords do not match!");
      return;
    }

    if (_passwordController.text.trim().length < 6) {
      showSnackBar(context, "Password must be at least 6 characters!");
      return;
    }

    String mobileNumber = _mobileController.text.trim();
    if (mobileNumber.length != 10) {
      showSnackBar(context, "Please enter a valid 10-digit mobile number!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final phoneNumber = '+91$mobileNumber';
      final encryptedPassword = encryptPassword(
        _passwordController.text.trim(),
      );

      print("=============== REGISTER START ===============");
      print("NAME: ${_nameController.text.trim()}");
      print("PHONE: $phoneNumber");

      // ========== SUPABASE SIGNUP ==========
      final response = await supabase.auth.signUp(
        phone: phoneNumber,
        password: _passwordController.text.trim(),
        data: {"name": _nameController.text.trim(), "mobile": phoneNumber},
      );

      if (response.user == null) {
        throw Exception("Supabase Signup failed");
      }

      print("USER CREATED (AUTH ID): ${response.user!.id}");
      print("TEST MODE OTP = 123456");

      // ========== SAVE LOCALLY IN SHARED PREFERENCES ==========
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("user_id", response.user!.id);
      await prefs.setString("name", _nameController.text.trim());
      await prefs.setString("mobile_number", phoneNumber);

      if (_emailController.text.trim().isNotEmpty) {
        await prefs.setString("email", _emailController.text.trim());
      }

      await prefs.setString("password", encryptedPassword);
      await prefs.setBool("is_logged_in", false); // Login only after OTP verify

      print("💾 Saved to SharedPreferences");

      setState(() => _isLoading = false);

      showSnackBar(context, "OTP sent! Verify to continue");

      // ========== NAVIGATE TO OTP SCREEN ==========
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => MobileOTPScreen(
                phoneNumber: phoneNumber,
                userId: response.user!.id,
                name: _nameController.text.trim(),
                email:
                    _emailController.text.trim().isNotEmpty
                        ? _emailController.text.trim()
                        : null,
                password: encryptedPassword,
                isRegistration: true,
              ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      print("❌ REGISTRATION ERROR: $e");
      showSnackBar(context, "Registration failed. Try again.");
    }
  }

  // Future<void> _registerUser() async {
  //   if (_nameController.text.trim().isEmpty ||
  //       _mobileController.text.trim().isEmpty ||
  //       _passwordController.text.trim().isEmpty) {
  //     showSnackBar(context, "Please fill all required fields!");
  //     return;
  //   }

  //   if (_passwordController.text.trim() != _confirmPassController.text.trim()) {
  //     showSnackBar(context, "Passwords do not match!");
  //     return;
  //   }

  //   if (_passwordController.text.trim().length < 6) {
  //     showSnackBar(context, "Password must be at least 6 characters!");
  //     return;
  //   }

  //   String mobileNumber = _mobileController.text.trim();
  //   if (mobileNumber.length != 10) {
  //     showSnackBar(context, "Please enter a valid 10-digit mobile number!");
  //     return;
  //   }

  //   setState(() => _isLoading = true);

  //   try {
  //     final phoneNumber = '+91$mobileNumber';
  //     final encryptedPassword = encryptPassword(_passwordController.text.trim());

  //     print("================ REGISTER STARTED ================");
  //     print("Name: ${_nameController.text}");
  //     print("Mobile: $phoneNumber");

  //     // 📌 Supabase Phone Auth (TEST MODE → OTP always 123456)
  //     final response = await supabase.auth.signUp(
  //       phone: phoneNumber,
  //       password: _passwordController.text.trim(),
  //       data: {
  //         "name": _nameController.text.trim(),
  //         "mobile": phoneNumber,
  //       },
  //     );

  //     if (response.user == null) {
  //       throw Exception("Signup failed");
  //     }

  //     print("USER CREATED → ID: ${response.user!.id}");
  //     print("OTP = 123456 (Supabase Test Mode)");

  //     setState(() => _isLoading = false);

  //     showSnackBar(context, "OTP sent! Verify to continue");

  //     // 🚀 NAVIGATE TO OTP SCREEN
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => MobileOTPScreen(
  //           phoneNumber: phoneNumber,
  //           userId: response.user!.id,
  //           name: _nameController.text.trim(),
  //           email: _emailController.text.trim().isNotEmpty
  //               ? _emailController.text.trim()
  //               : null,
  //           password: encryptedPassword,
  //           isRegistration: true,
  //         ),
  //       ),
  //     );
  //   } catch (e) {
  //     setState(() => _isLoading = false);
  //     print("❌ Error: $e");
  //     showSnackBar(context, "Registration failed. Try again.");
  //   }
  // }

  // // ===============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
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
                  'Register',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 5),

            Padding(
              padding: const EdgeInsets.only(left: 25),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        TextSpan(
                          text: "LOGIN",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            Expanded(
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
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommonInputField(
                            controller: _nameController,
                            label: "Full Name",
                            hintText: "John Doe",
                          ),
                          const SizedBox(height: 20),

                          CommonInputField(
                            controller: _mobileController,
                            label: "Mobile Number",
                            hintText: "9876543210",
                          ),
                          const SizedBox(height: 20),

                          CommonInputField(
                            controller: _emailController,
                            label: "Email(Optional)",
                            hintText: "example@gmail.com",
                          ),
                          const SizedBox(height: 20),

                          CommonInputField(
                            controller: _passwordController,
                            label: "Password",
                            hintText: "********",
                            isPassword: _obscurePassword,
                            onToggle: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          const SizedBox(height: 20),

                          CommonInputField(
                            controller: _confirmPassController,
                            label: "Confirm Password",
                            hintText: "********",
                            isPassword: _obscureConfirmPassword,
                            onToggle: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),

                          const SizedBox(height: 30),

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
                              onPressed: _isLoading ? null : _registerUser,
                              child:
                                  _isLoading
                                      ? const CircularProgressIndicator(
                                        color: Colors.black,
                                      )
                                      : const Text(
                                        'Register',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
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
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }
}
