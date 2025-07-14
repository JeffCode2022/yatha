import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart'; // Importamos Iconsax
import '../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/loan.dart';
import '../../utils/logger.dart';
import 'package:lottie/lottie.dart';

class PaymentModal extends StatefulWidget {
  final dynamic payment;
  final String paymentPeriod;
  final int uid;
  final Function(double paidAmount, String status) onPaymentComplete;

  const PaymentModal({
    Key? key,
    required this.payment,
    required this.paymentPeriod,
    required this.uid,
    required this.onPaymentComplete,
  }) : super(key: key);

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  final _formKey = GlobalKey<FormState>();
  String _selectedPaymentMethod = PaymentMethod.cash;
  final _interestController = TextEditingController();
  final _capitalController = TextEditingController();
  final _amountController = TextEditingController();
  final _cashAmountController = TextEditingController();
  final _transferAmountController = TextEditingController();
  bool _isProcessing = false;
  bool _isToday = true;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();

    // Inicializar controladores con valores predeterminados
    if (widget.paymentPeriod == 'monthly') {
      // Para préstamos mensuales, dividimos en capital e interés
      final totalAmount = widget.payment['payment_amount'] ?? 0.0;
      // Asumimos 60% capital, 40% interés por defecto
      _capitalController.text = (totalAmount * 0.6).toStringAsFixed(2);
      _interestController.text = (totalAmount * 0.4).toStringAsFixed(2);
    } else {
      // Para préstamos diarios
      final expectedAmount = widget.payment['payment_amount'] ?? 0.0;
      _amountController.text = expectedAmount.toStringAsFixed(2);
      // Inicializar los controladores para pago mixto con valores por defecto
      _cashAmountController.text = expectedAmount.toStringAsFixed(2);
      _transferAmountController.text = '0.00';
    }

