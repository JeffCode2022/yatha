class Loan {
  final String id;
  final String clientName;
  final String clientPhone;
  final String loanNumber;
  final double amount;
  final int term;
  final String status;
  final List<Installment> installments;

  Loan({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    required this.loanNumber,
    required this.amount,
    required this.term,
    required this.status,
    required this.installments,
  });
}

class Installment {
  final int id;
  final String dueDate;
  final double amount;
  final String status;

  Installment({
    required this.id,
    required this.dueDate,
    required this.amount,
    required this.status,
  });
}

