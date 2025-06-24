// ignore_for_file: file_names

import 'package:flutter/material.dart';

class FadeTransitionPageRoute extends PageRouteBuilder {
  final Widget page;
  FadeTransitionPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        );
}
