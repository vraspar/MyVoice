//
//  TrainView.swift
//  MyVoice
//
//  Created by onnx training on 7/19/23.
//

import SwiftUI

struct TrainView: View {
    
    private let knumRecording = 5
    private let audioRecorder = AudioRecorder()
    private let trainer = try! Trainer()
    
    @State private var currentSentenceIndex = 0
    @State private var readyToRecord: Bool = true
    @State private var isTrainingComplete = false
    let sentences: [String] = [
        "The sun sets in a blaze of fiery hues, casting its golden glow across the tranquil lake.",
        "The aroma of freshly baked bread wafts through the air, making mouths water in anticipation.",
        "The rhythmic sound of waves crashing against the shore creates a soothing melody for the soul.",
        "In the depths of the forest, a curious fox cautiously explores its surroundings, its bright eyes full of wonder.",
        "The laughter of children fills the playground as they swing high in the summer breeze.",
        "The city skyline sparkles at night, with a tapestry of lights illuminating the bustling streets below.",
        "With each stroke of the paintbrush, the artist breathes life into a blank canvas, creating a masterpiece.",
        "The gentle raindrops pitter-patter on the windowpane, creating a peaceful ambiance indoors.",
        "A lone wolf howls at the moon, its melancholic cry echoing through the wilderness.",
        "The scent of wildflowers permeates the meadow, painting it in vibrant shades of pink, purple, and yellow.",
        "The wind whispers secrets as it rustles through the leaves of ancient trees.",
        "A flock of graceful birds soars across the sky, their wings spread wide in a synchronized dance.",
        "The sound of crackling firewood brings warmth and comfort on a cold winter's night.",
        "A shooting star streaks across the night sky, granting wishes to those who believe.",
        "The sweet melody of a violin fills the concert hall, captivating the audience with its emotive notes.",
        "A gentle breeze carries the delicate petals of cherry blossoms, creating a picturesque scene of beauty.",
        "The aroma of coffee lingers in the air, enticing sleepy souls to wake up and embrace the day.",
        "The majestic mountains stand tall, their peaks reaching towards the heavens in a display of grandeur.",
        "The sound of distant thunder announces an approaching storm, as dark clouds gather in the sky.",
        "The first rays of sunlight peek over the horizon, painting the world in shades of gold and orange."
    ]
    
    private func recordVoice() {
        audioRecorder.record { recordResult in
            let recognizeResult = recordResult.flatMap { recordingBufferAndData in
                return trainer.train(audio: recordingBufferAndData.data)
            }
            endRecord(recognizeResult)
        }
    }
    
    private func endRecord(_ result: Result<Float, Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let loss):
                print("The loss is \(loss)")
            case .failure(let error):
                print("Error: \(error)")
            }
            readyToRecord = true
            
            if currentSentenceIndex < knumRecording {
                currentSentenceIndex += 1
                
            } else {
                isTrainingComplete = true
                try? trainer.exportModelForInference()
            }
        }
    }

    var body: some View {
        VStack {
            if !isTrainingComplete {
                Spacer()
                Text(sentences[currentSentenceIndex])
                    .font(.title)
                    .padding()
                    .multilineTextAlignment(.center)
                    .fontDesign(.monospaced)
                
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
                
            } else {
                Spacer()
                Text("Training successfully finished!")
                    .font(.title)
                    .padding()
                    .multilineTextAlignment(.center)
                    .fontDesign(.monospaced)
                
                Spacer()
                NavigationLink(destination: InferView()) {
                    Text("Infer")
                        .font(.title)
                        .padding()
                        .background(.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.leading, 20)

            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Train")
    }
    
    func startRecording() {
        
    }
    
    func stopRecording() {
        
    }
}

struct TrainView_Previews: PreviewProvider {
    static var previews: some View {
        TrainView()
    }
}

