import re, shutil, sys
m = 'android/app/src/main/AndroidManifest.xml'
s = open(m).read()
if 'android.permission.INTERNET' not in s:
    s = re.sub(r'(<manifest[^>]*>)', r'\1\n    <uses-permission android:name="android.permission.INTERNET"/>', s, count=1)
s = s.replace('android:label="minha"', 'android:label="Minha"')
open(m, 'w').write(s)
assert 'android.permission.INTERNET' in s, 'INTERNET permission missing'
for d in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']:
    shutil.copy(f'assets/icon/ic_launcher_{d}.png', f'android/app/src/main/res/mipmap-{d}/ic_launcher.png')
print(s)
