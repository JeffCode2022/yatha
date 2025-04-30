import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/loan.dart';

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
      final expectedAmount = widget.payment['payment_amount'] ?? 0.0;
      double totalAmount = 0.0;

      Map<String, dynamic> paymentData = {
        'jsonrpc': '2.0',
        'params': {
          'id': widget.payment['id'],
          'payment_met': _selectedPaymentMethod,
        }
      };

      if (_selectedPaymentMethod == 'mixto') {
        final cashAmount = double.tryParse(_cashAmountController.text) ?? 0.0;
        final transferAmount =
            double.tryParse(_transferAmountController.text) ?? 0.0;
        totalAmount = cashAmount + transferAmount;

        if ((totalAmount - expectedAmount).abs() > 0.01) {
          throw Exception('El monto total no coincide con el monto esperado');
        }

        paymentData['params'].addAll({
          'paid_amount_cash': cashAmount,
          'paid_amount_transferencia': transferAmount,
          'payment_met': 'mixto'
        });
      } else {
        totalAmount = double.tryParse(_amountController.text) ?? 0.0;

        if ((totalAmount - expectedAmount).abs() > 0.01) {
          throw Exception('El monto no coincide con el monto esperado');
        }

        if (PaymentMethod.isTransfer(_selectedPaymentMethod)) {
          paymentData['params'].addAll({
            'paid_amount_cash': 0.0,
            'paid_amount_transferencia': totalAmount,
            'payment_met': _selectedPaymentMethod
          });
        } else {
          paymentData['params'].addAll({
            'paid_amount_cash': totalAmount,
            'paid_amount_transferencia': 0.0,
            'payment_met': _selectedPaymentMethod
          });
        }
      }

      // Validar que el método de pago sea válido
      if (!PaymentMethod.isValid(_selectedPaymentMethod) &&
          _selectedPaymentMethod != 'mixto') {
        throw Exception('Método de pago no válido');
      }

      final resultado = await _apiService.registerPayment(
        widget.uid,
        widget.payment['id'],
        paymentData,
      );

      if (mounted) {
        if (resultado.containsKey('error')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado['error'] ?? 'Error al registrar pago'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Pago registrado con éxito por ${PaymentMethod.getDisplayName(_selectedPaymentMethod)}'),
              backgroundColor: Colors.green,
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            Navigator.pop(context);
            widget.onPaymentComplete();
          }
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

  void _updateMixedPaymentAmounts(String value, bool isCash) {
    final expectedAmount = widget.payment['payment_amount'] ?? 0.0;
    final enteredAmount = double.tryParse(value) ?? 0.0;

    if (isCash) {
      if (enteredAmount <= expectedAmount) {
        final remainingAmount = expectedAmount - enteredAmount;
        _transferAmountController.text = remainingAmount.toStringAsFixed(2);
      } else {
        _cashAmountController.text = expectedAmount.toStringAsFixed(2);
        _transferAmountController.text = '0.00';
      }
    } else {
      if (enteredAmount <= expectedAmount) {
        final remainingAmount = expectedAmount - enteredAmount;
        _cashAmountController.text = remainingAmount.toStringAsFixed(2);
      } else {
        _transferAmountController.text = expectedAmount.toStringAsFixed(2);
        _cashAmountController.text = '0.00';
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
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildPaymentMethodCard(
                title: 'Efectivo',
                icon: Icons.payments_outlined,
                value: 'cash',
                color: Colors.green,
              ),
              _buildPaymentMethodCard(
                title: 'BBVA',
                icon: Icons.account_balance,
                value: 'bbva',
                color: Colors.blue,
              ),
              _buildPaymentMethodCard(
                title: 'INTERBANK',
                icon: Icons.account_balance,
                value: 'interbank',
                color: Colors.orange,
              ),
              _buildPaymentMethodCard(
                title: 'BN',
                icon: Icons.account_balance,
                value: 'bcn',
                color: Colors.red,
              ),
              _buildPaymentMethodCard(
                title: 'PLIN',
                icon: Icons.phone_android,
                value: 'plin',
                color: const Color.fromARGB(255, 39, 130, 176),
              ),
              _buildPaymentMethodCard(
                title: 'YAPE',
                icon: Icons.phone_android,
                value: 'yape',
                color: Colors.deepPurple,
              ),
              _buildPaymentMethodCard(
                title: 'Mixto',
                icon: Icons.compare_arrows,
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
    final expectedAmount = widget.payment['payment_amount'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monto del pago (Préstamo Diario)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (_selectedPaymentMethod == 'mixto') ...[
          TextFormField(
            controller: _cashAmountController,
            decoration: InputDecoration(
              labelText: 'Monto en efectivo',
              prefixText: 'S/. ',
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
              if (cashAmount > expectedAmount) {
                return 'El monto no puede ser mayor a S/. ${expectedAmount.toStringAsFixed(2)}';
              }
              return null;
            },
            onChanged: (value) => _updateMixedPaymentAmounts(value, true),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _transferAmountController,
            decoration: const InputDecoration(
              labelText: 'Monto por transferencia',
              prefixText: 'S/. ',
              border: OutlineInputBorder(),
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
              if (transferAmount > expectedAmount) {
                return 'El monto no puede ser mayor a S/. ${expectedAmount.toStringAsFixed(2)}';
              }

              // Validar que la suma de ambos montos sea igual al monto esperado
              final cashAmount =
                  double.tryParse(_cashAmountController.text) ?? 0.0;
              final totalAmount = cashAmount + transferAmount;
              if ((totalAmount - expectedAmount).abs() > 0.01) {
                return 'La suma debe ser S/. ${expectedAmount.toStringAsFixed(2)}';
              }
              return null;
            },
            onChanged: (value) => _updateMixedPaymentAmounts(value, false),
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
                    const Text('Efectivo:',
                        style: TextStyle(color: Colors.grey)),
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
                    const Text('Transferencia:',
                        style: TextStyle(color: Colors.grey)),
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
                    const Text(
                      'Total:',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
              if ((amount - expectedAmount).abs() > 0.01) {
                return 'El monto debe ser S/. ${expectedAmount.toStringAsFixed(2)}';
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
}
