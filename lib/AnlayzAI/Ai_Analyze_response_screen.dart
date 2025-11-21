import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yoga/Home/Home_Screen.dart';
import 'package:yoga/utils/app_assests.dart';
import 'package:yoga/utils/colors.dart';

class AlAnalyzeResponseScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final File imageFile;
  final bool isFromVideo; // ✅ Added parameter

  const AlAnalyzeResponseScreen({
    Key? key,
    required this.result,
    required this.imageFile,
    this.isFromVideo = false,
  }) : super(key: key);

  @override
  State<AlAnalyzeResponseScreen> createState() =>
      _AlAnalyzeResponseScreenState();
}

class _AlAnalyzeResponseScreenState extends State<AlAnalyzeResponseScreen> {

  Future<String> _fetchUserProfilePic() async {
    print("🔹 _fetchUserProfilePic called");
    // final user = Supabase.instance.client.auth.currentUser;
    // print("👤 Current user: ${user?.id}");

    try {
      // final user = Supabase.instance.client.auth.currentUser;
      // if (user == null) {
        // print("⚠️ No logged-in user found");
        // return '';
      // }
      final prefs = await SharedPreferences.getInstance();
      final localUserId = prefs.getString('user_id');

      // final userId = user['id'];
      print("✅ Logged in userId: $localUserId");

      final response =
          await Supabase.instance.client
              .from('Users')
              .select('profile_image')
              .eq(
                'id',
                localUserId.toString(),
              ) // 👈 actual UUID pass kar rahe hain
              .maybeSingle();

      print("🔹 Response: $response");

      if (response != null && response['profile_image'] != null) {
        print("✅ Image URL: ${response['profile_image']}");
        return response['profile_image'];
      } else {
        print("⚠️ No image URL found for user");
        return '';
      }
    } catch (e) {
      print("❌ Error in _fetchUserProfilePic: $e");
      return '';
    }
  }


  @override
  Widget build(BuildContext context) {
    double accuracy = widget.result["accuracy"] ?? 0.0;
    String feedback = widget.result["feedback"] ?? "No feedback available";
    String detectedPose = widget.result["poseDetected"] ?? "Unknown";
    String selectedPose = widget.result["selectedPose"] ?? "Unknown";
    bool isCorrectPose = widget.result["isCorrectPose"] ?? false;

    // Determine colors based on accuracy and correctness
    Color accuracyColor;
    Color statusColor;
    IconData statusIcon;

    if (!isCorrectPose) {
      accuracyColor = Colors.red;
      statusColor = Colors.red.shade50;
      statusIcon = Icons.cancel;
    } else if (accuracy >= 90) {
      accuracyColor = const Color(0xFF4CAF50); // Green
      statusColor = Colors.green.shade50;
      statusIcon = Icons.check_circle;
    } else if (accuracy >= 80) {
      accuracyColor = const Color(0xFF8BC34A); // Light Green
      statusColor = Colors.lightGreen.shade50;
      statusIcon = Icons.check_circle_outline;
    } else {
      accuracyColor = const Color(0xFFFFA726); // Orange
      statusColor = Colors.orange.shade50;
      statusIcon = Icons.info;
    }
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundC,
      endDrawer: const ProfileDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const SizedBox(height: 20),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween, 
                  children: [
                    // 🔹 Back Icon
                    Padding(
                      padding: const EdgeInsets.only(left: 0, top: 0),
                      child: 
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 22,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
            
                 
                    Padding(
                      padding: const EdgeInsets.only(right: 16, top: 5),
                      child:
                      //  GestureDetector(
                      //   onTap: () {
                      //     _scaffoldKey.currentState?.openEndDrawer();
                      //   },
                      //   child: Container(
                      //     height: 40,
                      //     width: 40,
                      //     decoration: BoxDecoration(
                      //       color: Colors.white,
                      //       borderRadius: BorderRadius.circular(20),
                      //       boxShadow: [
                      //         BoxShadow(
                      //           color: Colors.black.withOpacity(0.1),
                      //           blurRadius: 4,
                      //           offset: const Offset(0, 2),
                      //         ),
                      //       ],
                      //     ),
                      //     child: Center(
                      //       child: Image.asset(
                      //         AppAssets.profileImages,
                      //         height: 28,
                      //         width: 28,
                      //         fit: BoxFit.contain,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                        GestureDetector(
                        onTap: () {
                          _scaffoldKey.currentState?.openEndDrawer();
                        },
                        child: Align(
                          alignment: Alignment.topRight,
                          child: FutureBuilder(
                            future:
                                _fetchUserProfilePic(), // 👈 Supabase se fetch karega
                            builder: (context, snapshot) {
                              final imageUrl = snapshot.data as String?;
                              return Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child:
                                      imageUrl == null || imageUrl.isEmpty
                                          ? Image.asset(
                                            AppAssets
                                                .profileImages, // 👈 Default asset image
                                            height: 28,
                                            width: 28,
                                            fit: BoxFit.cover,
                                          )
                                          : Image.network(
                                            imageUrl, // 👈 Supabase image
                                            height: 28,
                                            width: 28,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              // Agar URL invalid ho to fallback image dikhao
                                              return Image.asset(
                                                AppAssets.profileImages,
                                                height: 28,
                                                width: 28,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      "Let's Analyze\nYour work!!",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Image.asset(
                      AppAssets.AIScreenImages,
                      height: 140,
                      width: 180,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
            
                const SizedBox(height: 20),
            
            
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Image.file(
                        widget.imageFile,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                     
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                widget.isFromVideo
                                    ? Colors.red.withOpacity(0.9)
                                    : Colors.blue.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.isFromVideo ? Icons.videocam : Icons.image,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.isFromVideo ? 'Video' : 'Photo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Divider(thickness: 1, color: Colors.grey.shade400),
                ),
            
          
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Results',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
            
               
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Accuracy',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 70,
                                  height: 70,
                                  child: CircularProgressIndicator(
                                    value: accuracy / 100,
                                    strokeWidth: 7,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      accuracyColor,
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${accuracy.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: accuracyColor,
                                      ),
                                    ),
                                    Text(
                                      isCorrectPose ? 'Match' : 'Mismatch',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
            
                      const SizedBox(height: 24),
            
                      // Feedback Section
                      const Text(
                        'Suggestion',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
            
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          feedback,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
            
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFAAD38A),
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "Try Another Pose",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
