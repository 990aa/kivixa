import 'package:flutter/material.dart';
import 'package:kivixa/services/terms_and_conditions_service.dart';

/// A dialog for viewing Terms and Conditions and Privacy Policy
/// This is a read-only version for users who have already accepted the terms.
class LegalDocumentsViewer extends StatefulWidget {
  const LegalDocumentsViewer({super.key, this.initialTab = 0});

  /// 0 for Terms & Conditions, 1 for Privacy Policy
  final int initialTab;

  /// Shows the legal documents viewer dialog
  static Future<void> show(BuildContext context, {int initialTab = 0}) async {
    await showDialog(
      context: context,
      builder: (context) => LegalDocumentsViewer(initialTab: initialTab),
    );
  }

  /// Shows Terms & Conditions
  static Future<void> showTerms(BuildContext context) =>
      show(context, initialTab: 0);

  /// Shows Privacy Policy
  static Future<void> showPrivacyPolicy(BuildContext context) =>
      show(context, initialTab: 1);

  @override
  State<LegalDocumentsViewer> createState() => _LegalDocumentsViewerState();
}

class _LegalDocumentsViewerState extends State<LegalDocumentsViewer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Legal Documents',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
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
              tabs: const [
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.gavel, size: 18),
                      SizedBox(width: 8),
                      Text('Terms & Conditions'),
                    ],
                  ),
                ),
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.privacy_tip_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Privacy Policy'),
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
                  _buildContent(TermsAndConditionsService.getTermsText()),
                  // Privacy tab
                  _buildContent(
                    TermsAndConditionsService.getPrivacyPolicyText(),
                  ),
                ],
              ),
            ),

            // Close button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String content) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: SelectableText(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
      ),
    );
  }
}
