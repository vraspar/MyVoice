import SwiftUI

struct InferView: View {
    
    enum InferState {
        case user
        case other
        case notSet
    }
    private let audioRecorder = AudioRecorder()
    private let voiceIdentifier = try! VoiceIdentifier()
    @State private var readyToRecord: Bool = true
    @State private var inferResult: InferState = InferState.notSet
    @State private var probUser: Float = 0.0
    
    private func recordVoice() {
        audioRecorder.record { recordResult in
            let recognizeResult = recordResult.flatMap { recordingBufferAndData in
                return voiceIdentifier.evaluate(inputData: recordingBufferAndData.data)
            }
            endRecord(recognizeResult)
        }
    }

    private func endRecord(_ result: Result<(Bool, Float), Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let (isMatch, confidence)):
               print("Your Voice with confidence: \(isMatch),  \(confidence)")
                inferResult = isMatch ? .user : .notSet
                probUser = confidence
            case .failure(let error):
                print("Error: \(error)")
            }
            readyToRecord = true
        }
    }
    
    var body: some View {
        VStack {
            Spacer()

            ZStack(alignment: .center) {
                Image(systemName: "mic.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor( readyToRecord ? .gray: .red)
                    .transition(.scale)
                    .animation(.easeIn, value: 1)
            }
                
            if inferResult != .notSet {
                Spacer()
                ZStack (alignment: .center) {
                    Image(systemName: inferResult == .user ? "person.crop.circle.fill.badge.checkmark": "person.crop.circle.fill.badge.xmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.green)
                        .animation(.easeInOut, value: 0.5)
                   
                }
                Text("Probability:  \(String(format: "%.2f", probUser))")
                    .multilineTextAlignment(.center)
                
            }
            Spacer()
                
            Button(action: {
                    readyToRecord = false
                    recordVoice()
            }) {
                Text(readyToRecord ? "Record" : "Recording ...")
                    .font(.title)
                    .padding()
                    .background(readyToRecord ? .green : .gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                }.disabled(!readyToRecord)
            Spacer()
            
        }
        .padding()
        .navigationTitle("Infer")
    }
}

struct InferView_Previews: PreviewProvider {
    static var previews: some View {
        InferView()
    }
}

