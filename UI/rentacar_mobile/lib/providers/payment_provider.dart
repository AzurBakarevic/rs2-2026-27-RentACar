import '../models/payment_transaction.dart';
import 'base_provider.dart';

class PaymentProvider extends BaseProvider<PaymentTransaction> {
  PaymentProvider() : super('Payments');

  @override
  PaymentTransaction fromJson(data) {
    return PaymentTransaction.fromJson(data);
  }
}
