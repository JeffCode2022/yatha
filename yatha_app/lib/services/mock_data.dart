import '../models/loan.dart';
import '../models/gestor.dart';

class MockData {
  // Mock loans data
  static Map<String, Loan> loansData = {
    "1": Loan(
      id: "1",
      clientName: "Juan Pérez",
      clientPhone: "+123456789",
      loanNumber: "12345",
      amount: 1500,
      term: 10,
      status: "Al día",
      installments: [
        Installment(id: 1, dueDate: "2023-01-15", amount: 150, status: "Pagada"),
        Installment(id: 2, dueDate: "2023-02-15", amount: 150, status: "Pagada"),
        Installment(id: 3, dueDate: "2023-03-15", amount: 150, status: "Pagada"),
        Installment(id: 4, dueDate: "2023-04-15", amount: 150, status: "Pendiente"),
        Installment(id: 5, dueDate: "2023-05-15", amount: 150, status: "Pendiente"),
        Installment(id: 6, dueDate: "2023-06-15", amount: 150, status: "Pendiente"),
        Installment(id: 7, dueDate: "2023-07-15", amount: 150, status: "Pendiente"),
        Installment(id: 8, dueDate: "2023-08-15", amount: 150, status: "Pendiente"),
        Installment(id: 9, dueDate: "2023-09-15", amount: 150, status: "Pendiente"),
        Installment(id: 10, dueDate: "2023-10-15", amount: 150, status: "Pendiente"),
      ],
    ),
    "2": Loan(
      id: "2",
      clientName: "María López",
      clientPhone: "+987654321",
      loanNumber: "12346",
      amount: 2000,
      term: 10,
      status: "Vencido",
      installments: [
        Installment(id: 1, dueDate: "2023-01-15", amount: 200, status: "Pagada"),
        Installment(id: 2, dueDate: "2023-02-15", amount: 200, status: "Pagada"),
        Installment(id: 3, dueDate: "2023-03-15", amount: 200, status: "Vencida"),
        Installment(id: 4, dueDate: "2023-04-15", amount: 200, status: "Pendiente"),
        Installment(id: 5, dueDate: "2023-05-15", amount: 200, status: "Pendiente"),
        Installment(id: 6, dueDate: "2023-06-15", amount: 200, status: "Pendiente"),
        Installment(id: 7, dueDate: "2023-07-15", amount: 200, status: "Pendiente"),
        Installment(id: 8, dueDate: "2023-08-15", amount: 200, status: "Pendiente"),
        Installment(id: 9, dueDate: "2023-09-15", amount: 200, status: "Pendiente"),
        Installment(id: 10, dueDate: "2023-10-15", amount: 200, status: "Pendiente"),
      ],
    ),
    "3": Loan(
      id: "3",
      clientName: "Carlos Rodríguez",
      clientPhone: "+555555555",
      loanNumber: "12347",
      amount: 1750,
      term: 10,
      status: "Pendiente",
      installments: [
        Installment(id: 1, dueDate: "2023-01-15", amount: 175, status: "Pagada"),
        Installment(id: 2, dueDate: "2023-02-15", amount: 175, status: "Pagada"),
        Installment(id: 3, dueDate: "2023-03-15", amount: 175, status: "Pagada"),
        Installment(id: 4, dueDate: "2023-04-15", amount: 175, status: "Pagada"),
        Installment(id: 5, dueDate: "2023-05-15", amount: 175, status: "Pendiente"),
        Installment(id: 6, dueDate: "2023-06-15", amount: 175, status: "Pendiente"),
        Installment(id: 7, dueDate: "2023-07-15", amount: 175, status: "Pendiente"),
        Installment(id: 8, dueDate: "2023-08-15", amount: 175, status: "Pendiente"),
        Installment(id: 9, dueDate: "2023-09-15", amount: 175, status: "Pendiente"),
        Installment(id: 10, dueDate: "2023-10-15", amount: 175, status: "Pendiente"),
      ],
    ),
  };

  // Mock gestores data
  static Map<String, Gestor> gestoresData = {
    "1": Gestor(
      id: "1",
      name: "Roberto Gómez",
      totalCobros: 45,
      cobrosRealizados: 38,
      porcentajeAvance: 84,
      clientes: [
        Cliente(id: 1, name: "Juan Pérez", prestamos: 3, cobrosHoy: 1, estado: "Al día"),
        Cliente(id: 2, name: "Ana García", prestamos: 2, cobrosHoy: 1, estado: "Al día"),
        Cliente(id: 3, name: "Luis Torres", prestamos: 1, cobrosHoy: 0, estado: "Vencido"),
        Cliente(id: 4, name: "Carmen Ruiz", prestamos: 2, cobrosHoy: 1, estado: "Pendiente"),
      ],
    ),
    "2": Gestor(
      id: "2",
      name: "Ana Martínez",
      totalCobros: 52,
      cobrosRealizados: 40,
      porcentajeAvance: 77,
      clientes: [
        Cliente(id: 1, name: "Pedro Sánchez", prestamos: 2, cobrosHoy: 1, estado: "Al día"),
        Cliente(id: 2, name: "María Rodríguez", prestamos: 3, cobrosHoy: 2, estado: "Al día"),
        Cliente(id: 3, name: "José López", prestamos: 1, cobrosHoy: 0, estado: "Vencido"),
        Cliente(id: 4, name: "Laura Martín", prestamos: 2, cobrosHoy: 1, estado: "Pendiente"),
      ],
    ),
    "3": Gestor(
      id: "3",
      name: "Luis Hernández",
      totalCobros: 38,
      cobrosRealizados: 35,
      porcentajeAvance: 92,
      clientes: [
        Cliente(id: 1, name: "Carlos Jiménez", prestamos: 1, cobrosHoy: 1, estado: "Al día"),
        Cliente(id: 2, name: "Sofía Moreno", prestamos: 2, cobrosHoy: 2, estado: "Al día"),
        Cliente(id: 3, name: "Antonio Díaz", prestamos: 1, cobrosHoy: 1, estado: "Al día"),
        Cliente(id: 4, name: "Elena Muñoz", prestamos: 2, cobrosHoy: 1, estado: "Pendiente"),
      ],
    ),
    "4": Gestor(
      id: "4",
      name: "Carmen Sánchez",
      totalCobros: 41,
      cobrosRealizados: 28,
      porcentajeAvance: 68,
      clientes: [
        Cliente(id: 1, name: "Miguel Álvarez", prestamos: 2, cobrosHoy: 1, estado: "Al día"),
        Cliente(id: 2, name: "Lucía Romero", prestamos: 1, cobrosHoy: 0, estado: "Vencido"),
        Cliente(id: 3, name: "Javier Gil", prestamos: 3, cobrosHoy: 1, estado: "Pendiente"),
        Cliente(id: 4, name: "Isabel Castro", prestamos: 2, cobrosHoy: 1, estado: "Al día"),
      ],
    ),
  };
}

