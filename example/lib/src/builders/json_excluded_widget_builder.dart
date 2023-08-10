import 'package:json_dynamic_widget/json_dynamic_widget.dart';

part 'json_excluded_widget_builder.g.dart';

@JsonWidget(autoRegister: false, widget: 'Excluded')
abstract class _JsonExcludedWidgetBuilder extends JsonWidgetBuilder {
  @override
  const _JsonExcludedWidgetBuilder();

  @override
  SizedBox buildCustom({
    ChildWidgetBuilder? childBuilder,
    required BuildContext context,
    required JsonWidgetData data,
    Key? key,
  });
}
