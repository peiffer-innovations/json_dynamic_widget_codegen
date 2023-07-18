import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:json_dynamic_widget_codegen/json_dynamic_widget_codegen.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';
import 'package:yaon/yaon.dart';

class JsonWidgetLibraryBuilder extends GeneratorForAnnotation<JsonWidget> {
  static const kChildNames = {
    'builder': 1,
    'child': 1,
    'children': -1,
    'itemBuilder': -1,
  };

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final pubspec = yaon.parse(File('pubspec.yaml').readAsStringSync());
    final packageName = pubspec['name'].toString();
    final schemaBaseUrl = pubspec['schema_url'] ??
        'https://peiffer-innovations.github.io/flutter_json_schemas/schemas';
    final name = element.name;
    if (name == null) {
      throw Exception(
        'Annotation found on unnamed location, cannot continue.',
      );
    }
    if (!name.startsWith('_')) {
      throw Exception('Class must be private, but [$name] is not private.');
    }

    if (element is! ClassElement) {
      throw Exception('Annotation found but is ');
    }
    MethodElement? method;
    const builderChecker = TypeChecker.fromRuntime(JsonBuilder);
    for (var m in element.methods) {
      final annotation = builderChecker.firstAnnotationOf(m);
      if (annotation != null) {
        method = m;
        break;
      }
    }
    if (method == null) {
      for (var m in element.methods) {
        if (m.name == 'buildCustom') {
          method = m;
          break;
        }
      }
    }

    if (method == null) {
      throw Exception('No [buildCustom] or [_buildCustom] function found.');
    }

    final paramDecoders = <String, MethodElement>{};
    final schemaDecoders = <String, MethodElement>{};
    const paramChecker = TypeChecker.fromRuntime(JsonParamDecoder);
    const paramSchemaChecker = TypeChecker.fromRuntime(JsonParamSchema);
    for (var m in element.methods) {
      final paramAnnotation = paramChecker.firstAnnotationOf(m);
      final schemaAnnotation = paramSchemaChecker.firstAnnotationOf(m);
      if (paramAnnotation != null) {
        final param = ConstantReader(paramAnnotation).read('param').stringValue;
        paramDecoders[param] = m;
      }

      if (schemaAnnotation != null) {
        if (!m.isStatic) {
          throw Exception(
            'Encountered [JsonParamSchema] annotation on a non-static method named: [${m.displayName}].',
          );
        }
        final param =
            ConstantReader(schemaAnnotation).read('param').stringValue;
        schemaDecoders[param] = m;
      }
    }

    final widget = method.returnType;
    if (widget is! InterfaceType) {
      throw Exception(
        'Unknown type [${widget.runtimeType}] found on the return from [buildCustom].',
      );
    }

    ConstructorElement? con;
    for (var c in widget.constructors) {
      if (c.name == '') {
        con = c;
      }
    }

    if (con == null) {
      throw Exception(
        'Cannot find unnamed constructor in [${widget.getDisplayString(withNullability: false)}]',
      );
    }

    final constructor = con;

    final params = constructor.parameters;
    final childParams = params.where((p) => kChildNames.containsKey(p.name));
    final numSupportedChildren =
        childParams.isEmpty ? 0 : kChildNames[childParams.first.name]!;

