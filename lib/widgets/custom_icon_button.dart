import 'package:flutter/material.dart';
// import '../core/app_export.dart';

extension IconButtonStyleHelper on CustomIconButton {
  // static BoxDecoration get fillErrorContainer => BoxDecoration(
  //       color: theme.colorScheme.errorContainer,
  //       borderRadius: BorderRadius.circular(26.h),
  //     );
  // static BoxDecoration get fillOrange => BoxDecoration(
  //       color: appTheme.orange30028,
  //       borderRadius: BorderRadius.circular(26.h),
  //     );
  // static BoxDecoration get outlineOnPrimary => BoxDecoration(
  //       color: theme.colorScheme.onPrimary.withOpacity(1),
  //       borderRadius: BorderRadius.circular(12.h),
  //       border: Border.all(
  //         color: theme.colorScheme.onPrimary.withOpacity(0.5),
  //         width: 2.h,
  //       ),
  //     );
  // static BoxDecoration get fillRedA => BoxDecoration(
  //       color: appTheme.redA40028,
  //       borderRadius: BorderRadius.circular(26.h),
  //     );
  // static BoxDecoration get fillCyan => BoxDecoration(
  //       color: appTheme.cyan20028,
  //       borderRadius: BorderRadius.circular(26.h),
  //     );
  // static BoxDecoration get fillOrangeTL26 => BoxDecoration(
  //       color: appTheme.orange400.withOpacity(0.16),
  //       borderRadius: BorderRadius.circular(26.h),
  //     );
  // static BoxDecoration get fillPrimaryContainer => BoxDecoration(
  //       color: theme.colorScheme.primaryContainer,
  //       borderRadius: BorderRadius.circular(26.h),
  //     );
}

class CustomIconButton extends StatelessWidget {
  const CustomIconButton(
      {super.key,
      this.alignment,
      this.height,
      this.width,
      this.padding,
      this.decoration,
      this.child,
      this.onTap});

  final Alignment? alignment;

  final double? height;

  final double? width;

  final EdgeInsetsGeometry? padding;

  final BoxDecoration? decoration;

  final Widget? child;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(
            alignment: alignment ?? Alignment.center, child: iconButtonWidget)
        : iconButtonWidget;
  }

  Widget get iconButtonWidget => SizedBox(
        height: height ?? 0,
        width: width ?? 0,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Container(
            height: height ?? 0,
            width: width ?? 0,
            padding: padding ?? EdgeInsets.zero,
            decoration: decoration ??
                const BoxDecoration(
                  // color: theme.colorScheme.onPrimary.withOpacity(1),
                  // borderRadius: BorderRadius.circular(20.h),
                ),
            child: child,
          ),
          onPressed: onTap,
        ),
      );
}
