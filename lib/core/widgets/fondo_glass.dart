
import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';

class FondoPremium extends StatelessWidget {
  const FondoPremium({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: SizedBox.expand(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, AppColors.fondo],
              ),
            ),
          ),
        ),
      );
}
