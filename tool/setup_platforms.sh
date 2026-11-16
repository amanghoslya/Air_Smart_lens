#!/usr/bin/env bash
# Generates the Android folder with the installed Flutter SDK and applies the settings this app needs:
#   - app name "Air Smart Lens" under the icon
#   - Scan QR: the camera permission comes from mobile_scanner's own manifest (camera not required, so the app
#     still installs on phones without one)
#   - cart reminder (flutter_local_notifications): POST_NOTIFICATIONS comes from the plugin; this adds
#     RECEIVE_BOOT_COMPLETED and the two receivers for scheduled notifications, and core library desugaring,
#     Java 17 and minSdk 24 in android/app/build.gradle(.kts)
#
#   bash tool/setup_platforms.sh            then: flutter run   /   flutter build apk --release
#
# Change --org to Vishal Optical's own reverse domain before publishing; it becomes the Android application id
# (com.vishaloptical.air_smart_lens). Run it once; running it again is safe (every change is skipped when present).
set -euo pipefail
cd "$(dirname "$0")/.."

flutter create --platforms=android --org com.vishaloptical --project-name air_smart_lens .

# flutter create leaves existing files alone; make sure the template counter test was not added.
if grep -q "MyApp" test/widget_test.dart 2>/dev/null; then
  echo "test/widget_test.dart was replaced by the template; restore it from the zip." >&2
fi

python3 - <<'PY'
import re, pathlib

m = pathlib.Path('android/app/src/main/AndroidManifest.xml')
s = m.read_text()
s = re.sub(r'android:label="[^"]*"', 'android:label="Air Smart Lens"', s, count=1)
if 'RECEIVE_BOOT_COMPLETED' not in s:
    s = s.replace('<application', '<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>\n    <application', 1)
if 'ScheduledNotificationReceiver' not in s:
    rec = '''
        <!-- Cart reminder: scheduled local notifications (flutter_local_notifications) -->
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
    </application>'''
    s = s.replace('</application>', rec.lstrip('\n'), 1)
m.write_text(s)

kts = pathlib.Path('android/app/build.gradle.kts')
gr = pathlib.Path('android/app/build.gradle')
if kts.exists():
    s = kts.read_text()
    s = s.replace('JavaVersion.VERSION_11', 'JavaVersion.VERSION_17').replace('JvmTarget.JVM_11', 'JvmTarget.JVM_17')
    s = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = maxOf(24, flutter.minSdkVersion)', s)
    s = re.sub(r'compileSdk\s*=\s*flutter\.compileSdkVersion', 'compileSdk = maxOf(36, flutter.compileSdkVersion)', s)
    if 'isCoreLibraryDesugaringEnabled' not in s:
        s = re.sub(r'compileOptions\s*\{', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', s, count=1)
    if 'desugar_jdk_libs' not in s:
        s += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    kts.write_text(s)
elif gr.exists():
    s = gr.read_text()
    s = s.replace('JavaVersion.VERSION_11', 'JavaVersion.VERSION_17').replace('JvmTarget.JVM_11', 'JvmTarget.JVM_17')
    s = re.sub(r'minSdk(Version)?\s*=?\s*flutter\.minSdkVersion', 'minSdk = Math.max(24, flutter.minSdkVersion)', s)
    s = re.sub(r'compileSdk(Version)?\s*=?\s*flutter\.compileSdkVersion', 'compileSdk = Math.max(36, flutter.compileSdkVersion)', s)
    if 'coreLibraryDesugaringEnabled' not in s:
        s = re.sub(r'compileOptions\s*\{', 'compileOptions {\n        coreLibraryDesugaringEnabled true', s, count=1)
    if 'desugar_jdk_libs' not in s:
        s += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    gr.write_text(s)
print('Android settings applied')
PY

flutter pub get
echo "Done. Run: flutter run   (or: flutter build apk --release)"
