import 'package:flutter/material.dart';

class SalesCartSheet extends StatelessWidget {
  const SalesCartSheet({
    super.key,
    required this.controller,
    required this.minSize,
    required this.bodyHeight,
    required this.itemCountLabel,
    required this.hasAdjustment,
    required this.hasItems,
    required this.totalSummary,
    required this.cartItems,
    required this.paymentMethodSelector,
    required this.checkoutButton,
  });

  final DraggableScrollableController controller;
  final double minSize;
  final double bodyHeight;
  final String itemCountLabel;
  final bool hasAdjustment;
  final bool hasItems;
  final Widget totalSummary;
  final Widget cartItems;
  final Widget paymentMethodSelector;
  final Widget checkoutButton;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: minSize,
      minChildSize: minSize,
      maxChildSize: 0.7,
      builder: (context, scrollController) => LayoutBuilder(
        builder: (context, constraints) {
          final isExpanded = constraints.maxHeight > minSize * bodyHeight + 8;
          final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Stack(
                children: [
                  ListView(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      top: 75,
                      bottom: isExpanded && hasItems ? 170 + bottomInset : 20,
                    ),
                    children: [if (isExpanded) cartItems],
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Stack(
                      children: [
                        IgnorePointer(
                          child: Container(
                            color: Theme.of(context).cardColor,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 8),
                                Container(
                                  width: 40,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        itemCountLabel,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        height: hasAdjustment ? 54 : 40,
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                              ],
                            ),
                          ),
                        ),
                        Positioned(top: 25, right: 24, child: totalSummary),
                      ],
                    ),
                  ),
                  if (isExpanded && hasItems)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          16 + bottomInset,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            paymentMethodSelector,
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: checkoutButton,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
