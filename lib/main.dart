import 'package:material_ui/material_ui.dart';

import 'spike/spike_screen.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Echoes',
      theme: ThemeData(
        colorSchemeSeed: Colors.amber,
        brightness: Brightness.dark,
      ),
      home: const SpikeScreen(),
    ),
  );
}
