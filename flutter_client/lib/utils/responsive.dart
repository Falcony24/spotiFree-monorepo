import 'dart:math';

int getCrossAxisCount(double width, {double minItemWidth = 150}) {
  return max(1, (width / minItemWidth).floor());
}