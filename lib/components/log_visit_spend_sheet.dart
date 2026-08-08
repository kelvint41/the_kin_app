import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/local/community_impact_local_store.dart';

/// V1 Community Impact & Spend Tracker - "Log a Visit / Spend" modal.
///
/// Writes through [CommunityImpactLocalStore], which is Firestore-backed
/// (`spend_logs`, owner-only) with a SharedPreferences cache for instant
/// rendering - see that store's doc comment for the full sync design.
///
/// The business field is free text with autosuggest against the existing
/// directory (same "fetch once, filter client-side" pattern
/// KinQuestSearchWidget already uses) rather than a hard picker, so a
/// shopper can log a spend even at a business not yet in KIN's directory.
class LogVisitSpendSheet extends StatefulWidget {
  const LogVisitSpendSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const LogVisitSpendSheet(),
      );

  @override
  State<LogVisitSpendSheet> createState() => _LogVisitSpendSheetState();
}

class _LogVisitSpendSheetState extends State<LogVisitSpendSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  BusinessesRecord? _matchedBusiness;
  bool _saving = false;

  late final Future<List<BusinessesRecord>> _allBusinessesFuture;

  @override
  void initState() {
    super.initState();
    _allBusinessesFuture = queryBusinessesRecordOnce();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add a business name to log this visit.')),
      );
      return;
    }
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter a valid amount (0 is fine for a '
                'no-spend check-in).')),
      );
      return;
    }
    setState(() => _saving = true);
    await CommunityImpactLocalStore.instance.addEntry(
      businessName: name,
      businessId: _matchedBusiness?.reference.id ?? '',
      // Denormalized off the matched directory listing, if any - powers
      // the Executive Dashboard's by-city/by-category breakdown. Empty
      // for a free-text entry with no match, which still counts toward
      // the community-wide total but not either breakdown.
      businessCity: _matchedBusiness?.city ?? '',
      businessCategory: _matchedBusiness?.category ?? '',
      amount: amount,
      date: _date,
      note: _noteController.text,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Container(
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(theme.designToken.radius.lg),
              topRight: Radius.circular(theme.designToken.radius.lg),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40.0,
                      height: 4.0,
                      margin: EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: theme.alternate,
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                  Text(
                    'Log a Visit / Spend',
                    style: theme.headlineSmall.override(
                      font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold),
                      color: theme.primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    'Track what you spend at Black-owned businesses - it '
                    'grows your Community Impact totals and streak.',
                    style: theme.bodySmall.override(
                      color: theme.secondaryText,
                      lineHeight: 1.4,
                    ),
                  ),
                  SizedBox(height: 20.0),
                  _fieldLabel(theme, 'Business'),
                  TextFormField(
                    controller: _nameController,
                    onChanged: (_) => setState(() => _matchedBusiness = null),
                    decoration:
                        _inputDecoration(theme, hint: 'e.g. Sterling & Associates'),
                    style: theme.bodyMedium.override(color: theme.primaryText),
                  ),
                  if (_matchedBusiness == null &&
                      _nameController.text.trim().length >= 2)
                    _suggestions(theme),
                  SizedBox(height: 16.0),
                  _fieldLabel(theme, 'Amount spent'),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration(theme,
                        hint: '0.00', prefixText: r'$ '),
                    style: theme.bodyMedium.override(color: theme.primaryText),
                  ),
                  SizedBox(height: 16.0),
                  _fieldLabel(theme, 'Date'),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        color: theme.secondaryBackground,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: theme.alternate, width: 1.0),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 16.0, color: theme.secondaryText),
                          SizedBox(width: 8.0),
                          Text(
                            DateFormat.yMMMd().format(_date),
                            style: theme.bodyMedium
                                .override(color: theme.primaryText),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  _fieldLabel(theme, 'Note (optional)'),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration:
                        _inputDecoration(theme, hint: 'What did you get?'),
                    style: theme.bodyMedium.override(color: theme.primaryText),
                  ),
                  SizedBox(height: 24.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: _saving
                          ? SizedBox(
                              width: 20.0,
                              height: 20.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              'Log It',
                              style: theme.titleMedium.override(
                                font: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold),
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(FlutterFlowTheme theme, String label) => Padding(
        padding: EdgeInsets.only(bottom: 6.0),
        child: Text(
          label,
          style: theme.labelMedium.override(color: theme.secondaryText),
        ),
      );

  Widget _suggestions(FlutterFlowTheme theme) {
    return FutureBuilder<List<BusinessesRecord>>(
      future: _allBusinessesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();
        final q = _nameController.text.trim().toLowerCase();
        final matches = snapshot.data!
            .where((b) => b.businessName.toLowerCase().contains(q))
            .take(5)
            .toList();
        if (matches.isEmpty) return SizedBox.shrink();
        return Container(
          margin: EdgeInsets.only(top: 6.0),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: theme.alternate, width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: matches
                .map((b) => ListTile(
                      dense: true,
                      title: Text(
                        b.businessName,
                        style:
                            theme.bodyMedium.override(color: theme.primaryText),
                      ),
                      subtitle: b.category.isEmpty
                          ? null
                          : Text(
                              b.category,
                              style: theme.labelSmall
                                  .override(color: theme.secondaryText),
                            ),
                      onTap: () => setState(() {
                        _matchedBusiness = b;
                        _nameController.text = b.businessName;
                      }),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(
    FlutterFlowTheme theme, {
    required String hint,
    String? prefixText,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: theme.bodyMedium.override(color: theme.secondaryText),
        prefixText: prefixText,
        prefixStyle: theme.bodyMedium.override(color: theme.primaryText),
        filled: true,
        fillColor: theme.secondaryBackground,
        isDense: true,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.alternate, width: 1.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.secondary, width: 1.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
      );
}
