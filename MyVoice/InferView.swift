import SwiftUI

struct InferView: View {
    private let audioRecorder = AudioRecorder()
    private let voiceIdentifier = try! VoiceIdentifier()
    @State private var readyToRecord: Bool = true
    @State private var res: String = ""
    
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
                res = isMatch ? "Yes" : "No"
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
            
            if res != "" {
                Text("\(res)")
                
            }
            
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

