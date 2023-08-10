import 'package:json_dynamic_widget/json_dynamic_widget.dart';

part 'json_renamed_widget_builder.g.dart';

@JsonWidget(widget: 'Test')
abstract class _JsonRenamedWidgetBuilder extends JsonWidgetBuilder {
  @override
  const _JsonRenamedWidgetBuilder();

  @override
  SizedBox buildCustom({
    ChildWidgetBuilder? childBuilder,
    required BuildContext context,
    required JsonWidgetData data,
    Key? key,
  });
}
