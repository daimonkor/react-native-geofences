@objc(Geofences)
class Geofences: NSObject {

    @objc(multiply:withB:withResolver:withRejecter:)
    func multiply(a: Float, b: Float, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) {
        resolve(a*b)
    }

    @objc(startMonitoring:rejecter:)
     func startMonitoring(_ resolve:  RCTPromiseResolveBlock, rejecter reject:  RCTPromiseRejectBlock)  -> Void   {
       resolve(true)
    }

    @objc(stopMonitoring:rejecter:)
    func stopMonitoring(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock)  -> Void  {
         resolve(true)
      }
}
