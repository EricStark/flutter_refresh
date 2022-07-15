import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_refresh_component/behavior/scroll_behavior.dart';
import 'package:flutter_refresh_component/controller/controller.dart';
import 'package:flutter_refresh_component/indicator/footer/footer.dart';
import 'package:flutter_refresh_component/indicator/header/header.dart';
import 'package:flutter_refresh_component/indicator/indicator.dart';
import 'package:flutter_refresh_component/notifier/indicator_notifier.dart';
import 'package:flutter_refresh_component/physics/scroll_physics.dart';
import 'package:flutter_refresh_component/style/classic/footer/classic_footer.dart';
import 'package:flutter_refresh_component/style/classic/header/classic_header.dart';

/// EasyRefresh child builder.
/// Provide [ScrollPhysics], and use it in your [ScrollView].
/// [ScrollPhysics] will not be scoped.
typedef ERChildBuilder = Widget Function(
    BuildContext context, ScrollPhysics physics);

/// EasyRefresh needs to share data
class EasyRefreshData {
  /// Header status data and responsive
  final HeaderNotifier headerNotifier;

  /// Footer status data and responsive
  final FooterNotifier footerNotifier;

  /// Whether the user scrolls and responsive
  final ValueNotifier<bool> userOffsetNotifier;

  const EasyRefreshData({
    required this.headerNotifier,
    required this.footerNotifier,
    required this.userOffsetNotifier,
  });
}

class InheritedEasyRefresh extends InheritedWidget {
  final EasyRefreshData data;

  const InheritedEasyRefresh({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant InheritedEasyRefresh oldWidget) =>
      data != oldWidget.data;
}

class EasyRefresh extends StatefulWidget {
  /// Try to avoid including multiple ScrollViews.
  /// Or set separate ScrollPhysics for other ScrollView.
  /// Otherwise use [EasyRefresh.builder].
  final Widget? child;

  /// EasyRefresh controller.
  final EasyRefreshController? controller;

  /// Header indicator.
  final Header? header;

  /// Footer indicator.
  final Footer? footer;

  /// Overscroll behavior when [onRefresh] is null.
  /// Won't build widget.
  final NotRefreshHeader? notRefreshHeader;

  /// Overscroll behavior when [onLoad] is null.
  /// Won't build widget.
  final NotLoadFooter? notLoadFooter;

  /// EasyRefresh child builder.
  /// Provide [ScrollPhysics], and use it in your [ScrollView].
  /// [ScrollPhysics] will not be scoped.
  final ERChildBuilder? childBuilder;

  /// Refresh callback.
  /// Triggered on refresh.
  /// The Header current state is [IndicatorMode.processing].
  /// More see [IndicatorNotifier.onTask].
  final FutureOr Function()? onRefresh;

  /// Load callback.
  /// Triggered on load.
  /// The Footer current state is [IndicatorMode.processing].
  /// More see [IndicatorNotifier.onTask].
  final FutureOr Function()? onLoad;

  /// Structure that describes a spring's constants.
  /// When spring is not set in [Header] and [Footer].
  final SpringDescription? spring;

  /// Friction factor when list is out of bounds.
  final FrictionFactor? frictionFactor;

  /// Refresh and load can be performed simultaneously.
  final bool simultaneously;

  /// Is it possible to refresh after there is no more.
  final bool noMoreRefresh;

  /// Is it loadable after no more.
  final bool noMoreLoad;

  /// Reset after refresh when no more deactivation is loaded.
  final bool resetAfterRefresh;

  /// Refresh on start.
  /// When the EasyRefresh build is complete, trigger the refresh.
  final bool refreshOnStart;

  /// Header for refresh on start.
  /// Use [header] when null.
  final Header? refreshOnStartHeader;

  /// Offset beyond trigger offset when calling refresh.
  /// Used when refreshOnStart is true and [EasyRefreshController.callRefresh].
  final double callRefreshOverOffset;

  /// Offset beyond trigger offset when calling load.
  /// Used when [EasyRefreshController.callLoad].
  final double callLoadOverOffset;

  /// See [Stack.StackFit]
  final StackFit fit;

  /// See [Stack.clipBehavior].
  final Clip clipBehavior;

  /// Default header indicator.
  static Header get defaultHeader => defaultHeaderBuilder.call();
  static Header Function() defaultHeaderBuilder = _defaultHeaderBuilder;

  static Header _defaultHeaderBuilder() => const ClassicHeader();

  /// Default footer indicator.
  static Footer get defaultFooter => defaultFooterBuilder.call();
  static Footer Function() defaultFooterBuilder = _defaultFooterBuilder;

