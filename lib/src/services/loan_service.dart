import 'package:yatha_app/src/config/environment.dart';
import 'package:yatha_app/src/services/base_service.dart';
import 'package:yatha_app/src/utils/logger.dart';

class LoanService extends BaseService {
  Future<List<Map<String, dynamic>>> getLoansByDate(
      DateTime startDate, DateTime endDate) async {
    try {
      final queryFilters = [
        ["partner_salesperson", "=", (await getCredentials())['uid']],
        ["create_date", ">=", startDate.toIso8601String()],
        ["create_date", "<=", endDate.toIso8601String()]
      ];

      final response = await executeOdooMethod(
        model: Environment.loanManagementModel,
        method: Environment.searchReadMethod,
        args: [queryFilters, _getLoanFields()],
      );

      if (response['result'] != null) {
        return List<Map<String, dynamic>>.from(response['result']);
      }
      return [];
    } catch (e) {
      Logger.error('Error en getLoansByDate', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLoanDetails(int loanId) async {
    try {
      final queryFilters = [
        ["id", "=", loanId],
        ["partner_salesperson", "=", (await getCredentials())['uid']]
      ];

      final response = await executeOdooMethod(
        model: Environment.loanManagementModel,
        method: Environment.searchReadMethod,
        args: [queryFilters, _getLoanFields()],
      );

      if (response['result'] != null && response['result'].isNotEmpty) {
        return response['result'][0];
      }
      return {};
    } catch (e) {
      Logger.error('Error en getLoanDetails', e);
      rethrow;
    }
  }

  Future<bool> updateLoanStatus(int loanId, String status) async {
    try {
      final response = await executeOdooMethod(
        model: Environment.loanManagementModel,
        method: Environment.writeMethod,
        args: [
          [loanId],
          {"loan_status": status}
        ],
      );

      return response['result'] == true;
    } catch (e) {
      Logger.error('Error en updateLoanStatus', e);
      rethrow;
    }
  }

  List<String> _getLoanFields() {
    return [
      "id",
      "name",
      "partner_salesperson",
      "loan_status",
      "loan_amount",
      "payment_period",
      "payment_parts",
      "amount_due_today",
      "total_amount",
      "current_due"
    ];
  }
}
