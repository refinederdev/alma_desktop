import 'package:flutter/material.dart';

/// Widget لتنسيق النص مثل WhatsApp
/// يدعم:
/// - *text* للعريض (bold)
/// - _text_ للمائل (italic)
/// - ~text~ للمشطوب (strikethrough)
/// - `text` للنص أحادي المسافة (monospace)
class WhatsAppFormattedText extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final safeText = _sanitizeInvalidUtf16(text);
    // استخدام الخط من style إذا كان موجوداً، وإلا استخدم الخط الافتراضي
    final TextStyle baseStyle = style?.copyWith(
          fontFamily: style?.fontFamily ?? _defaultFontFamily,
        ) ??
        TextStyle(fontFamily: _defaultFontFamily);

    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: _parseText(safeText, baseStyle),
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
        spans.add(TextSpan(
          text: plainText,
          style: _applyFormats(baseStyle, activeFormats),
        ));
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
      spans.add(TextSpan(
        text: remainingText,
        style: _applyFormats(baseStyle, activeFormats),
      ));
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
            fontFamily: baseStyle.fontFamily ?? _defaultFontFamily,
            letterSpacing: 0.5, // إضافة مسافة بين الأحرف لمظهر أحادي المسافة
          );
          break;
      }
    }

    // التأكد من أن الخط موجود دائماً
    if (result.fontFamily == null) {
      result = result.copyWith(fontFamily: _defaultFontFamily);
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
