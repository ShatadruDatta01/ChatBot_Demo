//
//  ChatController.swift
//  ChatBot_Demo
//
//  Created by Shatadru Datta on 3/31/18.
//  Copyright © 2018 ARBSoftware. All rights reserved.
//

import UIKit
import ApiAI
import Speech
import AVFoundation

let speechRecognitionTimeout: Double = 3
let maximumAllowedTimeDuration = 3

class ChatController: UIViewController, SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate {

    var isAudioRunning = false
    var senderText: String!
    var botText: String!
    @IBOutlet weak var btnLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var chatViewLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var tblChatBot: UITableView!
    var checkText = false
    var isFinal: Bool!
    var isEnd = false
    var text: String!
    var arrData = [AnyObject]()
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var chipResponse: UILabel!
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var speechRecognizerUtility: SpeechRecognitionUtility?
    
    private var timer: Timer?
    private var totalTime: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tblChatBot.estimatedRowHeight = 70.0
        self.tblChatBot.rowHeight = UITableViewAutomaticDimension
        self.messageField.placeholder = "Type message"
//        let audioSession = AVAudioSession.sharedInstance()  //2
//        do {
//            try audioSession.setCategory(AVAudioSessionCategoryRecord)
//            try audioSession.setMode(AVAudioSessionModeMeasurement)
//            //try audioSession.setCategory(AVAudioSessionCategoryPlayback)
//            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
//        } catch {
//            print("audioSession properties weren't set because of an error.")
//        }
        
