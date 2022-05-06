// ignore_for_file: cascade_invocations, prefer_const_constructors

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinball/game/behaviors/behaviors.dart';
import 'package:pinball/game/components/android_acres/behaviors/behaviors.dart';
import 'package:pinball/game/game.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_flame/pinball_flame.dart';

class _TestGame extends Forge2DGame {
  @override
  Future<void> onLoad() async {
    images.prefix = '';
    await images.loadAll([
      Assets.images.android.ramp.boardOpening.keyName,
      Assets.images.android.ramp.railingForeground.keyName,
      Assets.images.android.ramp.railingBackground.keyName,
      Assets.images.android.ramp.main.keyName,
      Assets.images.android.ramp.arrow.inactive.keyName,
      Assets.images.android.ramp.arrow.active1.keyName,
      Assets.images.android.ramp.arrow.active2.keyName,
      Assets.images.android.ramp.arrow.active3.keyName,
      Assets.images.android.ramp.arrow.active4.keyName,
      Assets.images.android.ramp.arrow.active5.keyName,
      Assets.images.android.rail.main.keyName,
      Assets.images.android.rail.exit.keyName,
      Assets.images.score.fiveThousand.keyName,
    ]);
  }

  Future<void> pump(
    SpaceshipRamp child, {
    required GameBloc gameBloc,
  }) async {
    await ensureAdd(
      FlameBlocProvider<GameBloc, GameState>.value(
        value: gameBloc,
        children: [
          ZCanvasComponent(children: [child]),
        ],
      ),
    );
  }
}

class _MockGameBloc extends Mock implements GameBloc {}

class _MockSpaceshipRampCubit extends Mock implements SpaceshipRampCubit {}

class _MockStreamSubscription extends Mock
    implements StreamSubscription<SpaceshipRampState> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RampShotBehavior', () {
    const shotPoints = Points.fiveThousand;

    late GameBloc gameBloc;

    setUp(() {
      gameBloc = _MockGameBloc();
    });

    final flameBlocTester = FlameTester(_TestGame.new);

    flameBlocTester.test(
      'when hits are not multiple of 10 times '
      'increases multiplier and adds a ScoringBehavior',
      (game) async {
        final bloc = _MockSpaceshipRampCubit();
        final streamController = StreamController<SpaceshipRampState>();
        whenListen(
          bloc,
          streamController.stream,
          initialState: SpaceshipRampState.initial(),
        );
        final behavior = RampShotBehavior(points: shotPoints);
        final parent = SpaceshipRamp.test(bloc: bloc);

        await game.pump(
          parent,
          gameBloc: gameBloc,
        );
        await parent.ensureAdd(behavior);

        streamController.add(SpaceshipRampState(hits: 1));

        final scores = game.descendants().whereType<ScoringBehavior>();
        await game.ready();

        verify(() => gameBloc.add(MultiplierIncreased())).called(1);
        expect(scores.length, 1);
      },
    );

    flameBlocTester.test(
      'when hits multiple of 10 times '
      "doesn't increase multiplier, neither ScoringBehavior",
      (game) async {
        final bloc = _MockSpaceshipRampCubit();
        final streamController = StreamController<SpaceshipRampState>();
        whenListen(
          bloc,
          streamController.stream,
          initialState: SpaceshipRampState(hits: 9),
        );
        final behavior = RampShotBehavior(
          points: shotPoints,
        );
        final parent = SpaceshipRamp.test(
          bloc: bloc,
        );

        await game.pump(
          parent,
          gameBloc: gameBloc,
        );
        await parent.ensureAdd(behavior);

        streamController.add(SpaceshipRampState(hits: 10));

        final scores = game.children.whereType<ScoringBehavior>();
        await game.ready();

        verifyNever(() => gameBloc.add(MultiplierIncreased()));
        expect(scores.length, 0);
      },
    );

    flameBlocTester.test(
      'closes subscription when removed',
      (game) async {
        final bloc = _MockSpaceshipRampCubit();
        whenListen(
          bloc,
          const Stream<SpaceshipRampState>.empty(),
          initialState: SpaceshipRampState.initial(),
        );
        when(bloc.close).thenAnswer((_) async {});

        final subscription = _MockStreamSubscription();
        when(subscription.cancel).thenAnswer((_) async {});

        final behavior = RampShotBehavior.test(
          points: shotPoints,
          subscription: subscription,
        );
        final parent = SpaceshipRamp.test(
          bloc: bloc,
        );

        await game.pump(
          parent,
          gameBloc: gameBloc,
        );
        await parent.ensureAdd(behavior);

        parent.remove(behavior);
        await game.ready();

        verify(subscription.cancel).called(1);
      },
    );
  });
}