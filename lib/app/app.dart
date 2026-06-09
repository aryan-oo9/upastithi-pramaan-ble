// lib/app/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upastithi_pramaan/app/routes.dart';
import 'package:upastithi_pramaan/core/theme/app_theme.dart';

class UpastitiApp extends ConsumerWidget {
  const UpastitiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Upastithi Pramaan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}