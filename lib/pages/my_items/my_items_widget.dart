import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/add_edit_item_sheet.dart';
import '/components/business_image_widget.dart';
import '/components/main_menu_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'my_items_model.dart';
export 'my_items_model.dart';

/// Owner-side Marketplace item management: list, add, edit, delete. Self-guards
/// on ownedBusiness the same way OwnerProfileWidget does - no separate auth
/// check needed beyond the route's requireAuth.
class MyItemsWidget extends StatefulWidget {
  const MyItemsWidget({super.key});

  static String routeName = 'MyItems';
  static String routePath = '/myItems';

  @override
  State<MyItemsWidget> createState() => _MyItemsWidgetState();
}

class _MyItemsWidgetState extends State<MyItemsWidget> {
  late MyItemsModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MyItemsModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _openSheet(BuildContext context, DocumentReference businessRef,
      {BusinessItemsRecord? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AddEditItemSheet(businessRef: businessRef, existing: existing),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, BusinessItemsRecord item) async {
    final theme = FlutterFlowTheme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${item.title}?'),
        content: Text(
            'This removes it from the Marketplace for everyone. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Remove', style: TextStyle(color: theme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await item.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final ownedBusiness = currentUserDocument?.ownedBusiness;

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        automaticallyImplyLeading: false,
        title: Text(
          'My items',
          style: theme.headlineMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            color: theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0.0,
        actions: [Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: MainMenuButton(),
        )],
      ),
      body: SafeArea(
        top: true,
        child: ownedBusiness == null
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'Set up your business first to add items to the Marketplace.',
                    textAlign: TextAlign.center,
                    style: theme.bodyMedium
                        .override(color: theme.secondaryText),
                  ),
                ),
              )
            : StreamBuilder<List<BusinessItemsRecord>>(
                stream: queryBusinessItemsRecord(
                  queryBuilder: (q) =>
                      q.where('business_ref', isEqualTo: ownedBusiness),
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(theme.primary),
                      ),
                    );
                  }
                  final items = snapshot.data!;
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: FFButtonWidget(
                          onPressed: () =>
                              _openSheet(context, ownedBusiness),
                          text: 'Add item',
                          icon: Icon(Icons.add_rounded, size: 18.0),
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 48.0,
                            color: theme.primary,
                            textStyle: theme.titleSmall
                                .override(color: Colors.white),
                            elevation: 0.0,
                            borderRadius: BorderRadius.circular(
                                theme.designToken.radius.sm),
                          ),
                        ),
                      ),
                      if (items.isEmpty)
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'Nothing here yet. Add an item to show it '
                                'in the Marketplace.',
                                textAlign: TextAlign.center,
                                style: theme.bodyMedium
                                    .override(color: theme.secondaryText),
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 16.0, 16.0),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: 8.0),
                            itemBuilder: (context, index) =>
                                _itemRow(context, items[index], ownedBusiness),
                          ),
                        ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _itemRow(BuildContext context, BusinessItemsRecord item,
      DocumentReference businessRef) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: BusinessImage(
              imageUrl: item.photoUrl,
              width: 48.0,
              height: 48.0,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold),
                    fontWeight: FontWeight.bold,
                    color: theme.primaryText,
                    letterSpacing: 0.0,
                  ),
                ),
                Text(
                  item.priceDisplay,
                  style: theme.labelSmall
                      .override(color: theme.secondaryText, letterSpacing: 0.0),
                ),
              ],
            ),
          ),
          Switch(
            value: item.isAvailable,
            onChanged: (value) =>
                item.reference.update({'is_available': value}),
            activeColor: theme.primary,
          ),
          FlutterFlowIconButton(
            borderRadius: 8.0,
            buttonSize: 36.0,
            fillColor: Colors.transparent,
            icon: Icon(Icons.edit_rounded, color: theme.secondaryText, size: 18.0),
            onPressed: () =>
                _openSheet(context, businessRef, existing: item),
          ),
          FlutterFlowIconButton(
            borderRadius: 8.0,
            buttonSize: 36.0,
            fillColor: Colors.transparent,
            icon: Icon(Icons.delete_outline_rounded,
                color: theme.error, size: 18.0),
            onPressed: () => _confirmDelete(context, item),
          ),
        ],
      ),
    );
  }
}
