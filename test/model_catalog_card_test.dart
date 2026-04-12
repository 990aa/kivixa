import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/ai/model_catalog_card.dart';
import 'package:kivixa/services/ai/model_manager.dart';

void main() {
  AIModel buildModel({bool isDefault = false}) {
    return AIModel(
      id: 'test-model',
      name: 'Test Model',
      shortDescription: 'Short description for model card.',
      description:
          'Long description for model card that should not be primary.',
      recommendation: 'Use this when you need fast answers on small devices.',
      url: 'https://huggingface.co/test/model/resolve/main/test.gguf',
      fileName: 'test.gguf',
      sizeBytes: 512 * 1024 * 1024,
      categories: const [ModelCategory.general, ModelCategory.code],
      isDefault: isDefault,
    );
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('ModelCatalogCard UI rendering', () {
    testWidgets('shows short description and suggestion text', (tester) async {
      await tester.pumpWidget(
        wrap(
          ModelCatalogCard(
            model: buildModel(),
            isDownloaded: false,
            isCurrentlyLoaded: false,
            onDownload: () {},
            onLoad: () {},
            onDelete: () {},
          ),
        ),
      );

      expect(find.text('Test Model'), findsOneWidget);
      expect(find.text('Short description for model card.'), findsOneWidget);
      expect(
        find.text('Use this when you need fast answers on small devices.'),
        findsOneWidget,
      );
      expect(find.text('General Purpose'), findsOneWidget);
      expect(find.text('Code Generation'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
    });

    testWidgets('shows default and active chips for loaded default model', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ModelCatalogCard(
            model: buildModel(isDefault: true),
            isDownloaded: true,
            isCurrentlyLoaded: true,
            onDownload: () {},
            onLoad: () {},
            onDelete: () {},
          ),
        ),
      );

      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Loaded'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('shows load and delete actions for downloaded inactive model', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ModelCatalogCard(
            model: buildModel(),
            isDownloaded: true,
            isCurrentlyLoaded: false,
            onDownload: () {},
            onLoad: () {},
            onDelete: () {},
          ),
        ),
      );

      expect(find.text('Load'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Download'), findsNothing);
    });

    testWidgets('renders cards for new MCP/Agent models', (tester) async {
      final llama32 = ModelManager.getModelById('llama32-3b-instruct-q3km')!;
      final qwen15b = ModelManager.getModelById('qwen25-15b-instruct-q4km')!;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                ModelCatalogCard(
                  model: llama32,
                  isDownloaded: false,
                  isCurrentlyLoaded: false,
                  onDownload: () {},
                  onLoad: () {},
                  onDelete: () {},
                ),
                ModelCatalogCard(
                  model: qwen15b,
                  isDownloaded: false,
                  isCurrentlyLoaded: false,
                  onDownload: () {},
                  onLoad: () {},
                  onDelete: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Llama 3.2 3B Instruct'), findsOneWidget);
      expect(find.text('Qwen2.5 1.5B Instruct'), findsOneWidget);
      expect(find.text('MCP / Agent Brain'), findsAtLeastNWidgets(2));
      expect(find.text('Download'), findsNWidgets(2));
    });
  });
}
