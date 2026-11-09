import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../core/validators.dart';
import '../../data/api/product_api.dart';
import '../../data/models/api_error.dart';
import '../../data/models/product.dart';
import '../../state/async_controller.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/product_image.dart';
import '../../widgets/product_placeholder.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.productId, this.initial});

  final String? productId;

  final ProductResponse? initial;

  bool get isEdit => productId != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  AsyncController<ProductResponse>? _loader;

  @override
  void initState() {
    super.initState();
    final id = widget.productId;
    if (id != null && widget.initial == null && Validators.isUuid(id)) {
      final api = context.read<ProductApi>();
      _loader = AsyncController(() => api.get(id))..load();
    }
  }

  @override
  void dispose() {
    _loader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEdit ? 'Edit product' : 'New product';
    return Theme(
      data: AppTheme.admin(Theme.of(context)),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          title: Text(title),
        ),
        body: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (!widget.isEdit) return const _ProductForm();
    if (widget.initial != null) {
      return _ProductForm(product: widget.initial);
    }
    final loader = _loader;
    if (loader == null) {
      return EmptyView(
        icon: Icons.search_off,
        title: 'Product not found',
        action: FilledButton(
          onPressed: () => context.go('/admin/products'),
          child: const Text('Back to products'),
        ),
      );
    }
    return ListenableBuilder(
      listenable: loader,
      builder: (context, _) {
        final error = loader.error;
        if (error != null && !loader.isLoading) {
          if (error is ApiException && error.kind == ApiErrorKind.notFound) {
            return EmptyView(
              icon: Icons.search_off,
              title: 'Product not found',
              action: FilledButton(
                onPressed: () => context.go('/admin/products'),
                child: const Text('Back to products'),
              ),
            );
          }
          return ErrorView(error: error, onRetry: loader.load);
        }
        final product = loader.data;
        if (product == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _ProductForm(product: product);
      },
    );
  }
}

class _ProductForm extends StatefulWidget {
  const _ProductForm({this.product});

  final ProductResponse? product;

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _quantity;
  late final TextEditingController _thumbnail;
  final List<TextEditingController> _images = [];
  late bool _active;

