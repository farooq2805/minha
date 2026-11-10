import 'package:flutter/material.dart';

import '../data.dart';
import '../store.dart';
import '../theme.dart';

void showSettings(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: C.grouped,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
    builder: (_) => const FractionallySizedBox(heightFactor: .85, child: SettingsSheet()),
  );
}

Future<void> editName(BuildContext context) async {
  final ctrl = TextEditingController(text: Store.instance.name);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Your name on share cards'),
      content: TextField(controller: ctrl, autofocus: true, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(hintText: 'e.g. Ayesha Khan')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Save')),
      ],
    ),
  );
  if (result != null) await Store.instance.setName(result);
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
            Padding(padding: const EdgeInsets.only(left: 4, bottom: 18), child: Text('Settings', style: ui(28, weight: FontWeight.w700, spacing: -0.5))),
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
            const SizedBox(height: 22),
            _label('Translation'),
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
            _label('Share cards'),
            Group(
              padding: EdgeInsets.zero,
              child: Column(children: [
                ListTile(
                  title: Text('Your name', style: ui(16)),
                  subtitle: Text(s.name.isEmpty ? 'Not set' : s.name, style: ui(13, color: C.grey)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => editName(context),
                ),
                SwitchListTile(
                  title: Text('Show my name on cards', style: ui(16)),
                  value: s.showName,
                  activeTrackColor: const Color(0xFF34C759),
                  onChanged: s.setShowName,
                ),
              ]),
            ),
            const SizedBox(height: 22),
            Text('Test build. Quran text: Tanzil via alquran.cloud. Recitation: Mishary Alafasy via islamic.network. Word meanings: Quran.com.',
                style: ui(12, color: C.grey, height: 1.45)),
          ],
        );
      },
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(left: 20, bottom: 6), child: Text(t, style: ui(13, color: C.grey)));
}
