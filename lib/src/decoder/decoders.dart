import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:json_theme/codegen.dart';

typedef ParameterDecoder = String Function(ParameterElement element);

final kDecoders = <String, ParameterDecoder>{
  'bool': (ParameterElement element) => element.type.nullable
      ? "JsonClass.maybeParseBool('${element.name}',)"
      : "JsonClass.parseBool('${element.name}', whenNull: ${element.defaultValueCode ?? false},)",
  'double': (element) => _defaultDecoder(
        element,
        (element.type.nullable || element.defaultValueCode != null)
            ? 'JsonClass.maybeParseDouble'
            : 'JsonClass.parseDouble',
      ),
  'int': (element) => _defaultDecoder(
        element,
        (element.type.nullable || element.defaultValueCode != null)
            ? 'JsonClass.maybeParseInt'
            : 'JsonClass.parseInt',
      ),
  'DateTime': (element) => _defaultDecoder(
        element,
        (element.type.nullable || element.defaultValueCode != null)
            ? 'JsonClass.maybeParseDateTime'
            : 'JsonClass.parseDateTime',
      ),
  'List<double>': (element) => _defaultDecoder(
        element,
        (element.type.nullable || element.defaultValueCode != null)
            ? 'JsonClass.maybeParseDoubleList'
            : 'JsonClass.parseDoubleList',
      ),
  'List<int>': (element) => _defaultDecoder(
        element,
        (element.type.nullable || element.defaultValueCode != null)
            ? 'JsonClass.maybeParseIntList'
            : 'JsonClass.parseIntList',
      ),
  ...kThemeDecoders.map((key, value) => MapEntry<String, ParameterDecoder>(
      key, (element) => _themeDecoder(element, key))),
};

String decode(
  ClassElement classElement,
  ParameterElement element, {
  required Iterable<String> paramDecoders,
}) {
  var result = "map['${element.name}']";

  final name = element.getDisplayString(withNullability: false);
  final typeStr = element.type.getDisplayString(withNullability: false);

  var decoded = false;
  if (paramDecoders.contains(name)) {
    decoded = true;
  }

  if (!decoded) {
    final decoder = kDecoders[typeStr];

    if (decoder != null) {
      result = decoder(element);
    }
  }

  return result;
}

String _defaultDecoder(ParameterElement element, String funName) => '''
() {
  dynamic parsed = $funName(map['${element.name}']);
  ${element.defaultValueCode == null ? '' : 'parsed ??= ${element.defaultValueCode};'}
  ${!element.type.nullable && element.defaultValueCode == null ? "if (parsed == null) { throw Exception('Null value encountered for required parameter: [${element.name}].'); }" : ''}
  return parsed;
}()
''';

String _themeDecoder(ParameterElement element, String funName) => '''
() {
  dynamic parsed = ThemeDecoder.decode$funName(map['${element.name}'], validate: false,);
  ${element.defaultValueCode == null ? '' : 'parsed ??= ${element.defaultValueCode};'}
  ${!element.type.nullable && element.defaultValueCode == null ? "if (parsed == null) { throw Exception('Null value encountered for required parameter: [${element.name}].'); }" : ''}
  return parsed;
}()
''';

extension DartTypeNullable on DartType {
  bool get nullable => nullabilitySuffix == NullabilitySuffix.question;
}
