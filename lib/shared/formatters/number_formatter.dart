String formatInteger(int value) {
  final bool isNegative = value < 0;
  final String digits = value.abs().toString();
  final StringBuffer buffer = StringBuffer();

  for (int index = 0; index < digits.length; index += 1) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(digits[index]);
  }

  if (isNegative) {
    return '-$buffer';
  }

  return buffer.toString();
}

String formatSignedInteger(int value) {
  if (value > 0) {
    return '+${formatInteger(value)}';
  }

  return formatInteger(value);
}

String formatSignedRate(double value) {
  final String rate = value.abs().toStringAsFixed(2);

  if (value > 0) {
    return '+$rate%';
  }

  if (value < 0) {
    return '-$rate%';
  }

  return '0.00%';
}
