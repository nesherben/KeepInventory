import 'package:flutter/material.dart';

class SalesLandscapeCartPanel extends StatelessWidget {
  const SalesLandscapeCartPanel({
    super.key,
    required this.itemCountLabel,
    required this.totalSummary,
    required this.cartItems,
    required this.paymentMethodSelector,
    required this.checkoutButton,
  });

  final String itemCountLabel;
  final Widget totalSummary;
  final Widget cartItems;
  final Widget paymentMethodSelector;
  final Widget checkoutButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  itemCountLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                totalSummary,
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: cartItems),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: paymentMethodSelector,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: SizedBox(width: double.infinity, child: checkoutButton),
          ),
        ],
      ),
    );
  }
}
