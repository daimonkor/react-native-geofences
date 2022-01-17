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
