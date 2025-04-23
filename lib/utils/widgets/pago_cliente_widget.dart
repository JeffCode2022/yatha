import 'package:flutter/material.dart';
import '../../src/services/pago_service.dart';

class PagoClienteWidget extends StatefulWidget {
  final int clienteId;

  const PagoClienteWidget({Key? key, required this.clienteId})
    : super(key: key);

  @override
  State<PagoClienteWidget> createState() => _PagoClienteWidgetState();
}

class _PagoClienteWidgetState extends State<PagoClienteWidget> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _pagoService = PagoService();
  String _selectedMetodo = 'cash';
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  final List<String> _metodosPago = ['cash', 'BBVA', 'BCP'];

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _realizarPago() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final monto = double.parse(_montoController.text);
      final mensaje = await _pagoService.realizarPagoDiario(
        widget.clienteId,
        monto,
        _selectedMetodo,
      );

      setState(() {
        _successMessage = mensaje['message'];
        _montoController.clear();
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(
                  labelText: 'Monto a pagar',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el monto';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un monto válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMetodo,
                decoration: const InputDecoration(
                  labelText: 'Método de pago',
                  border: OutlineInputBorder(),
                ),
                items:
                    _metodosPago.map((metodo) {
                      return DropdownMenuItem(
                        value: metodo,
                        child: Text(metodo.toUpperCase()),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMetodo = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _realizarPago,
                  child: const Text('Realizar Pago'),
                ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_successMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
