// ignore: unused_import
import 'package:flutter/gestures.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';

part 'json_list_view_builder.g.dart';

/// Builder that can build an [ListView] widget.
@jsonWidget
abstract class _JsonListViewBuilder extends JsonWidgetBuilder {
  const _JsonListViewBuilder();

  @override
  _ListView buildCustom({
    ChildWidgetBuilder? childBuilder,
    required BuildContext context,
    required JsonWidgetData data,
    Key? key,
  });
}

class _ListView extends StatelessWidget {
  const _ListView({
    required this.addAutomaticKeepAlives,
    required this.addRepaintBoundaries,
    required this.addSemanticIndexes,
    this.cacheExtent,
    @JsonBuildArg() this.childBuilder,
    required this.children,
    required this.clipBehavior,
    this.controller,
    @JsonBuildArg() required this.data,
    required this.dragStartBehavior,
    this.findChildIndexCallback,
    this.itemExtent,
    required this.keyboardDismissBehavior,
    @JsonBuildArg() required this.model,
    this.padding,
    this.physics,
    required this.primary,
    this.prototypeItem,
    this.restorationId,
    required this.reverse,
    required this.scrollDirection,
    required this.shrinkWrap,
  });

  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double? cacheExtent;
  final Clip clipBehavior;
  final ChildWidgetBuilder? childBuilder;
  final List<JsonWidgetData> children;
  final ScrollController? controller;
  final JsonWidgetData data;
  final DragStartBehavior dragStartBehavior;
  final ChildIndexGetter? findChildIndexCallback;
  final double? itemExtent;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final JsonListViewBuilderModel model;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool primary;
  final JsonWidgetData? prototypeItem;
  final String? restorationId;
  final bool reverse;
  final Axis scrollDirection;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      addAutomaticKeepAlives: model.addAutomaticKeepAlives,
      addRepaintBoundaries: model.addRepaintBoundaries,
      addSemanticIndexes: model.addSemanticIndexes,
      cacheExtent: model.cacheExtent,
      clipBehavior: model.clipBehavior,
      controller: model.controller,
      dragStartBehavior: model.dragStartBehavior,
      findChildIndexCallback: findChildIndexCallback ??
          (key) {
            int? result;

            if (key is ValueKey) {
              final value = key.value?.toString();

              if (value != null) {
                for (var i = 0; i < children.length; i++) {
                  final child = children[i];
                  if (child.id == value) {
                    result = i;
                    break;
                  }
                }
              }
            }

            return result;
          },
      itemBuilder: (BuildContext context, int index) {
        final w = children[index].build(
          childBuilder: childBuilder,
          context: context,
          registry: data.registry,
        );
        return w;
      },
      itemCount: children.length,
      itemExtent: model.itemExtent,
      key: key,
      keyboardDismissBehavior: model.keyboardDismissBehavior,
      padding: model.padding,
      physics: model.physics,
      primary: model.primary,
      prototypeItem: model.prototypeItem?.build(
        context: context,
        childBuilder: childBuilder,
        registry: data.registry,
      ),
      restorationId: model.restorationId,
      reverse: model.reverse,
      scrollDirection: model.scrollDirection,
      semanticChildCount: children.length,
      shrinkWrap: model.shrinkWrap,
    );
  }
}
