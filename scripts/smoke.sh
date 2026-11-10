#!/usr/bin/env bash
# Installs the APK on the emulator, walks through the app, saves screenshots and logcat.
set -x
mkdir -p shots
APK=$(ls minha-*.apk | head -1)
adb install -r "$APK"
adb logcat -c
adb shell monkey -p app.minha.minha -c android.intent.category.LAUNCHER 1
sleep 25
shot() { adb exec-out screencap -p > "shots/$1.png"; }
shot 1_launch
SIZE=$(adb shell wm size | grep -o '[0-9]*x[0-9]*' | tail -1)
W=${SIZE%x*}; H=${SIZE#*x}
adb shell input tap $((W/2)) $((H*90/100))
sleep 25
shot 2_feed
adb shell input swipe $((W/2)) $((H*70/100)) $((W/2)) $((H*20/100)) 250
sleep 15
shot 3_feed_next
adb shell input tap $((W*3/8)) $((H*96/100))
sleep 15
shot 4_quran
adb shell input tap $((W*5/8)) $((H*96/100))
sleep 6
shot 5_ask
adb shell input tap $((W*7/8)) $((H*96/100))
sleep 6
shot 6_journey
adb shell pidof app.minha.minha > shots/pid.txt || echo "APP NOT RUNNING" > shots/pid.txt
adb logcat -d > shots/logcat.txt
echo "===== errors ====="
grep -iE "flutter|AndroidRuntime|FATAL|Exception" shots/logcat.txt | tail -150
exit 0