    final generated = Class((c) {
      c.name = name.substring(1);
      c.extend = Reference(name);
      params.sort((a, b) {
        var result = a.name.compareTo(b.name);

        if (kChildNames.containsKey(a.name)) {
          if (!kChildNames.containsKey(b.name)) {
            result = 1;
          }
        }
        if (kChildNames.containsKey(b.name)) {
          if (!kChildNames.containsKey(a.name)) {
            result = -1;
          }
        }

        return result;
      });

      c.fields.add(Field((f) {
        f.name = 'kNumSupportedChildren';
        f.static = true;
        f.modifier = FieldModifier.constant;
        f.assignment = Code('$numSupportedChildren');
      }));
      c.fields.add(Field((f) {
        f.name = 'kType';
        f.static = true;
        f.modifier = FieldModifier.constant;
        f.assignment = Code(
          "'${ReCase(widget.getDisplayString(withNullability: false)).snakeCase}'",
        );
      }));

      c.fields.add(Field((f) {
        f.name = 'model';
        f.type = Reference('${name.substring(1)}Model');
        f.modifier = FieldModifier.final$;
      }));

      c.constructors.add(Constructor((con) {
        con.constant = constructor.isConst;
        con.optionalParameters.add(
          Parameter(
            (param) {
              param.name = 'model';
              param.named = true;
              param.required = true;
              param.toThis = true;
            },
          ),
        );
        con.optionalParameters.add(Parameter((param) {
          param.defaultTo = const Code('kNumSupportedChildren');
          param.name = 'numSupportedChildren';
          param.named = true;
          param.toSuper = true;
        }));
      }));

      c.methods.add(
        Method(
          (m) {
            m.static = true;
            m.returns = Reference(c.name);
            m.name = 'fromDynamic';
            m.requiredParameters.add(
              Parameter(
                (p) {
                  p.name = 'map';
                  p.type = const Reference('dynamic');
                  p.named = false;
                },
              ),
            );
            m.optionalParameters.add(
              Parameter(
                (p) {
                  p.name = 'registry';
                  p.type = const Reference('JsonWidgetRegistry?');
                  p.named = true;
                },
              ),
            );
            m.body = Code('''
final result = maybeFromDynamic(map, registry: registry,);

if (result == null) {
  throw Exception('[${name.substring(1)}]: requested to parse from dynamic, but the input is null.',);
}

return result;
''');
          },
        ),
      );

      c.methods.add(
        Method(
          (m) {
            m.static = true;
            m.returns = Reference('${c.name}?');
            m.name = 'maybeFromDynamic';
            m.requiredParameters.add(
              Parameter(
                (p) {
                  p.name = 'map';
                  p.type = const Reference('dynamic');
                  p.named = false;
                },
              ),
            );
            m.optionalParameters.add(
              Parameter(
                (p) {
                  p.name = 'registry';
                  p.type = const Reference('JsonWidgetRegistry?');
                  p.named = true;
                },
              ),
            );
            final lines = <String>[];
            for (var param in params) {
              if (!kChildNames.containsKey(param.name) && param.name != 'key') {
                lines.add('${param.name}: ${decode(
                  element,
                  param,
                  paramDecoders: paramDecoders.keys,
                )}');
              }
            }

            m.body = Code(
              '''
${c.name}Model? result;

if (map != null) {
  if (map is String) {
    map = yaon.parse(map, normalize: true,);
  }

  if (map is ${c.name}Model) {
    result = map;
  } else {
    result = ${c.name}Model(
      ${lines.join(',')}${lines.isNotEmpty ? ',' : ''}
    );
  }
          }

return result == null ? null : ${c.name}(
  model: result,
);
''',
            );
          },
        ),
      );

      c.methods.add(Method((m) {
        m.name = method!.name;
        m.annotations.add(const CodeExpression(Code('override')));
        m.returns = Reference(widget.getDisplayString(withNullability: true));

        m.optionalParameters.add(Parameter((p) {
          p.name = 'childBuilder';
          p.named = true;
          p.required = false;
          p.type = const Reference('ChildWidgetBuilder?');
        }));
        m.optionalParameters.add(Parameter((p) {
          p.name = 'context';
          p.named = true;
          p.required = true;
          p.type = const Reference('BuildContext');
        }));
        m.optionalParameters.add(Parameter((p) {
          p.name = 'data';
          p.named = true;
          p.required = true;
          p.type = const Reference('JsonWidgetData');
        }));
        m.optionalParameters.add(Parameter((p) {
          p.name = 'key';
          p.named = true;
          p.required = false;
          p.type = const Reference('Key?');
        }));

        final lines = <String>[];
        final buf = StringBuffer();
        for (var param in params) {
          final method = paramDecoders[param.name];
          if (param.name == 'key' || param.name == 'context') {
            lines.add('${param.name}: ${param.name}');
          } else if (method == null) {
            if (kChildNames.containsKey(param.name)) {
              lines.add('${param.name}: ${param.name}');
            } else {
              lines.add('${param.name}: model.${param.name}');
            }
            if (param.name == 'child') {
              buf.write('''
final child = getChild(data).build(
          childBuilder: childBuilder,
          context: context,
        );

''');
            } else if (param.name == 'children') {
              buf.write('''
final children = (data.children ?? <JsonWidgetData>[]).map((c) =>
    c.build(
      childBuilder: childBuilder,
      context: context,
    ),
  ).toList();

''');
            }
          } else {
            lines.add('${param.name}: ${param.name}Decoded');
            var childBuilder = '';
            var context = '';
            var data = '';
            var registry = '';
            var value = '';

            for (var field in method.parameters) {
              if (field.name == 'childBuilder') {
                childBuilder = 'childBuilder: childBuilder,';
              } else if (field.name == 'context') {
                context = 'context: context,';
              } else if (field.name == 'data') {
                data = 'data: data,';
              } else if (field.name == 'registry') {
                registry = 'registry: data.registry,';
              } else if (field.name == 'value') {
                value = 'value: model.${param.name},';
              }
            }

            buf.write('''
final ${param.name}Decoded = ${paramDecoders[param.name]!.name}(
  $childBuilder
  $context
  $data
  $registry
  $value
);
''');
          }
        }

        m.body = Code('''
${buf.toString()}
return ${widget.getDisplayString(withNullability: false)}(
  ${lines.join(',')}${lines.isNotEmpty ? ',' : ''}
);
''');
      }));
    });

    final emitter = DartEmitter(useNullSafetySyntax: true);
    final builderCode = generated.accept(emitter).toString();

    final model = Class((c) {
      c.name = '${name.substring(1)}Model';
      c.constructors.add(
        Constructor(
          (con) {
            con.constant = constructor.isConst;

            for (var p in params) {
              if (!kChildNames.containsKey(p.name) && p.name != 'key') {
                con.optionalParameters.add(
                  Parameter(
                    (param) {
                      param.name = p.name;
                      param.named = true;
                      param.required = true;
                      param.toThis = true;
                    },
                  ),
                );
              }
            }
          },
        ),
      );
      for (var p in params) {
        if (!kChildNames.containsKey(p.name) && p.name != 'key') {
          final method = paramDecoders[p.name];
          c.fields.add(
            Field(
              (f) {
                f.modifier = FieldModifier.final$;
                f.name = p.name;
                f.type = Reference(
                  method == null
                      ? p.type.getDisplayString(
                          withNullability: true,
                        )
                      : 'dynamic',
                );
              },
            ),
          );
        }
      }
    });

    final modelCode = model.accept(emitter).toString();

    final properties = StringBuffer();
    final schema = Class((c) {
      final id =
          '$schemaBaseUrl/$packageName/${ReCase(widget.getDisplayString(withNullability: false)).snakeCase}.json';
      c.name = '${widget.getDisplayString(withNullability: false)}Schema';

      for (var param in params) {
        final name = param.displayName;
        if (!kChildNames.containsKey(name) && name != 'key') {
          final type = param.type.getDisplayString(withNullability: false);

          final sMethod = schemaDecoders[name];
          if (sMethod == null) {
            final fun = kSchemaDecoders[type];

            final schema = fun == null ? 'SchemaHelper.anySchema' : fun(param);
            properties.write("'$name': $schema,\n");
          } else {
            properties.write(
              "'$name': ${element.name}.${sMethod.displayName}(),",
            );
          }
        }
      }
      c.fields.add(Field((f) {
        f.name = 'id';
        f.modifier = FieldModifier.constant;
        f.static = true;
        f.assignment = Code("'$id'");
      }));
      c.fields.add(Field((f) {
        f.name = 'schema';
        f.modifier = FieldModifier.final$;
        f.static = true;
        f.assignment = Code(
          '''<String, dynamic>{
r'\$schema': 'http://json-schema.org/draft-06/schema#',
r'\$id': id,
r'\$children': '$numSupportedChildren',
'title': '${widget.getDisplayString(withNullability: false)}',
'oneOf': [
  {
    'type': 'null',
  },
  {
    'type': 'object',
    'additionalProperties': false,
    'properties': {
      ${properties.toString()}
    },
  },
],}
''',
        );
      }));
    });

    final schemaCode = schema.accept(emitter).toString();

    return '''
// ignore_for_file: deprecated_member_use
// ignore_for_file: prefer_const_constructors_in_immutables
// ignore_for_file: prefer_final_locals

$builderCode

$modelCode

$schemaCode
''';
  }
}