    // Verificar si la fecha de pago es hoy
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _isToday = widget.payment['payment_date'] == today;
  }

  @override
  void dispose() {
    _interestController.dispose();
    _capitalController.dispose();
    _amountController.dispose();
    _cashAmountController.dispose();
    _transferAmountController.dispose();
    super.dispose();
  }

  // Validar si es domingo (no se permiten pagos en domingo)
  bool _isSunday() {
    final paymentDate = DateTime.tryParse(widget.payment['payment_date'] ?? '');
    if (paymentDate == null) return false;
    return paymentDate.weekday == DateTime.sunday;
  }

  void _showErrorMessage(BuildContext context, String message) {
    OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.black.withOpacity(0.2),
          child: Center(
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 200),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.danger, // Iconsax en lugar de Material Icons
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Remover el mensaje después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  // Procesar pago
  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSunday()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Iconsax.danger,
                  color: Colors.white, size: 16), // Iconsax para error
              const SizedBox(width: 8),
              const Expanded(
                child: Text('No se pueden registrar pagos en domingo'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Mostrar diálogo de procesamiento
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.timer,
                        size: 16,
                        color: Colors.grey[700]), // Iconsax para procesando
                    const SizedBox(width: 8),
                    const Text(
                      'Procesando pago...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final expectedAmount = widget.payment['payment_amount'] ?? 0.0;
      double totalAmount = 0.0;

      Map<String, dynamic> paymentData = {
        'jsonrpc': '2.0',
        'params': {
          'id': widget.payment['id'],
          'payment_met': _selectedPaymentMethod,
        }
      };

      // Validar que el método de pago sea válido
      if (!PaymentMethod.isValid(_selectedPaymentMethod)) {
        throw Exception('Método de pago no válido: ${_selectedPaymentMethod}');
      }

      if (_selectedPaymentMethod == 'mixto') {
        final cashAmount = double.tryParse(_cashAmountController.text) ?? 0.0;
        final transferAmount =
            double.tryParse(_transferAmountController.text) ?? 0.0;
        totalAmount = cashAmount + transferAmount;

        paymentData['params'].addAll({
          'paid_amount_cash': cashAmount,
          'paid_amount_transferencia': transferAmount,
          'payment_met': 'mixto'
        });
      } else {
        totalAmount = double.tryParse(_amountController.text) ?? 0.0;

        // Validar que el monto no sea cero
        if (totalAmount <= 0) {
          throw Exception('El monto debe ser mayor a cero');
        }

        if (PaymentMethod.isTransfer(_selectedPaymentMethod)) {
          paymentData['params'].addAll({
            'paid_amount_cash': 0.0,
            'paid_amount_transferencia': totalAmount,
            'payment_met': _selectedPaymentMethod,
            'payment_type':
                PaymentMethod.isDigitalTransfer(_selectedPaymentMethod)
                    ? 'digital'
                    : 'transfer',
            'transfer_details': {
              'method': _selectedPaymentMethod,
              'amount': totalAmount,
              'status': totalAmount == expectedAmount
                  ? 'paid'
                  : totalAmount > expectedAmount
                      ? 'overpaid'
                      : 'partial',
              'is_digital':
                  PaymentMethod.isDigitalTransfer(_selectedPaymentMethod)
            }
          });
        } else {
          paymentData['params'].addAll({
            'paid_amount_cash': totalAmount,
            'paid_amount_transferencia': 0.0,
            'payment_met': 'cash'
          });
        }
      }

      // Determinar el estado del pago según el monto
      final roundedTotalAmount = (totalAmount * 100).round() / 100;
      final roundedExpectedAmount = (expectedAmount * 100).round() / 100;

      Logger.info('Monto pagado (redondeado): $roundedTotalAmount');
      Logger.info('Monto esperado (redondeado): $roundedExpectedAmount');
      Logger.info('Método de pago: ${_selectedPaymentMethod}');

      // Usar una diferencia máxima permitida de 0.01 para considerar montos iguales
      final difference = (roundedTotalAmount - roundedExpectedAmount).abs();
      if (difference <= 0.01) {
        paymentData['params']['payment_status'] = 'paid';
      } else if (roundedTotalAmount < roundedExpectedAmount) {
        paymentData['params']['payment_status'] = 'partial';
      } else {
        paymentData['params']['payment_status'] = 'overpaid';
      }

      Logger.info(
          'Estado del pago determinado: ${paymentData['params']['payment_status']}');
      Logger.info('Diferencia calculada: $difference');
      Logger.info('Enviando pago con datos: ${paymentData['params']}');

      final resultado = await _apiService.registerPayment(
        widget.uid,
        widget.payment['id'],
        paymentData,
      );

      // Cerrar el diálogo de procesamiento
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (!mounted) return;

      // Verificar si hay error en la respuesta
      if (resultado.containsKey('error')) {
        _showErrorMessage(
            context, resultado['error'] ?? 'Error al registrar pago');
        return;
      }

      // Verificar el estado del pago después del registro
      final verificationResponse = await _apiService.getLoanPayments(
        widget.uid,
        widget.payment['id'].toString(),
      );

      if (verificationResponse.containsKey('error')) {
        Logger.warning(
            'No se pudo verificar el estado del pago: ${verificationResponse['error']}');
      } else {
        final payments = verificationResponse['result'] as List?;
        if (payments != null && payments.isNotEmpty) {
          final payment = payments.firstWhere(
            (p) => p['id'] == widget.payment['id'],
            orElse: () => null,
          );

          if (payment != null) {
            // Obtener el monto pagado y el estado
            double paidAmount = 0.0;

            if (_selectedPaymentMethod == 'mixto') {
              final cashAmount =
                  (payment['paid_amount_cash'] ?? 0.0).toDouble();
              final transferAmount =
                  (payment['paid_amount_transferencia'] ?? 0.0).toDouble();
              paidAmount = cashAmount + transferAmount;
            } else if (PaymentMethod.isTransfer(_selectedPaymentMethod)) {
              paidAmount =
                  (payment['paid_amount_transferencia'] ?? 0.0).toDouble();
            } else {
              paidAmount = (payment['paid_amount_cash'] ?? 0.0).toDouble();
            }

            final status =
                payment['payment_status']?.toString().toLowerCase() ??
                    'pending';
            widget.onPaymentComplete(paidAmount, status);
            return;
          }
        }
      }

      // Si no se pudo verificar, usar los datos del registro original
      double paidAmount = totalAmount;
      String status = paymentData['params']['payment_status'];
      widget.onPaymentComplete(paidAmount, status);
    } catch (e) {
      // Cerrar el diálogo de procesamiento
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (!mounted) return;
      _showErrorMessage(context, e.toString());

      // Verificar si el pago se registró a pesar del error
      try {
        final verificationResponse = await _apiService.getLoanPayments(
          widget.uid,
          widget.payment['id'].toString(),
        );

        if (!verificationResponse.containsKey('error')) {
          final payments = verificationResponse['result'] as List?;
          if (payments != null && payments.isNotEmpty) {
            final payment = payments.firstWhere(
              (p) => p['id'] == widget.payment['id'],
              orElse: () => null,
            );

            if (payment != null &&
                payment['payment_status']?.toString().toLowerCase() !=
                    'pending') {
              // El pago se registró exitosamente a pesar del error
              double paidAmount = 0.0;
              if (payment['payment_met'] == 'mixto') {
                paidAmount = ((payment['paid_amount_cash'] ?? 0.0) +
                        (payment['paid_amount_transferencia'] ?? 0.0))
                    .toDouble();
              } else {
                paidAmount = (payment['paid_amount'] ?? 0.0).toDouble();
              }
              widget.onPaymentComplete(
                paidAmount,
                payment['payment_status'].toString().toLowerCase(),
              );
            }
          }
        }
      } catch (verificationError) {
        Logger.error(
            'Error al verificar el estado del pago', verificationError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _buildSuccessMessage(
      Map<String, dynamic> resultado, String paymentMethod) {
    final List<String> messages = [];

    messages.add(
        'Pago registrado con éxito por ${PaymentMethod.getDisplayName(paymentMethod)}');

    if (resultado['data']?['difference'] != null &&
        resultado['data']['difference'] > 0.01) {
      messages.add(
          'Pago excedido: S/.${resultado['data']['difference'].toStringAsFixed(2)} más que el monto esperado');
    }

    if (resultado.containsKey('warning')) {
      messages.add(resultado['warning']);
    }

    return messages.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final paymentStatus =
        widget.payment['payment_status']?.toString().toLowerCase() ?? 'pending';
    final bool isPaymentBlocked = paymentStatus == 'paid' ||
        paymentStatus == 'overpaid' ||
        paymentStatus == 'partial';

    if (isPaymentBlocked) {
      return Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.tick_circle, // Iconsax en lugar de Material Icons
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Este pago ya ha sido registrado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estado: ${_getStatusText(paymentStatus)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Iconsax.close_circle,
                      size: 16), // Iconsax para cerrar
                  label: const Text('Cerrar'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Iconsax.money_send, // Iconsax para pago
                          color: AppTheme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Registrar Pago',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Iconsax.close_circle), // Iconsax para cerrar
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                // Info de la cuota
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.colorScheme.primaryContainer.withOpacity(
                      0.2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.colorScheme.primaryContainer,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Iconsax.receipt_2, // Iconsax para cuota
                            size: 16,
                            color: AppTheme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cuota: ${widget.payment['name'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Iconsax.calendar, // Iconsax para fecha
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Fecha de pago: ${widget.payment['payment_date'] ?? 'Sin fecha'}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Iconsax.money, // Iconsax para monto
                            size: 16,
                            color: AppTheme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Monto: \\S/.${(widget.payment['payment_amount'] ?? 0.0).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _getPaymentStatusIcon(
                                paymentStatus), // Iconsax según estado
                            size: 16,
                            color: _getPaymentStatusColor(paymentStatus),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Estado: ${_getPaymentStatusText(paymentStatus)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getPaymentStatusColor(paymentStatus),
                            ),
                          ),
                        ],
                      ),
                      if (isPaymentBlocked) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                  Iconsax
                                      .tick_circle, // Iconsax para pago realizado
                                  color: Colors.green,
                                  size: 16),
                              const SizedBox(width: 4),
                              const Text(
                                'Pago ya realizado',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!_isToday) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.warning_2, // Iconsax para advertencia
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'La fecha de pago no es hoy',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_isSunday()) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.danger, // Iconsax para error
                                  color: Colors.red,
                                  size: 16),
                              const SizedBox(width: 4),
                              const Text(
                                'No se pueden registrar pagos en domingo',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Método de pago
                _buildPaymentMethodSelector(),
                const SizedBox(height: 24),

                // Campos según tipo de préstamo
                widget.paymentPeriod == 'monthly'
                    ? _buildMonthlyPaymentFields()
                    : _buildDailyPaymentFields(),

                const SizedBox(height: 24),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Iconsax.close_circle,
                            size: 16), // Iconsax para cancelar
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        label: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          isPaymentBlocked
                              ? Iconsax.tick_circle // Iconsax para completado
                              : Iconsax.money_send, // Iconsax para pagar
                          size: 16,
                          color: Colors.white,
                        ),
                        onPressed: isPaymentBlocked
                            ? null
                            : (_isProcessing ? null : _processPayment),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        label: _isProcessing
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: Lottie.asset(
                                    'assets/animations/loading.json'),
                              )
                            : Text(isPaymentBlocked
                                ? 'Pago Completado'
                                : 'Registrar Pago'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.card, // Iconsax para método de pago
              size: 16,
              color: Colors.grey[800],
            ),
            const SizedBox(width: 8),
            const Text(
              'Método de pago',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildPaymentMethodCard(
                title: 'Efectivo',
                icon: Iconsax.money, // Iconsax para efectivo
                value: 'cash',
                color: Colors.green,
              ),
              _buildPaymentMethodCard(
                title: 'BBVA',
                icon: Iconsax.bank, // Iconsax para banco
                value: 'bbva',
                color: Colors.blue,
              ),
              _buildPaymentMethodCard(
                title: 'INTERBANK',
                icon: Iconsax.bank, // Iconsax para banco
                value: 'interbank',
                color: Colors.orange,
              ),
              _buildPaymentMethodCard(
                title: 'BN',
                icon: Iconsax.bank, // Iconsax para banco
                value: 'bcn',
                color: Colors.red,
              ),
              _buildPaymentMethodCard(
                title: 'PLIN',
                icon: Iconsax.mobile, // Iconsax para móvil
                value: 'plin',
                color: const Color.fromARGB(255, 39, 130, 176),
              ),
              _buildPaymentMethodCard(
                title: 'YAPE',
                icon: Iconsax.mobile, // Iconsax para móvil
                value: 'yape',
                color: Colors.deepPurple,
              ),
              _buildPaymentMethodCard(
                title: 'Mixto',
                icon: Iconsax.convert, // Iconsax para mixto
                value: 'mixto',
                color: Colors.teal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required String title,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedPaymentMethod = value),
        child: Container(
          width: 90,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentFields() {
    if (_selectedPaymentMethod == 'mixto') {
      return Column(
        children: [
          TextFormField(
            controller: _cashAmountController,
            decoration: InputDecoration(
              labelText: 'Monto en efectivo',
              prefixText: 'S/. ',
              prefixIcon:
                  Icon(Iconsax.money, size: 18), // Iconsax para efectivo
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingrese el monto en efectivo';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _transferAmountController,
            decoration: InputDecoration(
              labelText: 'Monto por transferencia',
              prefixText: 'S/. ',
              prefixIcon:
                  Icon(Iconsax.card, size: 18), // Iconsax para transferencia
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingrese el monto por transferencia';
              }
              return null;
            },
          ),
        ],
      );
    } else {
      return TextFormField(
        controller: _amountController,
        decoration: InputDecoration(
          labelText: 'Monto a pagar',
          prefixText: 'S/. ',
          prefixIcon: Icon(
              _selectedPaymentMethod == 'cash' ? Iconsax.money : Iconsax.card,
              size: 18), // Iconsax según método
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ingrese el monto a pagar';
          }
          return null;
        },
      );
    }
  }

  Widget _buildMonthlyPaymentFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.document_text, // Iconsax para desglose
              size: 16,
              color: Colors.grey[800],
            ),
            const SizedBox(width: 8),
            const Text(
              'Desglose del pago (Préstamo Mensual)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Campo de interés
        TextFormField(
          controller: _interestController,
          decoration: InputDecoration(
            labelText: 'Interés Pagado',
            prefixIcon:
                Icon(Iconsax.money_recive, size: 18), // Iconsax para interés
            border: const OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'^\d+\.?\d{0,2}'),
            ), // Permite solo números con 2 decimales como máximo
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El interés es requerido';
            }
            if (double.tryParse(value) == null) {
              return 'Ingrese un número válido';
            }
            final amount = double.parse(value);
            if (amount <= 0) {
              return 'El interés debe ser mayor a cero';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Campo de capital
        TextFormField(
          controller: _capitalController,
          decoration: InputDecoration(
            labelText: 'Capital Pagado',
            prefixIcon:
                Icon(Iconsax.money_recive, size: 18), // Iconsax para capital
            border: const OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El capital es requerido';
            }
            if (double.tryParse(value) == null) {
              return 'Ingrese un número válido';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),
        // Total
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.money_tick, // Iconsax para total
                    size: 16,
                    color: Colors.grey[800],
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Total a pagar:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '\\S/.${_getTotalAmount().toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyPaymentFields() {
    final expectedAmount = widget.payment['payment_amount'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.money_tick, // Iconsax para monto
              size: 16,
              color: Colors.grey[800],
            ),
            const SizedBox(width: 8),
            const Text(
              'Monto del pago (Préstamo Diario)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedPaymentMethod == 'mixto') ...[
          TextFormField(
            controller: _cashAmountController,
            decoration: InputDecoration(
              labelText: 'Monto en efectivo',
              prefixText: 'S/. ',
              prefixIcon:
                  Icon(Iconsax.money, size: 18), // Iconsax para efectivo
              border: const OutlineInputBorder(),
              helperText:
                  'Monto total esperado: S/. ${expectedAmount.toStringAsFixed(2)}',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingrese el monto en efectivo';
              }
              final cashAmount = double.tryParse(value);
              if (cashAmount == null) {
                return 'Ingrese un monto válido';
              }
              if (cashAmount < 0) {
                return 'El monto no puede ser negativo';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _transferAmountController,
            decoration: InputDecoration(
              labelText: 'Monto por transferencia',
              prefixText: 'S/. ',
              prefixIcon:
                  Icon(Iconsax.card, size: 18), // Iconsax para transferencia
              border: const OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingrese el monto por transferencia';
              }
              final transferAmount = double.tryParse(value);
              if (transferAmount == null) {
                return 'Ingrese un monto válido';
              }
              if (transferAmount < 0) {
                return 'El monto no puede ser negativo';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.money,
                            size: 14,
                            color: Colors.grey[600]), // Iconsax para efectivo
                        const SizedBox(width: 4),
                        const Text('Efectivo:',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    Text(
                      'S/. ${(double.tryParse(_cashAmountController.text) ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.card,
                            size: 14,
                            color:
                                Colors.grey[600]), // Iconsax para transferencia
                        const SizedBox(width: 4),
                        const Text('Transferencia:',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    Text(
                      'S/. ${(double.tryParse(_transferAmountController.text) ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.money_tick,
                            size: 14,
                            color: Colors.grey[800]), // Iconsax para total
                        const SizedBox(width: 4),
                        const Text(
                          'Total:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      'S/. ${((double.tryParse(_cashAmountController.text) ?? 0.0) + (double.tryParse(_transferAmountController.text) ?? 0.0)).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Monto a pagar',
              prefixText: 'S/. ',
              prefixIcon: Icon(
                  _selectedPaymentMethod == 'cash'
                      ? Iconsax.money
                      : Iconsax.card,
                  size: 18), // Iconsax según método
              border: const OutlineInputBorder(),
              helperText:
                  'Monto esperado: S/. ${expectedAmount.toStringAsFixed(2)}',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingrese el monto a pagar';
              }
              final amount = double.tryParse(value);
              if (amount == null) {
                return 'Ingrese un monto válido';
              }
              if (amount <= 0) {
                return 'El monto debe ser mayor a cero';
              }
              return null;
            },
          ),
      ],
    );
  }

  double _getTotalAmount() {
    double interest = double.tryParse(_interestController.text) ?? 0;
    double capital = double.tryParse(_capitalController.text) ?? 0;
    return interest + capital;
  }

  String _getPaymentStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Pagado';
      case 'partial':
        return 'Pago Parcial';
      case 'overpaid':
        return 'Pago Excedido';
      case 'pending':
        return 'Pendiente';
      default:
        return 'Desconocido';
    }
  }

  IconData _getPaymentStatusIcon(String status) {
    switch (status) {
      case 'paid':
        return Iconsax.tick_circle;
      case 'partial':
        return Iconsax.timer_1;
      case 'overpaid':
        return Iconsax.money_add;
      case 'pending':
        return Iconsax.timer;
      default:
        return Iconsax.info_circle;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'paid':
      case 'partial':
      case 'overpaid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Pagado';
      case 'overpaid':
        return 'Pago Excedido';
      case 'partial':
        return 'Pago Parcial';
      default:
        return 'Estado desconocido';
    }
  }
}

class PaymentMethod {
  static const String cash = 'cash';
  static const String bbva = 'bbva';
  static const String interbank = 'interbank';
  static const String bcn = 'bcn';
  static const String plin = 'plin';
  static const String yape = 'yape';
  static const String mixto = 'mixto';

  static bool isValid(String method) {
    return method == cash ||
        method == bbva ||
        method == interbank ||
        method == bcn ||
        method == plin ||
        method == yape ||
        method == mixto;
  }

  static bool isTransfer(String method) {
    return method == bbva ||
        method == interbank ||
        method == bcn ||
        method == plin ||
        method == yape;
  }

  static bool isDigitalTransfer(String method) {
    return method == plin || method == yape;
  }

  static String getDisplayName(String method) {
    switch (method) {
      case cash:
        return 'Efectivo';
      case bbva:
        return 'BBVA';
      case interbank:
        return 'INTERBANK';
      case bcn:
        return 'Banco de la Nación';
      case plin:
        return 'PLIN';
      case yape:
        return 'YAPE';
      case mixto:
        return 'Pago Mixto';
      default:
        return 'Desconocido';
    }
  }
}
