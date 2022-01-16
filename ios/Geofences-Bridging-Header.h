#import <React/RCTBridgeModule.h>
#import <React/RCTViewManager.h>

@protocol GeofenceManagment
- (void) startMonitoring: (RCTPromiseResolveBlock) resolve reject: (RCTPromiseRejectBlock) reject;
- (void) stopMonitoring:  (RCTPromiseResolveBlock) resolve reject: (RCTPromiseRejectBlock) reject;
@end

@protocol GeofenceDelegate
- (void) geofenceEvent:(NSDictionary *) geofenceModel geofenceManager: (id<GeofenceManagment>) geofenceManager;
@end
