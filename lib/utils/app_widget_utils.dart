import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_app/utils/app_colors.dart';

class AppWidgetUtils {
  final _appColors = AppColors();

  static Widget buildSizedBox({double? custWidth, double? custHeight}) {
    return SizedBox(width: custWidth, height: custHeight);
  }


  static buildTextWidget(String text,
      {Color? color,
      double? fontSize,
      Color? backgroundColor,
      TextDecoration? textDecoration,
      Color? decorColor,
      FontWeight? fontWeight,
      TextAlign? textAlign,
      TextOverflow? overflow,
      int? maxLines}) {
    return Text(
      softWrap: true,
      text,
      style: GoogleFonts.roboto(
        color: color,
        fontSize: fontSize ?? 16,
        backgroundColor: backgroundColor,
        decoration: textDecoration,
        decorationColor: decorColor,
        fontWeight: fontWeight,
      ),
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow,
    );
  }
}
