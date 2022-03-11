import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:pinball_theme/pinball_theme.dart';

/// {@template character_theme}
/// Base class for creating character themes.
///
/// Character specific game components should have a getter specified here to
/// load their corresponding assets for the game.
/// {@endtemplate}
abstract class CharacterTheme extends Equatable {
  /// {@macro character_theme}
  const CharacterTheme();

  /// Ball color for this theme.
  Color get ballColor;

  /// Asset for the theme character.
  AssetGenImage get characterAsset;

  @override
  List<Object?> get props => [ballColor];
}