//
//  ErrorImpl.swift
//  Geofences
//
//  Created by Dima on 17.01.2022.
//  Copyright © 2022 Facebook. All rights reserved.
//

import Foundation

enum ErrorImpl: Error {
    case error(code: Int, message: String, error: NSError? = nil)
    
    func convertToTuple() -> (Int?, String?, NSError?){        
        switch self {
            case let.error(code, message, error1):
                return (code, message, error1)
            default:
                return (nil, nil, nil)
            }
    }
}
