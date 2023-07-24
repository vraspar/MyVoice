import Foundation
import AVFoundation
import onnxruntime_training_objc

class Trainer {
    private let ortEnv: ORTEnv
    private let trainingSession: ORTTrainingSession
    private let checkpoint: ORTCheckpoint
    private var recordingCounter: Int
    private let kSampleAudioRecordings: Int = 20
    
    enum TrainerError: Error {
        case Error(_ message: String)
    }
    
    init() throws {
        ortEnv = try ORTEnv(loggingLevel: ORTLoggingLevel.warning)
        
        // get path for artifacts
        guard let trainingModelPath = Bundle.main.path(forResource: "training_model", ofType: "onnx") else {
            throw TrainerError.Error("Failed to find training model file.")
        }
        
        guard let evalModelPath = Bundle.main.path(forResource: "eval_model",ofType: "onnx") else {
            throw TrainerError.Error("Failed to find eval model file.")
        }
        
        guard let optimizerPath = Bundle.main.path(forResource: "optimizer_model", ofType: "onnx") else {
            throw TrainerError.Error("Failed to find optimizer model file.")
        }
        
        guard let checkpointPath = Bundle.main.path(forResource: "checkpoint", ofType: nil) else {
            throw TrainerError.Error("Failed to find checkpoint file.")
        }
        
        checkpoint = try ORTCheckpoint(path: checkpointPath)
        
        trainingSession = try ORTTrainingSession(env: ortEnv, sessionOptions: ORTSessionOptions(), checkpoint: checkpoint, trainModelPath: trainingModelPath, evalModelPath: evalModelPath, optimizerModelPath: optimizerPath)
        
        recordingCounter = 0
    }

    
    func exportModelForInference() throws {
        guard let modelsDirUrl = Bundle.main.url(forResource: "models", withExtension: nil) else {
            throw TrainerError.Error("Failed to find models directory.")
        }
        let modelPath = modelsDirUrl.appendingPathComponent("inference_model.onnx").path
        try trainingSession.exportModelForInference(withOutputPath: modelPath, graphOutputNames: ["output"])
    }
    
    
    func train(audio: Data)  -> Result<Float, Error> {
        return Result<Float, Error> { () -> Float in
            let wavFileData = try getDataFromWavFile(fileName: "other_\(recordingCounter)")
            var loss = try trainStep(inputData: wavFileData, label: 0)
            loss = try trainStep(inputData: audio, label: 1)
            recordingCounter = min(recordingCounter + 1, kSampleAudioRecordings - 1)
            return loss
        }
    }

    
    func trainStep(inputData: Data, label: Int64) throws -> Float  {
        
        let inputs = [try getORTValue(data: inputData), try getORTValue(intData: label)]
        let outputs = try trainingSession.trainStep(withInputValues: inputs)
        

//        if outputs.count != 1 {
//            throw TrainerError.Error("Failed to perform training step: outputs are empty or outputData does not have correct shape")
//        }
//
//        let outputData = try Data(outputs[1].tensorData())
//
//        // get Float value from outputData: NSMutableData
//        var loss: Float = 0.0
//
//        outputData.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
//            loss = bytes.load(as: Float.self)
//        }
        
        
//        let loss = outputData.withUnsafeBytes { (ptr: UnsafePointer<Float>) -> Float in
//            return ptr.pointee
//        }

        // update the model params
        try trainingSession.optimizerStep()
        
        // reset the gradients
        try trainingSession.lazyResetGrad()
        
        return 0
       
    }
    
    private func getORTValue(data: Data) throws -> ORTValue {
        let tensorData = NSMutableData(data: data)
        let inputShape: [NSNumber] = [1, data.count / MemoryLayout<Float>.stride as NSNumber]

        return try ORTValue(
            tensorData: tensorData, elementType: ORTTensorElementDataType.float, shape: inputShape
        )
    }

    private func getORTValue(intData: Int64) throws -> ORTValue {
        let tensorData = NSMutableData(data: withUnsafeBytes(of: intData) {Data($0)})

        return try ORTValue (
            tensorData: tensorData, elementType: ORTTensorElementDataType.int64, shape: [1]
        )
    }

    private func getDataFromWavFile(fileName: String) throws -> Data {
        guard let fileUrl = Bundle.main.url(forResource: fileName, withExtension:"wav") else {
            throw TrainerError.Error("Failed to find wav file: \(fileName).")
        }
        
        let audioFile = try AVAudioFile(forReading: fileUrl)
        
        let format = audioFile.processingFormat
        
        let totalFrames = AVAudioFrameCount(audioFile.length)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else {
            throw TrainerError.Error("Failed to create audio buffer.")
        }
        
        try audioFile.read(into: buffer)
        
        guard let floatChannelData = buffer.floatChannelData else {
            throw TrainerError.Error("Failed to get float channel data.")
        }
        
        let data = Data(
            bytesNoCopy: floatChannelData[0],
            count: Int(buffer.frameLength) * MemoryLayout<Float>.size,
            deallocator: .none
        )
        
        return data
    }
}