  static Footer _defaultFooterBuilder() => const ClassicFooter();

  const EasyRefresh({
    Key? key,
    required this.child,
    this.controller,
    this.header,
    this.footer,
    this.onRefresh,
    this.onLoad,
    this.spring,
    this.frictionFactor,
    this.notRefreshHeader,
    this.notLoadFooter,
    this.simultaneously = false,
    this.noMoreRefresh = false,
    this.noMoreLoad = false,
    this.resetAfterRefresh = true,
    this.refreshOnStart = false,
    this.refreshOnStartHeader,
    this.callRefreshOverOffset = 20,
    this.callLoadOverOffset = 20,
    this.fit = StackFit.loose,
    this.clipBehavior = Clip.hardEdge,
  })  : childBuilder = null,
        assert(callRefreshOverOffset > 0,
        'callRefreshOverOffset must be greater than 0.'),
        assert(callLoadOverOffset > 0,
        'callLoadOverOffset must be greater than 0.'),
        super(key: key);

  const EasyRefresh.builder({
    Key? key,
    required this.childBuilder,
    this.controller,
    this.header,
    this.footer,
    this.onRefresh,
    this.onLoad,
    this.spring,
    this.frictionFactor,
    this.notRefreshHeader,
    this.notLoadFooter,
    this.simultaneously = false,
    this.noMoreRefresh = false,
    this.noMoreLoad = false,
    this.resetAfterRefresh = true,
    this.refreshOnStart = false,
    this.refreshOnStartHeader,
    this.callRefreshOverOffset = 20,
    this.callLoadOverOffset = 20,
    this.fit = StackFit.loose,
    this.clipBehavior = Clip.hardEdge,
  })  : child = null,
        assert(callRefreshOverOffset > 0,
        'callRefreshOverOffset must be greater than 0.'),
        assert(callLoadOverOffset > 0,
        'callLoadOverOffset must be greater than 0.'),
        super(key: key);

  @override
  EasyRefreshState createState() => EasyRefreshState();

