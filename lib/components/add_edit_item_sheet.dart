import '/backend/backend.dart';
import '/components/image_upload_button.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/services/kin_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kDefaultCategories = [
  'Salon & Beauty',
  'Restaurant & Food',
  'Retail',
  'Professional Services',
  'Health & Wellness',
];

/// Add/edit sheet for a Marketplace item (My Items). [existing] null means
/// add; non-null means edit - the form pre-fills and submit calls
/// KinServices.updateBusinessItem instead of createBusinessItem, and never
/// touches interest_count or business_ref (both frozen by firestore.rules
/// on update anyway, but the form doesn't offer them either).
class AddEditItemSheet extends StatefulWidget {
  const AddEditItemSheet({
    super.key,
    required this.businessRef,
    this.existing,
  });

  final DocumentReference businessRef;
  final BusinessItemsRecord? existing;

  @override
  State<AddEditItemSheet> createState() => _AddEditItemSheetState();
}

class _AddEditItemSheetState extends State<AddEditItemSheet> {
  late final _titleController =
      TextEditingController(text: widget.existing?.title ?? '');
  late final _priceController =
      TextEditingController(text: widget.existing?.priceDisplay ?? '');
  late final _descriptionController =
      TextEditingController(text: widget.existing?.description ?? '');
  final _otherCategoryController = TextEditingController();
  late final _categoryController = FormFieldController<String>(
    widget.existing?.category.isNotEmpty == true
        ? widget.existing!.category
        : _kDefaultCategories.first,
  );
  String? _photoUrl;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.existing?.photoUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _otherCategoryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final price = _priceController.text.trim();
    if (title.isEmpty || price.isEmpty) {
      setState(() => _error = 'Item name and price are required.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final otherCategory = _otherCategoryController.text.trim();
    final effectiveCategory = otherCategory.isNotEmpty
        ? otherCategory
        : (_categoryController.value ?? _kDefaultCategories.first);
    if (otherCategory.isNotEmpty) {
      await KinServices.ensureBusinessCategoryExists(otherCategory);
    }

    final existing = widget.existing;
    final result = existing == null
        ? await KinServices.createBusinessItem(
            businessRef: widget.businessRef,
            title: title,
            description: _descriptionController.text.trim(),
            priceDisplay: price,
            photoUrl: _photoUrl,
            category: effectiveCategory,
          )
        : await KinServices.updateBusinessItem(
            itemRef: existing.reference,
            title: title,
            description: _descriptionController.text.trim(),
            priceDisplay: price,
            photoUrl: _photoUrl,
            category: effectiveCategory,
          );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.isSuccess) {
      Navigator.pop(context);
    } else {
      setState(() => _error = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(theme.designToken.radius.lg),
          topRight: Radius.circular(theme.designToken.radius.lg),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          theme.designToken.spacing.lg,
          theme.designToken.spacing.md,
          theme.designToken.spacing.lg,
          MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              theme.designToken.spacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.0,
                  height: 4.0,
                  margin:
                      EdgeInsets.only(bottom: theme.designToken.spacing.md),
                  decoration: BoxDecoration(
                    color: theme.alternate,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              Text(
                widget.existing == null ? 'Add item' : 'Edit item',
                style: theme.titleMedium.override(
                  font: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold),
                  color: theme.primaryText,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.0,
                ),
              ),
              SizedBox(height: theme.designToken.spacing.md),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    width: 96.0,
                    height: 96.0,
                    color: theme.secondaryBackground,
                    child: _photoUrl == null || _photoUrl!.isEmpty
                        ? Icon(Icons.storefront_rounded,
                            color: theme.secondaryText, size: 28.0)
                        : Image.network(_photoUrl!, fit: BoxFit.cover),
                  ),
                ),
              ),
              Center(
                child: ImageUploadButton(
                  label: 'Add a photo',
                  onUploaded: (url) async {
                    setState(() => _photoUrl = url);
                  },
                ),
              ),
              SizedBox(height: theme.designToken.spacing.sm),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Item name',
                  hintStyle: theme.bodySmall.override(color: theme.hint),
                  filled: true,
                  fillColor: theme.secondaryBackground,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(theme.designToken.radius.sm),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(theme.designToken.spacing.sm),
                ),
                style: theme.bodyMedium.override(color: theme.primaryText),
              ),
              SizedBox(height: theme.designToken.spacing.sm),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  hintText: 'Price (e.g. \$25 or Starting at \$40)',
                  hintStyle: theme.bodySmall.override(color: theme.hint),
                  filled: true,
                  fillColor: theme.secondaryBackground,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(theme.designToken.radius.sm),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(theme.designToken.spacing.sm),
                ),
                style: theme.bodyMedium.override(color: theme.primaryText),
              ),
              SizedBox(height: theme.designToken.spacing.sm),
              StreamBuilder<List<BusinessCategoriesRecord>>(
                stream: queryBusinessCategoriesRecord(
                  queryBuilder: (q) => q.orderBy('display_name'),
                ),
                builder: (context, snapshot) {
                  final categoryOptions =
                      snapshot.hasData && snapshot.data!.isNotEmpty
                          ? snapshot.data!.map((c) => c.displayName).toList()
                          : _kDefaultCategories;
                  return FlutterFlowDropDown<String>(
                    controller: _categoryController,
                    options: categoryOptions,
                    onChanged: (val) => setState(() {}),
                    width: double.infinity,
                    height: 44.0,
                    textStyle:
                        theme.bodyMedium.override(color: theme.primaryText),
                    hintText: 'Category',
                    fillColor: theme.secondaryBackground,
                    elevation: 2.0,
                    borderColor: Colors.transparent,
                    borderRadius: theme.designToken.radius.sm,
                    borderWidth: 0.0,
                    margin:
                        EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                  );
                },
              ),
              SizedBox(height: theme.designToken.spacing.sm),
              TextFormField(
                controller: _otherCategoryController,
                decoration: InputDecoration(
                  hintText: "Don't see your category? Type a new one",
                  hintStyle: theme.bodySmall.override(color: theme.hint),
                  filled: true,
                  fillColor: theme.secondaryBackground,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(theme.designToken.radius.sm),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(theme.designToken.spacing.sm),
                ),
                style: theme.bodyMedium.override(color: theme.primaryText),
              ),
              SizedBox(height: theme.designToken.spacing.sm),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Description (optional)',
                  hintStyle: theme.bodySmall.override(color: theme.hint),
                  filled: true,
                  fillColor: theme.secondaryBackground,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(theme.designToken.radius.sm),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(theme.designToken.spacing.sm),
                ),
                style: theme.bodyMedium.override(color: theme.primaryText),
              ),
              if (_error != null) ...[
                SizedBox(height: theme.designToken.spacing.sm),
                Text(
                  _error!,
                  style: theme.bodySmall.override(color: theme.error),
                ),
              ],
              SizedBox(height: theme.designToken.spacing.md),
              FFButtonWidget(
                onPressed: _submitting ? null : _submit,
                text: _submitting
                    ? 'Saving...'
                    : (widget.existing == null
                        ? 'Publish item'
                        : 'Save changes'),
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 48.0,
                  color: theme.primary,
                  textStyle: theme.titleSmall.override(color: Colors.white),
                  elevation: 0.0,
                  borderRadius:
                      BorderRadius.circular(theme.designToken.radius.sm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
