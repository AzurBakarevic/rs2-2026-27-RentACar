import '../models/seasonal_price.dart';
import 'base_provider.dart';

class SeasonalPriceProvider extends BaseProvider<SeasonalPrice> {
  SeasonalPriceProvider() : super('SeasonalPrices');

  @override
  SeasonalPrice fromJson(data) {
    return SeasonalPrice.fromJson(data);
  }
}
