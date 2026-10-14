import 'dart:convert';

class Formatter {
  static String format(String source, String type) {
    final s = source.trim();
    if (type == 'Clean URL') {
      try {
        final uri = Uri.parse(s);
        const tracking = {'utm_source', 'utm_medium', 'utm_campaign', 'utm_term',
          'utm_content', 'gclid', 'fbclid', 'mc_cid', 'mc_eid'};
        final query = Map<String, String>.from(uri.queryParameters)
          ..removeWhere((key, _) => tracking.contains(key.toLowerCase()) ||
              key.toLowerCase().startsWith('utm_'));
        return uri.replace(queryParameters: query.isEmpty ? null : query).toString();
      } catch (_) {
        return s;
      }
    }
    if (type == 'JSON' || type == 'Receipt JSON') {
      try {
        return const JsonEncoder.withIndent('  ').convert(jsonDecode(s));
      } catch (_) {
        if (type == 'Receipt JSON') return _receiptJson(s);
        return s;
      }
    }
    if (type == 'CSV') return _toCsv(s);
    if (type == 'Markdown') {
      return s.split('\n').map((line) => line.trimRight()).join('\n')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n');
    }
    return s.split('\n').map((line) => line.trimRight()).join('\n')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  static String _receiptJson(String source) {
    final normalized = source.replaceAll(r'\n', '\n');
    final lines = normalized.split('\n').map((line) => line.trim())
        .where((line) => line.isNotEmpty).toList();

    // Only report currency when an explicit symbol was recognized in the text.
    final symbols = RegExp(r'[$€£₹¥₩₽₺₫₪฿₱]')
        .allMatches(normalized).map((match) => match.group(0)!).toSet();
    final currencySymbol = symbols.length == 1 ? symbols.first : null;
    final currencyDetection = symbols.isEmpty
        ? 'symbol_not_detected'
        : symbols.length == 1 ? 'symbol_detected' : 'multiple_symbols_detected';

    String? amountFor(String label) {
      final pattern = RegExp(
        '(?:$label)\\s*[:\\-]?\\s*(?:[$€£₹¥₩₽₺₫₪฿₱]\\s*)?'
        r'([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?|[0-9]+(?:\.[0-9]{2})?)',
        caseSensitive: false,
      );
      return pattern.firstMatch(normalized)?.group(1)?.replaceAll(',', '');
    }

    final date = RegExp(
      r'\b(?:\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{4}-\d{2}-\d{2})\b',
    ).firstMatch(normalized)?.group(0);

    final items = <Map<String, dynamic>>[];
    final pricePattern = RegExp(r'^(.*?)\s+([$€£₹¥₩₽₺₫₪฿₱])?\s*([0-9]+\.[0-9]{2})\s*$');
    final totalLabel = RegExp(
      r'^(subtotal|tax|gst|vat|total|grand total|balance due|amount due)\b',
      caseSensitive: false,
    );
    for (final line in lines) {
      final match = pricePattern.firstMatch(line);
      if (match == null) continue;
      final name = match.group(1)!.trim().replaceAll(RegExp(r'^[|•*\-]+\s*'), '');
      if (name.isEmpty || totalLabel.hasMatch(name)) continue;
      final item = <String, dynamic>{
        'name': name,
        'amount': double.tryParse(match.group(3)!),
      };
      final explicitLineSymbol = match.group(2);
      if (explicitLineSymbol != null) {
        item['currency_symbol'] = explicitLineSymbol;
      } else if (currencySymbol != null) {
        item['currency_symbol'] = currencySymbol;
      }
      items.add(item);
    }

    final subtotal = amountFor('subtotal');
    final tax = amountFor('(?:tax|gst|vat)');
    final total = amountFor('(?:grand total|total|amount due|balance due)');
    final result = <String, dynamic>{
      if (lines.isNotEmpty) 'merchant': lines.first,
      if (date != null) 'date': date,
      'items': items,
      if (subtotal != null) 'subtotal': double.tryParse(subtotal),
      if (tax != null) 'tax': double.tryParse(tax),
      if (total != null) 'total': double.tryParse(total),
      'currency_symbol': currencySymbol,
      'currency_detection': currencyDetection,
      'raw_text': source,
      'needs_review': true,
    };
    return const JsonEncoder.withIndent('  ').convert(result);
  }

  static String _toCsv(String source) {
    final rows = source.split('\n').where((line) => line.trim().isNotEmpty)
        .map((line) => line.split(RegExp(r'\t+|\s{2,}|\s*,\s*'))
            .map((value) => '"${value.replaceAll('"', '""')}"').join(','))
        .toList();
    return rows.join('\n');
  }
}
