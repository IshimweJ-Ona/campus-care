import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/incident.dart';
import '../providers/incident_providers.dart';
import 'incident_details_screen.dart';

class MyIncidentsScreen extends ConsumerWidget {
  const MyIncidentsScreen({super.key, this.category});

  final String? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _MyIncidentsBody(category: category);
  }
}

class _MyIncidentsBody extends ConsumerStatefulWidget {
  const _MyIncidentsBody({required this.category});

  final String? category;

  @override
  ConsumerState<_MyIncidentsBody> createState() => _MyIncidentsScreenState();
}

class _MyIncidentsScreenState extends ConsumerState<_MyIncidentsBody> {
  late Future<AppUser?> _userFuture;
  String _statusFilter = 'all';

  static const Color primaryColor = Color(0xFF1769AA);
  static const Color darkColor = Color(0xFF172B4D);
  static const Color backgroundColor = Color(0xFFF7F9FC);

  @override
  void initState() {
    super.initState();
    _userFuture = ref.read(authControllerProvider.notifier).getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(incidentsStreamProvider);

    return FutureBuilder<AppUser?>(
      future: _userFuture,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final isApprovedStaff = user?.canUseStaffFeatures ?? false;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home'),
            ),
            title: Text(
              widget.category == null ? 'Campus Incidents' : widget.category!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            foregroundColor: darkColor,
            elevation: 0,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(incidentsStreamProvider);
            },
            child: incidentsAsync.when(
              loading: () => _buildScrollablePage(
                context,
                isApprovedStaff: isApprovedStaff,
                content: const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stack) => _buildScrollablePage(
                context,
                isApprovedStaff: isApprovedStaff,
                content: SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: _buildError(error.toString())),
                ),
              ),
              data: (incidents) {
                var filteredIncidents = widget.category == null
                    ? incidents
                    : incidents
                          .where(
                            (incident) =>
                                incident.category == widget.category,
                          )
                          .toList();

                if (isApprovedStaff && _statusFilter != 'all') {
                  filteredIncidents = filteredIncidents
                      .where((incident) => incident.status == _statusFilter)
                      .toList();
                }

                final content = filteredIncidents.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(18),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index.isOdd) {
                                return const SizedBox(height: 14);
                              }

                              final incident =
                                  filteredIncidents[index ~/ 2];
                              return IncidentCard(
                                incident: incident,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => IncidentDetailsScreen(
                                        incidentId: incident.id,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: filteredIncidents.length * 2 - 1,
                          ),
                        ),
                      );

                return _buildScrollablePage(
                  context,
                  isApprovedStaff: isApprovedStaff,
                  content: content,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollablePage(
    BuildContext context, {
    required bool isApprovedStaff,
    required Widget content,
  }) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        if (isApprovedStaff)
          SliverToBoxAdapter(child: _buildStatusFilter()),
        content,
      ],
    );
  }
  Widget _buildStatusFilter() {
    const filters = <String, String>{
      'all': 'All',
      'pending': 'Pending',
      'reviewed': 'Reviewed',
      'in_progress': 'In Progress',
      'resolved': 'Resolved',
    };

    return SizedBox(
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: filters.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: _statusFilter == entry.key,
              selectedColor: primaryColor.withValues(alpha: 0.14),
              onSelected: (_) {
                setState(() => _statusFilter = entry.key);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.category == null
                ? 'Reports around campus'
                : '${widget.category} Reports',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.category == null
                ? 'Explore reported issues, check their progress, '
                      'and join the conversation.'
                : 'Explore all reported ${widget.category} issues around campus.',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (widget.category != null) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go('/incidents'),
                icon: const Icon(Icons.clear, size: 17),
                label: const Text('Show all incidents'),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 65, color: Colors.black26),
            const SizedBox(height: 16),
            Text(
              widget.category == null
                  ? 'No incidents reported yet'
                  : 'No ${widget.category} reports yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: darkColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.category == null
                  ? 'New campus reports will appear here.'
                  : 'Reports in this category will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 45),
            const SizedBox(height: 12),
            const Text(
              'Unable to load incidents',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class IncidentCard extends ConsumerWidget {
  const IncidentCard({super.key, required this.incident, required this.onTap});

  final Incident incident;
  final VoidCallback onTap;

  static const Color primaryColor = Color(0xFF1769AA);
  static const Color darkColor = Color(0xFF172B4D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownership = ref.watch(isMyIncidentProvider(incident.id));
    final isMyIncident = ownership.when(
      data: (value) => value,
      error: (error, stackTrace) => false,
      loading: () => false,
    );
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6EBF1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _categoryIcon(incident.category),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      incident.category,
                      style: const TextStyle(
                        color: darkColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusBadge(status: incident.status),
                ],
              ),

              // Show the incident photo when one was uploaded.
              if (incident.photoUrl != null &&
                  incident.photoUrl!.isNotEmpty) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    incident.photoUrl!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100,
                        width: double.infinity,
                        color: const Color(0xFFF0F3F7),
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.black38,
                          size: 35,
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 14),
              Text(
                incident.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.black45,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      incident.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.black45,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _formatDate(incident.createdAt),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (isMyIncident)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'My report',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 13,
                    color: Colors.black38,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryIcon(String category) {
    IconData icon;

    switch (category) {
      case 'Water Shortage':
        icon = Icons.water_drop_outlined;
        break;
      case 'Electricity Outage':
        icon = Icons.electrical_services_outlined;
        break;
      case 'Broken Furniture':
        icon = Icons.chair_outlined;
        break;
      case 'Damaged Facilities':
        icon = Icons.domain_outlined;
        break;
      case 'Sanitation':
        icon = Icons.cleaning_services_outlined;
        break;
      case 'Safety Concern':
        icon = Icons.health_and_safety_outlined;
        break;
      default:
        icon = Icons.report_problem_outlined;
    }

    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: primaryColor),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    Color color;
    String label;

    switch (normalized) {
      case 'reviewed':
        color = Colors.blue;
        label = 'Reviewed';
        break;
      case 'in_progress':
        color = Colors.orange;
        label = 'In Progress';
        break;
      case 'resolved':
        color = Colors.green;
        label = 'Resolved';
        break;
      default:
        color = Colors.redAccent;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
