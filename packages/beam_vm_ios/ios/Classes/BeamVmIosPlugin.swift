import Flutter
import UIKit

/// Flutter plugin for embedding the Erlang/Elixir BEAM VM on iOS.
public class BeamVmIosPlugin: NSObject, FlutterPlugin {
    private var isVmInitialized = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "io.beamvm/beam_vm",
            binaryMessenger: registrar.messenger()
        )
        let instance = BeamVmIosPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            handleInitialize(call, result: result)
        case "shutdown":
            handleShutdown(result: result)
        case "call":
            handleCall(call, result: result)
        case "send":
            handleSend(call, result: result)
        case "getOtpVersion":
            result(BeamVmBridge.getOtpVersion())
        case "isInitialized":
            result(isVmInitialized)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleInitialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let erlangPath = args["erlangPath"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "erlangPath is required",
                details: nil
            ))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let code = BeamVmBridge.initialize(erlangPath: erlangPath)

            DispatchQueue.main.async {
                if code == 0 {
                    self?.isVmInitialized = true
                    result(true)
                } else {
                    result(FlutterError(
                        code: "INIT_FAILED",
                        message: "BEAM VM initialization failed with code: \(code)",
                        details: code
                    ))
                }
            }
        }
    }

    private func handleShutdown(result: @escaping FlutterResult) {
        BeamVmBridge.shutdown()
        isVmInitialized = false
        result(nil)
    }

    private func handleCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isVmInitialized else {
            result(FlutterError(
                code: "NOT_INITIALIZED",
                message: "BEAM VM is not initialized",
                details: nil
            ))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let module = args["module"] as? String,
              let function = args["function"] as? String,
              let argsJson = args["args"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "module, function, and args are required",
                details: nil
            ))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let response = BeamVmBridge.call(module: module, function: function, args: argsJson)

            DispatchQueue.main.async {
                result(response)
            }
        }
    }

    private func handleSend(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isVmInitialized else {
            result(FlutterError(
                code: "NOT_INITIALIZED",
                message: "BEAM VM is not initialized",
                details: nil
            ))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let processName = args["processName"] as? String,
              let message = args["message"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "processName and message are required",
                details: nil
            ))
            return
        }

        BeamVmBridge.send(processName: processName, message: message)
        result(nil)
    }
}

/// Bridge to native BEAM VM functions.
/// The liberlang.xcframework is bundled in this package.
class BeamVmBridge {
    private static var initialized = false

    static func initialize(erlangPath: String) -> Int32 {
        guard !initialized else { return 0 }

        let result = beam_init(erlangPath)
        if result == 0 {
            initialized = true
        }
        return result
    }

    static func shutdown() {
        if initialized {
            beam_cleanup()
            initialized = false
        }
    }

    static func isInitialized() -> Bool {
        return initialized && beam_is_initialized()
    }

    static func getOtpVersion() -> String {
        return "28" // TODO: Extract from runtime
    }

    static func call(module: String, function: String, args: String) -> String? {
        // TODO: Implement using ei library
        return nil
    }

    static func send(processName: String, message: String) {
        // TODO: Implement using ei library
    }
}
