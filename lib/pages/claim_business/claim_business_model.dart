import '/flutter_flow/flutter_flow_util.dart';
import 'claim_business_widget.dart' show ClaimBusinessWidget;
import 'package:flutter/material.dart';

class ClaimBusinessModel extends FlutterFlowModel<ClaimBusinessWidget> {
  /// State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();

  // State field(s) for ClaimantName widget.
  FocusNode? claimantNameFocusNode;
  TextEditingController? claimantNameTextController;
  String? Function(BuildContext, String?)? claimantNameTextControllerValidator;

  // State field(s) for ClaimantRole widget.
  FocusNode? claimantRoleFocusNode;
  TextEditingController? claimantRoleTextController;

  // State field(s) for ContactEmail widget.
  FocusNode? contactEmailFocusNode;
  TextEditingController? contactEmailTextController;
  String? Function(BuildContext, String?)? contactEmailTextControllerValidator;

  // State field(s) for ContactPhone widget.
  FocusNode? contactPhoneFocusNode;
  TextEditingController? contactPhoneTextController;

  // State field(s) for ProofLink widget.
  FocusNode? proofLinkFocusNode;
  TextEditingController? proofLinkTextController;

  /// Self-declared attributes. Default to false so an owner has to actively
  /// assert them - we never pre-tick a claim on the owner's behalf.
  bool declaredBlackOwned = false;
  bool declaredVeteran = false;

  /// Required ownership attestation. Submit stays disabled until this is true.
  bool attested = false;

  /// Guards against double-submits while the write is in flight.
  bool isSubmitting = false;

  @override
  void initState(BuildContext context) {
    claimantNameTextControllerValidator = (context, val) {
      if (val == null || val.trim().isEmpty) {
        return 'Please enter your name.';
      }
      return null;
    };
    contactEmailTextControllerValidator = (context, val) {
      final value = val?.trim() ?? '';
      if (value.isEmpty) {
        return 'Please enter an email we can reach you at.';
      }
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
        return 'That doesn\'t look like a valid email address.';
      }
      return null;
    };
  }

  @override
  void dispose() {
    claimantNameFocusNode?.dispose();
    claimantNameTextController?.dispose();
    claimantRoleFocusNode?.dispose();
    claimantRoleTextController?.dispose();
    contactEmailFocusNode?.dispose();
    contactEmailTextController?.dispose();
    contactPhoneFocusNode?.dispose();
    contactPhoneTextController?.dispose();
    proofLinkFocusNode?.dispose();
    proofLinkTextController?.dispose();
  }
}
