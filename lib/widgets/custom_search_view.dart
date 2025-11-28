import 'package:flutter/material.dart';
// import '../core/app_export.dart';

class CustomSearchView extends StatelessWidget {
  const CustomSearchView(
      {super.key,
      this.alignment,
      this.width,
      this.scrollPadding,
      this.controller,
      this.focusNode,
      this.autofocus = false,
      this.textStyle,
      this.textInputType = TextInputType.text,
      this.maxLines,
      this.hintText,
      this.hintStyle,
      this.prefix,
      this.prefixConstraints,
      this.suffix,
      this.suffixConstraints,
      this.contentPadding,
      this.borderDecoration,
      this.fillColor,
      this.filled = true,
      this.validator,
      this.onChanged});

  final Alignment? alignment;

  final double? width;

  final TextEditingController? scrollPadding;

  final TextEditingController? controller;

  final FocusNode? focusNode;

  final bool? autofocus;

  final TextStyle? textStyle;

  final TextInputType? textInputType;

  final int? maxLines;

  final String? hintText;

  final TextStyle? hintStyle;

  final Widget? prefix;

  final BoxConstraints? prefixConstraints;

  final Widget? suffix;

  final BoxConstraints? suffixConstraints;

  final EdgeInsets? contentPadding;

  final InputBorder? borderDecoration;

  final Color? fillColor;

  final bool? filled;

  final FormFieldValidator<String>? validator;

  final Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(
            alignment: alignment ?? Alignment.center,
            child: searchViewWidget(context))
        : searchViewWidget(context);
  }

  Widget searchViewWidget(BuildContext context) => SizedBox(
        width: width ?? double.maxFinite,
        child: TextFormField(
          scrollPadding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          controller: controller,
          focusNode: focusNode,
          onTapOutside: (event) {
            if (focusNode != null) {
              focusNode?.unfocus();
            } else {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          autofocus: autofocus!,
          // style: textStyle ?? theme.textTheme.bodyMedium,
          keyboardType: textInputType,
          maxLines: maxLines ?? 1,
          decoration: decoration,
          validator: validator,
          onChanged: (String value) {
            onChanged?.call(value);
          },
        ),
      );
  InputDecoration get decoration => InputDecoration(
        hintText: hintText ?? "",
        // hintStyle: hintStyle ?? theme.textTheme.bodyMedium,
        prefixIcon: prefix ??
            Container(
              // margin: EdgeInsets.fromLTRB(20.h, 10.v, 6.h, 10.v),
              // child: CustomImageView(
              //   imagePath: ImageConstant.imgSearch,
              //   height: 24.adaptSize,
              //   width: 24.adaptSize,
              // ),
            ),
        prefixIconConstraints: prefixConstraints ??
            const BoxConstraints(
              // maxHeight: 44.v,
            ),
        suffixIcon: suffix ??
            Padding(
              padding: const EdgeInsets.only(
                // right: 15.h,
              ),
              child: IconButton(
                onPressed: () => controller!.clear(),
                icon: Icon(
                  Icons.clear,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        suffixIconConstraints: suffixConstraints ??
            const BoxConstraints(
              // maxHeight: 44.v,
            ),
        isDense: true,
        contentPadding: contentPadding ??
            const EdgeInsets.only(
              // top: 11.v,
              // right: 11.h,
              // bottom: 11.v,
            ),
        // fillColor: fillColor ?? appTheme.blueGray50,
        filled: filled,
        border: borderDecoration ??
            const OutlineInputBorder(
              // borderRadius: BorderRadius.circular(22.h),
              borderSide: BorderSide.none,
            ),
        enabledBorder: borderDecoration ??
            const OutlineInputBorder(
              // borderRadius: BorderRadius.circular(22.h),
              borderSide: BorderSide.none,
            ),
        focusedBorder: borderDecoration ??
            const OutlineInputBorder(
              // borderRadius: BorderRadius.circular(22.h),
              borderSide: BorderSide.none,
            ),
      );
}
