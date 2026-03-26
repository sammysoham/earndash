import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/notifications/local_notifications_service.dart';
import '../../admin/presentation/admin_page.dart';
import '../../auth/logic/auth_controller.dart';
import '../../wallet/presentation/wallet_page.dart';

class WithdrawalsPage extends ConsumerStatefulWidget {
  const WithdrawalsPage({super.key});

  @override
  ConsumerState<WithdrawalsPage> createState() => _WithdrawalsPageState();
}

class _WithdrawalsPageState extends ConsumerState<WithdrawalsPage> {
  final _destinationController = TextEditingController(text: 'demo@paypal.test');
  final _coinsController = TextEditingController(text: '5000');
  String _method = 'PAYPAL';
  bool _submitting = false;

  @override
  void dispose() {
    _destinationController.dispose();
    _coinsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdrawals')),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF101A1D),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Request payout', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Minimum: 5,000 coins. New users are capped at 20,000 coins per day.'),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _method,
                  decoration: const InputDecoration(labelText: 'Method'),
                  items: const [
                    DropdownMenuItem(value: 'PAYPAL', child: Text('PayPal')),
                    DropdownMenuItem(value: 'USDT', child: Text('USDT')),
                    DropdownMenuItem(value: 'GIFT_CARD', child: Text('Gift card')),
                  ],
                  onChanged: (value) => setState(() => _method = value ?? 'PAYPAL'),
                ),
                const SizedBox(height: 16),
                TextField(controller: _destinationController, decoration: const InputDecoration(labelText: 'Destination')),
                const SizedBox(height: 16),
                TextField(controller: _coinsController, decoration: const InputDecoration(labelText: 'Coins'), keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _submitting
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _submitting = true);
                          try {
                            await ref.read(apiClientProvider).requestWithdrawal(
                                  method: _method,
                                  destination: _destinationController.text,
                                  coins: int.parse(_coinsController.text),
                                );
                            ref.invalidate(walletProvider);
                            ref.invalidate(adminMetricsProvider);
                            if (!mounted) return;
                            await LocalNotificationsService.instance
                                .showWithdrawalSubmitted(
                              int.parse(_coinsController.text),
                            );
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Withdrawal submitted for admin review')),
                            );
                          } catch (error) {
                            if (!mounted) return;
                            messenger.showSnackBar(SnackBar(content: Text('$error')));
                          } finally {
                            if (mounted) {
                              setState(() => _submitting = false);
                            }
                          }
                        },
                  child: const Text('Submit withdrawal'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF101A1D),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Conversion', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                SizedBox(height: 12),
                Text('1,000 coins = 1 USD'),
                SizedBox(height: 8),
                Text('5,000 coins = 5 USD minimum payout'),
                SizedBox(height: 8),
                Text('20,000 coins = 20 USD new user daily cap'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
