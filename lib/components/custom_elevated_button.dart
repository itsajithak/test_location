import 'package:flutter/material.dart';
import 'package:test_app/utils/app_widget_utils.dart';

class CustomElevatedButton extends StatelessWidget {
  String text;
  IconData? icon;
  double fontSize;
  Color? fontColor;
  double? width;
  double? height;
  final Function()? onPressed;
  BoxBorder? border;
  Color? buttonBackgroundColor;
  Widget? suffixIcon;
  FontWeight? fontWeight;
  double? customWidth;
  Color? borderColor;
  WidgetStateProperty<EdgeInsetsGeometry?>? customPadding;

  CustomElevatedButton(
      {Key? key,
      required this.text,
      required this.fontSize,
      this.onPressed,
      this.icon,
      this.border,
      this.fontColor,
      this.buttonBackgroundColor,
      this.width,
      this.height,
      this.suffixIcon,
      this.fontWeight,
      this.customWidth,
      this.borderColor,
      this.customPadding})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? 40,
      child: ElevatedButton(
          style: ButtonStyle(
            padding: customPadding,
            backgroundColor: WidgetStatePropertyAll(buttonBackgroundColor),
            shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: borderColor ?? Colors.transparent))),
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              suffixIcon ?? Container(),
              AppWidgetUtils.buildSizedBox(custWidth: customWidth ?? 4),
              Text(
                text,
                style: TextStyle(
                  color: fontColor,
                  fontSize: fontSize,
                  fontWeight: fontWeight
                ),
              ),
            ],
          )),
    );
  }
}
