import '/flutter_flow/flutter_flow_util.dart';
import 'location_beacon_modal_widget.dart' show LocationBeaconModalWidget;
import 'package:flutter/material.dart';

class LocationBeaconModalModel extends FlutterFlowModel<LocationBeaconModalWidget> {
  /// State fields for stateful widgets in this modal.

  final formKey = GlobalKey<FormState>();

  /// Location text input
  FocusNode? locationFocusNode;
  TextEditingController? locationTextController;

  /// Duration dropdown: Until 2 PM / Until 5 PM / All day / Custom
  String? selectedDuration = 'Until 2 PM';

  /// Auto-post toggle
  bool autoPost = false;

  /// Loading state during submission
  bool isSubmitting = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    locationFocusNode?.dispose();
    locationTextController?.dispose();
  }
}
