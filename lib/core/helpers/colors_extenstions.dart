import 'package:flutter/material.dart';

extension GradientExtension on LinearGradient {
  LinearGradient copyWith({
    List<Color>? colors,
    AlignmentGeometry? begin,
    AlignmentGeometry? end,
    TileMode? tileMode,
    GradientTransform? transform,
    List<double>? stops,
  }) {
    return LinearGradient(
      colors: colors ?? this.colors,
      begin: begin ?? this.begin,
      end: end ?? this.end,
      tileMode: tileMode ?? this.tileMode,
      transform: transform ?? this.transform,
      stops: stops ?? this.stops,
    );
  }
}
