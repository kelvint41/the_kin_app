import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/kin_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'referral_share_model.dart';
export 'referral_share_model.dart';

/// Drop-in "Invite friends" card for a referral campaign.
///
/// On mount it fetches (minting if needed) the current user's personal
/// referral code via [KinServices.getOrCreateReferralCode], then offers
/// Copy + Share actions. Share reuses the app's existing
/// [KinServices.shareApp] flow (native share sheet + a `share_app`
/// engagement event), so the referral invite rides the same rail as the
/// "Promote" button in Owner Profile - it just carries the code and a
/// deep link.
///
/// The referrer is only ever resolved server-side from the code at
/// redemption time (see redeemReferralCode), so nothing sensitive is
/// trusted from this widget.
class ReferralShareWidget extends StatefulWidget {
  const ReferralShareWidget({
    super.key,
    required this.campaignRef,
    this.campaignTitle,
    this.inviteLinkBase = 'https://thekin.app/i',
  });

  final DocumentReference campaignRef;
  final String? campaignTitle;

  /// Base for the invite deep link; the code is appended as `/<code>`.
  final String inviteLinkBase;

  @override
  State<ReferralShareWidget> createState() => _ReferralShareWidgetState();
}

class _ReferralShareWidgetState extends State<ReferralShareWidget> {
  late ReferralShareModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReferralShareModel());
    _loadCode();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _loadCode() async {
    safeSetState(() {
      _model.isLoading = true;
      _model.errorMessage = null;
    });
    final result =
        await KinServices.getOrCreateReferralCode(campaignRef: widget.campaignRef);
    if (!mounted) return;
    safeSetState(() {
      _model.isLoading = false;
      if (result.isSuccess) {
        _model.code = result.data;
      } else {
        _model.errorMessage = result.error;
      }
    });
  }

  String get _inviteLink => '${widget.inviteLinkBase}/${_model.code}';

  String get _inviteText =>
      "I'm using The KIN App to find and support Black-owned businesses. "
      'Join me — use code ${_model.code} and we both get a KIN boost 👉 $_inviteLink';

  Future<void> _copyCode() async {
    if (_model.code == null) return;
    await Clipboard.setData(ClipboardData(text: _model.code!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied')),
    );
  }

  Future<void> _share() async {
    if (_model.code == null) return;
    await KinServices.shareApp(
      text: _inviteText,
      sharePositionOrigin: getWidgetBoundingBox(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group_add_rounded, color: theme.primary, size: 24.0),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    widget.campaignTitle ?? 'Bring a friend, grow the community',
                    style: theme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6.0),
            Text(
              'Share your code. When a friend joins, you both move up the Kindex.',
              style: theme.bodySmall.override(
                fontFamily: theme.bodySmall.fontFamily,
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(height: 16.0),
            _buildBody(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(FlutterFlowTheme theme) {
    if (_model.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: SizedBox(
          height: 24.0,
          width: 24.0,
          child: CircularProgressIndicator(strokeWidth: 2.0),
        ),
      );
    }
    if (_model.errorMessage != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              _model.errorMessage!,
              style: theme.bodySmall.override(
                fontFamily: theme.bodySmall.fontFamily,
                color: theme.error,
              ),
            ),
          ),
          TextButton(onPressed: _loadCode, child: const Text('Retry')),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Code chip + copy
        InkWell(
          onTap: _copyCode,
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.primaryBackground,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: theme.alternate, width: 1.0),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _model.code ?? '—',
                  style: theme.headlineSmall.override(
                    fontFamily: theme.headlineSmall.fontFamily,
                    letterSpacing: 4.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.copy_rounded, color: theme.secondaryText, size: 20.0),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14.0),
        FFButtonWidget(
          onPressed: _share,
          text: 'Share invite',
          icon: const Icon(Icons.ios_share_rounded, size: 20.0),
          options: FFButtonOptions(
            width: double.infinity,
            height: 48.0,
            color: theme.primary,
            textStyle: theme.titleSmall.override(
              fontFamily: theme.titleSmall.fontFamily,
              color: Colors.white,
            ),
            elevation: 0.0,
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ],
    );
  }
}
