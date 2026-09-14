import '../core/grab_result.dart';

/// Supported prompt formatting styles for AI coding assistants.
enum PromptFormatStyle {
  /// Standard Markdown format with bullet points and code formatting.
  markdown,

  /// XML tag format structured for Claude, Cursor, and LLM context blocks.
  xml,

  /// Compact single-line tag format.
  compact,
}

/// Formatter that transforms [GrabResult] into AI-ready prompt snippets.
class AiPromptFormatter {
  const AiPromptFormatter({
    this.style = PromptFormatStyle.markdown,
    this.includeAncestry = true,
    this.includeDimensions = true,
  });

  final PromptFormatStyle style;
  final bool includeAncestry;
  final bool includeDimensions;

  /// Formats the [result] according to the selected [style].
  String format(GrabResult result) {
    switch (style) {
      case PromptFormatStyle.markdown:
        return _formatMarkdown(result);
      case PromptFormatStyle.xml:
        return _formatXml(result);
      case PromptFormatStyle.compact:
        return _formatCompact(result);
    }
  }

  String _formatMarkdown(GrabResult result) {
    final buffer = StringBuffer();
    buffer.writeln('<!-- Flutter Grab Context -->');
    buffer.writeln('### 🎯 Selected Widget: `${result.widgetName}`');
    buffer.writeln('- **Source File:** `${result.locationString}`');

    if (includeAncestry && result.ancestry.isNotEmpty) {
      final fullAncestry = [...result.ancestry];
      if (fullAncestry.isEmpty || fullAncestry.last != result.widgetName) {
        fullAncestry.add(result.widgetName);
      }
      buffer.writeln('- **Widget Hierarchy:** `${fullAncestry.join(' > ')}`');
    }

    if (includeDimensions && result.bounds != null) {
      buffer.writeln('- **Render Size:** `${result.dimensionsString}`');
    }

    buffer.writeln();
    buffer.writeln(
      '> **Note for AI:** The user selected this widget on screen. '
      'Refer to `${result.locationString}` to inspect or modify its implementation.',
    );

    return buffer.toString().trim();
  }

  String _formatXml(GrabResult result) {
    final buffer = StringBuffer();
    buffer.writeln('<flutter_grab_context>');
    buffer.writeln('  <widget>${result.widgetName}</widget>');
    if (result.filePath != null) {
      buffer.writeln('  <file>${result.filePath}</file>');
    }
    if (result.line != null) {
      buffer.writeln('  <line>${result.line}</line>');
    }
    if (result.column != null) {
      buffer.writeln('  <column>${result.column}</column>');
    }
    if (includeAncestry && result.ancestry.isNotEmpty) {
      buffer.writeln('  <ancestry>${result.ancestryString}</ancestry>');
    }
    if (includeDimensions && result.bounds != null) {
      buffer.writeln('  <dimensions>${result.dimensionsString}</dimensions>');
    }
    buffer.write('</flutter_grab_context>');
    return buffer.toString();
  }

  String _formatCompact(GrabResult result) {
    final parts = <String>[
      'name="${result.widgetName}"',
      if (result.filePath != null) 'file="${result.filePath}"',
      if (result.line != null) 'line="${result.line}"',
      if (result.column != null) 'col="${result.column}"',
      if (includeAncestry && result.ancestry.isNotEmpty) 'ancestry="${result.ancestryString}"',
      if (includeDimensions && result.bounds != null) 'size="${result.dimensionsString}"',
    ];
    return '<Widget ${parts.join(' ')} />';
  }
}
