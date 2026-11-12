#!/usr/bin/env bash
# Installs the APK on the emulator, walks every main screen by tapping
# elements found by their visible label, saves screenshots and logcat.
set -x
mkdir -p shots
APK=$(ls minha-*.apk | head -1)
adb install -r "$APK"
adb logcat -c
adb shell monkey -p app.minha.minha -c android.intent.category.LAUNCHER 1
sleep 25
shot() { adb exec-out screencap -p > "shots/$1.png"; }
SIZE=$(adb shell wm size | grep -o '[0-9]*x[0-9]*' | tail -1)
W=${SIZE%x*}; H=${SIZE#*x}

# tap_label "Text" : find the element whose text or content-desc starts with Text and tap its centre
tap_label() {
  adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
  adb pull /sdcard/ui.xml /tmp/ui.xml >/dev/null 2>&1
  local xy
  xy=$(python3 - "$1" <<'PY'
import re, sys
label = sys.argv[1].lower()
xml = open('/tmp/ui.xml', encoding='utf-8', errors='ignore').read()
for m in re.finditer(r'<node [^>]*>', xml):
    n = m.group(0)
    t = (re.search(r' text="([^"]*)"', n) or [None, ''])[1]
    d = (re.search(r'content-desc="([^"]*)"', n) or [None, ''])[1]
    if t.lower().startswith(label) or d.lower().startswith(label):
        b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', n)
        x1, y1, x2, y2 = map(int, b.groups())
        print((x1 + x2) // 2, (y1 + y2) // 2)
        break
PY
)
  if [ -n "$xy" ]; then adb shell input tap $xy; return 0; fi
  echo "label not found: $1"; return 1
}
scroll_up() { adb shell input swipe $((W/2)) $((H*75/100)) $((W/2)) $((H*30/100)) 300; sleep 2; }

shot 01_welcome
scroll_up
shot 02_welcome_bottom
tap_label "Continue" || { adb shell input tap $((W/2)) $((H*87/100)); }
sleep 25
shot 03_feed
adb shell input swipe $((W/2)) $((H*70/100)) $((W/2)) $((H*20/100)) 250
sleep 15
shot 04_feed_next
tap_label "Quran"; sleep 15
shot 05_quran
tap_label "Al-Faatiha" || tap_label "Al-Fatiha" || adb shell input tap $((W/2)) $((H*35/100))
sleep 15
shot 06_reader
adb shell input keyevent 4; sleep 3
tap_label "Ask"; sleep 5
shot 07_ask
tap_label "Exams" || tap_label "Grief"
sleep 25
shot 08_ask_answer
scroll_up
shot 09_ask_answer_more
tap_label "Journey"; sleep 6
shot 10_journey
scroll_up
shot 11_journey_more
scroll_up
shot 12_journey_more2
tap_label "Today"; sleep 4
tap_label "Ramadan"; sleep 6
shot 13_ramadan
scroll_up
shot 14_ramadan_more
adb shell input keyevent 4; sleep 3
tap_label "Settings"; sleep 4
shot 15_settings
scroll_up
shot 16_settings_more
adb shell input keyevent 4; sleep 2
adb shell pidof app.minha.minha > shots/pid.txt || echo "APP NOT RUNNING" > shots/pid.txt
adb logcat -d > shots/logcat.txt
grep -iE "E/flutter|FATAL|AndroidRuntime" shots/logcat.txt | tail -80
exit 0
