import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/wattwise_prefs_repository.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import 'steps/step_0_welcome.dart';
import 'steps/step_1_scanning.dart';
import 'steps/step_2_confirm_specs.dart';
import 'steps/step_3_terms.dart';
import 'steps/step_4_rate.dart';
import 'steps/step_5_hours.dart';
import 'steps/step_6_complete.dart';

class OnboardingShell extends StatelessWidget {
  const OnboardingShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          OnboardingCubit(prefsRepository: WattwisePrefsRepository()),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingCubit, OnboardingState>(
      listenWhen: (previous, current) =>
          previous.currentStep != current.currentStep ||
          previous.isScanning != current.isScanning ||
          previous.scanError != current.scanError,
      listener: (context, state) {
        _controller.animateToPage(
          state.currentStep,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      },
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              leading: state.currentStep >= 2
                  ? IconButton(
                      onPressed: () =>
                          context.read<OnboardingCubit>().previousStep(),
                      icon: const Icon(Icons.arrow_back),
                    )
                  : null,
              title: const Text('WattWise Setup'),
            ),
            body: Column(
              children: [
                LinearProgressIndicator(value: state.currentStep / 6),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      switch (index) {
                        case 0:
                          return Step0Welcome(
                            onNext: () =>
                                context.read<OnboardingCubit>().nextStep(),
                          );
                        case 1:
                          return const Step1Scanning();
                        case 2:
                          return Step2ConfirmSpecs(
                            onContinue: (spec) {
                              final cubit = context.read<OnboardingCubit>();
                              cubit.confirmSpecs(spec);
                              cubit.nextStep();
                            },
                          );
                        case 3:
                          return Step3Terms(
                            onAgree: () =>
                                context.read<OnboardingCubit>().nextStep(),
                          );
                        case 4:
                          return Step4Rate(
                            onContinue: (rate, symbol) {
                              final cubit = context.read<OnboardingCubit>();
                              cubit.setRate(rate, symbol);
                              cubit.nextStep();
                            },
                          );
                        case 5:
                          return Step5Hours(
                            onContinue: (hours, usageProfile) {
                              final cubit = context.read<OnboardingCubit>();
                              cubit.setHours(hours);
                              cubit.setUsageProfile(usageProfile);
                              cubit.nextStep();
                            },
                          );
                        case 6:
                          return Step6Complete(
                            onStartTracking: () async {
                              await context
                                  .read<OnboardingCubit>()
                                  .completeOnboarding();
                              if (context.mounted) {
                                context.go('/dashboard');
                              }
                            },
                          );
                        default:
                          return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
