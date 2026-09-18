# Bible App Build Manual

## Prerequisites

| Tool | Version | Location |
|------|---------|----------|
| Flutter | 3.47.4 | `C:\Utils\flutter\bin` |
| Java JDK | 21 | `C:\Program Files\Java\jdk-21` |
| Android SDK | — | `C:\Users\junyoung.choi\AppData\Local\Android\sdk` |

Verify setup:
```bash
C:/Utils/flutter/bin/flutter.bat doctor
```

---

## Web Build

```bash
cd C:/temp/Workspace/Bible_App/bible_app
C:/Utils/flutter/bin/flutter.bat build web --release
```

Output: `build/web/` — deploy this directory to any static web host.

To preview locally:
```bash
C:/Utils/flutter/bin/flutter.bat run -d chrome
```

---

## Android APK Build

> **Note:** This machine has a known Gradle daemon IPC issue on Windows. The build requires these workarounds:
> - Pre-load the Gradle javaagent in `GRADLE_OPTS` to prevent daemon forking
> - Use `--android-skip-build-dependency-validation` to bypass Flutter's Gradle version check
> - Use AGP 8.2.1 with Gradle 8.4 (specific version combination that avoids the loopback failure)

### Step 1 — Set Java home

```bash
export JAVA_HOME="C:/Program Files/Java/jdk-21"
export PATH="$JAVA_HOME/bin:$PATH"
```

PowerShell equivalent:
```powershell
$env:JAVA_HOME = "C:\Program Files\Java\jdk-21"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
```

### Step 2 — Set GRADLE_OPTS with pre-loaded agent

Find the Gradle agent jar path (it lives inside the unwrapped Gradle distribution):
```
C:\Users\junyoung.choi\.gradle\wrapper\dists\gradle-8.4-all\<hash>\gradle-8.4\lib\agents\gradle-instrumentation-agent-8.4.jar
```

The hash `56r6xik2f6skrm47et0ibifug` is fixed for Gradle 8.4.

```bash
AGENT="C:/Users/junyoung.choi/.gradle/wrapper/dists/gradle-8.4-all/56r6xik2f6skrm47et0ibifug/gradle-8.4/lib/agents/gradle-instrumentation-agent-8.4.jar"
export GRADLE_OPTS="-javaagent:${AGENT} \
  --add-opens=java.base/java.util=ALL-UNNAMED \
  --add-opens=java.base/java.lang=ALL-UNNAMED \
  --add-opens=java.base/java.lang.invoke=ALL-UNNAMED \
  --add-opens=java.prefs/java.util.prefs=ALL-UNNAMED \
  --add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED \
  --add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED \
  --add-opens=java.base/java.nio.charset=ALL-UNNAMED \
  --add-opens=java.base/java.net=ALL-UNNAMED \
  --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED \
  -Xmx4G -XX:MaxMetaspaceSize=384m -XX:+HeapDumpOnOutOfMemoryError -Xms256m"
```

### Step 3 — Build

```bash
cd C:/temp/Workspace/Bible_App/bible_app
C:/Utils/flutter/bin/flutter.bat build apk --release --android-skip-build-dependency-validation
```

Build time: ~4–8 minutes.

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Complete one-liner script (Bash/Git Bash)

```bash
export JAVA_HOME="C:/Program Files/Java/jdk-21"
export PATH="$JAVA_HOME/bin:$PATH"
AGENT="C:/Users/junyoung.choi/.gradle/wrapper/dists/gradle-8.4-all/56r6xik2f6skrm47et0ibifug/gradle-8.4/lib/agents/gradle-instrumentation-agent-8.4.jar"
export GRADLE_OPTS="-javaagent:${AGENT} --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.invoke=ALL-UNNAMED --add-opens=java.prefs/java.util.prefs=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED --add-opens=java.base/java.nio.charset=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED -Xmx4G -XX:MaxMetaspaceSize=384m -XX:+HeapDumpOnOutOfMemoryError -Xms256m"
cd "C:/temp/Workspace/Bible_App/bible_app"
"C:/Utils/flutter/bin/flutter.bat" build apk --release --android-skip-build-dependency-validation
```

> **주의:** Flutter가 빌드 중에 `gradle-wrapper.properties`를 자동으로 8.14로 업그레이드하는 경우가 있습니다. 그 경우 즉시 `gradle-8.4-all.zip`으로 되돌려야 합니다:
> ```bash
> # gradle-wrapper.properties가 변경된 경우 확인
> cat android/gradle/wrapper/gradle-wrapper.properties | grep distributionUrl
> # gradle-8.14 로 바뀌어 있으면 되돌리기
> sed -i 's/gradle-8.14[^-]*-all/gradle-8.4-all/g' android/gradle/wrapper/gradle-wrapper.properties
> ```

---

## Android Gradle Configuration (do not change)

| File | Key setting |
|------|-------------|
| `android/gradle/wrapper/gradle-wrapper.properties` | `gradle-8.4-all.zip` |
| `android/settings.gradle.kts` | AGP `8.2.1`, Kotlin `1.9.25` |
| `android/app/build.gradle.kts` | `kotlinOptions { jvmTarget = "17" }` |
| `android/gradle.properties` | `org.gradle.daemon=false`, `android.enableJetifier=false` |

**Why these exact versions:** Gradle 8.4 + AGP 8.2.1 is the only combination on this machine that avoids both the Gradle daemon IPC failure and the AGP/Java-21 toolchain bugs. Upgrading Gradle (8.14+ required by Flutter) triggers a loopback socket error in the daemon. The `--android-skip-build-dependency-validation` flag bypasses Flutter's version check so Gradle 8.4 can be used.

---

## After Code Changes

1. Save your files.
2. For **web**: just rerun `flutter build web --release`. No extra steps.
3. For **Android APK**: rerun Steps 1–3 above (or the one-liner). Gradle incremental build will skip unchanged tasks, so subsequent builds are faster (~2–4 min).
4. No `flutter clean` needed unless you change `pubspec.yaml` dependencies or the build breaks unexpectedly.

### When to run `flutter pub get`

Run this after editing `pubspec.yaml` (adding/removing packages):
```bash
C:/Utils/flutter/bin/flutter.bat pub get
```

### When to run `flutter clean`

Only when:
- The build produces unexpected errors after a Dart/Flutter SDK upgrade
- Asset or font changes aren't reflected in the output

```bash
C:/Utils/flutter/bin/flutter.bat clean
```
Then rebuild normally.

---

## Install APK on Android Device

Enable **USB Debugging** on the device, connect via USB, then:
```bash
C:/Users/junyoung.choi/AppData/Local/Android/sdk/platform-tools/adb.exe install build/app/outputs/flutter-apk/app-release.apk
```

Or just copy the APK file to the device and open it (requires "Install from unknown sources" enabled in Android settings).
