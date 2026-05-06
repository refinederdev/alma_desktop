import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget لتنسيق النص مثل WhatsApp
/// يدعم:
/// - *text* للعريض (bold)
/// - _text_ للمائل (italic)
/// - ~text~ للمشطوب (strikethrough)
/// - `text` للنص أحادي المسافة (monospace)
class WhatsAppFormattedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  // خط التطبيق الافتراضي
  static const String _defaultFontFamily = 'IBMPlexSansArabic';

  const WhatsAppFormattedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  State<WhatsAppFormattedText> createState() => _WhatsAppFormattedTextState();
}

class _WhatsAppFormattedTextState extends State<WhatsAppFormattedText> {
  final List<TapGestureRecognizer> _linkRecognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final recognizer in _linkRecognizers) {
      recognizer.dispose();
    }
    _linkRecognizers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final recognizer in _linkRecognizers) {
      recognizer.dispose();
    }
    _linkRecognizers.clear();

    final safeText = _sanitizeInvalidUtf16(widget.text);
    // استخدام الخط من style إذا كان موجوداً، وإلا استخدم الخط الافتراضي
    final TextStyle baseStyle = widget.style?.copyWith(
          fontFamily:
              widget.style?.fontFamily ?? WhatsAppFormattedText._defaultFontFamily,
        ) ??
        TextStyle(fontFamily: WhatsAppFormattedText._defaultFontFamily);

    return SelectableText.rich(
      _parseText(safeText, baseStyle),
      textAlign: widget.textAlign ?? TextAlign.start,
      maxLines: widget.maxLines,
    );
  }

  TextSpan _parseText(String text, TextStyle baseStyle) {
    return _parseTextRecursive(text, baseStyle, <String>[]);
  }

  TextSpan _parseTextRecursive(
    String text,
    TextStyle baseStyle,
    List<String> activeFormats,
  ) {
    final List<TextSpan> spans = [];
    int currentIndex = 0;

    // نمط regex للبحث عن جميع التنسيقات مع دعم التنسيقات المتداخلة
    // *text* للعريض
    // _text_ للمائل
    // ~text~ للمشطوب
    // `text` للنص أحادي المسافة
    final RegExp pattern = RegExp(
      r'(\*[^*]+\*|_[^_]+_|~[^~]+~|`[^`]+`)',
      multiLine: true,
    );

    final Iterable<RegExpMatch> matches = pattern.allMatches(text);

    for (final match in matches) {
      // إضافة النص قبل التنسيق
      if (match.start > currentIndex) {
        final plainText = text.substring(currentIndex, match.start);
        spans.addAll(
          _buildTextSpansWithLinks(
            plainText,
            _applyFormats(baseStyle, activeFormats),
          ),
        );
      }

      // استخراج النص المنسق
      final String formattedText = match.group(0)!;
      final String content = formattedText.substring(1, formattedText.length - 1);
      final String formatType = formattedText[0];

      // إنشاء قائمة جديدة من التنسيقات النشطة
      final List<String> newFormats = List.from(activeFormats);
      
      // إضافة التنسيق الحالي إذا لم يكن موجوداً
      if (!newFormats.contains(formatType)) {
        newFormats.add(formatType);
      }

      // تحليل المحتوى بشكل متكرر لدعم التنسيقات المتداخلة
      final TextSpan formattedSpan = _parseTextRecursive(
        content,
        baseStyle,
        newFormats,
      );

      spans.add(formattedSpan);

      currentIndex = match.end;
    }

    // إضافة النص المتبقي بعد آخر تنسيق
    if (currentIndex < text.length) {
      final remainingText = text.substring(currentIndex);
      spans.addAll(
        _buildTextSpansWithLinks(
          remainingText,
          _applyFormats(baseStyle, activeFormats),
        ),
      );
    }

    // إذا لم يكن هناك تنسيقات، أعد النص كما هو
    if (spans.isEmpty) {
      return TextSpan(
        text: text,
        style: _applyFormats(baseStyle, activeFormats),
      );
    }

    return TextSpan(children: spans);
  }

  List<TextSpan> _buildTextSpansWithLinks(String input, TextStyle baseStyle) {
    final List<TextSpan> spans = <TextSpan>[];
    final RegExp linkPattern = RegExp(
      r'((?:https?:\/\/|www\.)[^\s]+)',
      caseSensitive: false,
    );

    int currentIndex = 0;
    for (final match in linkPattern.allMatches(input)) {
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: input.substring(currentIndex, match.start),
            style: baseStyle,
          ),
        );
      }

      final String rawUrl = match.group(0)!;
      final String normalizedUrl = rawUrl.toLowerCase().startsWith('http')
          ? rawUrl
          : 'https://$rawUrl';
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _openLink(normalizedUrl);
      _linkRecognizers.add(recognizer);

      spans.add(
        TextSpan(
          text: rawUrl,
          style: baseStyle.copyWith(
            decoration: TextDecoration.underline,
            color: Colors.blueAccent,
          ),
          recognizer: recognizer,
        ),
      );

      currentIndex = match.end;
    }

    if (currentIndex < input.length) {
      spans.add(TextSpan(text: input.substring(currentIndex), style: baseStyle));
    }

    return spans;
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  TextStyle _applyFormats(TextStyle baseStyle, List<String> formats) {
    TextStyle result = baseStyle;

    for (final format in formats) {
      switch (format) {
        case '*':
          result = result.copyWith(fontWeight: FontWeight.bold);
          break;
        case '_':
          result = result.copyWith(fontStyle: FontStyle.italic);
          break;
        case '~':
          result = result.copyWith(
            decoration: TextDecoration.lineThrough,
            decorationColor: result.color,
          );
          break;
        case '`':
          // استخدام نفس الخط للنص أحادي المسافة بدلاً من monospace
          // للحفاظ على الاتساق مع خط التطبيق
          result = result.copyWith(
            fontFamily: baseStyle.fontFamily ??
                WhatsAppFormattedText._defaultFontFamily,
            letterSpacing: 0.5, // إضافة مسافة بين الأحرف لمظهر أحادي المسافة
          );
          break;
      }
    }

    // التأكد من أن الخط موجود دائماً
    if (result.fontFamily == null) {
      result = result.copyWith(
        fontFamily: WhatsAppFormattedText._defaultFontFamily,
      );
    }

    return result;
  }

  String _sanitizeInvalidUtf16(String input) {
    if (input.isEmpty) return input;

    final buffer = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final unit = input.codeUnitAt(i);
      final isHigh = unit >= 0xD800 && unit <= 0xDBFF;
      final isLow = unit >= 0xDC00 && unit <= 0xDFFF;

      if (isHigh) {
        if (i + 1 < input.length) {
          final next = input.codeUnitAt(i + 1);
          final nextIsLow = next >= 0xDC00 && next <= 0xDFFF;
          if (nextIsLow) {
            buffer.writeCharCode(unit);
            buffer.writeCharCode(next);
            i++;
            continue;
          }
        }
        buffer.writeCharCode(0xFFFD);
        continue;
      }

      if (isLow) {
        buffer.writeCharCode(0xFFFD);
        continue;
      }

      buffer.writeCharCode(unit);
    }

    return buffer.toString();
  }
}
