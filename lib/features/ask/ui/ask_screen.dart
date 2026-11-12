import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:minha/core/analytics/ai_cost_tracker.dart';
import 'package:minha/core/analytics/analytics_service.dart';
import 'package:minha/core/analytics/event_types.dart';
import 'package:minha/features/quran/data/quran_api.dart';
import 'package:minha/core/services/store.dart';
import 'package:minha/core/theme/theme.dart';
import 'package:minha/features/saved/ui/saved_screen.dart';

class AskScreen extends StatefulWidget {
  const AskScreen({super.key, this.standalone = false});
  final bool standalone;
  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _ChatMessage {
  _ChatMessage({
    required this.question,
    required this.answer,
    this.report,
    this.dua,
    this.verseKeys = const [],
  });
  final String question;
  final String answer;
  final String? report;
  final String? dua;
  final List<String> verseKeys;
}

class _AskScreenState extends State<AskScreen> {
  final ctrl = TextEditingController();
  final scroll = ScrollController();
  final List<_ChatMessage> messages = [];
  bool isLoading = false;

  static const String _systemPrompt = '''
You are Minha, a gentle, humble, empathetic, and knowledgeable Islamic companion and Quran study guide.
Guidelines:
1. Address the user's question or emotions with deep empathy, wisdom, and warmth.
2. Quote relevant Quran verses with clear Surah and Ayah citations (e.g. Surah Al-Baqarah 2:286) and their English translation.
3. Quote authentic Hadith (Sahih Bukhari, Sahih Muslim, Tirmidhi, Abu Dawud) where relevant.
4. STRICT RULE: Never issue fatwas or decisive legal rulings. For fiqh or legal rulings, gently advise consulting a trusted local scholar.
5. Provide your response structured cleanly with:
   - Compassionate Guidance
   - Quranic Wisdom & Hadith
   - Short Takeaway / Spiritual Report (1-2 sentences)
   - A short recommended Dua for today.
''';

  Future<void> _ask(String q) async {
    q = q.trim();
    if (q.isEmpty || isLoading) return;
    final s = Store.instance;
    if (s.asksLeft <= 0) {
      _limitSheet();
      return;
    }

    await s.useAsk();
    ctrl.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    final topic = matchTopic(q);
    final stopwatch = Stopwatch()..start();

    // Track AI question submitted without PII or sensitive raw prompt
    AnalyticsService.instance.track(AnalyticsEvents.aiQuestionSubmitted, properties: {
      'category': topic.label,
      'has_api_key': s.geminiApiKey.isNotEmpty,
    });

    // Check if user has Gemini API key configured, otherwise use smart offline fallback + Quran match
    final apiKey = s.geminiApiKey;
    if (apiKey.isNotEmpty) {
      try {
        final res = await http.post(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': '$_systemPrompt\n\nUser Question: "$q"'}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 1000,
            }
          }),
        ).timeout(const Duration(seconds: 15));

        stopwatch.stop();
        final latencyMs = stopwatch.elapsedMilliseconds;

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List<dynamic>?;
            final text = parts?[0]['text'] as String? ?? '';

            final usage = data['usageMetadata'] as Map<String, dynamic>?;
            final inTokens = (usage?['promptTokenCount'] as int?) ?? (q.length ~/ 3.5);
            final outTokens = (usage?['candidatesTokenCount'] as int?) ?? (text.length ~/ 3.5);
            final hasCitations = text.contains(':') || text.toLowerCase().contains('surah');

            // Record into central AI Cost Ledger
            await AiCostTracker.instance.recordRequest(
              model: 'gemini-1.5-flash',
              inputTokens: inTokens,
              outputTokens: outTokens,
              latencyMs: latencyMs,
              success: true,
              hadCitations: hasCitations,
              topicCategory: topic.label,
            );

            AnalyticsService.instance.track(AnalyticsEvents.aiResponseGenerated, properties: {
              'model': 'gemini-1.5-flash',
              'input_tokens': inTokens,
              'output_tokens': outTokens,
              'latency_ms': latencyMs,
              'had_citations': hasCitations,
            });

            if (AiCostTracker.instance.isDailyBudgetExceeded()) {
              AnalyticsService.instance.track(AnalyticsEvents.aiBudgetAlert, properties: {
                'today_cost_usd': AiCostTracker.instance.getTodayCost(),
              });
            }

