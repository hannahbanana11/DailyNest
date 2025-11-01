import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dailynest/AuthPage/profile_setting.dart';
import 'package:dailynest/Auth/AuthService.dart';
import 'package:http/http.dart' as http;

class UserProfileData {
  static Uint8List? avatarBytes;
  static String username = 'Guest User';
  static String contactNumber = '';
}

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  String _username = 'Guest User';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = authService.value.currentUser;
    if (user != null) {
      setState(() {
        _username = user.displayName ?? 'Guest User';
        _email = user.email ?? '';
        UserProfileData.username = _username;
      });

      // Load profile data from Firestore
      final profile = await authService.value.getUserProfile();
      if (profile != null && mounted) {
        setState(() {
          UserProfileData.contactNumber = profile['contactNumber'] ?? '';
        });
      }

      // Load profile picture
      final photoUrl = user.photoURL ?? await authService.value.getProfilePictureUrl();
      if (photoUrl != null && mounted) {
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
            UserProfileData.avatarBytes = bytes;
          });
        }
        return;
      }

      // Otherwise load from HTTP URL
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && mounted) {
        setState(() {
          UserProfileData.avatarBytes = response.bodyBytes;
        });
      }
    } catch (e) {
      // Silently fail - image will show default icon
    }
  }

  void _openProfileSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileSettings()),
    ).then((_) {
      _loadUserData(); // Reload user data after returning from settings
      setState(() {});
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await authService.value.signOut();
                // No need to navigate - the StreamBuilder in main.dart will handle it
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to logout: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Logout'),
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
        leading: ModalRoute.of(context)?.canPop == true
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'DailyNest',
                  style: TextStyle(
                    color: Color(0xFFFF9E4D),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: UserProfileData.avatarBytes != null
                          ? MemoryImage(UserProfileData.avatarBytes!)
                          : null,
                      child: UserProfileData.avatarBytes == null
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 8,
                      child: GestureDetector(
                        onTap: _openProfileSettings,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.edit, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _openProfileSettings,
                  child: const Text(
                    'Profile Settings',
                    style: TextStyle(
                      color: Colors.black87,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (_email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
                if (UserProfileData.contactNumber.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Contact: ${UserProfileData.contactNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Logout'),
                ),
                const Spacer(),
                const Text(
                  'Tap the icons below to explore more features.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
