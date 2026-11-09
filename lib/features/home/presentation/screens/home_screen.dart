import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/providers/incident_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Future<AppUser?> _userFuture;

  @override
  void initState() {
    super.initState();

    _userFuture = ref.read(authControllerProvider.notifier).getCurrentUser();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildAccessMessage(
            'We could not load your CampusCare profile. '
            'Please sign in again.',
          );
        }

        final user = snapshot.data!;

        if (!user.canAccessIncidents) {
          return _buildAccessMessage(
            'Your account is not currently active. '
            'Please contact an administrator.',
          );
        }

        final isStaff = user.canUseStaffFeatures;

        return _buildDashboard(user: user, isStaff: isStaff);
      },
    );
  }

  Widget _buildAccessMessage(String message) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 55,
                color: AppColors.primary,
              ),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard({required AppUser user, required bool isStaff}) {
    final firstName = (user.displayName ?? 'there').trim().split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(user),
                  const SizedBox(height: 28),

                  _buildWelcome(firstName, isStaff),
                  const SizedBox(height: 22),

                  _buildReportBanner(isStaff),
                  const SizedBox(height: 28),

                  if (isStaff) ...[
                    _buildStaffStatistics(),
                    const SizedBox(height: 28),
                  ],

                  _buildCategorySection(),
                  const SizedBox(height: 28),

                  _buildCampusIncidents(),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Dashboard header with the user's Cloudinary profile picture.
  Widget _buildHeader(AppUser user) {
    final photoUrl = user.photoUrl;

    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.health_and_safety_rounded,
            color: Colors.white,
            size: 29,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CampusCare',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Campus made safer, together',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () =>
              _showMessage('Notifications will be available soon.'),
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textPrimary,
            size: 27,
          ),
        ),
        InkWell(
          onTap: () => context.go('/profile'),
          borderRadius: BorderRadius.circular(25),
          child: Tooltip(
            message: 'Open Profile',
            child: CircleAvatar(
              radius: 21,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl == null || photoUrl.isEmpty
                  ? const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primary,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  // Welcome message.
  Widget _buildWelcome(String firstName, bool isStaff) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $firstName 👋',
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          isStaff
              ? 'Help us keep the campus safe and comfortable.'
              : 'Help make our campus safer.',
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Report issues and track their resolution.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // Reporting banner.
  Widget _buildReportBanner(bool isStaff) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        height: constraints.maxWidth < 300
            ? 240
            : constraints.maxWidth < 400
            ? 210
            : 190,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://africahealthcollaborative.org/wp-content/uploads/2023/10/IMG_8926-1320x880.jpg'
              '?auto=format&fit=crop&w=1000&q=85',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.primary,
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white24,
                    size: 100,
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.98),
                    AppColors.primary.withValues(alpha: 0.78),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isStaff
                        ? 'Campus needs\nyour attention.'
                        : 'See something\nbroken?',
                    style: const TextStyle(
                      fontSize: 23,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isStaff
                        ? 'Review reported issues and\nhelp resolve them.'
                        : 'Report it and help improve\nour campus.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.go(
                          isStaff ? '/incidents' : '/incidents/create',
                        );
                      },
                      icon: Icon(
                        isStaff
                            ? Icons.visibility_rounded
                            : Icons.add_circle_rounded,
                      ),
                      label: Text(
                        isStaff ? 'View Campus Reports' : 'Report an Incident',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
    );
  }

  // Staff-only statistics.
  Widget _buildStaffStatistics() {
    final incidentsAsync = ref.watch(incidentsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    color: AppColors.primary,
                    size: 25,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Incident Statistics',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.circle,
                          color: AppColors.success,
                          size: 8,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Live',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              incidentsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stackTrace) =>
                    _errorMessage('Unable to load incident statistics.'),
                data: (incidents) {
                  final total = incidents.length;
                  final pending = incidents
                      .where((incident) => incident.status == 'pending')
                      .length;
                  final inProgress = incidents
                      .where((incident) => incident.status == 'in_progress')
                      .length;
                  final resolved = incidents
                      .where((incident) => incident.status == 'resolved')
                      .length;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = (constraints.maxWidth - 10) / 2;

                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 8,
                        childAspectRatio: cardWidth / 76,
                        children: [
                          _StatisticCard(
                            title: 'Total Incidents',
                            value: '$total',
                            icon: Icons.access_time_rounded,
                            accentColor: AppColors.primary,
                          ),
                          _StatisticCard(
                            title: 'Pending Review',
                            value: '$pending',
                            icon: Icons.hourglass_top_rounded,
                            accentColor: AppColors.warning,
                          ),
                          _StatisticCard(
                            title: 'In Progress',
                            value: '$inProgress',
                            icon: Icons.play_arrow_rounded,
                            accentColor: AppColors.primaryDark,
                          ),
                          _StatisticCard(
                            title: 'Resolved',
                            value: '$resolved',
                            icon: Icons.check_rounded,
                            accentColor: AppColors.success,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Selecting a category opens incidents filtered by its Firestore category.
  Widget _buildCategorySection() {
    final categories = [
      _CategoryData(
        name: 'Electricity',
        firestoreCategory: 'Electricity Outage',
        icon: Icons.bolt_rounded,
        image:
            'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e'
            '?auto=format&fit=crop&w=500&q=80',
        color: const Color(0xFFF59E0B),
      ),
      _CategoryData(
        name: 'Water',
        firestoreCategory: 'Water Shortage',
        icon: Icons.water_drop_rounded,
        image:
            'https://images.unsplash.com/photo-1548839140-29a749e1cf4d'
            '?auto=format&fit=crop&w=500&q=80',
        color: const Color(0xFF2563EB),
      ),
      _CategoryData(
        name: 'Furniture',
        firestoreCategory: 'Broken Furniture',
        icon: Icons.chair_rounded,
        image:
            'https://images.unsplash.com/photo-1497366754035-f200968a6e72'
            '?auto=format&fit=crop&w=500&q=80',
        color: const Color(0xFF7C3AED),
      ),
      _CategoryData(
        name: 'Facilities',
        firestoreCategory: 'Damaged Facilities',
        icon: Icons.construction_rounded,
        image:
            'https://images.unsplash.com/photo-1562774053-701939374585'
            '?auto=format&fit=crop&w=500&q=80',
        color: const Color(0xFF64748B),
      ),
      _CategoryData(
        name: 'Sanitation',
        firestoreCategory: 'Sanitation',
        icon: Icons.delete_outline_rounded,
        image:
            'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b'
            '?auto=format&fit=crop&w=500&q=80',
        color: const Color(0xFF16A34A),
      ),
      _CategoryData(
        name: 'Safety',
        firestoreCategory: 'Safety Concern',
        icon: Icons.security_rounded,
        image:
            'https://images.unsplash.com/photo-1557597774-9d273605dfa9'
            '?auto=format&fit=crop&w=500&q=80',
        color: const Color(0xFFDC2626),
      ),
      _CategoryData(
        name: 'Other',
        firestoreCategory: 'Other',
        icon: Icons.more_horiz_rounded,
        image:
            'https://africahealthcollaborative.org/wp-content/uploads/2023/10/IMG_8926-1320x880.jpg'
            '?auto=format&fit=crop&w=500&q=80',
        color: const Color(0xFF64748B),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('Browse by Category'),
        const SizedBox(height: 6),
        const Text(
          'Select a category to see related campus reports.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          itemCount: categories.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];

            return _CategoryCard(
              category: category,
              onTap: () {
                final encodedCategory = Uri.encodeQueryComponent(
                  category.firestoreCategory,
                );

                context.go('/incidents?category=$encodedCategory');
              },
            );
          },
        ),
      ],
    );
  }

  // Show ALL campus incidents on the home screen.
  Widget _buildCampusIncidents() {
    final incidentsAsync = ref.watch(incidentsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionHeading('All Campus Incidents')),
            TextButton(
              onPressed: () => context.go('/incidents'),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'See what has been reported across campus.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        incidentsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(25),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stackTrace) =>
              _errorMessage('Unable to load campus incidents.'),
          data: (incidents) {
            final sortedIncidents = List<Incident>.from(incidents)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return _buildIncidentList(sortedIncidents);
          },
        ),
      ],
    );
  }

  Widget _buildIncidentList(List<Incident> incidents) {
    if (incidents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
        ),
        child: const Column(
          children: [
            Icon(Icons.assignment_outlined, size: 45, color: AppColors.primary),
            SizedBox(height: 12),
            Text(
              'No reports to display yet',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'New incident reports will appear here.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: incidents.map((incident) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _RecentIncidentCard(
            incident: incident,
            onTap: () {
              context.push('/incidents/${incident.id}');
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _errorMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }

  Widget _sectionHeading(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  // Bottom navigation.
  Widget _buildBottomNavigation() {
    return NavigationBar(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withValues(alpha: 0.10),
      selectedIndex: 0,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            break;
          case 1:
            context.go('/incidents');
            break;
          case 2:
            context.go('/incidents/create');
            break;
          case 3:
            context.go('/profile');
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          label: 'All Reports',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle_outline_rounded),
          label: 'Report',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}

// Staff statistics card.
class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Category information.
class _CategoryData {
  const _CategoryData({
    required this.name,
    required this.firestoreCategory,
    required this.icon,
    required this.image,
    required this.color,
  });

  final String name;
  final String firestoreCategory;
  final IconData icon;
  final String image;
  final Color color;
}

// Category card.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final _CategoryData category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    category.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: category.color.withValues(alpha: 0.10),
                        child: Icon(
                          category.icon,
                          size: 45,
                          color: category.color,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: CircleAvatar(
                      radius: 19,
                      backgroundColor: Colors.white,
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 23,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 8, 11),
              child: Text(
                category.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Campus incident card.
class _RecentIncidentCard extends StatelessWidget {
  const _RecentIncidentCard({required this.incident, required this.onTap});

  final Incident incident;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (incident.status) {
      case 'resolved':
        return AppColors.success;
      case 'in_progress':
        return AppColors.primary;
      case 'reviewed':
        return AppColors.primaryDark;
      default:
        return const Color.fromARGB(255, 247, 158, 4);
    }
  }

  String get _statusLabel {
    switch (incident.status) {
      case 'resolved':
        return 'Resolved';
      case 'in_progress':
        return 'In Progress';
      case 'reviewed':
        return 'Reviewed';
      default:
        return 'Pending';
    }
  }

  String get _formattedDate {
    final date = incident.createdAt.toLocal();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (incident.photoUrl != null &&
                  incident.photoUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    incident.photoUrl!,
                    width: double.infinity,
                    height: 165,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100,
                        width: double.infinity,
                        color: AppColors.primary.withValues(alpha: 0.07),
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textSecondary,
                          size: 35,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 13),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      incident.category,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                incident.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      incident.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formattedDate,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
