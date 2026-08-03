import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/components/image_upload_button.dart';
import '/services/community_events_service.dart';

class EventCreatePage extends StatefulWidget {
  final String? businessId;

  const EventCreatePage({super.key, this.businessId});

  @override
  State<EventCreatePage> createState() => _EventCreatePageState();
}

class _EventCreatePageState extends State<EventCreatePage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  DateTime? selectedDate;
  String eventType = 'backpack_drive';
  bool isCreating = false;
  String? _imageUrl;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final businessId = widget.businessId ?? currentUserDocument?.ownedBusiness?.id;
    if (businessId == null) return;
    setState(() => isCreating = true);
    try {
      final eventId = await CommunityEventsService.createEvent(
        businessRef: businessId,
        title: titleController.text,
        description: descriptionController.text,
        eventType: eventType,
        location: locationController.text,
        eventDate: selectedDate ?? DateTime.now().add(const Duration(days: 7)),
        businessLocation: null,
        imageUrl: _imageUrl,
      );
      await CommunityEventsService.publishEvent(eventId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.primary,
          automaticallyImplyLeading: true,
          title: Text(
            'Create Event',
            style: theme.headlineMedium.override(
              font: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
              ),
              color: theme.info
            ),
          ),
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Event Title',
                    labelStyle: theme.labelSmall,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.alternate),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.primary, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: theme.labelSmall,
                    alignLabelWithHint: true,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.alternate),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.primary, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    labelStyle: theme.labelSmall,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.alternate),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.primary, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 16.0),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Event Date',
                      labelStyle: theme.labelSmall,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.alternate),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      selectedDate == null
                          ? 'Select a date'
                          : '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}',
                      style: theme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Text('Flyer (optional)', style: theme.labelSmall),
                const SizedBox(height: 8.0),
                if (_imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      _imageUrl!,
                      height: 160.0,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                ],
                Row(
                  children: [
                    ImageUploadButton(
                      label: _imageUrl == null ? 'Add a flyer' : 'Replace flyer',
                      icon: Icons.image_outlined,
                      onUploaded: (url) async {
                        setState(() => _imageUrl = url);
                      },
                    ),
                    if (_imageUrl != null) ...[
                      const SizedBox(width: 12.0),
                      TextButton(
                        onPressed: () => setState(() => _imageUrl = null),
                        child: Text('Remove',
                            style: theme.labelMedium
                                .override(color: theme.error)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  value: eventType,
                  decoration: InputDecoration(
                    labelText: 'Event Type',
                    labelStyle: theme.labelSmall,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.alternate),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.primary, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  items: CommunityEventsService.eventTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child:
                                Text(CommunityEventsService.eventTypeLabel(type)),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => eventType = value ?? 'backpack_drive'),
                ),
                const SizedBox(height: 32.0),
                FFButtonWidget(
                  onPressed: isCreating ? null : _submit,
                  text: isCreating ? 'Creating...' : 'Create Event',
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 56.0,
                    color: theme.primary,
                    textStyle: theme.titleSmall.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                      ),
                      color: theme.info
                    ),
                    elevation: 0.0,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