  bool _saving = false;
  String? _formError;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(
      text: p == null ? '' : _formatPrice(p.unitPrice),
    );
    _quantity = TextEditingController(
      text: p?.quantityInStock.toString() ?? '',
    );
    _thumbnail = TextEditingController(text: p?.thumbnail ?? '');
    for (final url in p?.images ?? const <String>[]) {
      _images.add(TextEditingController(text: url));
    }
    _active = p?.active ?? true;
  }

  static String _formatPrice(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _description.dispose();
    _price.dispose();
    _quantity.dispose();
    _thumbnail.dispose();
    for (final c in _images) {
      c.dispose();
    }
    super.dispose();
  }

  String? Function(String?) _withServer(
    String field,
    String? Function(String?) local,
  ) =>
      (v) => _fieldErrors[field] ?? local(v);

  void _clearServerError(String field) {
    if (_fieldErrors.containsKey(field)) {
      setState(() => _fieldErrors = {..._fieldErrors}..remove(field));
    }
  }

  void _addImage() {
    if (_images.length >= AppConfig.maxProductImages) return;
    setState(() => _images.add(TextEditingController()));
    _clearServerError('images');
  }

  void _removeImage(int index) {
    final c = _images.removeAt(index);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());
    _clearServerError('images');
  }

  String? get _imagesServerError {
    final entries = _fieldErrors.entries
        .where((e) => e.key == 'images' || e.key.startsWith('images['))
        .map((e) => e.value)
        .toSet();
    return entries.isEmpty ? null : entries.join('\n');
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _formError = null;
      _fieldErrors = const {};
    });
    if (!_formKey.currentState!.validate()) return;

    final description = _description.text.trim();
    final thumbnail = _thumbnail.text.trim();
    final images = _images
        .map((c) => c.text.trim())
        .where((u) => u.isNotEmpty)
        .toList();
    final request = ProductRequest(
      name: _name.text.trim(),
      sku: _sku.text.trim(),
      description: description.isEmpty ? null : description,
      unitPrice: double.parse(_price.text.trim()),
      quantityInStock: int.parse(_quantity.text.trim()),
      active: _active,
      thumbnail: thumbnail.isEmpty ? null : thumbnail,
      images: images,
    );

    setState(() => _saving = true);
    final api = context.read<ProductApi>();
    try {
      final existing = widget.product;
      if (existing == null) {
        final created = await api.create(request);
        if (mounted) context.pop('Created "${created.name}"');
      } else {
        final updated = await api.update(existing.id, request);
        if (mounted) context.pop('Saved "${updated.name}"');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.kind == ApiErrorKind.sessionExpired) return;
      setState(() {
        _fieldErrors = e.fieldErrors;
        _formError = switch (e.kind) {
          ApiErrorKind.badRequest when e.fieldErrors.isNotEmpty =>
            'Please fix the highlighted fields.',
          ApiErrorKind.badRequest => e.message,
          ApiErrorKind.forbidden =>
            'Access denied: your account can\'t change products.',
          ApiErrorKind.notFound => 'This product no longer exists.',
          _ => ErrorInfo.from(e).message,
        };
      });
      if (e.fieldErrors.isNotEmpty) _formKey.currentState!.validate();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_formError!),
            backgroundColor: AppColors.danger,
          ),
        );
    } catch (e) {
      if (mounted) setState(() => _formError = ErrorInfo.from(e).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (_formError != null) ...[
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _formError!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _name,
            enabled: !_saving,
            maxLength: 150,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name *'),
            validator: _withServer('name', Validators.productName),
            onChanged: (_) => _clearServerError('name'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _sku,
            enabled: !_saving,
            maxLength: 80,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'SKU *'),
            validator: _withServer('sku', Validators.sku),
            onChanged: (_) => _clearServerError('sku'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _description,
            enabled: !_saving,
            maxLength: 500,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
            ),
            validator: _withServer('description', Validators.description),
            onChanged: (_) => _clearServerError('description'),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _price,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Unit price *',
                    prefixText: r'$ ',
                  ),
                  validator: _withServer('unitPrice', Validators.unitPrice),
                  onChanged: (_) => _clearServerError('unitPrice'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _quantity,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Quantity in stock *',
                  ),
                  validator: _withServer(
                    'quantityInStock',
                    Validators.quantity,
                  ),
                  onChanged: (_) => _clearServerError('quantityInStock'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              value: _active,
              onChanged: _saving ? null : (v) => setState(() => _active = v),
              title: const Text('Active'),
              subtitle: Text(
                _active
                    ? 'Visible on the storefront'
                    : 'Hidden from the storefront',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          if (_fieldErrors['active'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(
                _fieldErrors['active']!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          _ImagesSection(
            thumbnail: _thumbnail,
            images: _images,
            enabled: !_saving,
            seed: widget.product?.id ?? 'new',
            name: _name.text.isEmpty ? 'Product' : _name.text,
            thumbnailValidator: _withServer(
              'thumbnail',
              Validators.thumbnailUrl,
            ),
            imageValidator: Validators.imageUrl,
            imagesError: _imagesServerError,
            onThumbnailChanged: () => _clearServerError('thumbnail'),
            onAdd: _addImage,
            onRemove: _removeImage,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(
              widget.product == null ? 'Create product' : 'Save changes',
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagesSection extends StatelessWidget {
  const _ImagesSection({
    required this.thumbnail,
    required this.images,
    required this.enabled,
    required this.seed,
    required this.name,
    required this.thumbnailValidator,
    required this.imageValidator,
    required this.imagesError,
    required this.onThumbnailChanged,
    required this.onAdd,
    required this.onRemove,
  });

  final TextEditingController thumbnail;
  final List<TextEditingController> images;
  final bool enabled;
  final String seed;
  final String name;
  final String? Function(String?) thumbnailValidator;
  final String? Function(String?) imageValidator;
  final String? imagesError;
  final VoidCallback onThumbnailChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  Widget _preview(TextEditingController c) => ValueListenableBuilder(
    valueListenable: c,
    builder: (context, value, _) {
      final url = value.text.trim();
      return SizedBox(
        width: 48,
        height: 48,
        child: ProductImage(
          url: Validators.isHttpUrl(url) ? url : null,
          seed: seed,
          name: name,
          size: PlaceholderSize.avatar,
          borderRadius: BorderRadius.circular(10),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final full = images.length >= AppConfig.maxProductImages;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Images', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Image URLs (http/https). The thumbnail is used on cards; the '
              'gallery is shown on the product page.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _preview(thumbnail),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: thumbnail,
                    enabled: enabled,
                    maxLength: 1000,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Thumbnail URL',
                      counterText: '',
                    ),
                    validator: thumbnailValidator,
                    onChanged: (_) => onThumbnailChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < images.length; i++) ...[
              Row(
                key: ObjectKey(images[i]),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _preview(images[i]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: images[i],
                      enabled: enabled,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'Gallery image ${i + 1}',
                      ),
                      validator: imageValidator,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove gallery image ${i + 1}',
                    onPressed: enabled ? () => onRemove(i) : null,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            if (imagesError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  imagesError!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: enabled && !full ? onAdd : null,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  full
                      ? 'Maximum ${AppConfig.maxProductImages} images'
                      : 'Add gallery image '
                            '(${images.length}/${AppConfig.maxProductImages})',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
