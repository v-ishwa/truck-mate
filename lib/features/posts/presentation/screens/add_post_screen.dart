import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_constants.dart';

class AddPostScreen extends StatefulWidget {
  final VoidCallback onPostPublished;

  const AddPostScreen({super.key, required this.onPostPublished});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure city options are sorted ascending
    _cityOptions.sort();
  }

  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  bool _isRoutePost = false;
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final List<String> _cityOptions = [
    'Chennai',
    'Coimbatore',
    'Madurai',
    'Tiruchirappalli',
    'Salem',
    'Tirunelveli',
    'Erode',
    'Vellore',
    'Thanjavur',
    'Dindigul',
    'Nagercoil',
    'Karur',
    'Cuddalore',
    'Kanchipuram',
    'Tirupur',
    'Hosur',
    'Namakkal',
    'Ariyalur',
    'Perambalur',
    'Kumbakonam',
    'Nagapattinam',
    'Pudukkottai',
    'Ramanathapuram',
    'Sivaganga',
    'Villupuram',
    'Thoothukudi',
    'Krishnagiri',
  ];
  String? _selectedFromCity;
  String? _selectedToCity;

  @override
  void dispose() {
    _captionController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _timeController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _showImageSourceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0095F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFF0095F6),
                  ),
                ),
                title: Text(
                  'Gallery',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                  ),
                ),
                subtitle: Text(
                  'Choose from your photos',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.green,
                  ),
                ),
                title: Text(
                  'Camera',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                  ),
                ),
                subtitle: Text(
                  'Take a new photo',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadImage(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;

    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.uploadPostImage}',
    );
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['imageUrl'];
      }
    }
    return null;
  }

  Future<bool> _createPost(String? imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createPost}');
    final body = <String, dynamic>{
      'description': _captionController.text.trim(),
      'postImage': imageUrl ?? '',
    };

    if (_isRoutePost) {
      body['fromLocation'] = _fromController.text.trim();
      body['toLocation'] = _toController.text.trim();
      body['travelDate'] = _dateController.text.trim();
      body['travelTime'] = _timeController.text.trim();
    }

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  void _handlePublish() async {
    final captionText = _captionController.text.trim();
    if (captionText.isEmpty) {
      _showSnackBar(
        'Please enter a description for your post.',
        Colors.redAccent,
      );
      return;
    }

    if (_isRoutePost) {
      if (_fromController.text.trim().isEmpty ||
          _toController.text.trim().isEmpty ||
          _timeController.text.trim().isEmpty) {
        _showSnackBar(
          'Please fill in all route details (From, To, Time).',
          Colors.redAccent,
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
        if (imageUrl == null) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showSnackBar(
              'Failed to upload image. Please try again.',
              Colors.redAccent,
            );
          }
          return;
        }
      }

      // Step 2: Create the post
      final success = await _createPost(imageUrl);

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          _showSnackBar(
            'Post published successfully!',
            Colors.green.shade600,
            icon: Icons.check_circle_rounded,
          );

          // Reset form
          _captionController.clear();
          _fromController.clear();
          _toController.clear();
          _timeController.clear();
          _dateController.clear();
          setState(() {
            _selectedImage = null;
            _isRoutePost = false;
          });

          // Callback to navigate to Feed page & trigger refresh
          widget.onPostPublished();
        } else {
          _showSnackBar(
            'Failed to publish post. Please try again.',
            Colors.redAccent,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(
          'Connection error: ${e.toString().replaceFirst("Exception: ", "")}',
          Colors.redAccent,
        );
      }
    }
  }

  void _showSnackBar(String message, Color color, {IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1C);
    final inputBgColor = isDark ? const Color(0xFF161616) : Colors.grey.shade50;
    final borderColor = isDark ? const Color(0xFF262626) : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Create Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF0095F6)),
                    const SizedBox(height: 16),
                    Text(
                      _selectedImage != null
                          ? 'Uploading image...'
                          : 'Publishing post...',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                          // 1. Image Section
                          Text(
                            'Post Photo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose a photo from your gallery or take one now',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Image preview or picker
                          GestureDetector(
                            onTap: _showImageSourceSheet,
                            child: _selectedImage != null
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: AspectRatio(
                                          aspectRatio: 16 / 10,
                                          child: Image.file(
                                            _selectedImage!,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(
                                              () => _selectedImage = null,
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 10,
                                        right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.edit_rounded,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Change',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(
                                    height: 180,
                                    decoration: BoxDecoration(
                                      color: inputBgColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: borderColor,
                                        width: 1.5,
                                        strokeAlign:
                                            BorderSide.strokeAlignInside,
                                      ),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF0095F6,
                                              ).withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.add_photo_alternate_rounded,
                                              size: 36,
                                              color: Color(0xFF0095F6),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Tap to add a photo',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Gallery or Camera',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white30
                                                  : Colors.grey.shade400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 24),

                          // 2. Description Input
                          Text(
                            'Post Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildCustomTextField(
                            controller: _captionController,
                            hintText:
                                'What truck load or update do you want to share?',
                            maxLines: 4,
                            minLines: 1,
                            keyboardType: TextInputType.multiline,
                            centerHint: false,
                          ),
                          const SizedBox(height: 20),

                          // 3. Route toggle
                          Container(
                            decoration: BoxDecoration(
                              color: inputBgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor, width: 1),
                            ),
                            child: SwitchListTile(
                              activeThumbColor: const Color(0xFF0095F6),
                              activeTrackColor: const Color(
                                0xFF0095F6,
                              ).withValues(alpha: 0.5),
                              title: Text(
                                'Share as Route Availability',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              subtitle: Text(
                                'Adds source, destination, departure time, and call button.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey.shade600,
                                ),
                              ),
                              value: _isRoutePost,
                              onChanged: (val) {
                                setState(() {
                                  _isRoutePost = val;
                                });
                              },
                            ),
                          ),

                          // 4. Route Form Fields
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child: _isRoutePost
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 20.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Route Details',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildDropdownField(
                                          label: 'Departure City',
                                          value: _selectedFromCity,
                                          items: _cityOptions,
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedFromCity = val;
                                              _fromController.text = val ?? '';
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        _buildDropdownField(
                                          label: 'Destination City',
                                          value: _selectedToCity,
                                          items: _cityOptions,
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedToCity = val;
                                              _toController.text = val ?? '';
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        _buildDateField(
                                          controller: _dateController,
                                          label: 'Travel Date',
                                          onTap: () async {
                                            final selected =
                                                await showDatePicker(
                                                  context: context,
                                                  initialDate: DateTime.now(),
                                                  firstDate: DateTime.now()
                                                      .subtract(
                                                        const Duration(days: 1),
                                                      ),
                                                  lastDate: DateTime.now().add(
                                                    const Duration(days: 365),
                                                  ),
                                                );
                                            if (selected != null) {
                                              setState(() {
                                                _dateController.text =
                                                    '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
                                              });
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTimeField(
                                          controller: _timeController,
                                          label: 'Departure Time',
                                          onTap: () async {
                                            final picked = await showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.now(),
                                            );
                                            if (picked != null) {
                                              final hour =
                                                  picked.hourOfPeriod == 0
                                                  ? 12
                                                  : picked.hourOfPeriod;
                                              final period =
                                                  picked.period == DayPeriod.am
                                                  ? 'AM'
                                                  : 'PM';
                                              setState(() {
                                                _timeController.text =
                                                    '$hour:${picked.minute.toString().padLeft(2, '0')} $period';
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 32),

                          // 5. Publish Button
                          GestureDetector(
                            onTap: _handlePublish,
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0095F6),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF0095F6,
                                    ).withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Publish Post',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
              ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    int? maxLines = 1,
    int? minLines,
    TextInputType keyboardType = TextInputType.text,
    bool centerHint = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBgColor = isDark ? const Color(0xFF161616) : Colors.grey.shade50;
    final borderColor = isDark ? const Color(0xFF262626) : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: inputBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: minLines,
        keyboardType: keyboardType,
        textAlign: centerHint ? TextAlign.center : TextAlign.start,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : const Color(0xFF1C1C1C),
        ),
        decoration: InputDecoration(
          icon: icon != null
              ? Icon(
                  icon,
                  color: isDark ? Colors.white60 : Colors.grey.shade500,
                  size: 20,
                )
              : null,
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDark ? Colors.white30 : Colors.grey.shade400,
            fontSize: 14,
          ),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  // Helper widgets for dropdown, date, and time fields
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBgColor = isDark ? const Color(0xFF161616) : Colors.grey.shade50;
    final borderColor = isDark ? const Color(0xFF262626) : Colors.grey.shade200;
    // Fixed width to avoid fullscreen dropdown overlay
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: inputBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        constraints: BoxConstraints(minHeight: 48),
        child: DropdownButtonFormField<String>(
          isExpanded: false,
          // No initial value => shows hint "Select ..."
          initialValue: null,
          menuMaxHeight: 250,
          decoration: InputDecoration(
            hintText: label, // acts as placeholder, no persistent label
            hintStyle: TextStyle(color: Colors.grey.shade600),
            border: InputBorder.none,
            isDense: true,
          ),
          items: items
              .map((city) => DropdownMenuItem(value: city, child: Text(city)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBgColor = isDark ? const Color(0xFF161616) : Colors.grey.shade50;
    final borderColor = isDark ? const Color(0xFF262626) : Colors.grey.shade200;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: inputBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.text.isEmpty
                    ? 'Select travel date'
                    : controller.text,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBgColor = isDark ? const Color(0xFF161616) : Colors.grey.shade50;
    final borderColor = isDark ? const Color(0xFF262626) : Colors.grey.shade200;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: inputBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.text.isEmpty
                    ? 'Select departure time'
                    : controller.text,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
