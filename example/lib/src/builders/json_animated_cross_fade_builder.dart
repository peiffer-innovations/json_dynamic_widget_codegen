import 'package:json_dynamic_widget/json_dynamic_widget.dart';

part 'json_animated_cross_fade_builder.g.dart';

/// Builder that can build an [AnimatedCrossFade] widget.
@jsonWidget
abstract class _JsonAnimatedCrossFadeBuilder extends JsonWidgetBuilder {
  const _JsonAnimatedCrossFadeBuilder();

  @override
  AnimatedCrossFade buildCustom({
    ChildWidgetBuilder? childBuilder,
    required BuildContext context,
    required JsonWidgetData data,
    Key? key,
  });
}
