import 'package:finance_track/features/profile/currency/screens/currency_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/currency/currency_bloc.dart';
import '../bloc/currency/currency_event.dart';
import '../bloc/currency/currency_state.dart';
import '../../../../core/models/currency_model.dart';

/// Shows a beautiful currency selection dialog
Future<void> showCurrencySelectionDialog(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (context) => const CurrencySelectionDialog(),
    barrierDismissible: true,
  );
}

/// Legacy full screen currency selection - keeping for reference
/// Can be removed once dialog implementation is confirmed working
class CurrencySelectionScreen extends StatelessWidget {
  const CurrencySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Currency'),
        centerTitle: true,
      ),
      body: BlocBuilder<CurrencyBloc, CurrencyState>(
        builder: (context, state) {
          if (state is CurrencyLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CurrencyError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          } else if (state is CurrencyLoaded) {
            return _buildLegacyCurrencyList(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLegacyCurrencyList(BuildContext context, CurrencyLoaded state) {
    final theme = Theme.of(context);
    final selectedCurrency = state.selectedCurrency;

    return ListView.builder(
      itemCount: Currencies.all.length,
      itemBuilder: (context, index) {
        final currency = Currencies.all[index];
        final isSelected = currency.code == selectedCurrency.code;

        return ListTile(
          title: Text(
            currency.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            '${currency.code} (${currency.symbol})',
            style: theme.textTheme.bodyMedium,
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                )
              : null,
          onTap: () {
            if (!isSelected) {
              context.read<CurrencyBloc>().add(ChangeCurrency(currency));
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
  }
}
