import 'package:flutter/material.dart';
import 'package:kivixa/services/terms_and_conditions_service.dart';

/// A dialog that displays Terms and Conditions for first-time users
class TermsAndConditionsDialog extends StatefulWidget {
  const TermsAndConditionsDialog({super.key});

  /// Shows the Terms and Conditions dialog if the user hasn't accepted them yet
  /// Returns true if terms were already accepted or just accepted
  /// Returns false if user declined (though this prevents app usage)
  static Future<bool> showIfNeeded(BuildContext context) async {
    final hasAccepted = await TermsAndConditionsService.hasAcceptedTerms();

    if (hasAccepted) {
      return true;
    }

    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const TermsAndConditionsDialog(),
    );

    return result ?? false;
  }

  @override
  State<TermsAndConditionsDialog> createState() =>
      _TermsAndConditionsDialogState();
}

class _TermsAndConditionsDialogState extends State<TermsAndConditionsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  var _hasReadTerms = false;
  var _hasReadPrivacy = false;
  var _agreedToTerms = false;
  var _agreedToPrivacy = false;
  final _termsScrollController = ScrollController();
  final _privacyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Track if user has scrolled to the bottom of each document
    _termsScrollController.addListener(_checkTermsScroll);
    _privacyScrollController.addListener(_checkPrivacyScroll);
  }

  void _checkTermsScroll() {
    if (_termsScrollController.position.pixels >=
        _termsScrollController.position.maxScrollExtent - 50) {
      if (!_hasReadTerms) {
        setState(() => _hasReadTerms = true);
      }
    }
  }

  void _checkPrivacyScroll() {
    if (_privacyScrollController.position.pixels >=
        _privacyScrollController.position.maxScrollExtent - 50) {
      if (!_hasReadPrivacy) {
        setState(() => _hasReadPrivacy = true);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _termsScrollController.dispose();
    _privacyScrollController.dispose();
    super.dispose();
  }

  bool get _canAccept => _agreedToTerms && _agreedToPrivacy;

  Future<void> _handleAccept() async {
    await TermsAndConditionsService.acceptTerms();
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: size.height * 0.85,
          minWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      width: 64,
                      height: 64,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome to Kivixa',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please read and accept our Terms and Privacy Policy',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.8,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Tab bar
            TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              tabs: [
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gavel, size: 18),
                      const SizedBox(width: 8),
                      const Text('Terms & Conditions'),
                      if (_hasReadTerms) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green.shade600,
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.privacy_tip_outlined, size: 18),
                      const SizedBox(width: 8),
                      const Text('Privacy Policy'),
                      if (_hasReadPrivacy) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green.shade600,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Terms tab
                  _buildScrollableContent(
                    controller: _termsScrollController,
                    content: TermsAndConditionsService.getTermsText(),
                    hasRead: _hasReadTerms,
                  ),
                  // Privacy tab
                  _buildScrollableContent(
                    controller: _privacyScrollController,
                    content: TermsAndConditionsService.getPrivacyPolicyText(),
                    hasRead: _hasReadPrivacy,
                  ),
                ],
              ),
            ),

            // Agreement checkboxes
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() => _agreedToTerms = value ?? false);
                    },
                    title: const Text(
                      'I have read and agree to the Terms and Conditions',
                      style: TextStyle(fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: colorScheme.primary,
                  ),
                  CheckboxListTile(
                    value: _agreedToPrivacy,
                    onChanged: (value) {
                      setState(() => _agreedToPrivacy = value ?? false);
                    },
                    title: const Text(
                      'I have read and agree to the Privacy Policy',
                      style: TextStyle(fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: colorScheme.primary,
                  ),
                ],
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Decline button - exits the app or shows a message
                  TextButton(
                    onPressed: () => _showDeclineDialog(context),
                    child: Text(
                      'Decline',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Accept button
                  FilledButton.icon(
                    onPressed: _canAccept ? _handleAccept : null,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('I Agree'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableContent({
    required ScrollController controller,
    required String content,
    required bool hasRead,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: SelectableText(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ),
        // Scroll indicator if not read yet
        if (!hasRead)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface.withValues(alpha: 0),
                    colorScheme.surface,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        size: 16,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Scroll to read',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showDeclineDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: colorScheme.error,
          size: 48,
        ),
        title: const Text('Cannot Continue Without Agreement'),
        content: const Text(
          'You must accept the Terms and Conditions and Privacy Policy to use Kivixa.\n\n'
          'If you decline, the app cannot be used.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
