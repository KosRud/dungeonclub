import 'dart:math';

import 'package:dungeonclub/measuring/area_of_effect.dart';
import 'package:dungeonclub/point_json.dart';
import 'package:dungeonclub/shape_painter/painter.dart';
import 'package:grid_space/grid_space.dart';

import 'ruleset.dart';

class DefaultHexMeasuringRuleset extends HexMeasuringRuleset
    with
        SupportsSphere<HexagonalGrid>,
        SupportsCube<HexagonalGrid>,
        SupportsCone<HexagonalGrid>,
        SupportsLine<HexagonalGrid> {
  static const degrees30 = pi / 6;
  static const degrees60 = pi / 3;

  /// Determines the distance between two points on a hex grid.
  ///
  /// This is done by sorting the vector between `A` and `B` into one of six
  /// triangles. This triangle is then rotated around the origin to point
  /// upwards, which lets us look at a straight horizontal line that
  /// crosses `B`. The distance between `A` and `B` is the (normalized)
  /// Y coordinate of this line.
  @override
  num distanceBetweenGridPoints(HexagonalGrid grid, Point a, Point b) {
    final vx = b.x - a.x;
    final vy = (b.y - a.y) * grid.tileHeightRatio;

    double result;

    if (grid.horizontal) {
      final angle = (atan2(vx, -vy) + pi) ~/ degrees60;
      var rotate = -angle * degrees60 - degrees30;
      result = vx * sin(rotate) + vy * cos(rotate);
    } else {
      final angle = (atan2(vx, -vy) + pi * 7 / 6) ~/ degrees60;
      var rotate = -angle * degrees60;
      result = (vx * sin(rotate) + vy * cos(rotate)) / grid.tileHeightRatio;
    }

    return result.undeviate();
  }

  @override
  Set<Point<int>> getTilesAffectedBySphere(
          SphereAreaOfEffect<HexagonalGrid> aoe) =>
      MeasuringRuleset.getTilesWithinCircle(aoe.grid, aoe.center, aoe.radius);

  @override
  Set<Point<int>> getTilesAffectedByCube(covariant HexCubeAreaOfEffect aoe) =>
      MeasuringRuleset.getTilesWithinCircle(aoe.grid, aoe.origin, aoe.distance,
          useTileShape: true);

  @override
  HexCubeAreaOfEffect makeInstance() => HexCubeAreaOfEffect();

  @override
  Set<Point<int>> getTilesAffectedByPolygon(Polygon polygon, HexagonalGrid grid,
          {bool checkCenter = false}) =>
      MeasuringRuleset.getTilesOverlappingPolygon(grid, polygon.points,
          checkCenter: checkCenter);
}
