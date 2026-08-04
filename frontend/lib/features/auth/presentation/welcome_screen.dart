import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  gradient: AppColors.gradientMatch,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_movies_rounded, color: Colors.white, size: 46),
              ),
              const SizedBox(height: 28),
              Text('MatchFlix', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 10),
              Text(
                'Deslizad juntos, encontrad la película\nperfecta para esta noche.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(flex: 4),
              PrimaryButton(label: 'Comenzar', onPressed: () => context.push('/register')),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/login'),
                child: const Text('Ya tengo cuenta', style: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
