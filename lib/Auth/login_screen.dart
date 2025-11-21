import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:yoga/Auth/Forgot_Password-Enter_Number.dart';
import 'package:yoga/Auth/Registration_Screen.dart';
import 'package:yoga/navBar/bottom_navbar.dart';
import 'package:yoga/utils/Common_Input_Field.dart';
import 'package:yoga/utils/app_assests.dart';
import 'package:yoga/utils/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // 🔐 Password Encryption Function (SAME as Registration)
  String encryptPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('user_id');
    if (savedUserId != null && savedUserId.isNotEmpty) {
      print('🔁 User already logged in with ID: $savedUserId');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavbar()),
      );
    }
  }

  String _formatPhoneNumber(String phone) {
    phone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.startsWith('+91')) {
      return phone;
    }
    if (phone.startsWith('91') && phone.length > 10) {
      return '+$phone';
    }
    return '+91$phone';
  }

  Future<void> _loginUser() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    // Validate phone number length
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter valid 10-digit phone number"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🔐 ========== LOGIN STARTED ==========');
      print('📱 Entered Phone: $phone');

      // 🔐 ENCRYPT PASSWORD (IMPORTANT!)
      final encryptedPassword = encryptPassword(password);
      print('🔑 Encrypted Password: $encryptedPassword');

      // Format phone number with country code
      final formattedPhone = _formatPhoneNumber(phone);
      print('📱 Formatted Phone: $formattedPhone');

      // ✅ Query user based on phone number
      print('🔍 Fetching user from database...');

      final existingUser =
          await supabase
              .from('Users')
              .select('id, name, email, mobile_number, password')
              .eq('mobile_number', formattedPhone)
              .maybeSingle();

      print('📊 User Response: $existingUser');

      if (existingUser == null) {
        print('❌ User not found in database');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid phone number or password')),
        );
        setState(() => _isLoading = false);
        return;
      }

      print('👤 User found: ${existingUser['name']}');
      print('🔐 Stored Password: ${existingUser['password']}');
      print('🔐 Entered Password (encrypted): $encryptedPassword');

      // 🔐 Verify encrypted password
      if (existingUser['password'] != encryptedPassword) {
        print('❌ Password mismatch!');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid password')));
        setState(() => _isLoading = false);
        return;
      }

      print('✅ Password verified!');
      print('🆔 User ID: ${existingUser['id']}');
      print('📱 Mobile: ${existingUser['mobile_number']}');

      // ✅ Save user data locally (DON'T save password)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', existingUser['id'] ?? '');
      await prefs.setString('name', existingUser['name'] ?? '');
      await prefs.setString('email', existingUser['email'] ?? '');
      await prefs.setString(
        'mobile_number',
        existingUser['mobile_number'] ?? '',
      );
      await prefs.setBool('is_logged_in', true);

      print('💾 User data saved locally');
      print('✅ LOGIN SUCCESSFUL!');

      // ✅ SAVE FCM TOKEN AFTER LOGIN
      try {
        print('\n📡 ========== SAVING FCM TOKEN ==========');
        final fcmToken = await FirebaseMessaging.instance.getToken();
        print('🔔 FCM Token: $fcmToken');

        if (fcmToken != null) {
          await supabase
              .from('Users')
              .update({'fcm_token': fcmToken})
              .eq('id', existingUser['id']);

          print('✅ FCM Token saved in Users table successfully');
        } else {
          print('⚠️ FCM Token is NULL (maybe permissions not granted)');
        }
        print('=========================================\n');
      } catch (e) {
        print('❌ Failed to save FCM token: $e');
      }

      print('============================================\n');

      // ✅ Navigate to Main Screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome, ${existingUser['name']}')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavbar()),
      );
    } catch (e) {
      print('❌ Error during login: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
      setState(() => _isLoading = false);
    }
  }

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
                  'Login',
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
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegistrationScreen(),
                      ),
                    );
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        TextSpan(
                          text: "SIGN UP",
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
                              // ✅ Only Phone Number Field
                              CommonInputField(
                                controller: _phoneController,
                                label: "Phone Number",
                                hintText: "Enter 10-digit phone number",
                                // keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 20),

                              CommonInputField(
                                controller: _passwordController,
                                label: "Password",
                                isPassword: _obscurePassword,
                                hintText: "********",
                                onToggle: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                              const SizedBox(height: 10),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (v) {
                                          setState(() {
                                            _rememberMe = v ?? false;
                                          });
                                        },
                                      ),
                                      const Text('Remember me'),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  ForgotPasswordScreenEnterMobileNumber(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Forgot Password ?',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 25),

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
                                  onPressed: _isLoading ? null : _loginUser,
                                  child:
                                      _isLoading
                                          ? const CircularProgressIndicator(
                                            color: Colors.black,
                                          )
                                          : const Text(
                                            'Log In',
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
                      ],
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
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:yoga/Auth/Forgot_Password-Enter_Number.dart';
// import 'package:yoga/Auth/Registration_Screen.dart';
// import 'package:yoga/navBar/bottom_navbar.dart';
// import 'package:yoga/utils/Common_Input_Field.dart';
// import 'package:yoga/utils/app_assests.dart';
// import 'package:yoga/utils/colors.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({Key? key}) : super(key: key);

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool _obscurePassword = true;
//   bool _isLoading = false;
//   bool _rememberMe = false;

//   final supabase = Supabase.instance.client;

//   @override
//   void initState() {
//     super.initState();
//     _checkLoginStatus(); // 🔹 Check login on startup
//   }

//   Future<void> _checkLoginStatus() async {
//   final prefs = await SharedPreferences.getInstance();
//   final savedUserId = prefs.getString('user_id');
//   if (savedUserId != null && savedUserId.isNotEmpty) {
//     print('🔁 User already logged in with ID: $savedUserId');
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const MainNavbar()),
//     );
//   }
// }
// Future<void> _loginUser() async {
//   final email = _emailController.text.trim();
//   final password = _passwordController.text.trim();

//   if (email.isEmpty || password.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Please fill all fields")),
//     );
//     return;
//   }

//   setState(() => _isLoading = true);

//   try {
//     print('🔐 ========== LOGIN STARTED ==========');
//     print('📧 Entered Email: $email');
//     print('🔑 Entered Password: $password');

//     // ✅ STEP 1 — Check if user exists with same email & password
//     final existingUser = await supabase
//         .from('Users')
//         .select('id, name, email, mobile_number, password')
//         .eq('email', email)
//         .eq('password', password)
//         .maybeSingle();

//     if (existingUser == null) {
//       print('🚫 Invalid email or password');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Invalid email or password')),
//       );
//       setState(() => _isLoading = false);
//       return;
//     }

//     print('✅ User found: ${existingUser['email']}');
//     print('🆔 User ID: ${existingUser['id']}');
//     print('👤 Name: ${existingUser['name']}');
//     print('📱 Mobile: ${existingUser['mobile_number']}');

//     // ✅ STEP 2 — Save complete user data locally
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('user_id', existingUser['id'] ?? '');
//     await prefs.setString('name', existingUser['name'] ?? '');
//     await prefs.setString('email', existingUser['email'] ?? '');
//     await prefs.setString('password', existingUser['password'] ?? '');
//     await prefs.setString('mobile_number', existingUser['mobile_number'] ?? '');

//     print('💾 Complete user data saved locally');

//     // ✅ STEP 3 — Navigate to Main Screen
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Welcome, ${existingUser['name']}')),
//     );

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const MainNavbar()),
//     );
//   } catch (e) {
//     print('⚠️ Error during login: $e');
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Something went wrong")),
//     );
//   } finally {
//     setState(() => _isLoading = false);
//   }
// }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.primary,
//       body: SafeArea(
//         child: Column(
//           children: [
//             const SizedBox(height: 40),
//             Align(
//               alignment: Alignment.centerLeft,
//               child: Padding(
//                 padding: const EdgeInsets.only(left: 25),
//                 child: Image.asset(AppAssets.yogaGirl, height: 60),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Padding(
//               padding: const EdgeInsets.only(left: 25),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   'Login',
//                   style: const TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 5),
//             Padding(
//               padding: const EdgeInsets.only(left: 25),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: GestureDetector(
//                   onTap: () {
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => RegistrationScreen(),
//                       ),
//                     );
//                   },
//                   child: RichText(
//                     text: const TextSpan(
//                       text: "Don't have an account? ",
//                       style: TextStyle(
//                         color: Colors.black,
//                         fontWeight: FontWeight.w400,
//                       ),
//                       children: [
//                         TextSpan(
//                           text: "SIGN UP",
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
//                     child: Column(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(18),
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade200,
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               CommonInputField(
//                                 controller: _emailController,
//                                 label: "Email",
//                                 hintText: "example@gmail.com",
//                               ),
//                               const SizedBox(height: 20),

//                               CommonInputField(
//                                 controller: _passwordController,
//                                 label: "Password",
//                                 isPassword: _obscurePassword,
//                                 hintText: "********",
//                                 onToggle: () {
//                                   setState(() => _obscurePassword = !_obscurePassword);
//                                 },
//                               ),
//                               const SizedBox(height: 10),

//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Row(
//                                     children: [
//                                       Checkbox(
//                                         value: _rememberMe,
//                                         onChanged: (v) {
//                                           setState(() {
//                                             _rememberMe = v ?? false;
//                                           });
//                                         },
//                                       ),
//                                       const Text('Remember me'),
//                                     ],
//                                   ),
//                                   TextButton(
//                                     onPressed: () {
//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (context) => ForgotPasswordScreenEnterMobileNumber(),
//                                         ),
//                                       );
//                                     },
//                                     child: const Text(
//                                       'Forgot Password ?',
//                                       style: TextStyle(color: Colors.black),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 25),

//                               SizedBox(
//                                 width: double.infinity,
//                                 height: 50,
//                                 child: ElevatedButton(
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: const Color(0xFFD6ECB4),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                   ),
//                                   onPressed: _isLoading ? null : _loginUser,
//                                   child: _isLoading
//                                       ? const CircularProgressIndicator(color: Colors.black)
//                                       : const Text(
//                                           'Log In',
//                                           style: TextStyle(fontSize: 18, color: Colors.black),
//                                         ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
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
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
// }
