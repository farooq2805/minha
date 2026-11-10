import 'package:flutter/material.dart';

import '../data.dart';
import '../store.dart';
import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String mood = 'Anxious';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.grouped,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Center(child: AppIcon(size: 96)),
              const SizedBox(height: 22),
              Center(child: Text('minha', style: serif(46, weight: FontWeight.w500, height: 1))),
              const SizedBox(height: 8),
              Center(
                child: Text('A gift from the Quran, one verse a day.',
                    textAlign: TextAlign.center, style: serif(20, color: const Color(0xFF3A3A3C))),
              ),
              const SizedBox(height: 44),
              Text('How is your heart today?', style: ui(20, weight: FontWeight.w600, spacing: -0.2)),
              const SizedBox(height: 12),
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
                      labelStyle: ui(15, weight: FontWeight.w500, color: m == mood ? Colors.white : C.ink),
                      selectedColor: C.emerald,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.black.withOpacity(.06)),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text("We'll open on verses that speak to how you feel. Change it any time.",
                  style: ui(13, color: C.grey, height: 1.45)),
              const Spacer(),
              PrimaryButton(label: 'Continue', onTap: () => Store.instance.finishOnboarding(mood)),
              const SizedBox(height: 14),
              Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.lock_outline_rounded, size: 13, color: C.grey),
                  const SizedBox(width: 6),
                  Text('No ads on verses. Your data stays on your phone.', style: ui(12, color: C.grey)),
                ]),
              ),
              const SizedBox(height: 20),
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
