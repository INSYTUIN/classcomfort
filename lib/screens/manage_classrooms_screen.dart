import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/data_service.dart';

/// Admin screen to add and remove classrooms.
class ManageClassroomsScreen extends StatelessWidget {
  const ManageClassroomsScreen({super.key});

  Future<void> _confirmRemove(BuildContext context, Classroom room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove classroom?'),
        content: Text(
          '${room.fullName} and all of its ratings and feedback will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) dataService.removeClassroom(room.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Classrooms')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add classroom'),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const _AddClassroomDialog(),
        ),
      ),
      body: ListenableBuilder(
        listenable: dataService,
        builder: (context, _) {
          final rooms = dataService.classrooms;
          if (rooms.isEmpty) {
            return const Center(child: Text('No classrooms yet. Tap "Add classroom".'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            children: [
              for (final room in rooms)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.meeting_room),
                    title: Text(room.fullName),
                    subtitle: Text(
                      'Capacity: ${room.capacity} · '
                      '${dataService.ratingsFor(room.id).length} evaluation(s)',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Remove',
                      onPressed: () => _confirmRemove(context, room),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AddClassroomDialog extends StatefulWidget {
  const _AddClassroomDialog();

  @override
  State<_AddClassroomDialog> createState() => _AddClassroomDialogState();
}

class _AddClassroomDialogState extends State<_AddClassroomDialog> {
  final _buildingController = TextEditingController();
  final _roomController = TextEditingController();
  final _capacityController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _buildingController.dispose();
    _roomController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _save() {
    final building = _buildingController.text.trim();
    final room = _roomController.text.trim();
    final capacity = int.tryParse(_capacityController.text.trim());

    if (building.isEmpty || room.isEmpty || capacity == null || capacity <= 0) {
      setState(() => _error = 'Fill in every field. Capacity must be a number.');
      return;
    }

    final added = dataService.addClassroom(
      building: building,
      roomNumber: room,
      capacity: capacity,
    );
    if (!added) {
      setState(() => _error = 'That classroom already exists.');
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add classroom'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _buildingController,
              decoration: const InputDecoration(labelText: 'Building'),
            ),
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(labelText: 'Room number'),
            ),
            TextField(
              controller: _capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacity'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Add')),
      ],
    );
  }
}
