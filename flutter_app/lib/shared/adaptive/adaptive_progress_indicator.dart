import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'platform_utils.dart';

class AdaptiveProgressIndicator extends StatelessWidget {
  final Color? color;

  const AdaptiveProgressIndicator({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    if (isIOSPlatform) {
      return CupertinoActivityIndicator(color: color);
    }
    return CircularProgressIndicator(color: color);
  }
}