  static EasyRefreshData of(BuildContext context) {
    final inheritedEasyRefresh =
    context.dependOnInheritedWidgetOfExactType<InheritedEasyRefresh>();
    assert(inheritedEasyRefresh != null,
    'Please use it in the scope of EasyRefresh!');
    return inheritedEasyRefresh!.data;
  }
}

class EasyRefreshState extends State<EasyRefresh>
    with TickerProviderStateMixin {
  /// [ScrollPhysics] use it in EasyRefresh.
  late ERScrollPhysics _physics;

  /// Needs to share data.
  late EasyRefreshData _data;

  /// User triggered notifier.
  /// Record user triggers and releases.
  ValueNotifier<bool> get userOffsetNotifier => _data.userOffsetNotifier;

  /// Header indicator notifier.
  HeaderNotifier get headerNotifier => _data.headerNotifier;

  /// Footer indicator notifier.
  FooterNotifier get footerNotifier => _data.footerNotifier;

  /// Whether the current is refresh on start.
  bool isRefreshOnStart = false;

  /// Indicator waiting for refresh task to complete.
  bool get waitRefreshResult =>
      !(widget.controller?.controlFinishRefresh ?? false);

  /// Indicator waiting for load task to complete.
  bool get waitLoadResult => !(widget.controller?.controlFinishLoad ?? false);

  /// Use [EasyRefresh._defaultHeader] without [EasyRefresh.header].
  /// Use [NotRefreshHeader] when [EasyRefresh.onRefresh] is null.
  Header get header {
    if (widget.onRefresh == null) {
      if (widget.notRefreshHeader != null) {
        return widget.notRefreshHeader!;
      } else {
        final h = widget.header ?? EasyRefresh.defaultHeader;
        return NotRefreshHeader(
          clamping: h.clamping,
          spring: h.spring,
          frictionFactor: h.frictionFactor,
        );
      }
    } else {
      Header h = widget.header ?? EasyRefresh.defaultHeader;
      if (isRefreshOnStart) {
        h = widget.refreshOnStartHeader ?? h;
      }
      return h;
    }
  }

  /// Use [EasyRefresh._defaultFooter] without [EasyRefresh.footer].
  /// Use [NotLoadFooter] when [EasyRefresh.onLoad] is null.
  Footer get footer {
    if (widget.onLoad == null) {
      if (widget.notLoadFooter != null) {
        return widget.notLoadFooter!;
      } else {
        final f = widget.footer ?? EasyRefresh.defaultFooter;
        return NotLoadFooter(
          clamping: f.clamping,
          spring: f.spring,
          frictionFactor: f.frictionFactor,
        );
      }
    } else {
      return widget.footer ?? EasyRefresh.defaultFooter;
    }
  }

  @override
  void initState() {
    super.initState();
    // Refresh on start.
    if (widget.refreshOnStart && widget.onRefresh != null) {
      isRefreshOnStart = true;
      Future(() {
        callRefresh(
          overOffset: widget.callRefreshOverOffset,
          duration: null,
        );
      });
    }
    _initData();
    widget.controller?.bind(this);
  }

  @override
  void didUpdateWidget(covariant EasyRefresh oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update header and footer.
    print('***************${header.clamping}');
    headerNotifier.update(
      indicator: header,
      noMoreProcess: widget.noMoreRefresh,
      task: _onRefresh,
      waitTaskRefresh: waitRefreshResult,
    );
    footerNotifier.update(
      indicator: footer,
      noMoreProcess: widget.noMoreLoad,
      task: widget.onLoad,
      waitTaskRefresh: waitLoadResult,
    );
    // Update controller.
    if (widget.controller != null &&
        oldWidget.controller != widget.controller) {
      widget.controller?.bind(this);
    }
  }

  @override
  void dispose() {
    headerNotifier.dispose();
    footerNotifier.dispose();
    userOffsetNotifier.dispose();
    super.dispose();
  }

  /// Initialize [EasyRefreshData].
  void _initData() {
    final userOffsetNotifier = ValueNotifier<bool>(false);
    _data = EasyRefreshData(
      userOffsetNotifier: userOffsetNotifier,
      headerNotifier: HeaderNotifier(
        header: header,
        userOffsetNotifier: userOffsetNotifier,
        vsync: this,
        onRefresh: _onRefresh,
        noMoreRefresh: widget.noMoreRefresh,
        waitRefreshResult: waitRefreshResult,
        onCanRefresh: () {
          if (widget.simultaneously) {
            return true;
          } else {
            return !footerNotifier.processing;
          }
        },
      ),
      footerNotifier: FooterNotifier(
        footer: footer,
        userOffsetNotifier: userOffsetNotifier,
        vsync: this,
        onLoad: widget.onLoad,
        noMoreLoad: widget.noMoreLoad,
        waitLoadResult: waitLoadResult,
        onCanLoad: () {
          if (widget.simultaneously) {
            return true;
          } else {
            return !headerNotifier.processing;
          }
        },
      ),
    );
    _physics = ERScrollPhysics(
      userOffsetNotifier: userOffsetNotifier,
      headerNotifier: headerNotifier,
      footerNotifier: footerNotifier,
      spring: widget.spring,
      frictionFactor: widget.frictionFactor,
    );
  }

  /// Refresh on start listener.
  /// From [IndicatorMode.processing] to [IndicatorMode.inactive].
  /// When back to inactive, end listening.
  void _refreshOnStartListener() {
    if (headerNotifier.mode == IndicatorMode.inactive) {
      isRefreshOnStart = false;
      headerNotifier.removeListener(_refreshOnStartListener);
      headerNotifier.update(
        indicator: header,
        task: _onRefresh,
      );
    }
  }

  /// Refresh callback.
  /// Handle [EasyRefresh.resetAfterRefresh].
  FutureOr Function()? get _onRefresh {
    if (widget.onRefresh == null) {
      return null;
    }
    return () async {
      // Start listening on refresh.
      if (isRefreshOnStart) {
        headerNotifier.addListener(_refreshOnStartListener);
      }
      final res = await Future.sync(widget.onRefresh!);
      // Reset Footer state.
      if (widget.resetAfterRefresh) {
        footerNotifier.reset();
      }
      return res;
    };
  }

  /// Automatically trigger refresh.
  /// [overOffset] Offset beyond the trigger offset, must be greater than 0.
  /// [duration] See [ScrollPosition.animateTo].
  /// [curve] See [ScrollPosition.animateTo].
  Future callRefresh({
    double? overOffset,
    Duration? duration,
    Curve curve = Curves.linear,
  }) {
    return headerNotifier.callTask(
      overOffset: overOffset ?? widget.callRefreshOverOffset,
      duration: duration,
      curve: curve,
    );
  }

  /// Automatically trigger load.
  /// [overOffset] Offset beyond the trigger offset, must be greater than 0.
  /// [duration] See [ScrollPosition.animateTo].
  /// [curve] See [ScrollPosition.animateTo].
  Future callLoad({
    double? overOffset,
    Duration? duration,
    Curve curve = Curves.linear,
  }) {
    return footerNotifier.callTask(
      overOffset: overOffset ?? widget.callRefreshOverOffset,
      duration: duration,
      curve: curve,
    );
  }

  /// Build Header widget.
  /// When the Header [Indicator.position] is
  /// [IndicatorPosition.above] or [IndicatorPosition.above].
  Widget buildHeaderView() {
    return ValueListenableBuilder(
      valueListenable: headerNotifier.listenable(),
      builder: (ctx, notifier, _) {
        // Physics is not initialized.
        if (headerNotifier.axis == null ||
            headerNotifier.axisDirection == null) {
          return const SizedBox();
        }
        // Axis and direction.
        final axis = headerNotifier.axis!;
        final axisDirection = headerNotifier.axisDirection!;
        // Set safe area offset.
        final safePadding = MediaQuery.of(context).padding;
        headerNotifier.safeOffset1 = axis == Axis.vertical
            ? axisDirection == AxisDirection.down
            ? safePadding.top
            : safePadding.bottom
            : axisDirection == AxisDirection.right
            ? safePadding.left
            : safePadding.right;
        return Positioned(
          top: axis == Axis.vertical
              ? axisDirection == AxisDirection.down
              ? 0
              : null
              : 0,
          bottom: axis == Axis.vertical
              ? axisDirection == AxisDirection.up
              ? 0
              : null
              : 0,
          left: axis == Axis.horizontal
              ? axisDirection == AxisDirection.right
              ? 0
              : null
              : 0,
          right: axis == Axis.horizontal
              ? axisDirection == AxisDirection.left
              ? 0
              : null
              : 0,
          child: headerNotifier.build(context),
        );
      },
    );
  }

  /// Build Footer widget.
  /// When the Footer [Indicator.position] is
  /// [IndicatorPosition.above] or [IndicatorPosition.above].
  Widget buildFooterView() {
    return ValueListenableBuilder(
      valueListenable: footerNotifier.listenable(),
      builder: (ctx, notifier, _) {
        // Physics is not initialized.
        if (headerNotifier.axis == null ||
            headerNotifier.axisDirection == null) {
          return const SizedBox();
        }
        // Axis and direction.
        final axis = headerNotifier.axis!;
        final axisDirection = headerNotifier.axisDirection!;
        // Set safe area offset.
        final safePadding = MediaQuery.of(context).padding;
        footerNotifier.safeOffset1 = axis == Axis.vertical
            ? axisDirection == AxisDirection.down
            ? safePadding.bottom
            : safePadding.top
            : axisDirection == AxisDirection.right
            ? safePadding.right
            : safePadding.left;
        return Positioned(
          top: axis == Axis.vertical
              ? axisDirection == AxisDirection.up
              ? 0
              : null
              : 0,
          bottom: axis == Axis.vertical
              ? axisDirection == AxisDirection.down
              ? 0
              : null
              : 0,
          left: axis == Axis.horizontal
              ? axisDirection == AxisDirection.left
              ? 0
              : null
              : 0,
          right: axis == Axis.horizontal
              ? axisDirection == AxisDirection.right
              ? 0
              : null
              : 0,
          child: footerNotifier.build(context),
        );
      },
    );
  }

  /// Build content widget.
  Widget buildContent() {
    Widget child;
    if (widget.childBuilder != null) {
      child = ScrollConfiguration(
        behavior: const ERScrollBehavior(),
        child: widget.childBuilder!(context, _physics),
      );
    } else {
      child = ScrollConfiguration(
        behavior: ERScrollBehavior(_physics),
        child: widget.child!,
      );
    }
    return InheritedEasyRefresh(
      data: _data,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentWidget = buildContent();
    final List<Widget> children = [];
    final hPosition = headerNotifier.iPosition;
    final fPosition = footerNotifier.iPosition;
    // Set the position of widgets.
    if (hPosition == IndicatorPosition.behind) {
      children.add(buildHeaderView());
    }
    if (fPosition == IndicatorPosition.behind) {
      children.add(buildFooterView());
    }
    children.add(contentWidget);
    if (hPosition == IndicatorPosition.above) {
      children.add(buildHeaderView());
    }
    if (fPosition == IndicatorPosition.above) {
      children.add(buildFooterView());
    }
    if (children.length == 1) {
      children.clear();
      return contentWidget;
    }
    return Stack(
      clipBehavior: widget.clipBehavior,
      fit: StackFit.loose,
      children: children,
    );
  }
}
