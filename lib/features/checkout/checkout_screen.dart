import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/validators.dart';
import '../../data/api/customer_api.dart';
import '../../data/models/api_error.dart';
import '../../data/models/cart.dart';
import '../../data/models/order.dart';
import '../../state/async_controller.dart';
import '../../state/cart_controller.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/section_card.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final AsyncController<CustomerResponse> _customer;

  @override
  void initState() {
    super.initState();
    final api = context.read<CustomerApi>();
    _customer = AsyncController(api.me)..load();
  }

  @override
  void dispose() {
    _customer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartController = context.watch<CartController>();
    final cart = cartController.cart;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListenableBuilder(
        listenable: _customer,
        builder: (context, _) {
          if (cart == null) {
            if (cartController.error != null && !cartController.isLoading) {
              return ErrorView(
                error: cartController.error!,
                onRetry: cartController.load,
              );
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: ListSkeleton(rows: 4),
            );
          }
          if (cart.isEmpty && !cartController.isBusy) {
            return EmptyView(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Add products to your cart before checking out.',
              action: FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Browse products'),
              ),
            );
          }

          final customer = _customer.data;
          final error = _customer.error;
          if (customer == null) {
            if (error != null && !_customer.isLoading) {
              return ErrorView(error: error, onRetry: _customer.load);
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: ListSkeleton(rows: 4),
            );
          }
          return _CheckoutForm(customer: customer, cart: cart);
        },
      ),
    );
  }
}

class _CheckoutForm extends StatefulWidget {
  const _CheckoutForm({required this.customer, required this.cart});

  final CustomerResponse customer;
  final Cart cart;

  @override
  State<_CheckoutForm> createState() => _CheckoutFormState();
}

class _CheckoutFormState extends State<_CheckoutForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late CustomerResponse _saved;

  bool _placing = false;
  String? _formError;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    _saved = widget.customer;
    _firstName = TextEditingController(text: _saved.firstName);
    _lastName = TextEditingController(text: _saved.lastName);
    _phone = TextEditingController(text: _saved.phone ?? '');
    _address = TextEditingController(text: _saved.address ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  static String? _orNull(String s) => s.trim().isEmpty ? null : s.trim();

  bool get _profileChanged =>
      _firstName.text.trim() != _saved.firstName ||
      _lastName.text.trim() != _saved.lastName ||
      _orNull(_phone.text) != _saved.phone ||
      _orNull(_address.text) != _saved.address;

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

  Future<void> _placeOrder() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _formError = null;
      _fieldErrors = const {};
    });
    if (!_formKey.currentState!.validate()) return;

    final customerApi = context.read<CustomerApi>();
    final cart = context.read<CartController>();
    setState(() => _placing = true);
    try {
      if (_profileChanged) {
        _saved = await customerApi.updateMe(
          CustomerProfileRequest(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            phone: _orNull(_phone.text),
            address: _orNull(_address.text),
          ),
        );
      }
      final order = await cart.checkout();
      if (!mounted) return;
      context.go('/orders/${order.id}', extra: order);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order ${order.orderNumber} placed')),
      );
    } on ApiException catch (e) {
      if (!mounted || e.kind == ApiErrorKind.sessionExpired) return;
      setState(() {
        _fieldErrors = e.fieldErrors;
        _formError = e.fieldErrors.isNotEmpty
            ? 'Please fix the highlighted fields.'
            : ErrorInfo.from(e).message;
      });
      if (e.fieldErrors.isNotEmpty) _formKey.currentState!.validate();
    } catch (e) {
      if (mounted) setState(() => _formError = ErrorInfo.from(e).message);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = widget.cart;
    final blocked = cart.hasUnavailableItems;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const _Banner(
            icon: Icons.info_outline,
            text:
                'No payment is taken. Your order is placed as Pending and '
                'confirmed by the store.',
            color: AppColors.info,
            background: AppColors.infoBg,
          ),
          const SizedBox(height: 12),
          if (_formError != null) ...[
            _Banner(
              icon: Icons.error_outline,
              text: _formError!,
              color: AppColors.danger,
              background: AppColors.dangerBg,
            ),
            const SizedBox(height: 12),
          ],
          if (blocked) ...[
            const _Banner(
              icon: Icons.warning_amber_rounded,
              text:
                  'Some items in your cart are unavailable. Go back to the '
                  'cart to update them.',
              color: AppColors.warning,
              background: AppColors.warningBg,
            ),
            const SizedBox(height: 12),
          ],
          SectionCard(
            title: 'Contact details',
            icon: Icons.person_outline,
            child: Column(
              children: [
                TextFormField(
                  initialValue: _saved.email,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    helperText: 'Your account email can\'t be changed here.',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstName,
                        enabled: !_placing,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.givenName],
                        decoration: const InputDecoration(
                          labelText: 'First name *',
                        ),
                        validator: _withServer(
                          'firstName',
                          Validators.firstName,
                        ),
                        onChanged: (_) => _clearServerError('firstName'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastName,
                        enabled: !_placing,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.familyName],
                        decoration: const InputDecoration(
                          labelText: 'Last name *',
                        ),
                        validator: _withServer('lastName', Validators.lastName),
                        onChanged: (_) => _clearServerError('lastName'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  enabled: !_placing,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: (_) => _fieldErrors['phone'],
                  onChanged: (_) => _clearServerError('phone'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address,
                  enabled: !_placing,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  autofillHints: const [AutofillHints.fullStreetAddress],
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    alignLabelWithHint: true,
                  ),
                  validator: (_) => _fieldErrors['address'],
                  onChanged: (_) => _clearServerError('address'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Order summary',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: [
                for (final item in cart.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity} × ${item.productName}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(Formatters.currency(item.lineTotal)),
                      ],
                    ),
                  ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text('Total', style: theme.textTheme.titleMedium),
                    ),
                    Text(
                      Formatters.currency(cart.totalAmount),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _placing || blocked || cart.isEmpty ? null : _placeOrder,
            icon: _placing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      semanticsLabel: 'Placing order',
                    ),
                  )
                : const Icon(Icons.check),
            label: const Text('Place order'),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
