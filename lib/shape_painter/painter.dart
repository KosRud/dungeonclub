import 'dart:math';

abstract class ShapePainter with ShapeMaker {
  void addShape(Shape shape);
  void removeShape(Shape shape);
}

mixin ShapeMaker {
  Circle circle();
  Rect rect();
  Polygon polygon();
}

class ShapeGroup with ShapeMaker {
  final ShapeMaker _maker;
  final shapes = <Shape>[];

  ShapeGroup(ShapeMaker maker) : _maker = maker;

  S _wrap<S extends Shape>(S shape) {
    shapes.add(shape);
    return shape;
  }

  @override
  Circle circle() => _wrap(_maker.circle());
  @override
  Rect rect() => _wrap(_maker.rect());
  @override
  Polygon polygon() => _wrap(_maker.polygon());
}

mixin Shape {}

mixin Circle implements Shape {
  Point<double> center = Point(0.0, 0.0);
  double radius = 0;
}

mixin Rect implements Shape {
  Point position = Point(0.0, 0.0);
  Point size = Point(0.0, 0.0);
}

mixin Polygon implements Shape {
  late List<Point<double>> _points;
  List<Point<double>> get points => _points;
  set points(List<Point<double>> points) {
    _points = points;
    handlePointsChanged();
  }

  void handlePointsChanged();
}
