import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/withdrawal_request.dart';
import '../../../core/notifications/local_notifications_service.dart';
import '../../admin/presentation/admin_page.dart';
import '../../auth/logic/auth_controller.dart';
import '../../wallet/presentation/wallet_page.dart';

final withdrawalsProvider = FutureProvider<List<WithdrawalRequestModel>>((ref) {
  return ref.read(apiClientProvider).getWithdrawals();
});

class WithdrawalsPage extends ConsumerStatefulWidget {
  const WithdrawalsPage({super.key});

  @override
  ConsumerState<WithdrawalsPage> createState() => _WithdrawalsPageState();
}

class _WithdrawalsPageState extends ConsumerState<WithdrawalsPage> {
  final _destinationController =
      TextEditingController(text: 'example@paypal.com');
  final _coinsController =
      TextEditingController(text: '${AppConstants.minWithdrawalCoins}');
  String _method = 'PAYPAL';
  String _usdtNetwork = 'TRC20';
  bool _submitting = false;

  static const _destinationExamples = <String, String>{
    'PAYPAL': 'example@paypal.com',
    'UPI': 'name@okicici',
    'SKRILL': 'example@skrill.com',
    'BANK_TRANSFER': '1234567890 / HDFC0000123',
    'USDT': 'TY8zQdemoWalletAddress123',
    'GIFT_CARD': 'Amazon India / Steam / Google Play',
  };

  static const _destinationLabels = <String, String>{
    'PAYPAL': 'PayPal email',
    'UPI': 'UPI ID',
    'SKRILL': 'Skrill email',
    'BANK_TRANSFER': 'Bank details',
    'USDT': 'USDT wallet address',
    'GIFT_CARD': 'Gift card preference',
  };

  static const _destinationHints = <String, String>{
    'PAYPAL': 'Example: example@paypal.com',
    'UPI': 'Example: name@okicici',
    'SKRILL': 'Example: example@skrill.com',
    'BANK_TRANSFER': 'Example: 1234567890 / HDFC0000123',
    'USDT': 'Paste the wallet address that matches your selected network.',
    'GIFT_CARD': 'Example: Amazon India, Flipkart, Steam, or Google Play',
  };

  @override
  void dispose() {
    _destinationController.dispose();
    _coinsController.dispose();
    super.dispose();
  }

  void _updateMethod(String method) {
    setState(() {
      _method = method;
      _destinationController.text = _destinationExamples[method] ?? '';
      if (method != 'USDT') {
        _usdtNetwork = 'TRC20';
      }
    });
  }

  String _buildDestinationPayload() {
    if (_method == 'USDT') {
      return '$_usdtNetwork:${_destinationController.text.trim()}';
    }
    return _destinationController.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final destinationLabel = _destinationLabels[_method] ?? 'Destination';
    final destinationHint = _destinationHints[_method] ?? '';
    final requests = ref.watch(withdrawalsProvider);

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
                const Text('Request payout',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'Minimum: ${AppConstants.minWithdrawalCoins} coins. New users are capped at ${AppConstants.newUserDailyWithdrawalCapCoins} coins per day.',
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _method,
                  decoration: const InputDecoration(labelText: 'Method'),
                  items: const [
                    DropdownMenuItem(value: 'PAYPAL', child: Text('PayPal')),
                    DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                    DropdownMenuItem(value: 'SKRILL', child: Text('Skrill')),
                    DropdownMenuItem(
                        value: 'BANK_TRANSFER', child: Text('Bank transfer')),
                    DropdownMenuItem(value: 'USDT', child: Text('USDT')),
                    DropdownMenuItem(
                        value: 'GIFT_CARD', child: Text('Gift card')),
                  ],
                  onChanged: (value) => _updateMethod(value ?? 'PAYPAL'),
                ),
                if (_method == 'USDT') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _usdtNetwork,
                    decoration:
                        const InputDecoration(labelText: 'USDT network'),
                    items: const [
                      DropdownMenuItem(value: 'TRC20', child: Text('TRC20')),
                      DropdownMenuItem(value: 'ERC20', child: Text('ERC20')),
                      DropdownMenuItem(value: 'BEP20', child: Text('BEP20')),
                      DropdownMenuItem(value: 'SOL', child: Text('SOL')),
                    ],
                    onChanged: (value) =>
                        setState(() => _usdtNetwork = value ?? 'TRC20'),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    labelText: destinationLabel,
                    hintText: _destinationExamples[_method],
                    helperText: destinationHint,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                    controller: _coinsController,
                    decoration: const InputDecoration(labelText: 'Coins'),
                    keyboardType: TextInputType.number),
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
                                  destination: _buildDestinationPayload(),
                                  coins: int.parse(_coinsController.text),
                                );
                            ref.invalidate(walletProvider);
                            ref.invalidate(withdrawalsProvider);
                            ref.invalidate(adminMetricsProvider);
                            if (!mounted) return;
                            await LocalNotificationsService.instance
                                .showWithdrawalSubmitted(
                              int.parse(_coinsController.text),
                            );
                            messenger.showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Withdrawal submitted for admin review')),
                            );
                          } catch (error) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  error
                                      .toString()
                                      .replaceFirst('Exception: ', ''),
                                ),
                              ),
                            );
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your requests',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                requests.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Text(
                        'You have not submitted any withdrawals yet.',
                        style: TextStyle(color: Color(0xFF9CB1AA)),
                      );
                    }

                    return Column(
                      children: [
                        for (var index = 0; index < items.length; index++) ...[
                          _WithdrawalRequestTile(item: items[index]),
                          if (index != items.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text(
                    error.toString().replaceFirst('Exception: ', ''),
                    style: const TextStyle(color: Color(0xFFFF8E8E)),
                  ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Conversion',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text('${AppConstants.coinsPerDollar} coins = 1 USD'),
                const SizedBox(height: 8),
                Text(
                    '${AppConstants.minWithdrawalCoins} coins = 5 USD minimum payout'),
                const SizedBox(height: 8),
                Text(
                    '${AppConstants.newUserDailyWithdrawalCapCoins} coins = 20 USD new user daily cap'),
                const SizedBox(height: 8),
                Text(
                  'Approved earnings stay pending for ${AppConstants.pendingRewardHoldDays} days before they become withdrawable.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawalRequestTile extends StatelessWidget {
  const _WithdrawalRequestTile({required this.item});

  final WithdrawalRequestModel item;

  Color get _statusColor => switch (item.status) {
        'PAID' => const Color(0xFF5BFF9D),
        'APPROVED' => const Color(0xFF7CFFB2),
        'REJECTED' => const Color(0xFFFF8E8E),
        _ => const Color(0xFFFFD66E),
      };

  String get _statusLabel => item.status.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D171B),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${item.coins} coins',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                      color: _statusColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${item.method} • ${item.destination}',
            style: const TextStyle(color: Color(0xFF9CB1AA)),
          ),
          const SizedBox(height: 6),
          Text(
            'Requested on ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
            style: const TextStyle(color: Color(0xFF7E9790)),
          ),
          if (item.note != null && item.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.note!,
              style: const TextStyle(color: Color(0xFF8FD9AE)),
            ),
          ],
        ],
      ),
    );
  }
}
