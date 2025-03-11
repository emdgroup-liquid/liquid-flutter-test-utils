import 'package:flutter/material.dart';
import 'package:liquid_flutter/liquid_flutter.dart';

import 'sample_liquid_widget.dart';

class SampleLiquidScreen extends StatelessWidget {
  const SampleLiquidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // A screen with a transcluent app bar and a nice background
    return Scaffold(
      appBar: LdAppBar(
        context: context,
        title: const Text('Sample Liquid Screen'),
      ),
      body: SampleLiquidWidget(),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
