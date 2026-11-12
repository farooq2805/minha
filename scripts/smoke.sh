#!/usr/bin/env bash
# Installs the APK on the emulator, walks every main screen, saves screenshots and logcat.
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
X() { echo $((W*$1/100)); }
Y() { echo $((H*$1/100)); }
shot 01_welcome
# Type a name, hide keyboard, scroll, Continue
adb shell input tap $(X 50) $(Y 55)
adb shell input text "Farooq"
adb shell input keyevent 111
sleep 2
adb shell input swipe $(X 50) $(Y 80) $(X 50) $(Y 20) 300
sleep 2
shot 02_welcome_bottom
adb shell input tap $(X 50) $(Y 87)
sleep 25
shot 03_feed
adb shell input swipe $(X 50) $(Y 70) $(X 50) $(Y 20) 250
sleep 15
shot 04_feed_next
# Quran tab, open first surah
adb shell input tap $(X 37) $(Y 96)
sleep 15
shot 05_quran
adb shell input tap $(X 50) $(Y 30)
sleep 15
shot 06_reader
adb shell input keyevent 4
sleep 3
# Ask tab
adb shell input tap $(X 62) $(Y 96)
sleep 5
shot 07_ask
adb shell input tap $(X 40) $(Y 86)
adb shell input text "I%sam%sanxious%sabout%smy%sexams"
adb shell input keyevent 66
sleep 25
adb shell input keyevent 111
sleep 2
shot 08_ask_answer
# Journey tab
adb shell input tap $(X 87) $(Y 96)
sleep 6
shot 09_journey
adb shell input swipe $(X 50) $(Y 75) $(X 50) $(Y 25) 300
sleep 3
shot 10_journey_more
adb shell input swipe $(X 50) $(Y 75) $(X 50) $(Y 25) 300
sleep 3
shot 11_journey_more2
adb shell pidof app.minha.minha > shots/pid.txt || echo "APP NOT RUNNING" > shots/pid.txt
adb logcat -d > shots/logcat.txt
grep -iE "E/flutter|FATAL|AndroidRuntime" shots/logcat.txt | tail -80
exit 0