            _addMessage(q, text, topic.verses);
            return;
          }
        } else {
          AnalyticsService.instance.track(AnalyticsEvents.aiResponseFailed, properties: {
            'status_code': res.statusCode,
          });
        }
      } catch (e) {
        stopwatch.stop();
        AnalyticsService.instance.track(AnalyticsEvents.aiResponseFailed, properties: {
          'error_type': e.runtimeType.toString(),
        });
      }
    }

    // Fallback: Smart local knowledge response with Quran citations & report
    final fallbackAnswer = _generateLocalCompanionAnswer(q, topic);
    _addMessage(q, fallbackAnswer.$1, topic.verses, report: fallbackAnswer.$2, dua: fallbackAnswer.$3);
  }

  (String, String, String) _generateLocalCompanionAnswer(String q, AskTopic topic) {
    final answer = '''
May Allah grant tranquility to your heart regarding this matter. In Islam, every hardship, question, and season of life is met with divine reassurance.

The Quran reminds us that Allah is closer to us than our jugular vein, and no sorrow or struggle goes unnoticed by the Most Merciful. Turn to Him in patience and remembrance, knowing that with every difficulty comes ease.''';

    final report = 'Take comfort that Allah hears your silent supplications. Focus on what is in your control and place your trust in Him.';
    final dua = '“Hasbunallahu wa ni’mal wakeel” (Allah is sufficient for us, and He is the best Disposer of affairs).';

    return (answer, report, dua);
  }

  void _addMessage(String q, String answer, List<String> verses, {String? report, String? dua}) {
    if (!mounted) return;
    setState(() {
      isLoading = false;
      messages.add(_ChatMessage(
        question: q,
        answer: answer,
        report: report,
        dua: dua,
        verseKeys: verses,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (scroll.hasClients) {
        scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
      }
    });
  }

  void _limitSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: C.emerald.withOpacity(.1), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: C.emerald, size: 30),
            ),
            const SizedBox(height: 14),
            Text("You've used today's questions", textAlign: TextAlign.center, style: ui(22, weight: FontWeight.w700, spacing: -0.3)),
            const SizedBox(height: 8),
            Text('Daily free questions refresh every morning at Fajr, or unlock an extra question instantly.',
                textAlign: TextAlign.center, style: ui(15, color: C.grey, height: 1.45)),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Unlock 1 extra question',
              onTap: () {
                Store.instance.unlockAsk();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unlocked 1 extra question!')));
              },
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Come back tomorrow', style: ui(15, color: C.emerald, weight: FontWeight.w600))),
          ]),
        ),
      ),
    );
  }

  void _showApiKeyDialog() {
    final keyCtrl = TextEditingController(text: Store.instance.geminiApiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Connect Gemini AI (Free)'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Enter your free Google Gemini API key to enable live conversational AI answers.',
              style: ui(14, color: C.grey)),
          const SizedBox(height: 12),
          TextField(
            controller: keyCtrl,
            decoration: const InputDecoration(
              hintText: 'AIzaSy...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Text('Free tier from Google AI Studio. Stored securely on your device only.', style: ui(11, color: C.grey)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Store.instance.setGeminiApiKey(keyCtrl.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gemini API configured!')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomBar = widget.standalone ? 0.0 : MediaQuery.of(context).padding.bottom + 58;
    return Scaffold(
      backgroundColor: C.grouped,
      appBar: widget.standalone ? AppBar(backgroundColor: C.grouped, surfaceTintColor: Colors.transparent) : null,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: Store.instance,
          builder: (context, _) => Column(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, widget.standalone ? 0 : 12, 20, 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Ask Minha', style: largeTitle()),
                  Text('Islamic Companion · Quran & Hadith citations', style: ui(12, color: C.grey)),
                ]),
                const Spacer(),
                IconButton(
                  tooltip: 'Gemini AI Settings',
                  icon: const Icon(Icons.auto_awesome_rounded, color: C.emerald, size: 22),
                  onPressed: _showApiKeyDialog,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('${Store.instance.asksLeft} left', style: ui(13, color: C.grey, weight: FontWeight.w600)),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  if (messages.isEmpty) ...[
                    Group(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: C.emerald.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.favorite_border_rounded, color: C.emerald, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text("What is weighing on your heart?", style: ui(17, weight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 8),
                        Text(
                          'Ask about your thoughts, emotions, family, patience, or daily life. Minha offers gentle Islamic guidance, quotes Quranic verses with translations, and provides a spiritual summary takeaway. Never a legal fatwa.',
                          style: ui(14, color: C.grey, height: 1.45),
                        ),
                      ]),
                    ),
                  ],
                  for (final msg in messages) ...[
                    // User bubble
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(top: 14, left: 50),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: C.emerald,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                        child: Text(msg.question, style: ui(15.5, color: Colors.white, height: 1.4)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Minha AI response bubble
                    Container(
                      margin: const EdgeInsets.only(right: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.black.withOpacity(.06)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(color: C.emerald, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: const Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          const SizedBox(width: 8),
                          Text('Minha Companion', style: ui(14, weight: FontWeight.w700, color: C.deep)),
                          const Spacer(),
                          const Icon(Icons.verified_user_outlined, size: 14, color: C.grey),
                          const SizedBox(width: 4),
                          Text('Quran & Hadith', style: ui(11, color: C.grey)),
                        ]),
                        const SizedBox(height: 12),
                        Text(msg.answer, style: ui(15, height: 1.5, color: const Color(0xFF2C2C2E))),
                        
                        if (msg.report != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFF2FBF7), borderRadius: BorderRadius.circular(12), border: Border.all(color: C.emerald.withOpacity(.2))),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                const Icon(Icons.summarize_rounded, size: 16, color: C.emerald),
                                const SizedBox(width: 6),
                                Text('Heart Takeaway', style: ui(13, weight: FontWeight.w700, color: C.emerald)),
                              ]),
                              const SizedBox(height: 4),
                              Text(msg.report!, style: ui(13.5, color: const Color(0xFF1E3A2F), height: 1.4)),
                            ]),
                          ),
                        ],

                        if (msg.dua != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFDE68A))),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                const Icon(Icons.volunteer_activism_rounded, size: 16, color: Color(0xFFB45309)),
                                const SizedBox(width: 6),
                                Text('Recommended Dua / Action', style: ui(13, weight: FontWeight.w700, color: const Color(0xFFB45309))),
                              ]),
                              const SizedBox(height: 4),
                              Text(msg.dua!, style: ui(13.5, color: const Color(0xFF78350F), height: 1.4)),
                            ]),
                          ),
                        ],
                      ]),
                    ),

                    if (msg.verseKeys.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                        child: Text('Relevant Quran Verses:', style: ui(14, weight: FontWeight.w700, color: const Color(0xFF3A3A3C))),
                      ),
                      for (final k in msg.verseKeys.take(2)) Padding(padding: const EdgeInsets.only(bottom: 8), child: VerseCard(verseKey: k)),
                    ],

                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 6, 6, 12),
                      child: Text('Reminders with Quran sources, not a legal fatwa. For rulings, please consult a trusted scholar.',
                          style: ui(11.5, color: C.grey, height: 1.35)),
                    ),
                  ],

                  if (isLoading) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: C.emerald)),
                          const SizedBox(width: 10),
                          Text('Reflecting with Quranic wisdom...', style: ui(13.5, color: C.grey)),
                        ]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              color: C.grouped,
              padding: EdgeInsets.fromLTRB(16, 6, 16, bottomBar + 8 + (widget.standalone ? MediaQuery.of(context).padding.bottom : 0)),
              child: Column(children: [
                SizedBox(
                  height: 34,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    for (final t in ['Studies & Exams', 'Anxiety', 'Patience (Sabr)', 'Parents', 'Marriage', 'Rizq & Job', 'Gratitude', 'Forgiveness'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(t, style: ui(13)),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.black.withOpacity(.06)),
                          shape: const StadiumBorder(),
                          onPressed: () => _ask('I need Islamic guidance and Quran verses about ${t.toLowerCase()}'),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _ask,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "What is on your heart today?",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: Colors.black.withOpacity(.12))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: Colors.black.withOpacity(.12))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send',
                    style: IconButton.styleFrom(backgroundColor: C.emerald, fixedSize: const Size(46, 46)),
                    onPressed: isLoading ? null : () => _ask(ctrl.text),
                    icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
