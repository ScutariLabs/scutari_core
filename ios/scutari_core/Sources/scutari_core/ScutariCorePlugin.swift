import Flutter
import UIKit
import Metal
import os

public class ScutariCorePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.scutarilabs.core/methods", binaryMessenger: registrar.messenger())
    let instance = ScutariCorePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "inspectDevice":
      let totalRamBytes = ProcessInfo.processInfo.physicalMemory
      let totalRamMb = Int(totalRamBytes / (1024 * 1024))

      var availableRamMb: Int
      if #available(iOS 13.0, *) {
        let availBytes = os_proc_available_memory()
        availableRamMb = Int(availBytes / (1024 * 1024))
      } else {
        availableRamMb = totalRamMb / 2
      }

      let cpuCores = ProcessInfo.processInfo.activeProcessorCount

      var delegates: [String] = ["cpu"]
      delegates.append("coreMl")

      if MTLCreateSystemDefaultDevice() != nil {
        delegates.append("metal")
        delegates.append("gpu")
      }

      let response: [String: Any] = [
        "totalRamMb": totalRamMb,
        "availableRamMb": availableRamMb,
        "cpuCores": cpuCores,
        "supportedDelegates": delegates
      ]
      result(response)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

