import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_refresh_component/indicator/indicator.dart';
import 'dart:math' as math;

import 'package:flutter_refresh_component/notifier/indicator_notifier.dart';
/// The multiple applied to overscroll to make it appear that scrolling past
/// the edge of the scrollable contents is harder than scrolling the list.
/// This is done by reducing the ratio of the scroll effect output vs the
/// scroll gesture input.
typedef FrictionFactor = double Function(double overscrollFraction);

/// EasyRefresh scroll physics.
class ERScrollPhysics extends BouncingScrollPhysics {
  ERScrollPhysics({
    ScrollPhysics? parent = const AlwaysScrollableScrollPhysics(),
    required this.userOffsetNotifier,
    required this.headerNotifier,
    required this.footerNotifier,
    SpringDescription? spring,
    FrictionFactor? frictionFactor,
  })  : _spring = spring,
        _frictionFactor = frictionFactor,
        super(parent: parent) {
    headerNotifier.bindPhysics(this);
    footerNotifier.bindPhysics(this);
  }

  @override
  ERScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ERScrollPhysics(
      parent: buildParent(ancestor),
      userOffsetNotifier: userOffsetNotifier,
      headerNotifier: headerNotifier,
      footerNotifier: footerNotifier,
      spring: _spring,
      frictionFactor: _frictionFactor,
    );
  }

  final ValueNotifier<bool> userOffsetNotifier;
  final HeaderNotifier headerNotifier;
  final FooterNotifier footerNotifier;

  /// The spring to use for ballistic simulations.
  final SpringDescription? _spring;

  /// The state of the indicator when the BallisticSimulation is created.
  final _headerSimulationCreationState =
  ValueNotifier<_BallisticSimulationCreationState>(
    const _BallisticSimulationCreationState(
      mode: IndicatorMode.inactive,
      offset: 0,
    ),
  );
  final _footerSimulationCreationState =
  ValueNotifier<_BallisticSimulationCreationState>(
    const _BallisticSimulationCreationState(
      mode: IndicatorMode.inactive,
      offset: 0,
    ),
  );

  /// Get the current [SpringDescription] to be used.
  @override
  SpringDescription get spring {
    if (headerNotifier.outOfRange) {
      if (headerNotifier.mode == IndicatorMode.ready &&
          headerNotifier.readySpringBuilder != null) {
        return headerNotifier.readySpringBuilder!(
          mode: headerNotifier.mode,
          offset: headerNotifier.offset,
          actualTriggerOffset: headerNotifier.actualTriggerOffset,
          velocity: headerNotifier.velocity,
        );
      } else if (headerNotifier.spring1 != null) {
        return headerNotifier.spring1!;
      }
    }
    if (footerNotifier.outOfRange) {
      if (footerNotifier.mode == IndicatorMode.ready &&
          footerNotifier.readySpringBuilder != null) {
        return footerNotifier.readySpringBuilder!(
          mode: footerNotifier.mode,
          offset: footerNotifier.offset,
          actualTriggerOffset: headerNotifier.actualTriggerOffset,
          velocity: headerNotifier.velocity,
        );
      } else if (footerNotifier.spring1 != null) {
        return footerNotifier.spring1!;
      }
    }
    return _spring ?? super.spring;
  }

  /// Friction factor when list is out of bounds.
  final FrictionFactor? _frictionFactor;

  @override
  double frictionFactor(double overscrollFraction) {
    FrictionFactor factor;
    if (headerNotifier.frictionFactor1 != null && headerNotifier.outOfRange) {
      factor = headerNotifier.frictionFactor1!;
    } else if (footerNotifier.frictionFactor1 != null &&
        footerNotifier.outOfRange) {
      factor = footerNotifier.frictionFactor1!;
    } else {
      factor = _frictionFactor ?? super.frictionFactor;
    }
    return factor.call(overscrollFraction);
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // User started scrolling.
    userOffsetNotifier.value = true;
    assert(offset != 0.0);
    assert(position.minScrollExtent <= position.maxScrollExtent);

    // Whether it is overscroll.
    // When clamping is true,
    // the indicator offset shall prevail.
    if (!(position.outOfRange ||
        (headerNotifier.clamping && headerNotifier.outOfRange) ||
        (footerNotifier.clamping && footerNotifier.outOfRange))) {
      return offset;
    }
    // Calculate the actual location.
    double pixels = position.pixels;
    if (headerNotifier.clamping && headerNotifier.outOfRange) {
      pixels = position.pixels - headerNotifier.offset;
    }
    if (footerNotifier.clamping && footerNotifier.outOfRange) {
      pixels = position.pixels + footerNotifier.offset;
    }
    double minScrollExtent = position.minScrollExtent;
    double maxScrollExtent = position.maxScrollExtent;

    if (headerNotifier.secondaryLocked) {
      // Header secondary
      pixels = headerNotifier.secondaryDimension +
          (headerNotifier.secondaryDimension + position.pixels);
      minScrollExtent = 0;
      maxScrollExtent = headerNotifier.secondaryDimension;
    }

    if (footerNotifier.secondaryLocked) {
      // Footer secondary
      pixels = position.pixels -
          footerNotifier.secondaryDimension -
          position.maxScrollExtent;
      minScrollExtent = 0;
      maxScrollExtent = footerNotifier.secondaryDimension;
    }

    final double overscrollPastStart = math.max(minScrollExtent - pixels, 0.0);
    final double overscrollPastEnd = math.max(pixels - maxScrollExtent, 0.0);
    final double overscrollPast =
    math.max(overscrollPastStart, overscrollPastEnd);
    final bool easing = (overscrollPastStart > 0.0 && offset < 0.0) ||
        (overscrollPastEnd > 0.0 && offset > 0.0);

    final double friction = easing
    // Apply less resistance when easing the overscroll vs tensioning.
        ? frictionFactor(
        (overscrollPast - offset.abs()) / position.viewportDimension)
        : frictionFactor(overscrollPast / position.viewportDimension);
    final double direction = offset.sign;

    return direction * _applyFriction(overscrollPast, offset.abs(), friction);
  }

  static double _applyFriction(
      double extentOutside, double absDelta, double gamma) {
    assert(absDelta > 0);
    double total = 0.0;
    if (extentOutside > 0) {
      final double deltaToLimit = extentOutside / gamma;
      if (absDelta < deltaToLimit) return absDelta * gamma;
      total += extentOutside;
      absDelta -= deltaToLimit;
    }
    return total + absDelta;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Extend of overscroll for offset.
    double bounds = 0;

    // Header
    if (headerNotifier.clamping == true) {
      if (value < position.pixels &&
          position.pixels <= position.minScrollExtent) {
        // underscroll
        bounds = value - position.pixels;
      } else if (value < position.minScrollExtent &&
          position.minScrollExtent < position.pixels) {
        // hit top edge
        _updateIndicatorOffset(position, 0);
        return value - position.minScrollExtent;
      } else if (headerNotifier.offset > 0 &&
          !(headerNotifier.modeLocked || headerNotifier.secondaryLocked)) {
        // Header does not disappear,
        // and the list does not shift.
        bounds = value - position.pixels;
      }
    } else {
      // hit top over
      if (!(headerNotifier.hitOver || headerNotifier.modeLocked) &&
          headerNotifier.mode != IndicatorMode.ready &&
          value < position.minScrollExtent &&
          position.minScrollExtent < position.pixels) {
        _updateIndicatorOffset(position, 0);
        return value - position.minScrollExtent;
      }
      // infinite hit top over
      if ((!headerNotifier.infiniteHitOver ||
          (!headerNotifier.hitOver && headerNotifier.modeLocked)) &&
          (headerNotifier.canProcess || headerNotifier.noMoreLocked) &&
          (value + headerNotifier.actualTriggerOffset) <
              position.minScrollExtent &&
          position.minScrollExtent <
              (position.pixels + headerNotifier.actualTriggerOffset)) {
        _updateIndicatorOffset(position, -headerNotifier.actualTriggerOffset);
        return (value + headerNotifier.actualTriggerOffset) -
            position.minScrollExtent;
      }
      // Stop spring rebound.
      if (headerNotifier.releaseOffset > 0 &&
          headerNotifier.mode == IndicatorMode.ready &&
          !headerNotifier.indicator.springRebound &&
          -value < headerNotifier.actualTriggerOffset) {
        _updateIndicatorOffset(position, -headerNotifier.actualTriggerOffset);
        return headerNotifier.actualTriggerOffset +
            value -
            position.minScrollExtent;
      }
      // if (!userOffsetNotifier.value &&
      //     (headerNotifier._mode == IndicatorMode.done ||
      //         headerNotifier._mode == IndicatorMode.drag) &&
      //     value > position.minScrollExtent) {
      //   _updateIndicatorOffset(position, 0);
      //   return value - position.minScrollExtent;
      // }
      // Cannot over the secondary.
      if (headerNotifier.hasSecondary) {
        if (value < position.pixels &&
            position.pixels <=
                position.minScrollExtent - headerNotifier.secondaryDimension) {
          // underscroll secondary
          bounds = value - position.pixels;
        } else if (value + headerNotifier.secondaryDimension <
            position.minScrollExtent &&
            position.minScrollExtent <
                position.pixels + headerNotifier.secondaryDimension) {
          // hit top secondary
          _updateIndicatorOffset(position, -headerNotifier.secondaryDimension);
          return value +
              headerNotifier.secondaryDimension -
              position.minScrollExtent;
        }
      }
    }

    // Footer
    if (footerNotifier.clamping == true) {
      if (position.maxScrollExtent <= position.pixels &&
          position.pixels < value) {
        // overscroll
        bounds = value - position.pixels;
      } else if (position.pixels < position.maxScrollExtent &&
          position.maxScrollExtent < value) {
        // hit bottom edge
        _updateIndicatorOffset(position, position.maxScrollExtent);
        return value - position.maxScrollExtent;
      } else if (footerNotifier.offset > 0 &&
          !(footerNotifier.modeLocked || footerNotifier.secondaryLocked)) {
        // Footer does not disappear,
        // and the list does not shift.
        bounds = value - position.pixels;
      }
    } else {
      // hit bottom over
      if (!(footerNotifier.hitOver || footerNotifier.modeLocked) &&
          footerNotifier.mode != IndicatorMode.ready &&
          position.pixels < position.maxScrollExtent &&
          position.maxScrollExtent < value) {
        _updateIndicatorOffset(position, position.maxScrollExtent);
        return value - position.maxScrollExtent;
      }
      // infinite hit bottom over
      if ((!footerNotifier.infiniteHitOver ||
          !footerNotifier.hitOver && footerNotifier.modeLocked) &&
          (footerNotifier.canProcess || footerNotifier.noMoreLocked) &&
          (position.pixels - footerNotifier.actualTriggerOffset) <
              position.maxScrollExtent &&
          position.maxScrollExtent <
              (value - footerNotifier.actualTriggerOffset)) {
        _updateIndicatorOffset(position,
            position.maxScrollExtent + footerNotifier.actualTriggerOffset);
        return (value - footerNotifier.actualTriggerOffset) -
            position.maxScrollExtent;
      }
      // Stop spring rebound.
      if (footerNotifier.releaseOffset > 0 &&
          footerNotifier.mode == IndicatorMode.ready &&
          !footerNotifier.indicator.springRebound &&
          value <
              position.maxScrollExtent + footerNotifier.actualTriggerOffset) {
        _updateIndicatorOffset(position,
            position.maxScrollExtent + footerNotifier.actualTriggerOffset);
        return (value - footerNotifier.actualTriggerOffset) -
            position.maxScrollExtent;
      }
      // if (!userOffsetNotifier.value &&
      //     (footerNotifier._mode == IndicatorMode.done ||
      //         footerNotifier._mode == IndicatorMode.drag) &&
      //     value < position.maxScrollExtent) {
      //   _updateIndicatorOffset(position, position.maxScrollExtent);
      //   return value - position.maxScrollExtent;
      // }
      // Cannot over the secondary.
      if (footerNotifier.hasSecondary) {
        if (position.maxScrollExtent + footerNotifier.secondaryDimension <=
            position.pixels &&
            position.pixels < value) {
          // overscroll
          bounds = value - position.pixels;
        } else if (position.pixels - footerNotifier.secondaryDimension <
            position.maxScrollExtent &&
            position.maxScrollExtent <
                value - footerNotifier.secondaryDimension) {
          // hit bottom edge
          _updateIndicatorOffset(position,
              position.maxScrollExtent + footerNotifier.secondaryDimension);
          return value -
              footerNotifier.secondaryDimension -
              position.maxScrollExtent;
        }
      }
    }

    // Update offset
    _updateIndicatorOffset(position, value);
    return bounds;
  }

  // Update indicator offset
  void _updateIndicatorOffset(ScrollMetrics position, double value) {
    final hClamping = headerNotifier.clamping && headerNotifier.offset > 0;
    final fClamping = footerNotifier.clamping && footerNotifier.offset > 0;
    headerNotifier.updateOffset(position, fClamping ? 0 : value, false);
    footerNotifier.updateOffset(position, hClamping ? 0 : value, false);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    // User stopped scrolling.
    final oldUserOffset = userOffsetNotifier.value;
    userOffsetNotifier.value = false;
    // Simulation update.
    headerNotifier.updateBySimulation(position, velocity);
    footerNotifier.updateBySimulation(position, velocity);
    // Create simulation.
    final hState = _BallisticSimulationCreationState(
      mode: headerNotifier.mode,
      offset: headerNotifier.offset,
    );
    final fState = _BallisticSimulationCreationState(
      mode: footerNotifier.mode,
      offset: footerNotifier.offset,
    );
    Simulation? simulation;
    bool hSecondary = !headerNotifier.clamping &&
        (headerNotifier.mode == IndicatorMode.secondaryReady ||
            headerNotifier.mode == IndicatorMode.secondaryOpen);
    bool fSecondary = !headerNotifier.clamping &&
        (footerNotifier.mode == IndicatorMode.secondaryReady ||
            footerNotifier.mode == IndicatorMode.secondaryOpen);
    bool secondary = hSecondary || fSecondary;
    if (velocity.abs() >= tolerance.velocity ||
        (position.outOfRange || (secondary && oldUserOffset)) &&
            (oldUserOffset ||
                _headerSimulationCreationState.value.needCreation(hState) ||
                _footerSimulationCreationState.value.needCreation(fState))) {
      double mVelocity = velocity;
      // Open secondary speed.
      if (secondary) {
        if (hSecondary) {
          if (headerNotifier.offset == headerNotifier.secondaryDimension) {
            mVelocity = 0;
          } else if (mVelocity > -headerNotifier.secondaryVelocity) {
            mVelocity = -headerNotifier.secondaryVelocity;
          }
        } else if (fSecondary) {
          if (footerNotifier.offset == footerNotifier.secondaryDimension) {
            mVelocity = 0;
          } else if (mVelocity < footerNotifier.secondaryVelocity) {
            mVelocity = footerNotifier.secondaryVelocity;
          }
        }
      }
      simulation = BouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        velocity: mVelocity,
        leadingExtent: position.minScrollExtent - headerNotifier.overExtent,
        trailingExtent: position.maxScrollExtent + footerNotifier.overExtent,
        tolerance: tolerance,
      );
    }
    _headerSimulationCreationState.value = hState;
    _footerSimulationCreationState.value = fState;
    return simulation;
  }
}

/// The state of the indicator when the BallisticSimulation is created.
/// Used to determine whether BallisticSimulation needs to be created.
class _BallisticSimulationCreationState {
  final IndicatorMode mode;
  final double offset;

  const _BallisticSimulationCreationState({
    required this.mode,
    required this.offset,
  });

  bool needCreation(_BallisticSimulationCreationState newState) {
    return mode != newState.mode || offset != newState.offset;
  }
}
