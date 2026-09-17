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

  /// Formats multiple [results] into a consolidated AI prompt.
  String formatMultiple(List<GrabResult> results) {
    if (results.isEmpty) return '';
    if (results.length == 1) return format(results.first);

    switch (style) {
      case PromptFormatStyle.markdown:
        return _formatMultipleMarkdown(results);
      case PromptFormatStyle.xml:
        return _formatMultipleXml(results);
      case PromptFormatStyle.compact:
        return results.map(_formatCompact).join('\n');
    }
  }

  String _formatMultipleMarkdown(List<GrabResult> results) {
    final buffer = StringBuffer();
    buffer.writeln('<!-- Flutter Grab Context (Multi-Widget Selection) -->');
    buffer.writeln('### 🎯 Selected Widgets (${results.length})');
    buffer.writeln();

    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      buffer.writeln('#### ${i + 1}. `${result.widgetName}`');
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
    }

    buffer.writeln(
      '> **Note for AI:** The user selected these ${results.length} widgets on screen together. '
      'Refer to the source files above to inspect or modify their implementation.',
    );

    return buffer.toString().trim();
  }

  String _formatMultipleXml(List<GrabResult> results) {
    final buffer = StringBuffer();
    buffer.writeln('<flutter_grab_multi_context count="${results.length}">');
    for (final res in results) {
      buffer.writeln('  <widget>');
      buffer.writeln('    <name>${res.widgetName}</name>');
      if (res.filePath != null) buffer.writeln('    <file>${res.filePath}</file>');
      if (res.line != null) buffer.writeln('    <line>${res.line}</line>');
      if (res.column != null) buffer.writeln('    <column>${res.column}</column>');
      if (includeAncestry && res.ancestry.isNotEmpty) {
        buffer.writeln('    <ancestry>${res.ancestryString}</ancestry>');
      }
      if (includeDimensions && res.bounds != null) {
        buffer.writeln('    <dimensions>${res.dimensionsString}</dimensions>');
      }
      buffer.writeln('  </widget>');
    }
    buffer.write('</flutter_grab_multi_context>');
    return buffer.toString();
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
