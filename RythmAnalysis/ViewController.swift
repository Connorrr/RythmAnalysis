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
    
    var fileName = "tmprecording.caf"
    
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
                
                do{
                    try player.replace(file: recorder.audioFile!)
                }catch let error as NSError {
                    print("Error replacing the player file in ViewController: recordbuttonPressed(): \(error)")
                }
                sender.setTitle("Record", for: .normal)
            }else{
                player.stop()
                
                do {
                    try recorder.reset()
                } catch let error as NSError {
                    AKLog("There was an error when attempting to reset the recorder:  \(error)")
                }
                
                do {
                    try recorder.record()
                }catch let error as NSError {
                    AKLog("Error, cannot record:  \(error)")
                }
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
        
        do {
            playerFile = try AKAudioFile(readFileName: "BluegrassRiff.wav")
        } catch let error as NSError {
            print("There's an error in the audiofile: \(error)")
        }
        
        //  Create the recording file
        do {
            recordingFile = try AKAudioFile()
        }catch let error as NSError {
            AKLog("Error creating the recording file:  \(error)")
        }
        
        do {
            recorder = try AKNodeRecorder(node: micMixer, file: recordingFile)

        }catch let error as NSError {
            print("There was an error creating the Recorder Node:  \(error)")
        }
        
        do {
            player = try AKAudioPlayer(file: playerFile, looping: true, lazyBuffering: true, completionHandler: nil)
        }catch let error as NSError{
            print("Audio Player setup error:  \(error)")
        }
        
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
        
        do {
            try AKSettings.setSession(category: .playAndRecord, with: .allowBluetoothA2DP)
        } catch let error as NSError{
            AKLog("Could not set session category:  \(error)")
        }
        
    }
    
    func AKNodeSetup(){
        
        
    }
    
    //  Initialize the subplots
    func initSubPlots(){
        let plot = AKNodeOutputPlot(mic, frame: graphView.bounds)
        plot.plotType = .buffer
        plot.backgroundColor = graphView.backgroundColor
        plot.shouldFill = true
        plot.shouldMirror = true
        plot.color = UIColor.purple
        graphView.addSubview(plot)
    }
    
}

