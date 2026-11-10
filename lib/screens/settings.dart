import 'package:flutter/material.dart';

import '../data.dart';
import '../store.dart';
import '../theme.dart';
import 'journey.dart';

void showSettings(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: C.grouped,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => const FractionallySizedBox(heightFactor: .88, child: SettingsSheet()),
  );
}

Future<void> editName(BuildContext context) async {
  final ctrl = TextEditingController(text: Store.instance.name);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Your Name'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'e.g. Farooq Syed'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Save')),
      ],
    ),
  );
  if (result != null && result.trim().isNotEmpty) {
    await Store.instance.setName(result.trim());
  }
}

Future<void> editGeminiKey(BuildContext context) async {
  final ctrl = TextEditingController(text: Store.instance.geminiApiKey);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Google Gemini API Key'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Get a free key from Google AI Studio. Enables smart conversational answers in Ask.',
            style: ui(13.5, color: C.grey)),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'AIzaSy...', border: OutlineInputBorder(), isDense: true),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Save')),
      ],
    ),
  );
  if (result != null) {
    await Store.instance.setGeminiApiKey(result.trim());
  }
}

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Store.instance,
      builder: (context, _) {
        final s = Store.instance;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 18),
              child: Text('Settings', style: ui(28, weight: FontWeight.w700, spacing: -0.5)),
            ),

            // Profile Card
            _label('Account & Profile'),
            Group(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [C.emerald, C.deep]),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s.name.isNotEmpty ? s.name[0].toUpperCase() : 'U',
                      style: ui(20, weight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.name.isEmpty ? 'Farooq' : s.name, style: ui(17, weight: FontWeight.w700)),
                      Text(s.email.isEmpty ? 'farooq2805@gmail.com' : s.email, style: ui(13, color: C.grey)),
                    ]),
                  ),
                  TextButton(
                    onPressed: () => editName(context),
                    child: Text('Edit', style: ui(14, color: C.emerald, weight: FontWeight.w600)),
                  ),
                ]),
                const Divider(height: 20, color: C.hair),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Show my name in app & cards', style: ui(15)),
                  value: s.showName,
                  activeTrackColor: const Color(0xFF34C759),
                  onChanged: s.setShowName,
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // Prayer times & Mosque section
            _label('Prayer Times & Mosque Settings'),
            Group(
              padding: EdgeInsets.zero,
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: C.emerald),
                  title: Text('Location & Mosque Adjustments', style: ui(16)),
                  subtitle: Text('${s.cityName} · ${s.calcMethod.toUpperCase()} (${s.madhab.toUpperCase()})',
                      style: ui(13, color: C.grey)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showMosqueAdjustDialog(context),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // AI Companion section
            _label('AI Companion (Ask)'),
            Group(
              padding: EdgeInsets.zero,
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.auto_awesome_rounded, color: C.emerald),
                  title: Text('Google Gemini API (Free Tier)', style: ui(16)),
                  subtitle: Text(
                    s.geminiApiKey.isEmpty ? 'Not connected · tap to add free key' : 'Key connected (AIzaSy...)',
                    style: ui(13, color: s.geminiApiKey.isEmpty ? const Color(0xFFE28B00) : C.emerald),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => editGeminiKey(context),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // Mood Section
            _label('How is your heart today?'),
            Group(
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                for (final m in moods.keys)
                  ChoiceChip(
                    label: Text(m),
                    selected: s.mood == m,
                    showCheckmark: false,
                    onSelected: (_) => s.setMood(m),
                    selectedColor: C.emerald,
                    labelStyle: ui(14, weight: FontWeight.w500, color: s.mood == m ? Colors.white : C.ink),
                    backgroundColor: C.grouped,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                  ),
              ]),
            ),
            const SizedBox(height: 20),

            // Translation Section
            _label('Quran Translation'),
            Group(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final t in translations)
                  ListTile(
                    title: Text(t.label, style: ui(16)),
                    trailing: s.translation == t.id ? const Icon(Icons.check_rounded, color: C.emerald) : null,
                    onTap: () => s.setTranslation(t.id),
                  ),
              ]),
            ),
            const SizedBox(height: 22),

            Text(
              'Minha · Version 0.1.0\nQuran text: Tanzil via alquran.cloud. Recitations: Mishary Alafasy. Prayer times: Adhan by Batoul Apps. AI: Google Gemini.',
              style: ui(12, color: C.grey, height: 1.45),
            ),
          ],
        );
      },
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(left: 18, bottom: 6), child: Text(t, style: ui(13, color: C.grey)));
}
