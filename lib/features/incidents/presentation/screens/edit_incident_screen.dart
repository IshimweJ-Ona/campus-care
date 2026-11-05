
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/incident.dart';
import '../providers/incident_providers.dart';

class EditIncidentScreen extends ConsumerStatefulWidget {
  const EditIncidentScreen({
    super.key,
    required this.incidentId,
  });

  final String incidentId;

  @override
  ConsumerState<EditIncidentScreen> createState() =>
      _EditIncidentScreenState();
}

class _EditIncidentScreenState
    extends ConsumerState<EditIncidentScreen> {
  static const Color primaryColor = Color(0xFF1769AA);
  static const Color darkColor = Color(0xFF172B4D);
  static const Color backgroundColor = Color(0xFFF7F9FC);

  String? _selectedStatus;
  bool _isUpdating = false;

  final List<Map<String, dynamic>> _statuses = [
    {
      'value': 'pending',
      'label': 'Pending',
      'description':
          'The issue has been reported and is awaiting attention.',
      'icon': Icons.hourglass_empty,
      'color': Colors.orange,
    },
    {
      'value': 'in_progress',
      'label': 'In Progress',
      'description':
          'Campus staff are currently working on this issue.',
      'icon': Icons.autorenew,
      'color': Colors.blue,
    },
    {
      'value': 'resolved',
      'label': 'Resolved',
      'description': 'The reported issue has been fixed.',
      'icon': Icons.check_circle_outline,
      'color': Colors.green,
    },
  ];

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) return;

    setState(() => _isUpdating = true);

    try {
      await ref.read(incidentRepositoryProvider).updateIncidentStatus(
            incidentId: widget.incidentId,
            status: _selectedStatus!,
          );

      if (!mounted) return;

      ref.invalidate(incidentDetailsProvider(widget.incidentId));
      ref.invalidate(incidentsStreamProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incident status updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      context.go('/home');
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update status: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidentAsync = ref.watch(
      incidentDetailsProvider(widget.incidentId),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Update Incident',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkColor,
        elevation: 0,
      ),
      body: incidentAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Unable to load incident: $error'),
          ),
        ),
        data: (incident) {
          if (incident == null) {
            return const Center(
              child: Text('Incident not found.'),
            );
          }

          return _buildContent(incident);
        },
      ),
    );
  }

  Widget _buildContent(Incident incident) {
    final currentStatus = _statuses.firstWhere(
      (status) => status['value'] == incident.status,
      orElse: () => _statuses.first,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIncidentCard(incident, currentStatus),
          const SizedBox(height: 28),
          const Text(
            'Update incident status',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the current progress of this incident.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 18),
          ..._statuses.map(_buildStatusOption),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isUpdating ||
                      _selectedStatus == null ||
                      _selectedStatus == incident.status
                  ? null
                  : _updateStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUpdating
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Only authorized campus staff can update incident status.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black45,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(
    Incident incident,
    Map<String, dynamic> currentStatus,
  ) {
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
          Text(
            incident.category,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),
          if (incident.photoUrl != null &&
              incident.photoUrl!.isNotEmpty) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                incident.photoUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;

                  return Container(
                    height: 200,
                    color: const Color(0xFFEAF3FC),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: const Color(0xFFEAF3FC),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 35,
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
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: primaryColor,
                size: 19,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  incident.location,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Description',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: darkColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            incident.description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Current status',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 7),
          _buildCurrentStatusBadge(currentStatus),
        ],
      ),
    );
  }

  Widget _buildCurrentStatusBadge(Map<String, dynamic> status) {
    final color = status['color'] as Color;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status['label'] as String,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusOption(Map<String, dynamic> status) {
    final value = status['value'] as String;
    final label = status['label'] as String;
    final description = status['description'] as String;
    final icon = status['icon'] as IconData;
    final color = status['color'] as Color;

    final isSelected = _selectedStatus == value;

    return InkWell(
      onTap: _isUpdating
          ? null
          : () {
              setState(() => _selectedStatus = value);
            },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : const Color(0xFFE5EAF0),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? primaryColor : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}
