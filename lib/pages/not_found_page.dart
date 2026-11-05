import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ticketing_app/routes.dart';
import 'package:ticketing_app/widgets/common.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmptyState(
        icon: Icons.explore_off_outlined,
        title: 'Page not found',
        message: 'The page you are looking for doesn\'t exist.',
        actions: [FilledButton(onPressed: () => Get.offAllNamed(Routes.home), child: const Text('Go to dashboard'))],
      ),
    );
  }
}
