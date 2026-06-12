import 'package:flutter/material.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/posts_repository.dart';
import '../../data/repositories/mock_posts_repository.dart';

class AddPostScreen extends StatefulWidget {
  final VoidCallback onPostPublished;

  const AddPostScreen({
    super.key,
    required this.onPostPublished,
  });

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final PostsRepository _repository = MockPostsRepository();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isRoutePost = false;
  bool _isLoading = false;
  
  // List of high-quality premium truck photos from Unsplash for selection
  final List<String> _selectableImages = [
    'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1591768793355-74d75b50f58f?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1532601224476-15c79f2f7a51?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1580674684081-7617fbf3d745?q=80&w=400&auto=format&fit=crop',
  ];
  
  late String _selectedImageUrl;

  @override
  void initState() {
    super.initState();
    _selectedImageUrl = _selectableImages[0];
    _phoneController.text = '+91 98765 43210'; // Pre-filled with active user Ramesh's phone
  }

  @override
  void dispose() {
    _captionController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _timeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handlePublish() async {
    final captionText = _captionController.text.trim();
    if (captionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description for your post.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_isRoutePost) {
      if (_fromController.text.trim().isEmpty ||
          _toController.text.trim().isEmpty ||
          _timeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all route details (From, To, Time).'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    // Extract hashtags from caption or default them
    final words = captionText.split(' ');
    final List<String> tags = words.where((w) => w.startsWith('#')).toList();
    if (tags.isEmpty) {
      tags.addAll(['#TruckMate', '#LoadAlert']);
      if (_isRoutePost) {
        tags.add('#LoadAvailable');
      }
    }

    // Compose final multiline status text
    String statusText = captionText;
    if (_isRoutePost) {
      statusText = '${_fromController.text} → ${_toController.text} 📍\n'
          'Departure: ${_timeController.text} ⏰\n'
          'Truck/Load details: $captionText';
    }

    final newPost = Post(
      id: 'post_custom_${DateTime.now().millisecondsSinceEpoch}',
      userName: 'Ramesh Transport',
      role: 'Owner',
      avatarUrl: 'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?q=80&w=200&auto=format&fit=crop',
      timeAgo: 'Just now',
      statusText: statusText,
      imageUrl: _selectedImageUrl,
      likeCount: 0,
      commentCount: 0,
      isLiked: false,
      isBookmarked: false,
      caption: captionText.length > 50 ? '${captionText.substring(0, 50)}...' : captionText,
      tags: tags,
      hasRouteCard: _isRoutePost,
      fromLocation: _isRoutePost ? _fromController.text.trim() : null,
      toLocation: _isRoutePost ? _toController.text.trim() : null,
      departureTime: _isRoutePost ? _timeController.text.trim() : null,
      contactNumber: _isRoutePost ? _phoneController.text.trim() : null,
    );

    try {
      await _repository.addPost(newPost);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Post published successfully!')),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
        // Reset form
        _captionController.clear();
        _fromController.clear();
        _toController.clear();
        _timeController.clear();
        _isRoutePost = false;
        
        // Callback to navigate to Feed page & trigger refresh
        widget.onPostPublished();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to publish post.')),
        );
      }
    }
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
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0095F6)),
                    SizedBox(height: 16),
                    Text('Publishing post... Please wait'),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Image Selector Title
                    Text(
                      'Select Post Photo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Selected Image Preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Image.network(
                          _selectedImageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Horizontal Carousel of selectable preset images
                    SizedBox(
                      height: 72,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectableImages.length,
                        itemBuilder: (context, index) {
                          final imageUrl = _selectableImages[index];
                          final isSelected = _selectedImageUrl == imageUrl;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImageUrl = imageUrl;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 12),
                              width: 96,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0095F6) : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 2. Status Description Input
                    Text(
                      'Post Description / Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildCustomTextField(
                      controller: _captionController,
                      hintText: 'What truck load or mechanic update do you want to share? (e.g. #Mumbai #LoadAvailable)',
                      maxLines: 4,
                      icon: Icons.edit_note_rounded,
                      keyboardType: TextInputType.multiline,
                    ),
                    const SizedBox(height: 20),
                    
                    // 3. Share as Route Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: inputBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: SwitchListTile(
                        activeThumbColor: const Color(0xFF0095F6),
                        activeTrackColor: const Color(0xFF0095F6).withValues(alpha: 0.5),
                        title: Text(
                          'Share as Route Availability',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        subtitle: Text(
                          'Adds source, destination, departure time, and call button to this post.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
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
                    
                    // 4. Expanding Route Form Fields
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _isRoutePost
                          ? Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  _buildCustomTextField(
                                    controller: _fromController,
                                    hintText: 'Departure City (e.g. Mumbai, MH)',
                                    icon: Icons.location_on_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildCustomTextField(
                                    controller: _toController,
                                    hintText: 'Destination City (e.g. Nagpur, MH)',
                                    icon: Icons.location_on_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildCustomTextField(
                                    controller: _timeController,
                                    hintText: 'Departure Date & Time (e.g. Tomorrow, 7:00 PM)',
                                    icon: Icons.access_time_rounded,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildCustomTextField(
                                    controller: _phoneController,
                                    hintText: 'Contact Phone Number',
                                    icon: Icons.phone_android_rounded,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 32),
                    
                    // 5. Share/Publish Button
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
                              color: const Color(0xFF0095F6).withValues(alpha: 0.2),
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
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
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
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : const Color(0xFF1C1C1C),
        ),
        decoration: InputDecoration(
          icon: Icon(icon, color: isDark ? Colors.white60 : Colors.grey.shade500, size: 20),
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
}
