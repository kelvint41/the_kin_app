import '/components/tracking_step_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'delivery_status_widget.dart' show DeliveryStatusWidget;
import 'package:flutter/material.dart';

class DeliveryStatusModel extends FlutterFlowModel<DeliveryStatusWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for TrackingStep.
  late TrackingStepModel trackingStepModel1;
  // Model for TrackingStep.
  late TrackingStepModel trackingStepModel2;

  @override
  void initState(BuildContext context) {
    trackingStepModel1 = createModel(context, () => TrackingStepModel());
    trackingStepModel2 = createModel(context, () => TrackingStepModel());
  }

  @override
  void dispose() {
    trackingStepModel1.dispose();
    trackingStepModel2.dispose();
  }
}
