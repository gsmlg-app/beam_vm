# beam_vm_android

The Android implementation of [`beam_vm`](https://pub.dev/packages/beam_vm).

## Usage

This package is [endorsed](https://flutter.dev/to/federated-plugins), which means you can simply use `beam_vm` normally. This package will be automatically included in your app when you do, so you do not need to add it to your `pubspec.yaml`.

However, if you `import` this package directly, you should add it to your `pubspec.yaml` as usual.

## Bundled Binaries

This package bundles pre-compiled `liberlang.a` static libraries for:

- `armeabi-v7a` (32-bit ARM)
- `arm64-v8a` (64-bit ARM)
- `x86_64` (Intel/AMD 64-bit emulators)

The binaries are approximately 41 MB total and are bundled from [beam_vm releases](https://github.com/gsmlg-app/beam_vm/releases).

## Requirements

- Android API level 26+ (Android 8.0 Oreo)
- NDK for native code compilation

## Root Access (Rooted Devices)

This section covers using beam_vm on rooted Android devices where you need elevated permissions.

### How the BEAM VM Executes

The BEAM VM runs **in-process** via JNI (`erl_start()`). This means:

- The VM shares the same process and permissions as your Flutter app
- You cannot elevate just the BEAM VM to root while the app runs as non-root
- Root access must be achieved through specific patterns described below

### Root Access Patterns

| Pattern | Description | Use Case |
|---------|-------------|----------|
| **Root File Preparation** | Use `su` for file operations, BEAM runs normally | Access releases from `/data/erlang/` |
| **Root App** | Entire app runs with root permissions | System apps, Magisk modules |
| **Root Helper** | Separate process runs BEAM with root, communicate via IPC | Full root VM execution |

### Pattern 1: Root File Preparation (Recommended)

Use root to place your Erlang release in a system location, then run the app normally. This is the simplest approach for most use cases.

```dart
import 'dart:io';

// Copy release to system path with root
await Process.run('su', ['-c', 'mkdir -p /data/erlang']);
await Process.run('su', ['-c', 'cp -r /sdcard/my_release /data/erlang/release']);
await Process.run('su', ['-c', 'chmod -R 755 /data/erlang']);
// Make readable by your app's UID
await Process.run('su', ['-c', 'chown -R \$(stat -c %u /data/data/com.example.app) /data/erlang']);

// Initialize normally - app can read /data/erlang if permissions set correctly
final beamVm = BeamVm();
await beamVm.initialize('/data/erlang/release');
```

**Common system paths:**
- `/data/erlang/` - App-specific data partition
- `/data/local/tmp/` - Temporary storage (may be cleared)
- `/sdcard/` - External storage (no root needed for read)

### Pattern 2: Running as a System App

For full root execution, install your Flutter app as a system app:

**Via Magisk Module:**
1. Create a Magisk module that places your APK in `/system/priv-app/`
2. The app runs with system-level permissions
3. BEAM VM inherits these elevated permissions

**Via Recovery/ADB:**
```bash
# Remount system as writable (requires root)
adb shell su -c "mount -o rw,remount /system"

# Copy APK to priv-app
adb shell su -c "mkdir -p /system/priv-app/MyApp"
adb shell su -c "cp /data/app/com.example.app*/base.apk /system/priv-app/MyApp/"
adb shell su -c "chmod 644 /system/priv-app/MyApp/base.apk"

# Reboot to apply
adb reboot
```

### Pattern 3: Root Helper Process

For scenarios requiring the BEAM VM to run with root while your UI runs as a normal app, use a separate helper process:

```dart
// Launch a root helper that runs Erlang
final result = await Process.run('su', [
  '-c',
  '/data/erlang/bin/erl -noshell -eval "..your code.." -s init stop'
]);

// Communicate via files, sockets, or other IPC
```

This pattern is more complex but provides full isolation between your UI and the root BEAM process.

### Limitations and Considerations

**SELinux:**
Modern Android enforces SELinux policies. Even with root:
- Some file operations may be blocked by SELinux context
- Use `chcon` to set appropriate SELinux contexts if needed:
  ```bash
  su -c "chcon -R u:object_r:app_data_file:s0 /data/erlang"
  ```

**Signal Handling:**
The BEAM VM registers signal handlers. In root contexts:
- Be aware of potential conflicts with system signal handling
- The VM may behave differently when running as UID 0

**File Permissions:**
- Files created by root may not be readable by your app
- Always set appropriate ownership after root file operations
- Use numeric UIDs when `chown` doesn't recognize app usernames

**No Selective Elevation:**
A `root: true` API parameter would be misleading because:
- The BEAM VM runs in the same process as your app
- You cannot elevate one thread/component to root
- Root access is an all-or-nothing decision at the app level

### Example: Persistent Erlang Release in /data

Complete example of setting up a persistent Erlang release:

```dart
import 'dart:io';
import 'package:beam_vm/beam_vm.dart';
import 'package:path_provider/path_provider.dart';

Future<void> setupRootRelease() async {
  final beamVm = BeamVm();

  // Check if root is available
  final rootCheck = await Process.run('su', ['-c', 'id']);
  if (rootCheck.exitCode != 0) {
    throw Exception('Root access not available');
  }

  const releasePath = '/data/erlang/my_release';

  // Check if release already exists
  final exists = await Process.run('su', ['-c', 'test -d $releasePath']);

  if (exists.exitCode != 0) {
    // Get the bundled release from assets/app storage
    final appDir = await getApplicationDocumentsDirectory();
    final sourceRelease = '${appDir.path}/erlang_release';

    // Copy to system location with root
    await Process.run('su', ['-c', '''
      mkdir -p /data/erlang
      cp -r "$sourceRelease" "$releasePath"
      chmod -R 755 /data/erlang
    ''']);
  }

  // Initialize the BEAM VM
  await beamVm.initialize(releasePath);
}
```
