import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reusable Wayv logo widget that renders the SVG from assets.
///
/// Defaults to a size that works for auth screen headers.
/// Set [width] / [height] to customise.
class WayvLogo extends StatelessWidget {
  final double? width;
  final double? height;

  const WayvLogo({
    super.key,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/Logo_Wayv.svg',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
