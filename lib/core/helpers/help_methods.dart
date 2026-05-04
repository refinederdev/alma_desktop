class HelpMethods {
  static double clampForIndecator(amount) {
    double paidAmount = double.parse(amount);

// Scale the value to [0.0, 1.0]
    double scaledValue = paidAmount / 100.0;

// Optionally, clamp the result to ensure it stays within [0.0, 1.0]
    scaledValue = scaledValue.clamp(0.0, 1.0);

    return scaledValue;
  }

  static bool isMorning() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour < 12) {
      return true;
    } else if (hour < 18) {
      return false;
    } else {
      return false;
    }
  }
}
