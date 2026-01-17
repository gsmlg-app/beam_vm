/**
 * BEAM VM Native Bridge for Flutter Plugin (Android)
 *
 * Provides JNI bindings to initialize and interact with the BEAM VM.
 */

#include <jni.h>
#include <android/log.h>
#include <cstdlib>
#include <cstring>
#include <string>

#define LOG_TAG "BeamVm"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

#ifdef HAVE_ERLANG
extern "C" {
    int erl_start(int argc, char *argv[]);
}
#endif

// Global state
static bool g_initialized = false;
static std::string g_erl_root;
static JavaVM* g_jvm = nullptr;
static jobject g_callback = nullptr;

// JNI OnLoad - cache the JavaVM
JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void* reserved) {
    g_jvm = vm;
    LOGI("BeamVm native library loaded");
    return JNI_VERSION_1_6;
}

extern "C" {

/**
 * Initialize the BEAM VM with the given Erlang root directory.
 *
 * @param erlangPath Path to directory containing lib/ and releases/
 * @return 0 on success, non-zero on failure
 */
JNIEXPORT jint JNICALL
Java_io_beamvm_beam_1vm_1android_BeamVmNative_nativeInit(
    JNIEnv *env,
    jobject thiz,
    jstring erlangPath
) {
    if (g_initialized) {
        LOGI("BEAM VM already initialized");
        return 0;
    }

#ifndef HAVE_ERLANG
    LOGE("liberlang.a not linked - BEAM VM unavailable");
    LOGE("Ensure the beam_vm_android package has bundled binaries");
    return -1;
#else
    const char* path = env->GetStringUTFChars(erlangPath, nullptr);
    if (!path) {
        LOGE("Failed to get erlang path string");
        return -2;
    }

    g_erl_root = path;
    env->ReleaseStringUTFChars(erlangPath, path);

    LOGI("Initializing BEAM VM with root: %s", g_erl_root.c_str());

    // Set required environment variables
    std::string bindir = g_erl_root + "/bin";
    setenv("BINDIR", bindir.c_str(), 1);
    setenv("ROOTDIR", g_erl_root.c_str(), 1);
    setenv("EMU", "beam", 1);

    // Build boot path
    std::string boot_path = g_erl_root + "/releases/start";

    // BEAM arguments optimized for mobile
    const char* args[] = {
        "beam",                     // Program name
        "--",                       // End of emulator flags
        "-sbwt", "none",            // No scheduler binding (not supported on mobile)
        "-MIscs", "10",             // 10MB literal super carrier
        "-noshell",                 // No interactive shell
        "-boot", boot_path.c_str(), // Boot script
        nullptr
    };

    int argc = 0;
    while (args[argc] != nullptr) argc++;

    LOGI("Starting BEAM with %d arguments", argc);
    for (int i = 0; i < argc; i++) {
        LOGI("  arg[%d] = %s", i, args[i]);
    }

    // Start the BEAM VM
    int result = erl_start(argc, const_cast<char**>(args));

    if (result == 0) {
        g_initialized = true;
        LOGI("BEAM VM initialized successfully");
    } else {
        LOGE("BEAM VM initialization failed with code: %d", result);
    }

    return result;
#endif
}

/**
 * Check if the BEAM VM is initialized.
 */
JNIEXPORT jboolean JNICALL
Java_io_beamvm_beam_1vm_1android_BeamVmNative_nativeIsInitialized(
    JNIEnv *env,
    jobject thiz
) {
    return g_initialized ? JNI_TRUE : JNI_FALSE;
}

/**
 * Shutdown the BEAM VM.
 * Note: BEAM cannot be cleanly stopped, this just marks it as uninitialized.
 */
JNIEXPORT void JNICALL
Java_io_beamvm_beam_1vm_1android_BeamVmNative_nativeShutdown(
    JNIEnv *env,
    jobject thiz
) {
    if (g_initialized) {
        LOGI("BEAM VM shutdown requested (marking as uninitialized)");
        g_initialized = false;
        // Note: erl_exit() would terminate the process, so we just mark as uninitialized
    }
}

/**
 * Get the OTP version string.
 */
JNIEXPORT jstring JNICALL
Java_io_beamvm_beam_1vm_1android_BeamVmNative_nativeGetOtpVersion(
    JNIEnv *env,
    jobject thiz
) {
    // TODO: Extract actual OTP version from runtime
    return env->NewStringUTF("28");
}

/**
 * Call an Erlang function (placeholder for future implementation).
 * Full implementation would require ei library integration.
 */
JNIEXPORT jstring JNICALL
Java_io_beamvm_beam_1vm_1android_BeamVmNative_nativeCall(
    JNIEnv *env,
    jobject thiz,
    jstring module,
    jstring function,
    jstring argsJson
) {
    if (!g_initialized) {
        LOGE("Cannot call: BEAM VM not initialized");
        return nullptr;
    }

    // TODO: Implement using ei library for Erlang term encoding
    // For now, return a placeholder response
    LOGI("nativeCall placeholder - full implementation requires ei library");
    return env->NewStringUTF("null");
}

/**
 * Send a message to an Erlang process (placeholder for future implementation).
 */
JNIEXPORT void JNICALL
Java_io_beamvm_beam_1vm_1android_BeamVmNative_nativeSend(
    JNIEnv *env,
    jobject thiz,
    jstring processName,
    jstring messageJson
) {
    if (!g_initialized) {
        LOGE("Cannot send: BEAM VM not initialized");
        return;
    }

    // TODO: Implement using ei library
    LOGI("nativeSend placeholder - full implementation requires ei library");
}

} // extern "C"
