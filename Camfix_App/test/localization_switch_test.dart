import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camfix_app/app_settings.dart';
import 'package:camfix_app/l10n/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Language switch between English and Khmer for Common Fixes & Fast Booking', () async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();

    // 1. English by default
    AppSettings.instance.setLang(AppLang.en);
    expect(AppSettings.instance.lang, AppLang.en);
    expect(AppStrings.t('commonFixesFastBooking'), 'Common Fixes & Fast Booking');
    expect(AppStrings.t('instantEstimates'), 'Instant Estimates');
    expect(AppStrings.t('categories'), 'Categories');
    expect(AppStrings.t('popularServices'), 'Popular Services');
    expect(AppStrings.t('book'), 'Book');
    expect(AppStrings.t('startingPrice'), 'STARTING');
    expect(AppStrings.t('leakingPipeRepair'), 'Leaking Pipe Repair');
    expect(AppStrings.t('acRefrigerantRecharge'), 'AC Refrigerant Recharge');
    expect(AppStrings.t('circuitBreakerTripping'), 'Circuit Breaker Tripping');
    expect(AppStrings.t('drainUnclogging'), 'Drain Unclogging');

    // 2. Switch to Khmer
    AppSettings.instance.setLang(AppLang.km);
    expect(AppSettings.instance.lang, AppLang.km);
    expect(AppStrings.t('commonFixesFastBooking'), 'ការជួសជុលទូទៅ និងការកក់រហ័ស');
    expect(AppStrings.t('instantEstimates'), 'ការប៉ាន់ស្មានតម្លៃភ្លាមៗ');
    expect(AppStrings.t('categories'), 'ប្រភេទសេវាកម្ម');
    expect(AppStrings.t('popularServices'), 'សេវាកម្មពេញនិយម');
    expect(AppStrings.t('book'), 'កក់');
    expect(AppStrings.t('startingPrice'), 'ចាប់ផ្ដើមពី');
    expect(AppStrings.t('leakingPipeRepair'), 'ជួសជុលបំពង់ទឹកលិច');
    expect(AppStrings.t('acRefrigerantRecharge'), 'បញ្ចូលហ្គាសម៉ាស៊ីនត្រជាក់');
    expect(AppStrings.t('circuitBreakerTripping'), 'ដោះស្រាយបញ្ហាដាច់ចរន្តអគ្គិសនី');
    expect(AppStrings.t('drainUnclogging'), 'បូម ឬបង្ហូរស្ទះលូទឹក');

    // 3. Switch back to English
    AppSettings.instance.setLang(AppLang.en);
    expect(AppSettings.instance.lang, AppLang.en);
    expect(AppStrings.t('commonFixesFastBooking'), 'Common Fixes & Fast Booking');
    expect(AppStrings.t('instantEstimates'), 'Instant Estimates');
  });
}

