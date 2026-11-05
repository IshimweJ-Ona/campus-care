import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/incident.dart';
import '../providers/incident_providers.dart';
import 'incident_details_screen.dart';

class MyIncidentsScreen extends ConsumerWidget {
  const MyIncidentsScreen({
    super.key,
    this.category,
  });

  final String? category;

  static const Color primaryColor = Color(0xFF1769AA);
  static const Color darkColor = Color(0xFF172B4D);
  static const Color backgroundColor = Color(0xFFF7F9FC);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(incidentsStreamProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          category == null ? 'Campus Incidents' : category!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: incidentsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => _buildError(error.toString()),
              data: (incidents) {
                // Students and staff can browse all campus incidents.
                // The category filter only changes which incidents are shown.
                final filteredIncidents = category == null
                    ? incidents
                    : incidents
                        .where((incident) =>
                            incident.category == category)
                        .toList();

                if (filteredIncidents.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(incidentsStreamProvider);
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(18),
                    itemCount: filteredIncidents.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final incident = filteredIncidents[index];

                      return _IncidentCard(
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
                  ),
                );
              },
            ),
          ),
        ],
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
            category == null
                ? 'Reports around campus'
                : '$category Reports',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category == null
                ? 'Explore reported issues, check their progress, '
                    'and join the conversation.'
                : 'Explore all reported $category issues around campus.',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (category != null) ...[
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        const Icon(
          Icons.inbox_outlined,
          size: 65,
          color: Colors.black26,
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            category == null
                ? 'No incidents reported yet'
                : 'No $category reports yet',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: darkColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            category == null
                ? 'New campus reports will appear here.'
                : 'Reports in this category will appear here.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 45,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load incidents',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
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

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    required this.incident,
    required this.onTap,
  });

  final Incident incident;
  final VoidCallback onTap;

  static const Color primaryColor = Color(0xFF1769AA);
  static const Color darkColor = Color(0xFF172B4D);

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Only checks the signed-in user's own private incident reference.
    // It does not read the private reporter identity collection.
    final Future<DocumentSnapshot<Map<String, dynamic>>>? myIncidentFuture =
        currentUserId == null
            ? null
            : FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .collection('reported_incidents')
                .doc(incident.id)
                .get();

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: myIncidentFuture,
      builder: (context, snapshot) {
        final isMyIncident = snapshot.data?.exists == true;

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
                border: Border.all(
                  color: const Color(0xFFE6EBF1),
                ),
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
      },
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
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
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