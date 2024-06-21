import 'command_parser_command.dart';

/// A class which holds commands.
class CommandParser {
  /// Create an instance.
  const CommandParser(this.commands);

  /// The commands which this parser knows about.
  final List<CommandParserCommand> commands;

  /// Handle a command.
  ///
  /// If [command] is handled by this parser, `true` is returned. Otherwise,
  /// `false` will be returned.
  Future<bool> handleCommand(final String command) async {
    if (command.contains(' ')) {
      return false;
    }
    for (final handler in commands) {
      if (handler.command == command) {
        await handler.invoke(this);
        return true;
      }
    }
    return false;
  }
}
