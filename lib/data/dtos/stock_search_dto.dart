import '../models/stock.dart';
import 'dto_parsing.dart';

class StockSearchDto {
  const StockSearchDto({
    required this.code,
    required this.name,
    required this.typeName,
    required this.nationCode,
  });

  factory StockSearchDto.fromJson(Map<String, dynamic> json) {
    return StockSearchDto(
      code: readRequiredString(json['code'], 'code'),
      name: readRequiredString(json['name'], 'name'),
      typeName: readRequiredString(json['typeName'], 'typeName'),
      nationCode: readRequiredString(json['nationCode'], 'nationCode'),
    );
  }

  final String code;
  final String name;
  final String typeName;
  final String nationCode;

  Stock toModel() {
    return Stock(
      symbol: code,
      name: name,
      market: typeName,
    );
  }
}
