import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dailynest/AuthPage/user_profile.dart';
import 'package:dailynest/Auth/AuthService.dart';
import 'package:http/http.dart' as http;

class ProfileSettings extends StatefulWidget {
  static const String id = "ProfileSettings";

  const ProfileSettings({super.key});

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _contactController =
      TextEditingController(text: UserProfileData.contactNumber);

  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedAvatar = UserProfileData.avatarBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = authService.value.currentUser;
    if (user != null) {
      _usernameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      UserProfileData.username = user.displayName ?? 'Guest User';

      // Load profile data from Firestore
      final profile = await authService.value.getUserProfile();
      if (profile != null) {
        _contactController.text = profile['contactNumber'] ?? '';
        UserProfileData.contactNumber = profile['contactNumber'] ?? '';
      }

      // Load profile picture URL
      final photoUrl = user.photoURL ?? await authService.value.getProfilePictureUrl();
      if (photoUrl != null && mounted) {
        // Download and cache the image
        _loadImageFromUrl(photoUrl);
      }
    }
  }

  Future<void> _loadImageFromUrl(String url) async {
    try {
      // Check if it's a base64 data URL
      if (url.startsWith('data:image')) {
        final base64String = url.split(',').last;
        final bytes = base64Decode(base64String);
        if (mounted) {
          setState(() {
            _selectedAvatar = bytes;
            UserProfileData.avatarBytes = bytes;
          });
        }
        return;
      }

      // Otherwise load from HTTP URL
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _selectedAvatar = response.bodyBytes;
          UserProfileData.avatarBytes = response.bodyBytes;
        });
      }
    } catch (e) {
      // Silently fail - image will show default icon
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        return;
      }
      final bytes = await picked.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedAvatar = bytes;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to select image'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    final username = _usernameController.text.trim();
    final currentPassword = _currentPasswordController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (kDebugMode) {
      print('=== SAVE PROFILE STARTED ===');
      print('Username: $username');
      print('Has avatar: ${_selectedAvatar != null}');
      if (_selectedAvatar != null) {
        print('Avatar size: ${_selectedAvatar!.length} bytes');
      }
    }

    // Validate username
    if (username.isEmpty) {
      _showErrorDialog('Username cannot be empty');
      return;
    }

    // If changing password, validate all password fields
    if (password.isNotEmpty || confirm.isNotEmpty) {
      if (currentPassword.isEmpty) {
        _showErrorDialog('Please enter your current password to change it');
        return;
      }
      
      if (password.isEmpty) {
        _showErrorDialog('Please enter a new password');
        return;
      }

      if (password != confirm) {
        _showErrorDialog('New passwords do not match');
        return;
      }

      if (password.length < 6) {
        _showErrorDialog('New password must be at least 6 characters');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update username
      if (username != authService.value.currentUser?.displayName) {
        await authService.value.updateUsername(username: username);
        UserProfileData.username = username;
      }

      // Update password if provided
      if (password.isNotEmpty && currentPassword.isNotEmpty) {
        final email = authService.value.currentUser?.email;
        if (email != null) {
          await authService.value.resetPasswordFromCurrentPassword(
            currentPassword: currentPassword,
            newPassword: password,
            email: email,
          );
        }
      }

      // Upload profile picture if changed
      if (_selectedAvatar != null) {
        try {
          if (kDebugMode) {
            print('Attempting to upload profile picture...');
          }
          final uploadResult = await authService.value.uploadProfilePicture(_selectedAvatar!);
          if (uploadResult == null) {
            throw Exception('Failed to get upload URL - uploadResult is null');
          }
          if (kDebugMode) {
            print('Profile picture uploaded successfully');
          }
        } catch (uploadError) {
          if (kDebugMode) {
            print('Upload error caught: $uploadError');
          }
          throw Exception('Profile picture upload failed: ${uploadError.toString()}');
        }
      }

      // Save contact number to Firestore
      await authService.value.saveUserProfile(
        contactNumber: _contactController.text.trim(),
      );

      // Update local data
      UserProfileData.contactNumber = _contactController.text.trim();
      UserProfileData.avatarBytes = _selectedAvatar;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFFFF9E4D),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to update profile';
        
        if (e.toString().contains('wrong-password')) {
          errorMessage = 'Current password is incorrect';
        } else if (e.toString().contains('requires-recent-login')) {
          errorMessage = 'Please log out and log in again to change your password';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'New password is too weak';
        } else if (e.toString().contains('storage/unauthorized')) {
          errorMessage = 'Storage permission denied. Please contact support.';
        } else if (e.toString().contains('Profile picture upload failed')) {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        } else {
          errorMessage = 'Failed to update profile: ${e.toString()}';
        }

        _showErrorDialog(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 6),
                        const Text(
                          'DailyNest',
                          style: TextStyle(
                            color: Color(0xFFFF9E4D),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Profile Settings',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  _selectedAvatar != null ? MemoryImage(_selectedAvatar!) : null,
                              child: _selectedAvatar == null
                                  ? const Icon(Icons.person, size: 55, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _pickAvatar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9E4D),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.file_upload_outlined),
                              label: const Text('Upload File'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                          controller: _usernameController,
                          label: 'Username',
                          hint: 'Enter your username',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Your email address',
                          keyboardType: TextInputType.emailAddress,
                          enabled: false, // Email cannot be changed in Firebase
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          'Change Password (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _currentPasswordController,
                          label: 'Current Password',
                          hint: 'Enter current password',
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'New Password',
                          hint: 'Enter new password',
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm New Password',
                          hint: 'Re-enter new password',
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _contactController,
                          label: 'Contact Number',
                          hint: 'Enter contact number',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9E4D),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Save'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enabled: enabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[200],
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF9E4D)),
            ),
          ),
        ),
      ],
    );
  }
}
