/*

	
	Abstract:
	High-level call audio management functions
*/

import Foundation

private var audioController: AudioController?

func configureAudioSession() {
    print("Configuring audio session")
    
    if audioController == nil {
        audioController = AudioController()
    }
}

func startAudio() {
    print("Starting audio")
    
    if audioController?.startIOUnit() == kAudioServicesNoError {
        audioController?.muteAudio = false
    } else {
        // handle error
    }
}

func stopAudio() {
    print("Stopping audio")
    
    if audioController?.stopIOUnit() != kAudioServicesNoError {
        // handle error
    }
}
