import 'package:flutter/material.dart';
import 'package:liquid_flutter/liquid_flutter.dart';

class SampleLiquidWidget extends StatelessWidget {
  final bool isError;

  const SampleLiquidWidget({super.key, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return isError ? _buildError(context) : _buildNormal(context);
  }

  Widget _buildError(BuildContext context) {
    return LdCard(
      child: LdExceptionView(
        exception: LdException(message: "An error occurred"),
      ),
    );
  }

  Widget _buildNormal(BuildContext context) {
    return Column(
      children: [
        LdCard(
          flat: false,
          child: const LdTextL("Hello world"),
        ),
        ldSpacerM,
        LdCard(
          flat: true,
          header: const Row(
            children: [
              LdTag(child: Text("Important information for you")),
            ],
          ),
          footer: Row(
            children: [
              LdButton(
                child: const Text("Action"),
                onPressed: () {},
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LdTextH(
                "Hello footer",
              ),
              ldSpacerM,
            ],
          ),
        ),
      ],
    );
  }
}
