import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/incident_validation.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_comment.dart';
import '../providers/incident_providers.dart';

class IncidentDetailsScreen extends ConsumerStatefulWidget {
  const IncidentDetailsScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  ConsumerState<IncidentDetailsScreen> createState() =>
      _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends ConsumerState<IncidentDetailsScreen> {
  final _commentController = TextEditingController();

  late Future<AppUser?> _userFuture;
  bool _isPosting = false;
  bool _isUpdatingStatus = false;
  String? _selectedStatus;

  static const Color primaryColor = Color(0xFF1769AA);
  static const Color darkColor = Color(0xFF172B4D);
  static const Color backgroundColor = Color(0xFFF7F9FC);

  @override
  void initState() {
    super.initState();
    _userFuture = ref.read(authControllerProvider.notifier).getCurrentUser();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final message = _commentController.text.trim();

    final commentError = IncidentValidation.validateComment(message);
    if (commentError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(commentError)),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      await ref
          .read(incidentRepositoryProvider)
          .addComment(incidentId: widget.incidentId, message: message);

      if (!mounted) return;

      _commentController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to post comment: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  Future<void> _updateStatus(Incident incident) async {
    final status = _selectedStatus;
    if (status == null ||
        !IncidentValidation.canTransitionStatus(incident.status, status) ||
        _isUpdatingStatus) {
      return;
    }

    setState(() => _isUpdatingStatus = true);

    try {
      await ref
          .read(incidentRepositoryProvider)
          .updateIncidentStatus(incidentId: incident.id, status: status);

      if (!mounted) return;

      setState(() => _selectedStatus = status);
      ref.invalidate(incidentDetailsProvider(widget.incidentId));
      ref.invalidate(incidentsStreamProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Incident status updated successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Unable to update incident status: $error'),
            backgroundColor: AppColors.error,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidentAsync = ref.watch(incidentDetailsProvider(widget.incidentId));

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Incident Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkColor,
        elevation: 0,
      ),
      body: incidentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Unable to load incident: $error'),
          ),
        ),
        data: (incident) {
          if (incident == null) {
            return const Center(
              child: Text('This incident could not be found.'),
            );
          }

          return FutureBuilder<AppUser?>(
            future: _userFuture,
            builder: (context, userSnapshot) {
              final user = userSnapshot.data;
              final isApprovedStaff = user?.canUseStaffFeatures ?? false;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIncidentInformation(
                            incident,
                            isApprovedStaff: isApprovedStaff,
                          ),
                          if (isApprovedStaff) ...[
                            const SizedBox(height: 18),
                            _buildStatusManagement(incident),
                          ],
                          const SizedBox(height: 28),
                          _buildCommentsSection(),
                        ],
                      ),
                    ),
                  ),
                  _buildCommentInput(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildIncidentInformation(
    Incident incident, {
    required bool isApprovedStaff,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  incident.category,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),
              ),
              _buildStatusBadge(incident.status),
            ],
          ),
          if (incident.photoUrl != null && incident.photoUrl!.isNotEmpty) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                incident.photoUrl!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;

                  return Container(
                    height: 220,
                    color: const Color(0xFFEAF3FC),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    width: double.infinity,
                    color: const Color(0xFFEAF3FC),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 38,
                          color: Colors.black38,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Unable to load incident photo',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),
          _buildInformationRow(
            Icons.location_on_outlined,
            'Location',
            incident.location,
          ),
          const SizedBox(height: 16),
          _buildInformationRow(
            Icons.calendar_today_outlined,
            'Date submitted',
            _formatDateTime(incident.createdAt),
          ),
          const SizedBox(height: 16),
          _buildReporterInformation(isApprovedStaff),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 14),
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            incident.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReporterInformation(bool isApprovedStaff) {
    if (!isApprovedStaff) {
      return _buildInformationRow(
        Icons.person_outline,
        'Reported by',
        'Campus member',
      );
    }

    final reporterAsync = ref.watch(
      incidentReporterProvider(widget.incidentId),
    );

    return reporterAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (error, stackTrace) => _buildInformationRow(
        Icons.person_outline,
        'Reported by',
        'Reporter details unavailable',
      ),
      data: (reporter) {
        if (reporter == null) {
          return _buildInformationRow(
            Icons.person_outline,
            'Reported by',
            'Reporter details unavailable',
          );
        }

        final name = reporter.name.trim().isEmpty
            ? 'Campus member'
            : reporter.name.trim();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.10),
              backgroundImage:
                  reporter.photoUrl != null && reporter.photoUrl!.isNotEmpty
                  ? NetworkImage(reporter.photoUrl!)
                  : null,
              child: reporter.photoUrl == null || reporter.photoUrl!.isEmpty
                  ? const Icon(Icons.person_outline, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reported by',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      color: darkColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (reporter.email.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      reporter.email.trim(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusManagement(Incident incident) {
    const statuses = <String, String>{
      'pending': 'Pending',
      'reviewed': 'Reviewed',
      'in_progress': 'In Progress',
      'resolved': 'Resolved',
    };
    final currentStatus = statuses.containsKey(incident.status)
        ? incident.status
        : 'pending';
    final selectedStatus = _selectedStatus ?? currentStatus;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Update status',
            style: TextStyle(
              color: darkColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Incident status',
              border: OutlineInputBorder(),
            ),
            items: statuses.entries
                .map(
                  (entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: _isUpdatingStatus
                ? null
                : (status) {
                    setState(() => _selectedStatus = status);
                  },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUpdatingStatus || selectedStatus == incident.status
                  ? null
                  : () => _updateStatus(incident),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isUpdatingStatus
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : const Text('Update Status'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryColor, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: darkColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final normalized = status.toLowerCase();

    final Color color;
    final String label;

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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    final commentsAsync = ref.watch(
      incidentCommentsProvider(widget.incidentId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Discussion',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: darkColor,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'See what other students and campus staff are saying.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 16),
        commentsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Unable to load comments: $error'),
          ),
          data: (comments) {
            if (comments.isEmpty) {
              return _buildEmptyComments();
            }

            return Column(children: comments.map(_buildCommentCard).toList());
          },
        ),
      ],
    );
  }

  Widget _buildCommentCard(IncidentComment comment) {
    final hasVisibleName =
        comment.authorName != null && comment.authorName!.trim().isNotEmpty;

    final displayName = hasVisibleName
        ? comment.authorName!.trim()
        : 'Campus member';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFFEAF3FC),
                child: Icon(
                  hasVisibleName
                      ? Icons.verified_user_outlined
                      : Icons.person_outline,
                  size: 19,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      _formatDateTime(comment.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            comment.message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyComments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.chat_bubble_outline, size: 35, color: Colors.black26),
          SizedBox(height: 10),
          Text(
            'No comments yet',
            style: TextStyle(fontWeight: FontWeight.w600, color: darkColor),
          ),
          SizedBox(height: 5),
          Text(
            'Be the first to share an update.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  filled: true,
                  fillColor: backgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 46,
              width: 46,
              child: ElevatedButton(
                onPressed: _isPosting ? null : _postComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
                child: _isPosting
                    ? const SizedBox(
                        height: 19,
                        width: 19,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${_formatDate(date)} at $hour:$minute';
  }
}
