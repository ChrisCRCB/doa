import 'dart:io';

import 'package:dart_openai/dart_openai.dart';
import 'package:doa/doa.dart';
import 'package:mason_logger/mason_logger.dart';

/// The message to show when generating responses.
const generatingMessage = 'Generating...';

/// Run the program.
Future<void> main() async {
  final logger = Logger();
  const variableName = 'OPENAI_API_KEY';
  final apiKey = Platform.environment[variableName] ??
      logger.prompt(
        'API key (can be set with the $variableName environment variable)',
      );
  final messages = <OpenAIChatCompletionChoiceMessageModel>[];
  OpenAI.apiKey = apiKey;
  final api = OpenAI.instance;
  var model = 'gpt-4o';
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
      CommandParserCommand(
        command: ':m',
        description: 'Change the used model.',
        invoke: (final parser) async {
          final progress = logger.progress('Loading models...');
          final models = await api.model.list();
          progress.complete();
          model = logger.chooseOne(
            'Select model:',
            choices:
                models.map((final modelFromApi) => modelFromApi.id).toList(),
            defaultValue: model,
          );
          logger.info('Using model $model.');
        },
      ),
    ],
  );
  while (running) {
    final string = logger.prompt('GPT>');
    if (!(await parser.handleCommand(string))) {
      stdout.write(generatingMessage);
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
      for (var i = 0; i < generatingMessage.length; i++) {
        stdout.write('\b \b');
      }
      if (texts.isEmpty) {
        logger.warn('Empty message.');
      } else {
        final text = texts.join('\n');
        logger.info(text);
      }
    }
  }
}
