import 'package:flutter/material.dart';
import '../config/finance_theme.dart';
import '../services/currency_service.dart';
import '../services/preferences_service.dart';
import '../widgets/currency_converter.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  String _baseCurrency = 'USD';
  String _targetCurrency = 'EUR';
  String _mainCurrency = 'USD';
  double _amount = 100.0;
  Map<String, double>? _exchangeRates;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMainCurrency();
    _loadExchangeRates();
  }

  Future<void> _loadMainCurrency() async {
    final mainCurrency = await PreferencesService.getMainCurrency();
    setState(() {
      _mainCurrency = mainCurrency;
    });
  }

  Future<void> _saveMainCurrency(String currency) async {
    await PreferencesService.setMainCurrency(currency);
    setState(() {
      _mainCurrency = currency;
    });
  }

  Future<void> _loadExchangeRates() async {
    print('🌐 [CurrencySettings] Loading exchange rates for $_baseCurrency');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rates = await CurrencyService.getExchangeRates(_baseCurrency);
      print(
        '✅ [CurrencySettings] Successfully loaded ${rates.length} exchange rates',
      );
      setState(() {
        _exchangeRates = rates;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [CurrencySettings] Error loading exchange rates: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _swapCurrencies() {
    print(
      '🔄 [CurrencySettings] Swapping currencies: $_baseCurrency ↔ $_targetCurrency',
    );
    setState(() {
      final temp = _baseCurrency;
      _baseCurrency = _targetCurrency;
      _targetCurrency = temp;
    });
    print(
      '✅ [CurrencySettings] Currencies swapped: $_baseCurrency ↔ $_targetCurrency',
    );
    _loadExchangeRates();
  }

  @override
  Widget build(BuildContext context) {
    final currencyNames = CurrencyService.getCurrencyNames();

    return Scaffold(
      appBar: AppBar(
        title: Text('Currency Settings', style: FinanceTheme.headingSmall),
        backgroundColor: FinanceTheme.primaryColor.withValues(alpha: 0.1),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: FinanceTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Currency Section
            Container(
              decoration: FinanceTheme.cardDecoration,
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Main Currency', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  CurrencySelector(
                    selectedCurrency: _mainCurrency,
                    onCurrencyChanged: _saveMainCurrency,
                    label: 'Your Main Currency',
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  Text(
                    'This currency will be used as the default for all financial calculations.',
                    style: FinanceTheme.bodySmall.copyWith(
                      color: FinanceTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: FinanceTheme.spacingL),

            // Currency Converter Section
            Container(
              decoration: FinanceTheme.cardDecoration,
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Currency Converter', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  Column(
                    children: [
                      CurrencySelector(
                        selectedCurrency: _baseCurrency,
                        onCurrencyChanged: (currency) {
                          setState(() {
                            _baseCurrency = currency;
                          });
                          _loadExchangeRates();
                        },
                        label: 'From Currency',
                      ),
                      SizedBox(height: FinanceTheme.spacingM),

                      // Swap currencies button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _swapCurrencies();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Swapped currencies: $_baseCurrency ↔ $_targetCurrency',
                                ),
                                backgroundColor: FinanceTheme.primaryColor,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: Icon(Icons.swap_horiz, color: Colors.white),
                          label: Text(
                            'Swap Currencies',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FinanceTheme.primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),

                      SizedBox(height: FinanceTheme.spacingM),
                      CurrencySelector(
                        selectedCurrency: _targetCurrency,
                        onCurrencyChanged: (currency) {
                          setState(() {
                            _targetCurrency = currency;
                          });
                        },
                        label: 'To Currency',
                      ),
                    ],
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: FinanceTheme.inputDecoration.copyWith(
                      labelText: 'Amount',
                      hintText: '100.00',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _amount = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                  SizedBox(height: FinanceTheme.spacingM),
                  CurrencyConverter(
                    amount: _amount,
                    fromCurrency: _baseCurrency,
                    toCurrency: _targetCurrency,
                    onConverted: (converted) {
                      // Handle conversion result if needed
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: FinanceTheme.spacingL),

            // Exchange Rates Section
            Container(
              decoration: FinanceTheme.cardDecoration,
              padding: FinanceTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Exchange Rates', style: FinanceTheme.headingSmall),
                  SizedBox(height: FinanceTheme.spacingM),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_error != null)
                    Text(
                      'Error: $_error',
                      style: FinanceTheme.bodyMedium.copyWith(
                        color: FinanceTheme.dangerColor,
                      ),
                    )
                  else if (_exchangeRates != null)
                    SizedBox(
                      height: 300, // Fixed height to prevent overflow
                      child: ListView.builder(
                        itemCount: _exchangeRates!.length,
                        itemBuilder: (context, index) {
                          final currency = _exchangeRates!.keys.elementAt(
                            index,
                          );
                          final rate = _exchangeRates![currency];
                          return ListTile(
                            leading: Icon(
                              Icons.currency_exchange,
                              color: FinanceTheme.primaryColor,
                            ),
                            title: Text(
                              currencyNames[currency] ?? currency,
                              style: FinanceTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              currency,
                              style: FinanceTheme.bodySmall,
                            ),
                            trailing: Text(
                              '${rate?.toStringAsFixed(4)}',
                              style: FinanceTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: FinanceTheme.spacingL),
          ],
        ),
      ),
    );
  }
}
