import '/backend/backend.dart';
import '/components/main_menu_button.dart';
import '/components/showcase_item_card_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'showcase_model.dart';
export 'showcase_model.dart';

/// Phase 1 (discovery only) marketplace showcase - see memory
/// `showcase-feature-phased-commission`. Businesses post items
/// (lib/pages/my_items/my_items_widget.dart), customers browse a "Popular
/// near you" rail (ranked by interest_count, the aggregate of the five
/// Exchange-style reactions) plus a full grid. Tapping an item routes to
/// the business's profile, not a checkout - there is none yet.
class ShowcaseWidget extends StatefulWidget {
  const ShowcaseWidget({super.key});

  static String routeName = 'Showcase';
  static String routePath = '/showcase';

  @override
  State<ShowcaseWidget> createState() => _ShowcaseWidgetState();
}

class _ShowcaseWidgetState extends State<ShowcaseWidget> {
  late ShowcaseModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ShowcaseModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        automaticallyImplyLeading: false,
        title: Text(
          'Showcase',
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<List<BusinessItemsRecord>>(
                stream: queryBusinessItemsRecord(
                  queryBuilder: (q) => q
                      .where('is_available', isEqualTo: true)
                      .orderBy('interest_count', descending: true)
                      .limit(10),
                ),
                builder: (context, snapshot) {
                  final popular = snapshot.data ?? [];
                  // Hidden entirely when nothing has any interest yet -
                  // an empty shelf beats a rail full of zero-reaction
                  // items with nothing to differentiate them.
                  if (popular.isEmpty || popular.first.interestCount == 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                        16.0, 16.0, 16.0, 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Popular near you',
                          style: theme.labelLarge.override(
                            font: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold),
                            color: theme.secondaryText,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: popular
                                .where((item) => item.interestCount > 0)
                                .map((item) =>
                                    ShowcaseItemCardWidget(item: item))
                                .toList()
                                .divide(SizedBox(width: 12.0)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Padding(
                padding:
                    EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 8.0),
                child: Text(
                  'Browse all items',
                  style: theme.labelLarge.override(
                    font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold),
                    color: theme.secondaryText,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StreamBuilder<List<BusinessItemsRecord>>(
                stream: queryBusinessItemsRecord(
                  queryBuilder: (q) => q
                      .where('is_available', isEqualTo: true)
                      .orderBy('created_at', descending: true),
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(theme.primary),
                        ),
                      ),
                    );
                  }
                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          "Nothing here yet. Check back once businesses "
                          'start adding items.',
                          textAlign: TextAlign.center,
                          style: theme.bodyMedium
                              .override(color: theme.secondaryText),
                        ),
                      ),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsetsDirectional.fromSTEB(
                        16.0, 0.0, 16.0, 24.0),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12.0,
                      crossAxisSpacing: 12.0,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) => ShowcaseItemCardWidget(
                      item: items[index],
                      width: double.infinity,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