        speechSynthesizer.delegate = self
        speechRecognizer.delegate = self
    
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            switch authStatus {
                
            case .authorized:
                print("Success")

            case .denied:
                print("User denied access to speech recognition")
                
            case .restricted:
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                print("Speech recognition not yet authorized")
            }
        }
        
     //   self.recording()
        // Do any additional setup after loading the view.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    @IBAction func playVoice(_ sender: UIButton) {
        if sender.isSelected {
            self.messageField.placeholder = "Type message"
            sender.isSelected = false
            self.recording()
            btnPlay.setImage(UIImage(named: "mic"), for: .normal)
            
        } else {
            self.messageField.placeholder = "Say something..."
            self.recording()
            sender.isSelected = true
            btnPlay.setImage(UIImage(named: "mic_active"), for: .normal)
        }
    }
    
    @IBAction func sendMessage(_ sender: UIButton) {
        
        if (self.messageField.text?.isEmpty)! {
            //.........//
        } else {
            self.arrData.append(self.messageField.text as AnyObject)
            self.tblChatBot.reloadData()
            self.scrollToBottom()
            self.senderText = self.messageField.text
            self.sendMessage(text: self.messageField.text!)
        }
    }
    
    func scrollToBottom(){
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.arrData.count-1, section: 0)
            self.tblChatBot.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    func recording() {
        self.startRecordingSecondMethod()
        //self.startRecording()
    }
    
    
    func startRecording() {
        
        if recognitionTask != nil {  //1
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        } //5
        
        recognitionRequest.shouldReportPartialResults = true  //6
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in  //7
            
            self.isFinal = false  //8
            
            if result != nil {
                
                
                self.messageField.text = result?.bestTranscription.formattedString  //9
                
//                for segment in (result?.bestTranscription.segments)! {
//                    let indexTo = result?.bestTranscription.formattedString.index((result?.bestTranscription.formattedString.endIndex)!, offsetBy: segment.substringRange.location)
//                    print("Recent One  \(result!.bestTranscription.formattedString.substring(from: indexTo!))")
//                }
                
                self.isFinal = (result?.isFinal)!
                print(self.isFinal)
                
                Timer.scheduledTimer(timeInterval: 5,
                                     target: self,
                                     selector: #selector(self.stop),
                                     userInfo: nil,
                                     repeats: false)
                
            }
            
            if error != nil || self.isFinal {  //10
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.sendMessage(text: self.messageField.text!)
            }
        })
        
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)  //11
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()  //12

        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        
       // self.messageField.text = "Say something, I'm listening!"
        
    }
    
    @objc func stop() {
        //self.sendMessage()
    }
    
    
    @objc func sendMessage(text: String) {
        
        
        let request = ApiAI.shared().textRequest()
        
        if let text = self.messageField.text, text != "" {
            request?.query = text
        } else {
            return
        }
        
        request?.setMappedCompletionBlockSuccess({ (request, response) in
            let response = response as! AIResponse
            print(response)
            if let textResponse = response.result.fulfillment.speech {
                print(textResponse)
                self.speechAndText(text: textResponse)
            }
        }, failure: { (request, error) in
            print(error!)
        })
        
        ApiAI.shared().enqueue(request)
        messageField.text = ""
    }
    
    
    
    func speechAndText(text: String) {
        
//        let audioSession = AVAudioSession.sharedInstance()  //2
//        do {
//            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
//            try audioSession.setMode(AVAudioSessionModeMeasurement)
//            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
//        } catch {
//            print("audioSession properties weren't set because of an error.")
//        }

        
        let speechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")!
        speechUtterance.rate = 0.4
        speechSynthesizer.speak(speechUtterance)
        UIView.animate(withDuration: 1.0, delay: 0.0, options: .curveEaseInOut, animations: {
            self.chipResponse.text = text
            self.arrData.append(text as AnyObject)
            self.tblChatBot.reloadData()
            self.scrollToBottom()
        }, completion: nil)


    }
    
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("all done")
//        if btnPlay.isSelected {
//            self.startRecordingSecondMethod()
//        } else {
//            //.....//
//        }
        
        if self.isAudioRunning {
        } else {
            self.startRecordingSecondMethod()
        }
    }
    
    
    
    
    func startRecordingSecondMethod() {
        
        if speechRecognizerUtility == nil {
            // Initialize the speech recognition utility here
            speechRecognizerUtility = SpeechRecognitionUtility(speechRecognitionAuthorizedBlock: { [weak self] in
                self?.toggleSpeechRecognitionState()
                }, stateUpdateBlock: { [weak self] (currentSpeechRecognitionState, finalOutput) in
                    // A block to update the status of speech recognition. This block will get called every time Speech framework recognizes the speech input
                    self?.stateChangedWithNew(state: currentSpeechRecognitionState)
                    // We won't perform translation until final input is ready. We will usually wait for users to finish speaking their input until translation request is sent
                    if finalOutput {
                        //self?.stopTimeCounter()
                        self?.toggleSpeechRecognitionState()
                        self?.speechRecognitionDone()
                    }
                }, timeoutPeriod: speechRecognitionTimeout) // We will set the Speech recognition Timeout to make sure we get the full string output once user has stopped talking. For example, if we specify timeout as 2 seconds. User initiates speech recognition, speaks continuously (Hopegully way less than full one minute), and if pauses for more than 2 seconds, value of finalOutput in above block will be true. Before that you will keep getting output, but that won't be the final one.
        } else {
            // We will call this method to toggle the state on/off of speech recognition operation.
            self.toggleSpeechRecognitionState()
        }
    }
    
    func speechRecognitionDone() {
        // Trigger the request to get translations as soon as user has done providing full speech input. Don't trigger until query length is at least one.
        if let query = self.messageField.text, query.count > 0 {
            // Disable the toggle speech button while we're getting translations from server.
            NetworkRequest.sendRequestWith(query: query, completion: { (translation) in
                OperationQueue.main.addOperation {
                    // Explicitly execute the code on main thread since the request we get back need not be on the main thread.
                    self.sendMessage(text: self.messageField.text!)
                    self.arrData.append(self.senderText as AnyObject)
                    self.tblChatBot.reloadData()
                    self.scrollToBottom()
                      //translation
                    // Re-enable the toggle speech button once translations are ready.
                }
            })
        }
    }
    
    // A method to toggle the speech recognition state between on/off
    private func toggleSpeechRecognitionState() {
        do {
            try self.speechRecognizerUtility?.toggleSpeechRecognitionActivity()
        } catch SpeechRecognitionOperationError.denied {
            print("Speech Recognition access denied")
        } catch SpeechRecognitionOperationError.notDetermined {
            print("Unrecognized Error occurred")
        } catch SpeechRecognitionOperationError.restricted {
            print("Speech recognition access restricted")
        } catch SpeechRecognitionOperationError.audioSessionUnavailable {
            print("Audio session unavailable")
        } catch SpeechRecognitionOperationError.invalidRecognitionRequest {
            print("Recognition request is null. Expected non-null value")
        } catch SpeechRecognitionOperationError.audioEngineUnavailable {
            print("Audio engine is unavailable. Cannot perform speech recognition")
        } catch {
            print("Unknown error occurred")
        }
    }
    
    private func stateChangedWithNew(state: SpeechRecognitionOperationState) {
        switch state {
        case .authorized:
            print("State: Speech recognition authorized")
        case .audioEngineStart:
            self.isAudioRunning = true
            self.startTimeCounterAndUpdateUI()
            print("State: Audio Engine Started")
        case .audioEngineStop:
            print("State: Audio Engine Stopped")
        case .recognitionTaskCancelled:
            self.isAudioRunning = false
            print("State: Recognition Task Cancelled")
        case .speechRecognized(let recognizedString):
            self.messageField.text = recognizedString
            senderText = recognizedString
            print("State: Recognized String \(recognizedString)")
        case .speechNotRecognized:
            print("State: Speech Not Recognized")
        case .availabilityChanged(let availability):
            print("State: Availability changed. New availability \(availability)")
        case .speechRecognitionStopped(let finalRecognizedString):
            self.stopTimeCounter()
            print("State: Speech Recognition Stopped with final string \(finalRecognizedString)")
        }
    }

    
    private func startTimeCounterAndUpdateUI() {
        
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }

        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
            guard let weakSelf = self else { return }
            
            guard weakSelf.totalTime < maximumAllowedTimeDuration else {
                //weakSelf.stopTimeCounter()
                return
            }
            
            weakSelf.totalTime = weakSelf.totalTime + 1
        })
    }
    
    private func stopTimeCounter() {
        self.timer?.invalidate()
        self.timer = nil
        self.totalTime = 0
    }
    
}

// MARK: - TextFieldDelegate
extension ChatController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        self.startRecordingSecondMethod()
        
       
        btnSend.isSelected = false
        btnSend.setImage(UIImage(named: "send"), for: .normal)
        
        self.btnLayoutConstraint.constant = 26
        self.chatViewLayoutConstraint.constant = 0
        self.checkText = false
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        btnSend.isSelected = true
        btnSend.setImage(UIImage(named: "send_active"), for: .normal)

        self.btnLayoutConstraint.constant = 284
        self.chatViewLayoutConstraint.constant = 258
        self.checkText = true
        return true
    }
}



// MARK: - TableViewDelegate, TableViewDatasource
extension ChatController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(indexPath.row % 2 == 0) {
            let senderCell = tableView.dequeueReusableCell(withIdentifier: "SenderCell", for: indexPath) as! SenderCell
            senderCell.datasource = self.arrData[indexPath.row]
            return senderCell

        } else {
            let receiverCell = tableView.dequeueReusableCell(withIdentifier: "ReceiverCell", for: indexPath) as! ReceiverCell
            receiverCell.datasource = self.arrData[indexPath.row]
            return receiverCell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

