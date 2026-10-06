import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tripsplit_widgets.dart';

class TripGalleryScreen extends StatefulWidget {
  final int? initialTripId;

  const TripGalleryScreen({Key? key, this.initialTripId}) : super(key: key);

  @override
  State<TripGalleryScreen> createState() => _TripGalleryScreenState();
}

class _TripGalleryScreenState extends State<TripGalleryScreen> {
  int _selectedTripIndex = 0;
  int _selectedDayIndex = 0;
  bool _initializedFromArgs = false;

  late final List<Map<String, dynamic>> _tripAlbums;

  @override
  void initState() {
    super.initState();
    _initAlbums();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromArgs) {
      _initializedFromArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('tripId')) {
        final id = args['tripId'];
        final foundIndex = _tripAlbums.indexWhere((t) => t['id'] == id);
        if (foundIndex != -1) {
          setState(() {
            _selectedTripIndex = foundIndex;
            _selectedDayIndex = 0;
          });
        }
      } else if (widget.initialTripId != null) {
        final foundIndex = _tripAlbums.indexWhere((t) => t['id'] == widget.initialTripId);
        if (foundIndex != -1) {
          setState(() {
            _selectedTripIndex = foundIndex;
            _selectedDayIndex = 0;
          });
        }
      }
    }
  }

  void _initAlbums() {
    _tripAlbums = [
      {
        'id': 1,
        'title': 'Goa Trip 🏖️',
        'destination': 'Goa, India',
        'dates': '12 - 16 Dec 2024',
        'cover': 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=800&auto=format&fit=crop&q=80',
        'days': ['All Photos (24)', 'Day 1 (8)', 'Day 2 (5)', 'Day 3 (7)', 'Day 4 (4)'],
        'photos': [
          {
            'title': 'Sunset at Baga Beach',
            'day': 'Day 1',
            'uploader': 'Het',
            'image': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
            'isFeatured': true,
          },
          {
            'title': 'Dinner at Beach Shack',
            'day': 'Day 1',
            'uploader': 'Neha',
            'image': 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=500',
          },
          {
            'title': 'Friends by the Shore',
            'day': 'Day 2',
            'uploader': 'Rahul',
            'image': 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=500',
          },
          {
            'title': 'Parasailing & Jet Ski',
            'day': 'Day 3',
            'uploader': 'Amit',
            'image': 'https://images.unsplash.com/photo-1502680390469-be75c86b636f?w=500',
          },
          {
            'title': 'Anjuna Flea Market',
            'day': 'Day 3',
            'uploader': 'Priya',
            'image': 'https://images.unsplash.com/photo-1510414842594-a61c69b5ae57?w=500',
          },
          {
            'title': 'Villa Pool Evening',
            'day': 'Day 4',
            'uploader': 'Het',
            'image': 'https://images.unsplash.com/photo-1495954484750-af469f2f9be5?w=500',
            'extraCount': '+18',
          },
        ],
      },
      {
        'id': 2,
        'title': 'Manali Winter 🏔️',
        'destination': 'Manali, Himachal',
        'dates': '5 - 10 Jan 2025',
        'cover': 'https://images.unsplash.com/photo-1517411032315-54ef2cb783bb?w=800&auto=format&fit=crop&q=80',
        'days': ['All Photos (18)', 'Day 1 (6)', 'Day 2 (7)', 'Day 3 (5)'],
        'photos': [
          {
            'title': 'Snow Peaks at Solang Valley',
            'day': 'Day 1',
            'uploader': 'Rahul',
            'image': 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800',
            'isFeatured': true,
          },
          {
            'title': 'Ski Gear & Snowboarding',
            'day': 'Day 1',
            'uploader': 'Pooja',
            'image': 'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=500',
          },
          {
            'title': 'Warm Bonfire Night',
            'day': 'Day 2',
            'uploader': 'Het',
            'image': 'https://images.unsplash.com/photo-1475483768296-6163e08872a1?w=500',
          },
          {
            'title': 'Old Manali Wooden Cafe',
            'day': 'Day 2',
            'uploader': 'Rohan',
            'image': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=500',
          },
          {
            'title': 'Pine Forest Walk',
            'day': 'Day 3',
            'uploader': 'Rahul',
            'image': 'https://images.unsplash.com/photo-1448375240586-882707db888b?w=500',
            'extraCount': '+13',
          },
        ],
      },
      {
        'id': 3,
        'title': 'Weekend Roadtrip 🚗',
        'destination': 'Lonavala & Khandala',
        'dates': '22 - 24 Nov 2024',
        'cover': 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800&auto=format&fit=crop&q=80',
        'days': ['All Photos (12)', 'Day 1 (7)', 'Day 2 (5)'],
        'photos': [
          {
            'title': 'Mumbai-Pune Expressway Cruise',
            'day': 'Day 1',
            'uploader': 'Neha',
            'image': 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800',
            'isFeatured': true,
          },
          {
            'title': 'Tiger Point Misty View',
            'day': 'Day 1',
            'uploader': 'Siddharth',
            'image': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=500',
          },
          {
            'title': 'Bhushi Dam Steps',
            'day': 'Day 2',
            'uploader': 'Het',
            'image': 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?w=500',
            'extraCount': '+9',
          },
        ],
      },
      {
        'id': 4,
        'title': 'Udaipur Heritage 🏰',
        'destination': 'Udaipur, Rajasthan',
        'dates': '10 - 14 Oct 2024',
        'cover': 'https://images.unsplash.com/photo-1599661046289-e31897846e41?w=800&auto=format&fit=crop&q=80',
        'days': ['All Photos (35)', 'Day 1 (10)', 'Day 2 (12)', 'Day 3 (13)'],
        'photos': [
          {
            'title': 'Lake Pichola Palace Reflection',
            'day': 'Day 1',
            'uploader': 'Het',
            'image': 'https://images.unsplash.com/photo-1599661046289-e31897846e41?w=800',
            'isFeatured': true,
          },
          {
            'title': 'City Palace Courtyard',
            'day': 'Day 1',
            'uploader': 'Rahul',
            'image': 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?w=500',
          },
          {
            'title': 'Rooftop Rajasthani Dinner',
            'day': 'Day 2',
            'uploader': 'Priya',
            'image': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=500',
          },
          {
            'title': 'Monsoon Palace Sunset',
            'day': 'Day 3',
            'uploader': 'Amit',
            'image': 'https://images.unsplash.com/photo-1495954484750-af469f2f9be5?w=500',
            'extraCount': '+28',
          },
        ],
      },
    ];
  }

  Map<String, dynamic> get _currentAlbum => _tripAlbums[_selectedTripIndex];

  List<Map<String, dynamic>> get _filteredPhotos {
    final album = _currentAlbum;
    final photos = (album['photos'] as List<Map<String, dynamic>>?) ?? [];
    if (_selectedDayIndex == 0) return photos;

    final dayPrefix = 'Day $_selectedDayIndex';
    return photos.where((p) => (p['day'] as String).startsWith(dayPrefix)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentAlbum = _currentAlbum;
    final days = (currentAlbum['days'] as List<String>?) ?? [];
    final photos = _filteredPhotos;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            TripSplitHeader(
              title: 'Trip Gallery',
              subtitle: '${currentAlbum['title']} • ${currentAlbum['dates']}',
              rightAction: GestureDetector(
                onTap: () => _showAddPhotosSheet(context, isDark, currentAlbum),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded, size: 15, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Upload',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              onBack: () => Navigator.of(context).maybePop(),
            ),

            const SizedBox(height: 6),

            // 1. Horizontal Trip-by-Trip Selector Header
            _buildTripSelectorBar(isDark),

            const SizedBox(height: 10),

            // 2. Day Filter Tabs for Active Trip
            if (days.isNotEmpty)
              SizedBox(
                height: 36,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: days.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, index) {
                    final isSelected = index == _selectedDayIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDayIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? const Color(0xFF131A29) : Colors.white),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            days[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.textDarkMuted : AppColors.textLightMain),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),

            // 3. Photos Grid & Featured Card
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    // Featured Cover Card
                    GestureDetector(
                      onTap: () => _openPhotoViewer(
                        context,
                        isDark,
                        currentAlbum['cover'] as String,
                        '${currentAlbum['title']} Featured Memories',
                        currentAlbum['destination'] as String,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            Image.network(
                              currentAlbum['cover'] as String,
                              height: 175,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              height: 175,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 14,
                              bottom: 12,
                              right: 14,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.25),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'HIGHLIGHT REEL',
                                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currentAlbum['destination'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 24),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Photo Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (ctx, index) {
                        final photo = photos[index];
                        final hasExtra = photo.containsKey('extraCount');

                        return GestureDetector(
                          onTap: () => _openPhotoViewer(
                            context,
                            isDark,
                            photo['image'] as String,
                            photo['title'] as String,
                            'Uploaded by ${photo['uploader']} • ${photo['day']}',
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  photo['image'] as String,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.transparent, Colors.black.withOpacity(0.68)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 10,
                                  bottom: 10,
                                  right: 10,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        photo['day'] as String,
                                        style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        photo['title'] as String,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasExtra)
                                  Container(
                                    color: Colors.black.withOpacity(0.55),
                                    child: Center(
                                      child: Text(
                                        photo['extraCount'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons: Download All & Share to Group
                    Row(
                      children: [
                        Expanded(
                          child: TripSplitSecondaryButton(
                            label: 'Download All',
                            icon: const Icon(Icons.download_rounded, size: 18, color: AppColors.primary),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Downloading photos for ${currentAlbum['title']}... 📥')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TripSplitButton(
                            label: 'Share Gallery',
                            icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gallery link for ${currentAlbum['title']} copied! 🔗')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Horizontal Trip-by-Trip Selector Header
  Widget _buildTripSelectorBar(bool isDark) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _tripAlbums.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, index) {
          final trip = _tripAlbums[index];
          final isSelected = index == _selectedTripIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTripIndex = index;
                _selectedDayIndex = 0;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xFF1E283D) : Colors.white)
                    : (isDark ? const Color(0xFF131A29) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      trip['cover'] as String,
                      width: 26,
                      height: 26,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    trip['title'] as String,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.white : AppColors.primary)
                          : (isDark ? AppColors.textDarkMuted : AppColors.textLightMain),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Full-Screen Image Viewer Modal
  void _openPhotoViewer(BuildContext context, bool isDark, String imageUrl, String title, String subtitle) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 380,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131A29) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, color: AppColors.primary),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Photo saved to device gallery! 📸')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Upload/Add Photo Bottom Sheet
  void _showAddPhotosSheet(BuildContext context, bool isDark, Map<String, dynamic> album) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111726) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Upload to ${album['title']}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2338) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3), style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 44, color: AppColors.primary),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose Photos from Device',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Supports JPG, PNG up to 25MB',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TripSplitButton(
                label: 'Upload Selected Photos',
                icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 18),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Photos successfully uploaded to ${album['title']}! 🎉'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
