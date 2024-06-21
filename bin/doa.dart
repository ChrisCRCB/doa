import 'dart:io';

import 'package:dart_openai/dart_openai.dart';
import 'package:doa/doa.dart';
import 'package:mason_logger/mason_logger.dart';

/// Run the program.
Future<void> main() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'] ?? '';
  final logger = Logger();
  final messages = <OpenAIChatCompletionChoiceMessageModel>[];
  OpenAI.apiKey = apiKey;
  final api = OpenAI.instance;
  const model = 'gpt-4o';
  var running = true;
  final parser = CommandParser(
    [
      CommandParserCommand(
        command: ':q',
        description: 'Quit the program.',
        invoke: (final parser) {
          running = false;
          logger.info('Goodbye.');
        },
      ),
      CommandParserCommand(
        command: ':c',
        description: 'Clear the conversation.',
        invoke: (final parser) {
          messages.clear();
          logger.info('Conversation cleared.');
        },
      ),
      CommandParserCommand(
        command: '?',
        description: 'List commands.',
        invoke: (final parser) {
          final commands = List<CommandParserCommand>.from(parser.commands)
            ..sort(
              (final a, final b) =>
                  a.command.toLowerCase().compareTo(b.command.toLowerCase()),
            );
          for (final command in commands) {
            logger.info('${command.command} - ${command.description}');
          }
        },
      ),
    ],
  );
  while (running) {
    final string = logger.prompt('GPT>');
    if (!parser.handleCommand(string)) {
      logger.info('Generating...');
      messages.add(
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(string),
          ],
        ),
      );
      final chat = await api.chat.create(model: model, messages: messages);
      final choice = chat.choices.first;
      final message = choice.message;
      messages.add(message);
      final texts = message.content
              ?.map((final content) => content.text)
              .where((final maybeText) => maybeText != null)
              .toList() ??
          [];
      if (texts.isEmpty) {
        logger.warn('Empty message.');
      } else {
        final text = texts.join('\n');
        logger.info(text);
      }
    }
  }
}
