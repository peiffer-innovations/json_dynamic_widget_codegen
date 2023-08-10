import 'package:json_dynamic_widget/json_dynamic_widget.dart';

part 'json_save_context_builder.g.dart';

/// Builder that sets a the current [BuildContext] on the [JsonWidgetRegistry].
/// This doesn't actually have a widget and instead simply returns the child's
/// built widget.
@jsonWidget
abstract class _JsonSaveContextBuilder extends JsonWidgetBuilder {
  const _JsonSaveContextBuilder();

  @override
  @JsonArgAlias(alias: 'key', name: 'varName')
  _SaveContext buildCustom({
    ChildWidgetBuilder? childBuilder,
    required BuildContext context,
    required JsonWidgetData data,
    Key? key,
  });
}

class _SaveContext extends StatefulWidget {
  const _SaveContext({
    this.child,
    @JsonBuildArg() this.childBuilder,
    @JsonBuildArg() required this.data,
    super.key,
    required this.varName,
  });

  final JsonWidgetData? child;
  final ChildWidgetBuilder? childBuilder;
  final JsonWidgetData data;
  final String varName;

  @override
  State createState() => _SaveContextState();
}

class _SaveContextState extends State<_SaveContext> {
  @override
  void dispose() {
    widget.data.registry.removeValue(
      widget.varName,
      originator: widget.varName,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Builder(
        builder: (BuildContext context) {
          widget.data.registry.setValue(
            widget.varName,
            context,
            originator: widget.varName,
          );
          return widget.child?.build(
                context: context,
                childBuilder: widget.childBuilder,
                registry: widget.data.registry,
              ) ??
              const SizedBox();
        },
      );
}
