import 'package:flutter/material.dart';

class TpDetalleScreen extends StatelessWidget {
  final String tpId;
  const TpDetalleScreen({required this.tpId,super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Detalle de TP'));
  }
}
