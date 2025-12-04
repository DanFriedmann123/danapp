import 'package:flutter/material.dart';
import '../services/currency_service.dart';
import '../config/finance_theme.dart';

class CurrencyConverter extends StatefulWidget {
  final double amount;
  final String fromCurrency;
  final String toCurrency;
  final Function(double)? onConverted;
  final bool showConvertButton;

  const CurrencyConverter({
    super.key,
    required this.amount,
    required this.fromCurrency,
    required this.toCurrency,
    this.onConverted,
    this.showConvertButton = true,
  });

  @override
  State<CurrencyConverter> createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  double? _convertedAmount;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _convertCurrency();
  }

  @override
  void didUpdateWidget(CurrencyConverter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount ||
        oldWidget.fromCurrency != widget.fromCurrency ||
        oldWidget.toCurrency != widget.toCurrency) {
      _convertCurrency();
    }
  }

  Future<void> _convertCurrency() async {
    if (widget.fromCurrency == widget.toCurrency) {
      setState(() {
        _convertedAmount = widget.amount;
        _isLoading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final converted = await CurrencyService.convertCurrency(
        widget.amount,
        widget.fromCurrency,
        widget.toCurrency,
      );

      setState(() {
        _convertedAmount = converted;
        _isLoading = false;
      });

      widget.onConverted?.call(converted);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: FinanceTheme.cardPadding,
      decoration: FinanceTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Currency Converter', style: FinanceTheme.headingSmall),
          SizedBox(height: FinanceTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Original Amount', style: FinanceTheme.bodySmall),
                    Text(
                      CurrencyService.formatCurrency(
                        widget.amount,
                        widget.fromCurrency,
                      ),
                      style: FinanceTheme.valueMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: FinanceTheme.primaryColor),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Converted Amount', style: FinanceTheme.bodySmall),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (_error != null)
                      Text(
                        'Error',
                        style: FinanceTheme.bodySmall.copyWith(
                          color: FinanceTheme.dangerColor,
                        ),
                      )
                    else
                      Text(
                        CurrencyService.formatCurrency(
                          _convertedAmount ?? 0.0,
                          widget.toCurrency,
                        ),
                        style: FinanceTheme.valueMedium,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            SizedBox(height: FinanceTheme.spacingS),
            Text(
              _error!,
              style: FinanceTheme.bodySmall.copyWith(
                color: FinanceTheme.dangerColor,
              ),
            ),
          ],
          if (widget.showConvertButton && _error != null) ...[
            SizedBox(height: FinanceTheme.spacingM),
            ElevatedButton(
              onPressed: _convertCurrency,
              style: FinanceTheme.primaryButtonStyle,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class CurrencySelector extends StatefulWidget {
  final String selectedCurrency;
  final Function(String) onCurrencyChanged;
  final String? label;

  const CurrencySelector({
    super.key,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    this.label,
  });

  @override
  State<CurrencySelector> createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends State<CurrencySelector> {
  @override
  Widget build(BuildContext context) {
    final currencies = CurrencyService.getSupportedCurrencies();
    final currencyNames = CurrencyService.getCurrencyNames();

    return DropdownButtonFormField<String>(
      value: widget.selectedCurrency,
      decoration: FinanceTheme.inputDecoration.copyWith(
        labelText: widget.label ?? 'Currency',
      ),
      items: currencies.map((currency) {
        final name = currencyNames[currency] ?? currency;
        return DropdownMenuItem(
          value: currency,
          child: Text(
            '$currency - $name',
            style: FinanceTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          widget.onCurrencyChanged(value);
        }
      },
      isExpanded: true,
    );
  }
}
