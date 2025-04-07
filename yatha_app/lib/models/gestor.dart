class Gestor {
  final String id;
  final String name;
  final int totalCobros;
  final int cobrosRealizados;
  final double porcentajeAvance;
  final List<Cliente> clientes;

  Gestor({
    required this.id,
    required this.name,
    required this.totalCobros,
    required this.cobrosRealizados,
    required this.porcentajeAvance,
    required this.clientes,
  });
}

class Cliente {
  final int id;
  final String name;
  final int prestamos;
  final int cobrosHoy;
  final String estado;

  Cliente({
    required this.id,
    required this.name,
    required this.prestamos,
    required this.cobrosHoy,
    required this.estado,
  });
}

