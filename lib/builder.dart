import 'package:build/build.dart';
import 'package:json_dynamic_widget_codegen/json_dynamic_widget_codegen.dart';
import 'package:source_gen/source_gen.dart';

Builder widgetLibrary(BuilderOptions options) => SharedPartBuilder(
      [
        JsonWidgetLibraryBuilder(),
      ],
      'widget',
    );
