import 'package:flutter/material.dart';
import 'package:yatha_app/src/services/pago_service.dart';

class PagoWidget extends StatefulWidget {
  final int clienteId;
  final double montoDiario;

  const PagoWidget({
    Key? key,
    required this.clienteId,
    required this.montoDiario,
  }) : super(key: key);

  @override
  _PagoWidgetState createState() => _PagoWidgetState();
}

class _PagoWidgetState extends State<PagoWidget> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  String _metodoPago = 'Efectivo';
  bool _isLoading = false;
  final _pagoService = PagoService();

  @override
  void initState() {
    super.initState();
    _montoController.text = widget.montoDiario.toString();
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(BuildContext context, String mensaje, bool esError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Cerrar',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _realizarPago() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final monto = double.parse(_montoController.text);
      debugPrint('=== INICIANDO PROCESO DE PAGO ===');
      debugPrint('Cliente ID: ${widget.clienteId}');
      debugPrint('Monto: S/ $monto');
      debugPrint('Método: $_metodoPago');

      final resultado = await _pagoService.realizarPagoDiario(
        widget.clienteId,
        monto,
        _metodoPago,
      );

      debugPrint('=== RESULTADO DEL PAGO ===');
      debugPrint('Resultado: $resultado');

      if (mounted) {
        if (resultado['success'] == true) {
          _mostrarMensaje(
            context,
            resultado['message'] ?? 'Pago realizado con éxito',
            false,
          );
          Navigator.of(context).pop(true);
        } else {
          _mostrarMensaje(
            context,
            resultado['message']?.toString() ?? 'Error al realizar el pago',
            true,
          );
        }
      }
    } catch (e) {
      debugPrint('=== ERROR EN EL PAGO ===');
      debugPrint('Error: $e');
      if (mounted) {
        _mostrarMensaje(context, e.toString(), true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto a pagar',
                prefixText: 'S/ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el monto a pagar';
                }
                final monto = double.tryParse(value);
                if (monto == null) {
                  return 'Ingrese un monto válido';
                }
                if (monto <= 0) {
                  return 'El monto debe ser mayor a 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _metodoPago,
              decoration: const InputDecoration(
                labelText: 'Método de pago',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                DropdownMenuItem(
                  value: 'Transferencia',
                  child: Text('Transferencia'),
                ),
                DropdownMenuItem(value: 'Yape', child: Text('Yape')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _metodoPago = value);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Seleccione un método de pago';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _realizarPago,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Realizar Pago'),
            ),
          ],
        ),
      ),
    );
  }
}

class PagoScreen extends StatelessWidget {
  final int clienteId;
  final double montoDiario;

  PagoScreen({required this.clienteId, required this.montoDiario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Realizar Pago')),
      body: PagoWidget(clienteId: clienteId, montoDiario: montoDiario),
    );
  }
}
