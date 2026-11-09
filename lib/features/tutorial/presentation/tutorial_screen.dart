import 'package:flutter/material.dart';

import 'package:keepinventory/l10n/app_localizations_ext.dart';

import '../../../core/services/app_preferences.dart';
import '../../../core/shared_widgets/app_ui.dart';

/// Tutorial de bienvenida: carrusel de pasos que se muestra en el primer
/// arranque y que se puede volver a abrir desde el menú lateral.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialStep {
  const _TutorialStep(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_TutorialStep> _steps(BuildContext context) {
    final l10n = context.l10n;
    return [
      _TutorialStep(
        Icons.storefront,
        l10n.tutorialWelcomeTitle,
        l10n.tutorialWelcomeBody,
      ),
      _TutorialStep(
        Icons.inventory_2_outlined,
        l10n.tutorialInventoryTitle,
        l10n.tutorialInventoryBody,
      ),
      _TutorialStep(
        Icons.local_offer_outlined,
        l10n.tutorialOffersTitle,
        l10n.tutorialOffersBody,
      ),
      _TutorialStep(
        Icons.point_of_sale_outlined,
        l10n.tutorialSalesTitle,
        l10n.tutorialSalesBody,
      ),
      _TutorialStep(
        Icons.receipt_long_outlined,
        l10n.tutorialHistoryTitle,
        l10n.tutorialHistoryBody,
      ),
      _TutorialStep(
        Icons.home_outlined,
        l10n.tutorialDashboardTitle,
        l10n.tutorialDashboardBody,
      ),
      _TutorialStep(
        Icons.storage_outlined,
        l10n.tutorialDataTitle,
        l10n.tutorialDataBody,
      ),
    ];
  }

  /// Marca el tutorial como visto y vuelve atrás; si es el primer arranque
  /// (no hay pantalla debajo) va al panel principal.
  Future<void> _finish() async {
    await AppPreferences.markTutorialSeen();
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed('/');
    }
  }

  void _goTo(int page) => _controller.animateToPage(
    page,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    final steps = _steps(context);
    final isLast = _page == steps.length - 1;
    final colors = Theme.of(context).colorScheme;
    final pagePadding = AppSpacing.page(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: AnimatedOpacity(
                    opacity: isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: isLast ? null : _finish,
                      child: Text(context.l10n.tutorialSkip),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: steps.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) =>
                      _StepPage(step: steps[index], padding: pagePadding),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < steps.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? colors.primary
                              : colors.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  pagePadding,
                  0,
                  pagePadding,
                  AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    if (_page > 0)
                      TextButton(
                        onPressed: () => _goTo(_page - 1),
                        child: Text(context.l10n.tutorialBack),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: isLast ? _finish : () => _goTo(_page + 1),
                      child: Text(
                        isLast
                            ? context.l10n.tutorialStart
                            : context.l10n.tutorialNext,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  const _StepPage({required this.step, required this.padding});

  final _TutorialStep step;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconBadge(step.icon, size: 56),
              const SizedBox(height: AppSpacing.xl),
              Text(
                step.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                step.body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
