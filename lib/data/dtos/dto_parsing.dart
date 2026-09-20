int readRequiredInt(Object? value, String fieldName) {
  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.toInt();
  }

  if (value is String) {
    final String numberText = value.replaceAll(',', '').trim();
    final int? parsedValue = int.tryParse(numberText);

    if (parsedValue != null) {
      return parsedValue;
    }
  }

  throw FormatException('$fieldName 값을 정수로 변환할 수 없습니다.');
}

String readRequiredString(Object? value, String fieldName) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }

  throw FormatException('$fieldName 값이 없거나 올바르지 않습니다.');
}
