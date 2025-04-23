import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../src/providers/payment_provider.dart';
import '../theme/app_theme.dart';
import '../../src/services/api_service.dart';

class PaymentModal extends StatefulWidget {
  final dynamic payment;
  final String paymentPeriod;
  final int uid;
  final Function() onPaymentComplete;

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
  String _selectedPaymentMethod = 'cash';
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
      // Para préstamos diarios, solo un monto total
      _amountController.text =
          (widget.payment['payment_amount'] ?? 0.0).toStringAsFixed(2);
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

  // Procesar pago
  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSunday()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pueden registrar pagos en domingo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      Map<String, dynamic> paymentData;

      if (_selectedPaymentMethod == 'mixto') {
        paymentData = {
          'payment_met': 'mixto',
          'paid_amount_cash': double.parse(_cashAmountController.text),
          'paid_amount_transferencia':
              double.parse(_transferAmountController.text),
        };
      } else {
        paymentData = {
          'payment_met': _selectedPaymentMethod,
          'paid_amount': double.parse(_amountController.text),
        };
      }

      final resultado = await _apiService.registerPayment(
        widget.uid,
        widget.payment['id'],
        paymentData,
      );

      if (resultado.containsKey('error')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado['error'] ?? 'Error al registrar pago'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pago registrado con éxito'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onPaymentComplete();
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    Text(
                      'Registrar Pago',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
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
                      Text(
                        'Cuota: ${widget.payment['name'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fecha de pago: ${widget.payment['payment_date'] ?? 'Sin fecha'}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Monto: \\S/.${(widget.payment['payment_amount'] ?? 0.0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.colorScheme.primary,
                        ),
                      ),
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.orange,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 16),
                              SizedBox(width: 4),
                              Text(
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
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Registrar Pago'),
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
        const Text(
          'Método de pago',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Efectivo'),
                value: 'cash',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) =>
                    setState(() => _selectedPaymentMethod = value!),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Transferencia'),
                value: 'transfer',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) =>
                    setState(() => _selectedPaymentMethod = value!),
              ),
            ),
          ],
        ),
        RadioListTile<String>(
          title: const Text('Mixto (Efectivo + Transferencia)'),
          value: 'mixto',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
        ),
      ],
    );
  }

  Widget _buildPaymentFields() {
    if (_selectedPaymentMethod == 'mixto') {
      return Column(
        children: [
          TextFormField(
            controller: _cashAmountController,
            decoration: const InputDecoration(
              labelText: 'Monto en efectivo',
              prefixText: 'S/. ',
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
            decoration: const InputDecoration(
              labelText: 'Monto por transferencia',
              prefixText: 'S/. ',
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
        decoration: const InputDecoration(
          labelText: 'Monto a pagar',
          prefixText: 'S/. ',
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
        const Text(
          'Desglose del pago (Préstamo Mensual)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),

        // Campo de interés
        TextFormField(
          controller: _interestController,
          decoration: const InputDecoration(
            labelText: 'Interés Pagado',
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text('S/', style: TextStyle(fontSize: 16)),
            ),
            border: OutlineInputBorder(),
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
          decoration: const InputDecoration(
            labelText: 'Capital Pagado',
            prefixIcon: Icon(Icons.account_balance_wallet),
            border: OutlineInputBorder(),
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
              const Text(
                'Total a pagar:',
                style: TextStyle(fontWeight: FontWeight.bold),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monto del pago (Préstamo Diario)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),

        // Campo de monto total
        _buildPaymentFields(),
      ],
    );
  }

  double _getTotalAmount() {
    double interest = double.tryParse(_interestController.text) ?? 0;
    double capital = double.tryParse(_capitalController.text) ?? 0;
    return interest + capital;
  }
}
