import 'package:flutter/material.dart';

class CurrencyInformer extends StatelessWidget {
  // depends on data from camera
  const CurrencyInformer(this.nominal, {super.key});
  final String? nominal;
  @override
  Widget build(BuildContext context) {
    if (nominal == null) {
      return Container();
    }
    return Text(nominal!);
  }
}
