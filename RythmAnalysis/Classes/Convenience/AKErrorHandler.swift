//
//  ErrorHandler.swift
//  RythmAnalysis
//
//  Created by Connor Reid on 24/1/18.
//  Copyright © 2018 Connor Reid. All rights reserved.
//
// This class handles the do, try, catch methods that are overwhelmingly common in AudioKit.

import AudioKit

class AKErrorHandler {
    
    
    /// Takes a block which throws an error and handles the error by logging the error with or without a custom message.
    ///
    /// - Parameters:
    ///   - f: Block of code to be executed
    ///   - errorMessage: custom message prefix for the error log
    /// - Returns: Block return
    func wrap<ReturnType>(f: () throws -> ReturnType?, errorMessage: String?) -> ReturnType? {
        do {
            return try f()
        } catch let error as NSError {
            logError(error: error, msg: errorMessage)
            return nil
        }
    }
    
    private func logError(error: NSError, msg: String?) {
        if msg != nil {
            AKLog("\(msg!):  \(error)")
        }else{
            AKLog("AudioKit has encountered an error:  \(error)")
        }
    }
    
}
