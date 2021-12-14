#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(Geofences, NSObject)

/*RCT_EXTERN_METHOD(multiply:(float)a withB:(float)b
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)*/

RCT_EXTERN_METHOD(startMonitoring:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(stopMonitoring:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(requestPermissions:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(permissionsStatus:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(addGeofences:(NSDictionary *)geofencesHolder                                          resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(isExistsGeofenceById:(String) id
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(isExistsGeofenceByCoordinate:(NSDictionary*)coordinate
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(removeGeofences:(NSArray*) filter
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(isStartedMonitoring:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

@end
