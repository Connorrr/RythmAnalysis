//
//  ViewController.swift
//  RythmAnalysis
//
//  Created by Connor Reid on 9/1/18.
//  Copyright © 2018 Connor Reid. All rights reserved.
//

import AudioKit
import AudioKitUI
import UIKit
import Foundation

class ViewController: UIViewController {
    
    @IBOutlet weak var bPMLabel: UILabel!
    @IBOutlet weak var startStopMetroButton: UIButton!
    @IBOutlet weak var graphView: EZAudioPlot!
    @IBOutlet weak var playStopButton: UIButton!
    
    var metronome = AKMetronome()
    var mic : AKMicrophone!
    var micBooster = AKBooster()
    var mixer = AKMixer()
    var micMixer = AKMixer()
    var recorder : AKNodeRecorder!
    var player : AKAudioPlayer!
    var playerBooster = AKBooster()
    var recordingFile : AKAudioFile!
    var playerFile : AKAudioFile!
    
    var lastTapTime : Date?
    var newTapTime : Date?
    var numberOfTaps : Int = 0
    var avgDuration = TimeInterval()
    var BPM = 0.0
    
    let errorHandler = AKErrorHandler()
    
    //MARK:  Actions
    
    @IBAction func bPMTabButtonPressed(sender: UIButton) {
        timeAverager: if numberOfTaps != 0 {
            lastTapTime = newTapTime
            newTapTime = Date()
            let currentAvg = newTapTime!.timeIntervalSince(lastTapTime!)
            
            if numberOfTaps > 3{
                if (currentAvg < avgDuration/2 || currentAvg > avgDuration*3/2){
                    BPM = 0.0
                    numberOfTaps = 0
                    newTapTime = Date()
                    lastTapTime = nil
                    avgDuration = 0
                    break timeAverager
                }
                metronome.tempo = BPM
            }
            if numberOfTaps == 1 {
                avgDuration = currentAvg
                BPM = 60/avgDuration
            }else{
                avgDuration = (avgDuration + currentAvg)/2
                BPM = 60/avgDuration
            }
            
        }else{
            newTapTime = Date()
            BPM = 0
        }
        bPMLabel.text = "\(Int(BPM)) BPM"
        numberOfTaps += 1
        
    }
    
    @IBAction func startStopButtonPressed(_ sender: UIButton) {
        if metronome.isStarted {
            metronome.stop()
            metronome.reset()
            sender.setTitle("Start", for: .normal)
        }else{
            metronome.tempo = BPM
            metronome.reset()
            metronome.restart()
            sender.setTitle("Stop", for: .normal)
        }
    }
    
    @IBAction func recorduttonPressed(_ sender: UIButton) {
        
        if recorder != nil {
            if recorder.isRecording {
                recorder.stop()
                
                //  Replace the players audio file with this new one if applicable
                errorHandler.wrap(f: {try player.replace(file: recorder.audioFile!)}, errorMessage: "Error replacing the player file in ViewController: recordbuttonPressed()")
                sender.setTitle("Record", for: .normal)
                
            }else{
                
                if player.isPlaying {
                    player.stop()
                    playStopButton.setTitle("Start", for: .normal)
                }
                
                //  overwrite the audio file if it exists
                errorHandler.wrap(f: {try recorder.reset()}, errorMessage: "There was an error when attempting to reset the recorder")
                
                //  Start recording
                errorHandler.wrap(f: {try recorder.record()}, errorMessage: "Error, cannot record")

                if recorder.isRecording {
                    sender.setTitle("Stop Recording", for: .normal)
                }
            }
        }else{
            print("ERROR(ViewController:recorduttonPressed):  AKRecorder does not exist.")
        }
        
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        if player != nil {
            if player.isPlaying {
                player.stop()
                sender.setTitle("Play", for: .normal)
            }else{
                player.start()
                sender.setTitle("Stop", for: .normal)
            }
        }else{
            print("ERROR:  ViewController(playButtonPressed): No player.  Please make sure there is a recording to play")
        }
    }
    
    //MARK:  ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAKSession()
        
        mic = AKMicrophone()
        
        micMixer = AKMixer(mic)
        
        micBooster = AKBooster(micMixer, gain: 0.0)
        
        //  Init the players initial AKAudioFile
        playerFile = errorHandler.wrap(f: { return try AKAudioFile(readFileName: "BluegrassRiff.wav") }, errorMessage: "There's an error in the audiofile")
        
        //  Create the recording file
        recordingFile = errorHandler.wrap(f: {return try AKAudioFile()}, errorMessage: "Error creating the recording file")
        
        //  Init the recorder node
        recorder = errorHandler.wrap(f: {return try AKNodeRecorder(node: micMixer, file: recordingFile)}, errorMessage: "There was an error creating the Recorder Node")
        
        //  Init the player node
        player = errorHandler.wrap(f: {return try AKAudioPlayer(file: playerFile, looping: true, lazyBuffering: true, completionHandler: nil)}, errorMessage: "Audio Player setup error")
        
        metronome.subdivision = 4
        metronome.frequency1 = 4000
        metronome.frequency2 = 2000
        
        playerBooster = AKBooster(player, gain: 1.0)
        
        mixer = AKMixer(metronome, playerBooster, micBooster)
        
        AudioKit.output = mixer
        
        AudioKit.start()
        initSubPlots()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //  MARK:  SetupFunctions
    
    func setupAKSession(){
        AKSettings.bufferLength = .medium
        
        // Set the AK Settion up to play and record
        errorHandler.wrap(f: {try AKSettings.setSession(category: .playAndRecord, with: .allowBluetoothA2DP)}, errorMessage: "Could not set session category")
        
    }
    
    //  Initialize the subplots
    func initSubPlots(){
        let plot = AKNodeOutputPlot(mic, frame: graphView.bounds)
        plot.plotType = .buffer
        plot.backgroundColor = graphView.backgroundColor
        plot.shouldFill = true
        plot.shouldMirror = true
        plot.clipsToBounds = true
        graphView.addSubview(plot)
    }
    
}

