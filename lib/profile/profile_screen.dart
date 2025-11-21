import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:yoga/navBar/bottom_navbar.dart';
import 'dart:convert';
import 'package:yoga/utils/Button.dart';
import 'package:yoga/utils/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isUploading = false;
  bool isLoadingStats = true;
  bool isLoadingProfile = true;

  String? userId;
  String? profileImageUrl;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Course Progress Stats
  int totalBasicVideos = 0;
  int completedBasicVideos = 0;
  double basicProgressPercentage = 0.0;

  int totalAdvancedVideos = 0;
  int completedAdvancedVideos = 0;
  double advancedProgressPercentage = 0.0;

  int totalVideosCompleted = 0;
  int totalVideos = 0;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  // 🔐 Password Encryption Function
  String encryptPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // ✅ Initialize Profile Data
  Future<void> _initializeProfile() async {
    await _loadUserDataFromDatabase();
    if (userId != null && userId!.isNotEmpty) {
      await _loadCourseStats();
    } else {
      print('⚠️ User ID is null or empty, skipping stats load');
      setState(() => isLoadingStats = false);
    }
  }

  // ✅ Load User Data from Database (NOT SharedPreferences)
  Future<void> _loadUserDataFromDatabase() async {
    try {
      print('📥 Loading user profile from database...');

      final prefs = await SharedPreferences.getInstance();
      final localUserId = prefs.getString('user_id');

      if (localUserId == null || localUserId.isEmpty) {
        print('❌ No user ID found in local storage');
        setState(() => isLoadingProfile = false);
        return;
      }

      // Fetch complete user data from database
      final userData =
          await supabase
              .from('Users')
              .select('id, name, email, mobile_number, profile_image')
              .eq('id', localUserId)
              .maybeSingle();

      print('📊 User Data from Database: $userData');

      if (userData != null) {
        setState(() {
          userId = userData['id'];
          nameController.text = userData['name'] ?? '';
          emailController.text = userData['email'] ?? '';
          mobileController.text = userData['mobile_number'] ?? '';
          profileImageUrl = userData['profile_image'];
          isLoadingProfile = false;
        });

        // Update local storage with latest data
        await prefs.setString('name', userData['name'] ?? '');
        await prefs.setString('email', userData['email'] ?? '');
        await prefs.setString('mobile_number', userData['mobile_number'] ?? '');
        if (userData['profile_image'] != null) {
          await prefs.setString('profile_image', userData['profile_image']);
        }

        print('✅ Profile loaded successfully');
        print('   Name: ${nameController.text}');
        print('   Email: ${emailController.text}');
        print('   Profile Image: $profileImageUrl');
      } else {
        print('❌ User not found in database');
        setState(() => isLoadingProfile = false);
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      setState(() => isLoadingProfile = false);
    }
  }

  // ✅ Load Course Stats
  Future<void> _loadCourseStats() async {
    if (userId == null || userId!.isEmpty) {
      print('❌ Cannot load stats: User ID is empty');
      setState(() => isLoadingStats = false);
      return;
    }

    try {
      print('\n📊 Loading course stats for user: $userId');

      // Get Basic Course Videos
      print('📥 Fetching Basic Course videos...');
      var basicVideosResponse = await supabase
          .from('videos')
          .select('id, title')
          .eq('course_type', 'Basic Course');

      if ((basicVideosResponse as List).isEmpty) {
        basicVideosResponse = await supabase
            .from('videos')
            .select('id, title')
            .ilike('course_type', 'basic%');
      }

      final List<dynamic> basicVideosList = basicVideosResponse as List;
      print('✅ Found ${basicVideosList.length} Basic Course videos');

      if (basicVideosList.isNotEmpty) {
        final List<int> basicVideoIds =
            basicVideosList
                .map(
                  (v) =>
                      (v['id'] is int)
                          ? v['id'] as int
                          : int.parse(v['id'].toString()),
                )
                .toList();

        final basicProgressResponse = await supabase
            .from('user_video_progress')
            .select('video_id, status')
            .eq('user_id', userId!)
            .inFilter('video_id', basicVideoIds);

        int basicCompleted = 0;
        for (var record in basicProgressResponse) {
          if (record['status']?.toString().toLowerCase() == 'completed') {
            basicCompleted++;
          }
        }

        setState(() {
          totalBasicVideos = basicVideoIds.length;
          completedBasicVideos = basicCompleted;
          basicProgressPercentage =
              basicVideoIds.isEmpty
                  ? 0.0
                  : (basicCompleted / basicVideoIds.length) * 100;
        });
      }

      // Get Advanced Course Videos
      print('📥 Fetching Advanced Course videos...');
      var advancedVideosResponse = await supabase
          .from('videos')
          .select('id, title')
          .eq('course_type', 'Advanced Course');

      if ((advancedVideosResponse as List).isEmpty) {
        advancedVideosResponse = await supabase
            .from('videos')
            .select('id, title')
            .or('course_type.eq.Advance Course,course_type.ilike.advan%');
      }

      final List<dynamic> advancedVideosList = advancedVideosResponse as List;
      print('✅ Found ${advancedVideosList.length} Advanced Course videos');

      if (advancedVideosList.isNotEmpty) {
        final List<int> advancedVideoIds =
            advancedVideosList
                .map(
                  (v) =>
                      (v['id'] is int)
                          ? v['id'] as int
                          : int.parse(v['id'].toString()),
                )
                .toList();

        final advancedProgressResponse = await supabase
            .from('user_video_progress')
            .select('video_id, status')
            .eq('user_id', userId!)
            .inFilter('video_id', advancedVideoIds);

        int advancedCompleted = 0;
        for (var record in advancedProgressResponse) {
          if (record['status']?.toString().toLowerCase() == 'completed') {
            advancedCompleted++;
          }
        }

        setState(() {
          totalAdvancedVideos = advancedVideoIds.length;
          completedAdvancedVideos = advancedCompleted;
          advancedProgressPercentage =
              advancedVideoIds.isEmpty
                  ? 0.0
                  : (advancedCompleted / advancedVideoIds.length) * 100;
        });
      }

      setState(() {
        totalVideos = totalBasicVideos + totalAdvancedVideos;
        totalVideosCompleted = completedBasicVideos + completedAdvancedVideos;
        isLoadingStats = false;
      });

      print('✅ Stats loaded successfully');
    } catch (e) {
      print('❌ Error loading stats: $e');
      setState(() => isLoadingStats = false);
    }
  }

  // ✅ Pick Image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        print('✅ Image selected: ${pickedFile.path}');
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  // ✅ Show Image Picker Options
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Profile Photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppColors.ProgressB,
                  ),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.ProgressB,
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Remove Photo'),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfileImage();
                    },
                  ),
              ],
            ),
          ),
    );
  }

  // ✅ Remove Profile Image
  Future<void> _removeProfileImage() async {
    try {
      print('🗑️ Removing profile image...');

      setState(() {
        _selectedImage = null;
        profileImageUrl = null;
      });

      // Update database
      await supabase
          .from('Users')
          .update({'profile_image': null})
          .eq('id', userId!);

      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image');

      print('✅ Profile photo removed');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo removed')));
    } catch (e) {
      print('❌ Error removing image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove image: $e')));
    }
  }

  // ✅ Upload Image to Supabase Storage
  Future<String?> _uploadImageToSupabase(File imageFile) async {
    try {
      print('📤 Uploading image to Supabase...');

      final String fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'profiles/$fileName';

      setState(() => isUploading = true);

      // Upload file
      await supabase.storage
          .from('profile-images')
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final String publicUrl = supabase.storage
          .from('profile-images')
          .getPublicUrl(filePath);

      print('✅ Image uploaded successfully');
      print('🔗 Public URL: $publicUrl');

      setState(() => isUploading = false);

      return publicUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      setState(() => isUploading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      return null;
    }
  }

  // ✅ Update Profile in Database
  Future<void> _updateProfile() async {
    if (userId == null || userId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User ID not found")));
      return;
    }

    try {
      print('💾 Updating profile...');

      String? imageUrl = profileImageUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        print('📤 Uploading new profile image...');
        imageUrl = await _uploadImageToSupabase(_selectedImage!);
        if (imageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
          return;
        }
      }

      // Prepare update data
      Map<String, dynamic> updateData = {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'mobile_number': mobileController.text.trim(),
      };

      // Add profile image if exists
      if (imageUrl != null && imageUrl.isNotEmpty) {
        updateData['profile_image'] = imageUrl;
      }

      print('📊 Update Data: $updateData');

      // Update database
      final result =
          await supabase
              .from('Users')
              .update(updateData)
              .eq('id', userId!)
              .select();

      print('✅ Database updated: $result');

      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', nameController.text.trim());
      await prefs.setString('email', emailController.text.trim());
      await prefs.setString('mobile_number', mobileController.text.trim());

      if (imageUrl != null && imageUrl.isNotEmpty) {
        await prefs.setString('profile_image', imageUrl);
        setState(() {
          profileImageUrl = imageUrl;
          _selectedImage = null;
        });
      }

      print('✅ Profile updated successfully');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error updating profile: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update profile: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingProfile) {
      return Scaffold(
        backgroundColor: AppColors.backgroundC,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundC,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundC,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Padding(
            padding: const EdgeInsets.only(left: 16, top: 5),
            child: Container(
              height: 50,
              width: 50,
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Profile Image
                Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child:
                            _selectedImage != null
                                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                : (profileImageUrl != null &&
                                    profileImageUrl!.isNotEmpty)
                                ? Image.network(
                                  profileImageUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    print('❌ Image load error: $error');
                                    return const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white,
                                    );
                                  },
                                )
                                : const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: isUploading ? null : _showImagePickerOptions,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child:
                              isUploading
                                  ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Course Progress Stats
                _buildProgressStatsSection(),

                const SizedBox(height: 30),

                // User Details
                _buildTextField(
                  label: 'Enter Your Name',
                  controller: nameController,
                  hintText: 'Yogesh Laxmi',
                ),
                const SizedBox(height: 20),

                _buildTextFielddisable(
                  label: 'Enter Your Mobile Number',
                  controller: mobileController,
                  hintText: '+91 9123456789',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  label: 'Enter Your Email',
                  controller: emailController,
                  hintText: 'email@.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 30),

                CommonButton(
                  text: isUploading ? "Uploading..." : "Save Changes",
                  onTap: _updateProfile,
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStatsSection() {
    if (isLoadingStats) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (totalVideos == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: // Replace the "No course videos found" section with:
            Column(
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Start Your Yoga Journey',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Begin your first course to track your progress',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Your Learning Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (totalBasicVideos > 0)
            _buildCourseProgressCard(
              title: 'Basic Course',
              completed: completedBasicVideos,
              total: totalBasicVideos,
              progress: basicProgressPercentage / 100,
              color: Colors.green,
            ),

          if (totalBasicVideos > 0) const SizedBox(height: 16),

          if (totalAdvancedVideos > 0)
            _buildCourseProgressCard(
              title: 'Advanced Course',
              completed: completedAdvancedVideos,
              total: totalAdvancedVideos,
              progress: advancedProgressPercentage / 100,
              color: Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _buildCourseProgressCard({
    required String title,
    required int completed,
    required int total,
    required double progress,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                '$completed / $total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: total > 0 ? progress : 0,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% Complete',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFielddisable({
    required String label,
    required TextEditingController controller,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: true,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,

            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:yoga/utils/Button.dart';
// import 'package:yoga/utils/colors.dart';
// import 'package:image_picker/image_picker.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({Key? key}) : super(key: key);

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController mobileController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController =
//       TextEditingController();

//   bool isPasswordVisible = false;
//   bool isConfirmPasswordVisible = false;
//   bool isUploading = false;
//   String? userId;
//   String? profileImageUrl;
//   File? _selectedImage;
//   final ImagePicker _picker = ImagePicker();

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     final prefs = await SharedPreferences.getInstance();

//     setState(() {
//       userId = prefs.getString('user_id') ?? '';
//       nameController.text = prefs.getString('name') ?? '';
//       emailController.text = prefs.getString('email') ?? '';
//       mobileController.text = prefs.getString('mobile_number') ?? '';
//       passwordController.text = prefs.getString('password') ?? '';
//       confirmPasswordController.text = prefs.getString('password') ?? '';
//       profileImageUrl = prefs.getString('profile_image') ?? '';
//     });

//     print('🧠 Loaded user data from SharedPreferences:');
//     print('User ID: $userId');
//     print('Profile Image: $profileImageUrl');
//   }

//   // Pick image from gallery or camera
//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final XFile? pickedFile = await _picker.pickImage(
//         source: source,
//         maxWidth: 1024,
//         maxHeight: 1024,
//         imageQuality: 85,
//       );

//       if (pickedFile != null) {
//         setState(() {
//           _selectedImage = File(pickedFile.path);
//         });
//       }
//     } catch (e) {
//       print('❌ Error picking image: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
//     }
//   }

//   // Show image picker options
//   void _showImagePickerOptions() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder:
//           (context) => Container(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   'Choose Profile Photo',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 20),
//                 ListTile(
//                   leading: const Icon(
//                     Icons.camera_alt,
//                     color: AppColors.ProgressB,
//                   ),
//                   title: const Text('Take Photo'),
//                   onTap: () {
//                     Navigator.pop(context);
//                     _pickImage(ImageSource.camera);
//                   },
//                 ),
//                 ListTile(
//                   leading: const Icon(
//                     Icons.photo_library,
//                     color: AppColors.ProgressB,
//                   ),
//                   title: const Text('Choose from Gallery'),
//                   onTap: () {
//                     Navigator.pop(context);
//                     _pickImage(ImageSource.gallery);
//                   },
//                 ),
//                 if (profileImageUrl != null && profileImageUrl!.isNotEmpty)
//                   ListTile(
//                     leading: const Icon(Icons.delete, color: Colors.red),
//                     title: const Text('Remove Photo'),
//                     onTap: () {
//                       Navigator.pop(context);
//                       _removeProfileImage();
//                     },
//                   ),
//               ],
//             ),
//           ),
//     );
//   }

//   // Remove profile image
//   Future<void> _removeProfileImage() async {
//     setState(() {
//       _selectedImage = null;
//       profileImageUrl = null;
//     });

//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('profile_image');

//     if (userId != null && userId!.isNotEmpty) {
//       try {
//         final supabase = Supabase.instance.client;
//         await supabase
//             .from('Users')
//             .update({'profile_image': null})
//             .eq('id', userId!);

//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text('Profile photo removed')));
//       } catch (e) {
//         print('❌ Error removing image: $e');
//       }
//     }
//   }

//   // Upload image to Supabase Storage
//   Future<String?> _uploadImageToSupabase(File imageFile) async {
//     try {
//       final supabase = Supabase.instance.client;
//       final String fileName =
//           'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
//       final String filePath = 'profiles/$fileName';

//       setState(() {
//         isUploading = true;
//       });

//       // Upload to Supabase Storage
//       final String uploadPath = await supabase.storage
//           .from('profile-images') // Make sure this bucket exists in Supabase
//           .upload(filePath, imageFile);

//       // Get public URL
//       final String publicUrl = supabase.storage
//           .from('profile-images')
//           .getPublicUrl(filePath);

//       print('✅ Image uploaded successfully: $publicUrl');

//       setState(() {
//         isUploading = false;
//       });

//       return publicUrl;
//     } catch (e) {
//       print('❌ Error uploading image: $e');
//       setState(() {
//         isUploading = false;
//       });

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
//       return null;
//     }
//   }

//   Future<void> _updateUserInSupabase() async {
//     try {
//       final supabase = Supabase.instance.client;
//       String? imageUrl = profileImageUrl;

//       // Upload new image if selected
//       if (_selectedImage != null) {
//         imageUrl = await _uploadImageToSupabase(_selectedImage!);
//         if (imageUrl == null) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Failed to upload image')),
//           );
//           return;
//         }
//       }

//       final response = await supabase
//           .from('Users')
//           .update({
//             'name': nameController.text,
//             'email': emailController.text,
//             'mobile_number': mobileController.text,
//             'password': passwordController.text,
//             'c_password': confirmPasswordController.text,
//             'profile_image': imageUrl,
//           })
//           .eq('id', userId!);

//       print('✅ Supabase update response: $response');

//       // Save to SharedPreferences
//       final prefs = await SharedPreferences.getInstance();
//       if (imageUrl != null) {
//         await prefs.setString('profile_image', imageUrl);
//         setState(() {
//           profileImageUrl = imageUrl;
//           _selectedImage = null;
//         });
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Profile updated successfully")),
//       );
//     } catch (e) {
//       print('❌ Error updating Supabase: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Failed to update profile: $e")));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundC,
//       appBar: AppBar(
//         backgroundColor: AppColors.backgroundC,
//         elevation: 0,
//         title: const Text(
//           'Profile',
//           style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black87),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               children: [
//                 const SizedBox(height: 20),

//                 // Profile Image with Upload Option
//                 Stack(
//                   children: [
//                     Container(
//                       width: 120,
//                       height: 120,
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade300,
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 10,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: ClipOval(
//                         child:
//                             _selectedImage != null
//                                 ? Image.file(_selectedImage!, fit: BoxFit.cover)
//                                 : (profileImageUrl != null &&
//                                     profileImageUrl!.isNotEmpty)
//                                 ? Image.network(
//                                   profileImageUrl!,
//                                   fit: BoxFit.cover,
//                                   loadingBuilder: (
//                                     context,
//                                     child,
//                                     loadingProgress,
//                                   ) {
//                                     if (loadingProgress == null) return child;
//                                     return Center(
//                                       child: CircularProgressIndicator(
//                                         value:
//                                             loadingProgress
//                                                         .expectedTotalBytes !=
//                                                     null
//                                                 ? loadingProgress
//                                                         .cumulativeBytesLoaded /
//                                                     loadingProgress
//                                                         .expectedTotalBytes!
//                                                 : null,
//                                       ),
//                                     );
//                                   },
//                                   errorBuilder: (context, error, stackTrace) {
//                                     return const Icon(
//                                       Icons.person,
//                                       size: 60,
//                                       color: Colors.white,
//                                     );
//                                   },
//                                 )
//                                 : const Icon(
//                                   Icons.person,
//                                   size: 60,
//                                   color: Colors.white,
//                                 ),
//                       ),
//                     ),

//                     // Camera Icon Button
//                     Positioned(
//                       bottom: 0,
//                       right: 0,
//                       child: GestureDetector(
//                         onTap: isUploading ? null : _showImagePickerOptions,
//                         child: Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: AppColors.primary,
//                             shape: BoxShape.circle,
//                             border: Border.all(color: Colors.white, width: 3),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.2),
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child:
//                               isUploading
//                                   ? const Padding(
//                                     padding: EdgeInsets.all(8.0),
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 2,
//                                       valueColor: AlwaysStoppedAnimation<Color>(
//                                         Colors.white,
//                                       ),
//                                     ),
//                                   )
//                                   : const Icon(
//                                     Icons.camera_alt,
//                                     size: 20,
//                                     color: Colors.white,
//                                   ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 30),

//                 _buildTextField(
//                   label: 'Enter Your Name',
//                   controller: nameController,
//                   hintText: 'Yogesh Laxmi',
//                 ),

//                 const SizedBox(height: 20),

//                 _buildTextField(
//                   label: 'Enter Your Mobile Number',
//                   controller: mobileController,
//                   hintText: '+91 9123456789',
//                   keyboardType: TextInputType.phone,
//                 ),

//                 const SizedBox(height: 20),

//                 _buildTextField(
//                   label: 'Enter Your Email',
//                   controller: emailController,
//                   hintText: 'email@.com',
//                   keyboardType: TextInputType.emailAddress,
//                 ),

//                 const SizedBox(height: 20),

//                 // _buildPasswordField(
//                 //   label: 'Password',
//                 //   controller: passwordController,
//                 //   isVisible: isPasswordVisible,
//                 //   toggleVisibility: () {
//                 //     setState(() => isPasswordVisible = !isPasswordVisible);
//                 //   },
//                 // ),

//                 // const SizedBox(height: 20),

//                 // _buildPasswordField(
//                 //   label: 'Confirm Password',
//                 //   controller: confirmPasswordController,
//                 //   isVisible: isConfirmPasswordVisible,
//                 //   toggleVisibility: () {
//                 //     setState(
//                 //       () =>
//                 //           isConfirmPasswordVisible = !isConfirmPasswordVisible,
//                 //     );
//                 //   },
//                 // ),
//                 const SizedBox(height: 30),

//                 CommonButton(
//                   text: isUploading ? "Uploading..." : "Save Changes",
//                   onTap: () async {
//                     // ✅ Save locally
//                     final prefs = await SharedPreferences.getInstance();
//                     await prefs.setString('name', nameController.text);
//                     await prefs.setString('email', emailController.text);
//                     await prefs.setString(
//                       'mobile_number',
//                       mobileController.text,
//                     );
//                     await prefs.setString('password', passwordController.text);

//                     // ✅ Also update in Supabase
//                     if (userId != null && userId!.isNotEmpty) {
//                       await _updateUserInSupabase();
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text("User ID not found, cannot update"),
//                         ),
//                       );
//                     }
//                   },
//                 ),

//                 const SizedBox(height: 30),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required String label,
//     required TextEditingController controller,
//     String? hintText,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(left: 4, bottom: 8),
//           child: Text(
//             label,
//             style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
//           ),
//         ),
//         TextField(
//           controller: controller,
//           keyboardType: keyboardType,
//           decoration: InputDecoration(
//             hintText: hintText,
//             hintStyle: TextStyle(color: Colors.grey.shade500),
//             filled: true,
//             fillColor: Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide.none,
//             ),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 14,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   void dispose() {
//     nameController.dispose();
//     mobileController.dispose();
//     emailController.dispose();
//     passwordController.dispose();
//     confirmPasswordController.dispose();
//     super.dispose();
//   }
// }

// class ChangePasswordScreen extends StatefulWidget {
//   final String? userId;

//   const ChangePasswordScreen({Key? key, this.userId}) : super(key: key);

//   @override
//   State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
// }

// class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
//   final TextEditingController currentPasswordController =
//       TextEditingController();
//   final TextEditingController newPasswordController = TextEditingController();
//   final TextEditingController confirmPasswordController =
//       TextEditingController();

//   bool isCurrentPasswordVisible = false;
//   bool isNewPasswordVisible = false;
//   bool isConfirmPasswordVisible = false;
//   bool isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _printDebugInfo();
//   }

//   // Debug function to print saved password
//   Future<void> _printDebugInfo() async {
//     final prefs = await SharedPreferences.getInstance();
//     final savedPassword = prefs.getString('password') ?? 'NOT FOUND';
//     final savedEmail = prefs.getString('email') ?? 'NOT FOUND';
//     final userId = prefs.getString('user_id') ?? 'NOT FOUND';

//     print('═' * 50);
//     print('🔍 DEBUG INFO:');
//     print('User ID: $userId');
//     print('Saved Email: $savedEmail');
//     print('Saved Password: "$savedPassword"');
//     print('Password Length: ${savedPassword.length}');
//     print('═' * 50);
//   }

//   final supabase = Supabase.instance.client;
//   String sha256Hex(String input) {
//     final bytes = utf8.encode(input);
//     final digest = sha256.convert(bytes);
//     return digest.toString();
//   }

//   Future<void> updatePassword() async {
//     final currentPassword = currentPasswordController.text.trim();
//     final newPassword = newPasswordController.text.trim();

//     if (currentPassword.isEmpty || newPassword.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Please fill all fields")));
//       return;
//     }

//     try {
//       print("🔍 Checking logged-in user ID...");
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getString('user_id');

//       if (userId == null) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("User not logged in")));
//         return;
//       }

//       print("🔍 Checking user: $userId");

//       // Fetch user from Supabase
//       final user =
//           await supabase
//               .from('Users')
//               .select('id, password')
//               .eq('id', userId)
//               .maybeSingle();

//       if (user == null) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("User not found")));
//         return;
//       }

//       final dbPassword = user['password']; // stored password in DB
//       print("🔒 Stored Password: $dbPassword");

//       // 🔐 Encrypt entered current password
//       final encryptedEnteredPassword = sha256Hex(currentPassword);
//       print("🔑 Entered (SHA256 HEX): $encryptedEnteredPassword");

//       // ❌ Incorrect current password
//       if (encryptedEnteredPassword != dbPassword) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("❌ Current password is incorrect")),
//         );
//         return;
//       }

//       print("✅ Password matched! Updating password...");

//       // 🔐 Encrypt new password
//       final newEncryptedPassword = sha256Hex(newPassword);

//       // Update password in Supabase
//       await supabase
//           .from('Users')
//           .update({'password': newEncryptedPassword})
//           .eq('id', userId);

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("✅ Password updated successfully!")),
//       );
//     } catch (e) {
//       print("❌ Error updating password: $e");
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Something went wrong")));
//     }
//   }
//   // Future<void> _changePassword() async {
//   //   final currentPassword = currentPasswordController.text;
//   //   final newPassword = newPasswordController.text;
//   //   final confirmPassword = confirmPasswordController.text;

//   //   // ✅ VALIDATION
//   //   if (currentPassword.isEmpty ||
//   //       newPassword.isEmpty ||
//   //       confirmPassword.isEmpty) {
//   //     ScaffoldMessenger.of(
//   //       context,
//   //     ).showSnackBar(const SnackBar(content: Text('All fields are required')));
//   //     return;
//   //   }

//   //   if (newPassword != confirmPassword) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(
//   //         content: Text('New password and confirm password do not match'),
//   //       ),
//   //     );
//   //     return;
//   //   }

//   //   if (newPassword.length < 6) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text('Password must be at least 6 characters')),
//   //     );
//   //     return;
//   //   }

//   //   setState(() => isLoading = true);

//   //   try {
//   //     // ✅ GET SAVED PASSWORD FROM SHAREDPREFERENCES
//   //     final prefs = await SharedPreferences.getInstance();
//   //     final savedPassword = prefs.getString('password') ?? '';

//   //     print('═' * 50);
//   //     print('🔐 PASSWORD VERIFICATION:');
//   //     print('Current Password Entered: "$currentPassword"');
//   //     print('Saved Password in Device: "$savedPassword"');
//   //     print('Do they match? ${currentPassword == savedPassword}');
//   //     print('═' * 50);

//   //     // ✅ VERIFY CURRENT PASSWORD
//   //     if (currentPassword != savedPassword) {
//   //       setState(() => isLoading = false);
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         const SnackBar(
//   //           content: Text('❌ Current password is incorrect'),
//   //           backgroundColor: Colors.red,
//   //         ),
//   //       );
//   //       return;
//   //     }

//   //     print('✅ Password verified successfully');

//   //     // ✅ UPDATE IN SUPABASE
//   //     final supabase = Supabase.instance.client;
//   //     if (widget.userId != null && widget.userId!.isNotEmpty) {
//   //       await supabase
//   //           .from('Users')
//   //           .update({'password': newPassword, 'c_password': newPassword})
//   //           .eq('id', widget.userId!);

//   //       print('✅ Supabase updated for User ID: ${widget.userId}');
//   //     }

//   //     // ✅ UPDATE IN SHAREDPREFERENCES
//   //     await prefs.setString('password', newPassword);

//   //     setState(() => isLoading = false);

//   //     print('✅ Password changed successfully');
//   //     print('═' * 50);

//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(
//   //         content: Text('✅ Password changed successfully'),
//   //         backgroundColor: Colors.green,
//   //       ),
//   //     );

//   //     // Clear fields
//   //     currentPasswordController.clear();
//   //     newPasswordController.clear();
//   //     confirmPasswordController.clear();

//   //     // Go back after 1 second
//   //     Future.delayed(const Duration(seconds: 1), () {
//   //       if (mounted) {
//   //         Navigator.pop(context);
//   //       }
//   //     });
//   //   } catch (e) {
//   //     setState(() => isLoading = false);
//   //     print('❌ Error changing password: $e');
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
//   //     );
//   //   }
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundC,
//       appBar: AppBar(
//         backgroundColor: AppColors.backgroundC,
//         elevation: 0,
//         title: const Text(
//           'Change Password',
//           style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black87),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 30),

//                 Text(
//                   'Secure Your Account',
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),

//                 const SizedBox(height: 8),

//                 Text(
//                   'Enter your current password and choose a new one',
//                   style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//                 ),

//                 const SizedBox(height: 40),

//                 _buildPasswordField(
//                   label: 'Current Password',
//                   controller: currentPasswordController,
//                   isVisible: isCurrentPasswordVisible,
//                   toggleVisibility: () {
//                     setState(
//                       () =>
//                           isCurrentPasswordVisible = !isCurrentPasswordVisible,
//                     );
//                   },
//                   hintText: 'Enter your current password',
//                 ),

//                 const SizedBox(height: 24),

//                 _buildPasswordField(
//                   label: 'New Password',
//                   controller: newPasswordController,
//                   isVisible: isNewPasswordVisible,
//                   toggleVisibility: () {
//                     setState(
//                       () => isNewPasswordVisible = !isNewPasswordVisible,
//                     );
//                   },
//                   hintText: 'Enter new password (min 6 characters)',
//                 ),

//                 const SizedBox(height: 24),

//                 _buildPasswordField(
//                   label: 'Confirm New Password',
//                   controller: confirmPasswordController,
//                   isVisible: isConfirmPasswordVisible,
//                   toggleVisibility: () {
//                     setState(
//                       () =>
//                           isConfirmPasswordVisible = !isConfirmPasswordVisible,
//                     );
//                   },
//                   hintText: 'Confirm your new password',
//                 ),

//                 const SizedBox(height: 40),

//                 // SizedBox(
//                 //   width: double.infinity,
//                 //   height: 50,
//                 //   child: ElevatedButton(
//                 //     style: ElevatedButton.styleFrom(
//                 //       backgroundColor: AppColors.ProgressB,
//                 //       shape: RoundedRectangleBorder(
//                 //         borderRadius: BorderRadius.circular(12),
//                 //       ),
//                 //     ),
//                 //     onPressed: isLoading ? null : _changePassword,
//                 //     child: isLoading
//                 //         ? const CircularProgressIndicator(
//                 //             color: Colors.white,
//                 //           )
//                 //         : const Text(
//                 //             'Change Password',
//                 //             style: TextStyle(
//                 //               fontSize: 16,
//                 //               fontWeight: FontWeight.bold,
//                 //               color: Colors.white,
//                 //             ),
//                 //           ),
//                 //   ),
//                 // ),
//                 CommonButton(text: "Change Password", onTap: updatePassword),

//                 const SizedBox(height: 30),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPasswordField({
//     required String label,
//     required TextEditingController controller,
//     required bool isVisible,
//     required VoidCallback toggleVisibility,
//     String hintText = '••••••••',
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(left: 4, bottom: 8),
//           child: Text(
//             label,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey.shade700,
//             ),
//           ),
//         ),
//         TextField(
//           controller: controller,
//           obscureText: !isVisible,
//           decoration: InputDecoration(
//             hintText: hintText,
//             hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
//             filled: true,
//             fillColor: Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.white, width: 1),
//             ),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 14,
//             ),
//             suffixIcon: IconButton(
//               icon: Icon(
//                 isVisible ? Icons.visibility : Icons.visibility_off,
//                 color: Colors.grey.shade600,
//               ),
//               onPressed: toggleVisibility,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   void dispose() {
//     currentPasswordController.dispose();
//     newPasswordController.dispose();
//     confirmPasswordController.dispose();
//     super.dispose();
//   }
// }
class ChangePasswordScreen extends StatefulWidget {
  final String? userId;

  const ChangePasswordScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isCurrentPasswordVisible = false;
  bool isNewPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _printDebugInfo();
  }

  // Debug function to print saved password
  Future<void> _printDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString('password') ?? 'NOT FOUND';
    final savedEmail = prefs.getString('email') ?? 'NOT FOUND';
    final userId = prefs.getString('user_id') ?? 'NOT FOUND';

    print('═' * 50);
    print('🔍 DEBUG INFO:');
    print('User ID: $userId');
    print('Saved Email: $savedEmail');
    print('Saved Password: "$savedPassword"');
    print('Password Length: ${savedPassword.length}');
    print('═' * 50);
  }

  final supabase = Supabase.instance.client;

  String sha256Hex(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> updatePassword() async {
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // ✅ Validation
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please fill all fields")));
      return;
    }

    // ✅ Check if new passwords match
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("New password and confirm password do not match"),
        ),
      );
      return;
    }

    // ✅ Check password length
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      print("🔍 Checking logged-in user ID...");
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("User not logged in")));
        return;
      }

      print("🔍 Checking user: $userId");

      // Fetch user from Supabase
      final user =
          await supabase
              .from('Users')
              .select('id, password')
              .eq('id', userId)
              .maybeSingle();

      if (user == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("User not found")));
        return;
      }

      final dbPassword = user['password']; // stored password in DB
      print("🔒 Stored Password: $dbPassword");

      // 🔐 Encrypt entered current password
      final encryptedEnteredPassword = sha256Hex(currentPassword);
      print("🔑 Entered (SHA256 HEX): $encryptedEnteredPassword");

      // ❌ Incorrect current password
      if (encryptedEnteredPassword != dbPassword) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Current password is incorrect"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print("✅ Password matched! Updating password...");

      // 🔐 Encrypt new password
      final newEncryptedPassword = sha256Hex(newPassword);

      // Update password in Supabase
      await supabase
          .from('Users')
          .update({'password': newEncryptedPassword})
          .eq('id', userId);

      // Update password in SharedPreferences
      await prefs.setString('password', newPassword);

      setState(() => isLoading = false);

      print("✅ Password updated successfully!");

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Password updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // Clear all text fields
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      // Navigate back to home page after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          // Pop until home screen (adjust route name as per your app)
          Navigator.of(context).popUntil((route) => route.isFirst);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainNavbar()),
          );

        }
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("❌ Error updating password: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundC,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundC,
        elevation: 0,
        title: const Text(
          'Change Password',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),

                Text(
                  'Secure Your Account',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Enter your current password and choose a new one',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 40),

                _buildPasswordField(
                  label: 'Current Password',
                  controller: currentPasswordController,
                  isVisible: isCurrentPasswordVisible,
                  toggleVisibility: () {
                    setState(
                      () =>
                          isCurrentPasswordVisible = !isCurrentPasswordVisible,
                    );
                  },
                  hintText: 'Enter your current password',
                ),

                const SizedBox(height: 24),

                _buildPasswordField(
                  label: 'New Password',
                  controller: newPasswordController,
                  isVisible: isNewPasswordVisible,
                  toggleVisibility: () {
                    setState(
                      () => isNewPasswordVisible = !isNewPasswordVisible,
                    );
                  },
                  hintText: 'Enter new password (min 6 characters)',
                ),

                const SizedBox(height: 24),

                _buildPasswordField(
                  label: 'Confirm New Password',
                  controller: confirmPasswordController,
                  isVisible: isConfirmPasswordVisible,
                  toggleVisibility: () {
                    setState(
                      () =>
                          isConfirmPasswordVisible = !isConfirmPasswordVisible,
                    );
                  },
                  hintText: 'Confirm your new password',
                ),

                const SizedBox(height: 40),

                CommonButton(
                  text: isLoading ? "Updating..." : "Change Password",
                  onTap: updatePassword,
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback toggleVisibility,
    String hintText = '••••••••',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: !isVisible,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey.shade600,
              ),
              onPressed: toggleVisibility,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
