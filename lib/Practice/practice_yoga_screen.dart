import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yoga/Home/Home_Screen.dart';
import 'package:yoga/course/course_Screen.dart';
import 'package:yoga/utils/app_assests.dart';
import 'package:yoga/utils/colors.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({Key? key}) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final supabase = Supabase.instance.client;

  String? userId;
  Map<String, dynamic>? basicPracticeVideo;
  Map<String, dynamic>? advancedPracticeVideo;
  bool isBasicCourseCompleted = false;
  bool isAdvancedCourseCompleted = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getUserId();
    await _fetchPracticeVideos();
    await _checkCourseCompletion();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _getUserId() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      userId = user.id;
      print("🔑 User ID from Auth: $userId");
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('user_id') ?? 'guest_user';
      print("🔑 User ID from SharedPrefs: $userId");
    }
  }

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

  Future<void> _fetchPracticeVideos() async {
    try {
      final basicResponse =
          await supabase
              .from('practice_videos')
              .select()
              .eq('course_type', 'Basic Course')
              .maybeSingle();

      final advancedResponse =
          await supabase
              .from('practice_videos')
              .select()
              .eq('course_type', 'Advanced Course')
              .maybeSingle();

      setState(() {
        basicPracticeVideo = basicResponse;
        advancedPracticeVideo = advancedResponse;
      });

      print("✅ Basic Practice Video: ${basicPracticeVideo?['title']}");
      print("✅ Advanced Practice Video: ${advancedPracticeVideo?['title']}");
    } catch (e) {
      print("❌ Error fetching practice videos: $e");
    }
  }

  Future<void> _checkCourseCompletion() async {
    if (userId == null) {
      print("⚠️ User ID is null, cannot check completion");
      return;
    }

    try {
      print("\n🔍 Checking course completion for user: $userId");

      // Get all videos from Basic Course
      final basicVideos = await supabase
          .from('videos')
          .select('id')
          .eq('course_type', 'Basic Course');

      print("📹 Total Basic Course videos: ${basicVideos.length}");
      print("📹 Basic Video IDs: ${basicVideos.map((v) => v['id']).toList()}");

      if (basicVideos.isEmpty) {
        print("⚠️ No Basic Course videos found!");
        return;
      }

      // Check Basic Course completion
      final basicVideoIds = basicVideos.map((v) => v['id']).toList();

      final basicProgress = await supabase
          .from('user_video_progress')
          .select('video_id, status')
          .eq('user_id', userId!)
          .inFilter('video_id', basicVideoIds);

      print("📊 Basic Progress Records Found: ${basicProgress.length}");

      // Count completed videos
      int completedCount = 0;
      for (var record in basicProgress) {
        print("   Video ${record['video_id']}: ${record['status']}");
        if (record['status'] == 'completed') {
          completedCount++;
        }
      }

      print("✅ Completed videos: $completedCount / ${basicVideoIds.length}");

      // Check if all videos are completed
      isBasicCourseCompleted =
          completedCount == basicVideoIds.length && basicVideoIds.isNotEmpty;

      print("🎯 Basic Course Completed: $isBasicCourseCompleted");

      // Get all videos from Advanced Course
      final advancedVideos = await supabase
          .from('videos')
          .select('id')
          .eq('course_type', 'Advanced Course');

      // Try alternate spelling if empty
      if (advancedVideos.isEmpty) {
        print("⚠️ Trying alternate spelling: 'Advance Course'");
        final altResponse = await supabase
            .from('videos')
            .select('id')
            .eq('course_type', 'Advance Course');
        advancedVideos.addAll(altResponse);
      }

      print("📹 Total Advanced Course videos: ${advancedVideos.length}");

      if (advancedVideos.isNotEmpty) {
        final advancedVideoIds = advancedVideos.map((v) => v['id']).toList();

        final advancedProgress = await supabase
            .from('user_video_progress')
            .select('video_id, status')
            .eq('user_id', userId!)
            .inFilter('video_id', advancedVideoIds);

        int advCompletedCount = 0;
        for (var record in advancedProgress) {
          if (record['status'] == 'completed') {
            advCompletedCount++;
          }
        }

        isAdvancedCourseCompleted =
            advCompletedCount == advancedVideoIds.length &&
            advancedVideoIds.isNotEmpty;

        print("🎯 Advanced Course Completed: $isAdvancedCourseCompleted");
      }

      setState(() {});
    } catch (e) {
      print("❌ Error checking course completion: $e");
      print("Stack trace: ${StackTrace.current}");
    }
  }

  void _showLockedDialog(String courseName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.lock, color: Colors.orange),
                SizedBox(width: 10),
                Text('Video Locked'),
              ],
            ),
            content: Text(
              'Please complete all videos in the $courseName to unlock this practice session.',
              style: const TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  // ✅ FIXED: Added position parameter
  // ✅ FIXED: Only 2 parameters (double, String)
  // ✅ FIXED: Explicitly typed parameters to match the signature
  void _openPracticeVideo(Map<String, dynamic> video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => YoutubeVideoPlayerScreen(
              videoUrl: video['video_url'],
              videoTitle: video['title'],
              videoId: video['id'],
              videoDescription: video['description'],
              lastPosition: 0, // Practice videos start from beginning
              onVideoProgress: (double progress, String status, int position) {
                print(
                  "Practice video progress: $progress - $status at ${position}s",
                );
                // Optional: Save practice video progress if needed
              },
            ),
      ),
    );
  }

  Widget _buildPracticeVideoCard({
    required String title,
    required bool isUnlocked,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Stack(
              children: [
                // Container(
                //   width: 70,
                //   height: 70,
                //   decoration: BoxDecoration(
                //     color: Colors.grey.shade200,
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: ClipRRect(
                //     borderRadius: BorderRadius.circular(12),
                //     child: Image.asset(
                //       AppAssets.courseImages,
                //       fit: BoxFit.cover,
                //     ),
                //   ),
                // ),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        basicPracticeVideo!['thumbnail_url'] == null
                            ? Image.asset(
                              AppAssets.courseImages,
                              fit: BoxFit.cover,
                            )
                            : Image.network(
                              basicPracticeVideo!['thumbnail_url'],
                              fit: BoxFit.cover,
                            ),
                  ),
                ),

                if (!isUnlocked)
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isUnlocked ? Icons.check_circle : Icons.lock,
                        size: 16,
                        color: isUnlocked ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isUnlocked ? 'Unlocked' : 'Complete course to unlock',
                          style: TextStyle(
                            fontSize: 10,
                            color: isUnlocked ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              isUnlocked ? Icons.play_circle_filled : Icons.lock,
              color: isUnlocked ? Colors.blue : Colors.grey,
              size: 36,
            ),
          ],
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundC,
      endDrawer: ProfileDrawer(),
      body: SafeArea(
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // const SizedBox(height: 10),

                      // Profile Icon and Refresh Button
                      Padding(
                        padding: const EdgeInsets.only(right: 0, bottom: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // const SizedBox(width: 8),
                            // Profile Icon
                            // GestureDetector(
                            //   onTap: () {
                            //     _scaffoldKey.currentState?.openEndDrawer();
                            //   },
                            //   child: Align(
                            //     alignment: Alignment.topRight,
                            //     child: Container(
                            //       height: 40,
                            //       width: 40,
                            //       decoration: BoxDecoration(
                            //         color: Colors.white,
                            //         borderRadius: BorderRadius.circular(20),
                            //         boxShadow: [
                            //           BoxShadow(
                            //             color: Colors.black.withOpacity(0.1),
                            //             blurRadius: 4,
                            //             offset: const Offset(0, 2),
                            //           ),
                            //         ],
                            //       ),
                            //       child: Center(
                            //         child: Image.asset(
                            //           AppAssets.profileImages,
                            //           height: 28,
                            //           width: 28,
                            //           fit: BoxFit.contain,
                            //         ),
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
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
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
                          ],
                        ),
                      ),

                      // Row(
                      //   // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   crossAxisAlignment: CrossAxisAlignment.start,
                      //   children: [
                      //     Text(
                      //       "Let's Practice\nTogether!",
                      //       style: const TextStyle(
                      //         fontSize: 24,
                      //         fontWeight: FontWeight.bold,
                      //       ),
                      //     ),
                      //     // Expanded(
                      //     //   child: Padding(
                      //     //     padding: const EdgeInsets.only(top: 0, left: 24),
                      //     //     child: Text.rich(
                      //     //       TextSpan(
                      //     //         text: "Let's Practice\nTogether!",
                      //     //         style: const TextStyle(
                      //     //           fontSize: 24,
                      //     //           color: Colors.black87,
                      //     //         ),
                      //     //       ),
                      //     //     ),
                      //     //   ),
                      //     // ),
                      //     Padding(
                      //       padding: const EdgeInsets.only(right: 13.0),
                      //       child: Image.asset(
                      //         AppAssets.practicImages,
                      //         height: 150,
                      //         width: 200,
                      //         fit: BoxFit.cover,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              "Let's Practice\nTogether!",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Image.asset(
                            AppAssets.practicImages,
                            height: 130,
                            width: 160,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Wrap the remaining content in Expanded and make it scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Basic Practice Video Section
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                  border: Border.all(color: Colors.grey),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, -4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Basic Practice Video',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      if (basicPracticeVideo != null)
                                        _buildPracticeVideoCard(
                                          title:
                                              basicPracticeVideo!['title'] ??
                                              'Basic Practice',
                                          isUnlocked: isBasicCourseCompleted,
                                          onTap: () {
                                            if (isBasicCourseCompleted) {
                                              _openPracticeVideo(
                                                basicPracticeVideo!,
                                              );
                                            } else {
                                              _showLockedDialog('Basic Course');
                                            }
                                          },
                                        )
                                      else
                                        const Center(
                                          child: Text(
                                            'No basic practice video available',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Advanced Practice Video Section
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                  border: Border.all(color: Colors.grey),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, -4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Advanced Practice Video',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      if (advancedPracticeVideo != null)
                                        _buildPracticeVideoCard(
                                          title:
                                              advancedPracticeVideo!['title'] ??
                                              'Advanced Practice',
                                          isUnlocked: isAdvancedCourseCompleted,
                                          onTap: () {
                                            if (isAdvancedCourseCompleted) {
                                              _openPracticeVideo(
                                                advancedPracticeVideo!,
                                              );
                                            } else {
                                              _showLockedDialog(
                                                'Advanced Course',
                                              );
                                            }
                                          },
                                        )
                                      else
                                        const Center(
                                          child: Text(
                                            'No advanced practice video available',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: AppColors.backgroundC,
//       endDrawer: ProfileDrawer(),
//       body: SafeArea(
//         child: isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 20),

//                   // Profile Icon and Refresh Button
//                   Padding(
//                     padding: const EdgeInsets.only(right: 16, bottom: 0),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         const SizedBox(width: 8),
//                         // Profile Icon
//                         GestureDetector(
//                           onTap: () {
//                             _scaffoldKey.currentState?.openEndDrawer();
//                           },
//                           child: Align(
//                             alignment: Alignment.topRight,
//                             child: Container(
//                               height: 40,
//                               width: 40,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(20),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.black.withOpacity(0.1),
//                                     blurRadius: 4,
//                                     offset: const Offset(0, 2),
//                                   ),
//                                 ],
//                               ),
//                               child: Center(
//                                 child: Image.asset(
//                                   AppAssets.profileImages,
//                                   height: 28,
//                                   width: 28,
//                                   fit: BoxFit.contain,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Padding(
//                           padding: const EdgeInsets.only(top: 0, left: 25),
//                           child: Text.rich(
//                             TextSpan(
//                               text: "Let's Practice\nTogether!",
//                               style: const TextStyle(
//                                 fontSize: 24,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.only(right: 15.0),
//                         child: Image.asset(
//                           AppAssets.practicImages,
//                           height: 150,
//                           width: 200,
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ],
//                   ),

//                   SizedBox(height: 20),
//                   // Main Content Container
//                   Container(
//                     margin: const EdgeInsets.symmetric(horizontal: 8),
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade300,
//                       borderRadius: const BorderRadius.all(
//                         Radius.circular(20),
//                       ),
//                       border: Border.all(color: Colors.grey),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.08),
//                           blurRadius: 20,
//                           offset: const Offset(0, -4),
//                         ),
//                       ],
//                     ),
//                     child: SingleChildScrollView(
//                       padding: const EdgeInsets.all(24),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Basic Practice Video Section
//                           Text(
//                             'Basic Practice Video',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.grey.shade800,
//                             ),
//                           ),
//                           const SizedBox(height: 16),

//                           if (basicPracticeVideo != null)
//                             _buildPracticeVideoCard(
//                               title:
//                                   basicPracticeVideo!['title'] ??
//                                   'Basic Practice',
//                               isUnlocked: isBasicCourseCompleted,
//                               onTap: () {
//                                 if (isBasicCourseCompleted) {
//                                   _openPracticeVideo(basicPracticeVideo!);
//                                 } else {
//                                   _showLockedDialog('Basic Course');
//                                 }
//                               },
//                             )
//                           else
//                             const Center(
//                               child: Text(
//                                 'No basic practice video available',
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   Container(
//                     margin: const EdgeInsets.symmetric(horizontal: 8),
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade300,
//                       borderRadius: const BorderRadius.all(
//                         Radius.circular(20),
//                       ),
//                       border: Border.all(color: Colors.grey),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.08),
//                           blurRadius: 20,
//                           offset: const Offset(0, -4),
//                         ),
//                       ],
//                     ),
//                     child: SingleChildScrollView(
//                       padding: const EdgeInsets.all(24),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Advanced Practice Video Section
//                           Text(
//                             'Advanced Practice Video',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.grey.shade800,
//                             ),
//                           ),
//                           const SizedBox(height: 16),

//                           if (advancedPracticeVideo != null)
//                             _buildPracticeVideoCard(
//                               title:
//                                   advancedPracticeVideo!['title'] ??
//                                   'Advanced Practice',
//                               isUnlocked: isAdvancedCourseCompleted,
//                               onTap: () {
//                                 if (isAdvancedCourseCompleted) {
//                                   _openPracticeVideo(advancedPracticeVideo!);
//                                 } else {
//                                   _showLockedDialog('Advanced Course');
//                                 }
//                               },
//                             )
//                           else
//                             const Center(
//                               child: Text(
//                                 'No advanced practice video available',
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }
// }
