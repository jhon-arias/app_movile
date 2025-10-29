import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? fallbackIconColor;
  final IconData? fallbackIcon;
  final bool circular;

  const AppLogo({
    Key? key,
    this.size = 50,
    this.backgroundColor,
    this.fallbackIconColor,
    this.fallbackIcon = Icons.account_balance_wallet,
    this.circular = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget logoWidget = Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('Error loading logo: $error');
        return Icon(
          fallbackIcon,
          size: size * 0.6,
          color: fallbackIconColor ?? Colors.white,
        );
      },
    );

    if (circular) {
      logoWidget = ClipOval(child: logoWidget);
    } else {
      logoWidget = ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: logoWidget,
      );
    }

    if (backgroundColor != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: circular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circular ? null : BorderRadius.circular(size * 0.2),
        ),
        child: logoWidget,
      );
    }

    return logoWidget;
  }
}

class AppLogoWithShadow extends StatelessWidget {
  final double size;
  final Color shadowColor;
  final double blurRadius;
  final Offset offset;

  const AppLogoWithShadow({
    Key? key,
    this.size = 80,
    required this.shadowColor,
    this.blurRadius = 15,
    this.offset = const Offset(0, 5),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: blurRadius, offset: offset),
        ],
      ),
      child: AppLogo(size: size, backgroundColor: Colors.white, circular: true),
    );
  }
}
