import 'package:flutter/material.dart';

import 'package:minha/core/analytics/analytics_service.dart';
import 'package:minha/core/analytics/event_types.dart';
import 'package:minha/features/quran/data/quran_api.dart';
import 'package:minha/core/services/store.dart';
import 'package:minha/core/theme/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String mood = 'Anxious';
  final nameCtrl = TextEditingController(text: 'Farooq');

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.track(AnalyticsEvents.onboardingStarted);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.grouped,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 36),
              Center(child: AppIcon(size: 88)),
              const SizedBox(height: 18),
              Center(child: Text('minha', style: serif(44, weight: FontWeight.w500, height: 1))),
              const SizedBox(height: 6),
              Center(
                child: Text('A gift from the Quran, one verse a day.',
                    textAlign: TextAlign.center, style: serif(18, color: const Color(0xFF3A3A3C))),
              ),
              const SizedBox(height: 28),
              Text('What should Minha call you?', style: ui(18, weight: FontWeight.w600, spacing: -0.2)),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Your name',
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withOpacity(.1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withOpacity(.1))),
                ),
              ),
              const SizedBox(height: 24),
              Text('How is your heart today?', style: ui(18, weight: FontWeight.w600, spacing: -0.2)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in moods.keys)
                    ChoiceChip(
                      label: Text(m),
                      selected: m == mood,
                      onSelected: (_) => setState(() => mood = m),
                      showCheckmark: false,
                      labelStyle: ui(14, weight: FontWeight.w500, color: m == mood ? Colors.white : C.ink),
                      selectedColor: C.emerald,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.black.withOpacity(.06)),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text("We'll open on verses that speak to how you feel. Change it any time.",
                  style: ui(12.5, color: C.grey, height: 1.4)),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Continue',
                onTap: () {
                  AnalyticsService.instance.track(
                    AnalyticsEvents.onboardingCompleted,
                    properties: {
                      'has_name': nameCtrl.text.trim().isNotEmpty,
                      'initial_mood': mood,
                    },
                  );
                  Store.instance.finishOnboarding(mood, nameCtrl.text);
                },
              ),
              const SizedBox(height: 14),
              Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.lock_outline_rounded, size: 13, color: C.grey),
                  const SizedBox(width: 6),
                  Text('No ads on verses. Your data stays on your phone.', style: ui(12, color: C.grey)),
                ]),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class AppIcon extends StatelessWidget {
  const AppIcon({super.key, this.size = 96});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .23),
        gradient: const RadialGradient(center: Alignment(-0.4, -0.55), radius: 1.1, colors: [C.glow, C.emerald, C.deep], stops: [0, .46, 1]),
        boxShadow: [BoxShadow(color: C.emerald.withOpacity(.4), blurRadius: size * .3, offset: Offset(0, size * .12))],
      ),
      alignment: Alignment.center,
      child: MinhaMark(size: size * .66),
    );
  }
}
