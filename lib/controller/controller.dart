
import 'package:flutter/animation.dart';
import 'package:flutter_refresh_component/easy_refresh.dart';
import 'package:flutter_refresh_component/indicator/indicator.dart';

/// Controls a EasyRefresh widget.
/// Control refresh, loading and indicator states.
class EasyRefreshController {
  /// Take over the completion event of the refresh task.
  /// Finish the refresh with [finishRefresh] and return the result.
  final bool controlFinishRefresh;

  /// Take over the completion event of the load task.
  /// Finish the load with [finishLoad] and return the result.
  final bool controlFinishLoad;

  /// [EasyRefresh] sate.
  EasyRefreshState? _state;

  EasyRefreshController({
    this.controlFinishRefresh = false,
    this.controlFinishLoad = false,
  });

  /// Binding with EasyRefresh.
  void bind(EasyRefreshState state) {
    _state = state;
  }

  /// Automatically trigger refresh.
  /// [overOffset] Offset beyond the trigger offset, must be greater than 0.
  /// [duration] See [ScrollPosition.animateTo].
  /// [curve] See [ScrollPosition.animateTo].
  Future callRefresh({
    double? overOffset,
    Duration? duration = const Duration(milliseconds: 200),
    Curve curve = Curves.linear,
  }) async {
    await _state?.callRefresh(
      overOffset: overOffset,
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
    Duration? duration = const Duration(milliseconds: 300),
    Curve curve = Curves.linear,
  }) async {
    await _state?.callLoad(
      overOffset: overOffset,
      duration: duration,
      curve: curve,
    );
  }

  /// Open header secondary.
  /// [duration] See [ScrollPosition.animateTo].
  /// [curve] See [ScrollPosition.animateTo].
  Future openHeaderSecondary({
    Duration? duration = const Duration(milliseconds: 200),
    Curve curve = Curves.linear,
  }) async {
    if (_state == null) {
      return;
    }
    if (_state!.header.secondaryTriggerOffset != null) {
      final headerNotifier = _state!.headerNotifier;
      if (headerNotifier.modeLocked ||
          headerNotifier.noMoreLocked ||
          headerNotifier.secondaryLocked ||
          !headerNotifier.canProcess) {
        return;
      }
      await headerNotifier.animateToOffset(
        offset: headerNotifier.secondaryDimension,
        mode: IndicatorMode.secondaryOpen,
        duration: duration,
        curve: curve,
      );
    }
  }

  /// Close header secondary.
  /// [duration] See [ScrollPosition.animateTo].
  /// [curve] See [ScrollPosition.animateTo].
  Future closeHeaderSecondary({
    Duration? duration = const Duration(milliseconds: 200),
    Curve curve = Curves.linear,
  }) async {
    if (_state == null) {
      return;
    }
    if (_state!.header.secondaryTriggerOffset != null) {
      final headerNotifier = _state!.headerNotifier;
      if (headerNotifier.mode != IndicatorMode.secondaryOpen) {
        return;
      }
      await headerNotifier.animateToOffset(
        offset: 0,
        mode: IndicatorMode.inactive,
        jumpToEdge: false,
        duration: duration,
        curve: curve,
      );
    }
  }

  /// Open footer secondary.
  /// [duration] See [ScrollPosition.animateTo].
  /// [curve] See [ScrollPosition.animateTo].
  Future openFooterSecondary({
    Duration? duration = const Duration(milliseconds: 200),
    Curve curve = Curves.linear,
  }) async {
    if (_state == null) {
      return;
    }
    if (_state!.footer.secondaryTriggerOffset != null) {
      final footerNotifier = _state!.footerNotifier;
      if (footerNotifier.modeLocked ||
          footerNotifier.noMoreLocked ||
          footerNotifier.secondaryLocked ||
          !footerNotifier.canProcess) {
        return;
      }
      await footerNotifier.animateToOffset(
        offset: footerNotifier.secondaryDimension,
        mode: IndicatorMode.secondaryOpen,
        jumpToEdge: false,
        duration: duration,
        curve: curve,
      );
    }
  }

  /// Close footer secondary.
  /// [duration] See [ScrollPosition.animateTo].
  /// [curve] See [ScrollPosition.animateTo].
  Future closeFooterSecondary({
    Duration? duration = const Duration(milliseconds: 200),
    Curve curve = Curves.linear,
  }) async {
    if (_state == null) {
      return;
    }
    if (_state!.footer.secondaryTriggerOffset != null) {
      final footerNotifier = _state!.footerNotifier;
      if (footerNotifier.mode != IndicatorMode.secondaryOpen) {
        return;
      }
      await footerNotifier.animateToOffset(
        offset: 0,
        mode: IndicatorMode.inactive,
        duration: duration,
        curve: curve,
      );
    }
  }

  /// Reset Header indicator state.
  void resetHeader() {
    _state?.headerNotifier.reset();
  }

  /// Reset Footer indicator state.
  void resetFooter() {
    _state?.footerNotifier.reset();
  }

  /// Finish the refresh task and return the result.
  /// [result] Result of task completion.
  void finishRefresh([IndicatorResult result = IndicatorResult.success]) {
    assert(controlFinishRefresh,
    'Please set controlFinishRefresh to true, then use.');
    _state?.headerNotifier.finishTask(result);
  }

  /// Finish the load task and return the result.
  /// [result] Result of task completion.
  void finishLoad([IndicatorResult result = IndicatorResult.success]) {
    assert(controlFinishRefresh,
    'Please set controlFinishLoad to true, then use.');
    _state?.footerNotifier.finishTask(result);
  }

  /// Unbind.
  void dispose() {
    _state = null;
  }
}
