"""Patches the android/ folder that `flutter create` generates (it is gitignored).

- INTERNET permission and the "Minha" app label
- launcher icons from assets/icon
- release signing from android/key.properties when CI has written it
  (from the KEYSTORE_BASE64 / KEYSTORE_PASSWORD secrets); otherwise the
  release build keeps Flutter's debug signing and a warning is printed.
"""
import os
import re
import shutil

m = 'android/app/src/main/AndroidManifest.xml'
s = open(m).read()
if 'android.permission.INTERNET' not in s:
    s = re.sub(r'(<manifest[^>]*>)', r'\1\n    <uses-permission android:name="android.permission.INTERNET"/>', s, count=1)
s = s.replace('android:label="minha"', 'android:label="Minha"')
open(m, 'w').write(s)
assert 'android.permission.INTERNET' in s, 'INTERNET permission missing'
for d in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']:
    shutil.copy(f'assets/icon/ic_launcher_{d}.png', f'android/app/src/main/res/mipmap-{d}/ic_launcher.png')

KTS_HEADER = 'import java.util.Properties\nimport java.io.FileInputStream\n\n'
KTS_PROPS = '''
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
'''
KTS_SIGNING = '''    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {'''

GROOVY_PROPS = '''
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
'''
GROOVY_SIGNING = '''    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {'''


def patch_signing():
    if not os.path.exists('android/key.properties'):
        print('WARNING: android/key.properties missing; release APK is signed with the debug key.')
        return
    kts = 'android/app/build.gradle.kts'
    groovy = 'android/app/build.gradle'
    if os.path.exists(kts):
        g = open(kts).read()
        g = KTS_HEADER + g
        g = g.replace('android {', KTS_PROPS + '\nandroid {', 1)
        g = g.replace('    buildTypes {', KTS_SIGNING, 1)
        g = g.replace('signingConfig = signingConfigs.getByName("debug")',
                      'signingConfig = signingConfigs.getByName("release")')
        assert 'signingConfigs.getByName("release")' in g, 'release signing not applied (kts)'
        open(kts, 'w').write(g)
    else:
        g = open(groovy).read()
        g = g.replace('android {', GROOVY_PROPS + '\nandroid {', 1)
        g = g.replace('    buildTypes {', GROOVY_SIGNING, 1)
        g = g.replace('signingConfig signingConfigs.debug', 'signingConfig signingConfigs.release')
        assert 'signingConfig signingConfigs.release' in g, 'release signing not applied (groovy)'
        open(groovy, 'w').write(g)
    print('Release signing configured from android/key.properties.')


patch_signing()
print(s)
