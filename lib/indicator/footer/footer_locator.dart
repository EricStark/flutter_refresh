import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_refresh_component/easy_refresh.dart';
import 'package:flutter_refresh_component/indicator/indicator.dart';
import 'dart:math' as math;
/// Find Footer's Location
/// Put the last item in the list
/// it will smartly show Footer
class FooterLocator extends StatelessWidget {
  final bool _isSliver;

  /// Link [SliverGeometry.paintExtent].
  /// Extent that is always maintained.
  final double paintExtent;

  /// Whether to calculate the extent.
  /// When true, extent is always 0.
  final bool clearExtent;

  /// Use in Box
  const FooterLocator({
    Key? key,
    this.paintExtent = 0,
    this.clearExtent = true,
  })  : _isSliver = false,
        super(key: key);

  /// User in Sliver
  const FooterLocator.sliver({
    Key? key,
    this.paintExtent = 0,
    this.clearExtent = true,
  })  : _isSliver = true,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final footerNotifier = EasyRefresh.of(context).footerNotifier;
    assert(
    footerNotifier.iPosition == IndicatorPosition.locator ||
        footerNotifier.iPosition == IndicatorPosition.custom,
    'Cannot use FooterLocator when header position is not IndicatorPosition.locator.');
    footerNotifier.safeOffset1 = MediaQuery.of(context).padding.bottom;
    return ValueListenableBuilder(
      valueListenable: footerNotifier.listenable(),
      builder: (ctx, notifier, _) {
        final footerWidget = footerNotifier.build(context);
        if (!clearExtent) {
          return _isSliver
              ? SliverToBoxAdapter(
            child: footerWidget,
          )
              : footerWidget;
        }
        return FooterLocatorRenderWidget(
          child: footerWidget,
          isSliver: _isSliver,
          paintExtent: paintExtent,
        );
      },
    );
  }
}

class FooterLocatorRenderWidget extends SingleChildRenderObjectWidget {
  final bool isSliver;

  final double paintExtent;

  const FooterLocatorRenderWidget({
    Key? key,
    required Widget? child,
    required this.isSliver,
    required this.paintExtent,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => isSliver
      ? FooterLocatorRenderSliver(
    context: context,
    paintExtent: paintExtent,
  )
      : FooterLocatorRenderBox(
    context: context,
    paintExtent: paintExtent,
  );
}

/// User in Box
class FooterLocatorRenderBox extends RenderProxyBox {
  final BuildContext context;

  final double paintExtent;

  FooterLocatorRenderBox({
    required this.context,
    required this.paintExtent,
    RenderBox? child,
  }) : super(child);

  @override
  final bool needsCompositing = true;

  @override
  void performLayout() {
    final footerNotifier = EasyRefresh.of(context).footerNotifier;
    final axis = footerNotifier.axis;
    final double extend = paintExtent == 0
        ? (footerNotifier.offset == 0 ? 0 : 0.0000000001)
        : paintExtent;
    if (axis == null) {
      size = constraints.smallest;
    } else {
      size = Size(
        constraints
            .constrainWidth(axis == Axis.vertical ? double.infinity : extend),

        /// Not 0 will be paint
        constraints
            .constrainHeight(axis == Axis.vertical ? extend : double.infinity),
      );
    }
    if (child != null) {
      child!.layout(constraints, parentUsesSize: true);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final footerNotifier = EasyRefresh.of(this.context).footerNotifier;
    final axis = footerNotifier.axis;
    final axisDirection = footerNotifier.axisDirection;
    final extend = footerNotifier.offset;
    Offset mOffset;
    if (axis == null || axisDirection == null) {
      mOffset = offset;
    } else {
      final double dx = axis == Axis.vertical
          ? 0
          : axisDirection == AxisDirection.left
          ? -extend
          : 0;
      final double dy = axis == Axis.horizontal
          ? 0
          : axisDirection == AxisDirection.up
          ? -extend
          : 0;
      mOffset = Offset(dx, dy);
    }
    if (child != null) {
      context.paintChild(child!, mOffset);
    }
  }
}

/// User in Sliver
class FooterLocatorRenderSliver extends RenderSliverSingleBoxAdapter {
  final BuildContext context;

  final double paintExtent;

  FooterLocatorRenderSliver({
    required this.context,
    required this.paintExtent,
    RenderBox? child,
  }) : super(child: child);

  @override
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }
    final SliverConstraints constraints = this.constraints;
    child!.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    final double childExtent;
    switch (constraints.axis) {
      case Axis.horizontal:
        childExtent = child!.size.width;
        break;
      case Axis.vertical:
        childExtent = child!.size.height;
        break;
    }
    final double paintedChildSize =
    calculatePaintOffset(constraints, from: 0, to: childExtent);
    // final double cacheExtent =
    //     calculateCacheOffset(constraints, from: 0, to: childExtent);

    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0);
    final footerNotifier = EasyRefresh.of(context).footerNotifier;
    geometry = SliverGeometry(
      scrollExtent: 0,
      paintExtent: math.min(childExtent, paintExtent),
      paintOrigin: constraints.axisDirection == AxisDirection.down ||
          constraints.axisDirection == AxisDirection.right
          ? 0
          : math.min(footerNotifier.offset, constraints.remainingPaintExtent),
      // No cache extent.
      cacheExtent: math.min(childExtent, paintExtent),
      maxPaintExtent: math.max(childExtent, paintExtent),
      hitTestExtent: paintedChildSize,
      hasVisualOverflow: childExtent > constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0,
      visible: true,
    );
    setChildParentData(child!, constraints.copyWith(), geometry!);
  }
}
