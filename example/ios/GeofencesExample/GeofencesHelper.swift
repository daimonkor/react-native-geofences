//
//  GeofencesHelper.swift
//  GeofencesExample
//
//  Created by Dima on 17.01.2022.
//

import Foundation

enum AppError: Error {
  case networkError(Error)
  case dataNotFound
  case jsonParsingError(Error)
  case invalidStatusCode(Int)
}

enum Result<T> {
  case success(T)
  case failure(AppError)
}

struct CodingKeys: CodingKey {
  var stringValue: String
  init(stringValue: String) {
    self.stringValue = stringValue
  }
  var intValue: Int?
  init?(intValue: Int) {
    return nil
  }
}

class ResponseModel: Decodable{
  let id: String?
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try? container.decode(String.self, forKey: CodingKeys(stringValue: "id"))
  }
}


@objc(GeofencesHelper)
class GeofencesHelper: NSObject {
  static let STOP_SHIFT_KEY = "STOP_SHIFT_KEY"
  
  override init(){
    super.init()
  }
  
  @objc static func openUrl(notification: UNNotification?){
    let userInfo = notification?.request.content.userInfo;
    let siteURL = userInfo?["actionUrl"] as? String;
    if(siteURL != nil){
      guard let url = URL(string: siteURL!) else {
        return //be safe
      }
      
      if #available(iOS 10.0, *) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      } else {
        UIApplication.shared.openURL(url)
      }
    }
  }
  
  @objc
  public func request(geofenceModel: NSDictionary, geofenceManager: GeofenceManagment ){
    let typeTransactions = (geofenceModel["GEOFENCES_LIST_KEY"] as? [String: Any?])?["typeTransactions"] as? [String: Any?]
    if(geofenceModel["TRANSITION_TYPE_KEY"] != nil){
      let extraData = (typeTransactions?[String(geofenceModel["TRANSITION_TYPE_KEY"] as! Int)] as? [String: Any?])?["extraData"] as? [String: Any?]
      let url = extraData?["url"] as? String
      let headers = extraData?["headers"]
      let body = extraData?["body"]
      if(url != nil){
        self.dataRequest(with: url!, headers: headers as? [String: Any?], body: body as? [String: Any?], objectType: ResponseModel.self, completion: {result in
          switch result {
            case .success(let success):
              print("Response success", success.id)
            case .failure(let error):
              print("Response error", error.localizedDescription)
          }
          //          geofenceManager.sendEvent("onStopShiftByServer", body: [GeofencesHelper.STOP_SHIFT_KEY: true])
          //          geofenceManager.stopMonitoring { data in
          //
          //          } reject: { code, message, error in
          //
          //  
        })
      }
    }
  }
  
  
  func dataRequest<T: Decodable>(with url: String, headers: [String: Any?]?, body: [String: Any?]?, objectType: T.Type, completion: @escaping (Result<T>) -> Void) {
    let dataURL = URL(string: url)!
    let session = URLSession.shared
    var request = URLRequest(url: dataURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
    headers?.forEach({ (key: String, value: Any?) in
      request.addValue(key, forHTTPHeaderField: value as? String ?? "")
    })
    let jsonData = try? JSONSerialization.data(withJSONObject: body)
    if(jsonData != nil){
       request.httpBody = jsonData
    }
    request.httpMethod = "POST"
    print("Request: \(request)")
    
    let task = session.dataTask(with: request, completionHandler: { data, response, error in
      guard error == nil else {
        completion(Result.failure(AppError.networkError(error!)))
        return
      }
      guard let data = data else {
        completion(Result.failure(AppError.dataNotFound))
        return
      }
      do {
        let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
         if let responseJSON = responseJSON as? [String: Any] {
             print("Response json", responseJSON)
         }
        let decodedObject = try JSONDecoder().decode(objectType.self, from: data)
        completion(Result.success(decodedObject))
      } catch let error {
        completion(Result.failure(AppError.jsonParsingError(error as! DecodingError)))
      }
    })
    task.resume()
  }
}
