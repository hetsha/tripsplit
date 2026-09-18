import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class TripSelectorScreen extends StatefulWidget {
  const TripSelectorScreen({Key? key}) : super(key: key);

  @override
  State<TripSelectorScreen> createState() => _TripSelectorScreenState();
}

class _TripSelectorScreenState extends State<TripSelectorScreen> {
  final _joinCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSwitchTrip(int tripId) async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthService>(context, listen: false).switchTrip(tripId);
      // Wait, switching trip returns success. The parent shell will rebuild main.dart based on active trip id!
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to switch trip: $e'), backgroundColor: AppColors.negative),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groups', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.negative),
            onPressed: () => authService.logout(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Select a group to continue or join a new one using an invite code.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Trips list
                  Expanded(
                    child: authService.trips.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.beach_access_rounded, size: 64, color: Colors.grey.withOpacity(0.4)),
                                const SizedBox(height: 12),
                                const Text('No groups yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const Text('Join a group or ask to be added!', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: authService.trips.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final trip = authService.trips[index];
                              final isSelected = authService.activeTripId == trip.id;

                              return GlassCard(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: InkWell(
                                  onTap: () => _handleSwitchTrip(trip.id),
                                  child: Row(
                                    children: [
                                      // Trip Icon Box
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: isSelected ? AppColors.brandGradient : [Colors.grey, Colors.grey],
                                          ),
                                        ),
                                        child: const Icon(Icons.map_rounded, color: Colors.white, size: 24),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Trip Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              trip.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            Text(
                                              trip.tripCode,
                                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Selection Arrow/Check
                                      if (isSelected)
                                        const Icon(Icons.check_circle_rounded, color: AppColors.positive, size: 28)
                                      else
                                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Join trip input row
                  const SizedBox(height: 16),
                  const Text('Have an invite code?', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _joinCodeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'e.g. TRIP-DXQAT',
                            filled: true,
                            fillColor: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final code = _joinCodeController.text.trim().toUpperCase();
                          if (code.isEmpty) return;
                          setState(() => _isLoading = true);
                          // For MVP, join trip via client API wrapper
                          try {
                            final client = ApiClient();
                            final res = await client.post(ApiEndpoints.joinTrip, {'trip_code': code});
                            if (res['success'] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Joined trip successfully!'), backgroundColor: AppColors.positive),
                              );
                              _joinCodeController.clear();
                              await authService.checkAuth(); // reload list
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppColors.negative),
                            );
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Join'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
