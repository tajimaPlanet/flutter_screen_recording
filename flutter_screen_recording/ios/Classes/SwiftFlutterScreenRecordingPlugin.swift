import Flutter
import UIKit
import ReplayKit
import AVFoundation

public class SwiftFlutterScreenRecordingPlugin: NSObject, FlutterPlugin {
    
    let recorder = RPScreenRecorder.shared()
    var videoOutputURL: URL?
    var isRecording = false
    let screenSize = UIScreen.main.bounds
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_screen_recording", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterScreenRecordingPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startRecordScreen":
            guard let args = call.arguments as? [String: Any],
                  let name = args["name"] as? String,
                  let path = args["path"] as? String,
                  let includeAudio = args["audio"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments", details: nil))
                return
            }
            startRecording(videoName: name, path: path, recordAudio: includeAudio, result: result)
        case "stopRecordScreen":
            stopRecording(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func startRecording(videoName: String, path: String, recordAudio: Bool, result: @escaping FlutterResult) {
        guard !isRecording else {
            result(FlutterError(code: "ALREADY_RECORDING", message: "Recording is already in progress", details: nil))
            return
        }
        
        isRecording = true
        
        // Configurar la ruta del archivo de video
        let tmpPath = NSTemporaryDirectory()
        videoOutputURL = URL(fileURLWithPath: tmpPath).appendingPathComponent("\(videoName).mp4")
        
        // Eliminar el archivo si ya existe
        if FileManager.default.fileExists(atPath: videoOutputURL!.path) {
            try? FileManager.default.removeItem(at: videoOutputURL!)
        }
        
        if #available(iOS 11.0, *) {
            // 録画開始
            recorder.startRecording { error in
                if let _ = error {
                    self.isRecording = false
                    debugPrint("歯磨きサポート収録開始に失敗。 \(#function) - \(#line)行目")
                } else {
                    self.isRecording = true
                }
                result(self.isRecording)
            }
        } else {
            result(FlutterError(code: "IOS_VERSION_ERROR", message: "This feature is only available on iOS 11 or later", details: nil))
        }
    }
    
    func stopRecording(result: @escaping FlutterResult) {
        // 録画中かどうかを確認
        guard isRecording else {
            result(FlutterError(code: "NOT_RECORDING", message: "No recording in progress", details: nil))
            return
        }
        
        isRecording = false
        
        if #available(iOS 11.0, *) {
            // 録画停止・録画データ一時保存ディレクトリに動画書き出し
            recorder.stopRecording(withOutput: videoOutputURL!) {err in
                if let err = err {
                    debugPrint("歯磨きサポート収録停止・保存に失敗。 \(#function) - \(#line)行目")
                    debugPrint(err)
                } else {
                    result(self.videoOutputURL?.path)
                }
            }
        } else {
            result(FlutterError(code: "IOS_VERSION_ERROR", message: "This feature is only available on iOS 11 or later", details: nil))
        }
    }
}
