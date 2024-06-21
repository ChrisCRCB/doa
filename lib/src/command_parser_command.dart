import 'command_parser.dart';

/// A command in a [CommandParser].
class CommandParserCommand {
  /// Create an instance.
  const CommandParserCommand({
    required this.command,
    required this.description,
    required this.invoke,
  });

  /// The string which will activate this command.
  final String command;

  /// The description of this command.
  final String description;

  /// The function to run to use this command.
  final void Function(CommandParser parser) invoke;
}
