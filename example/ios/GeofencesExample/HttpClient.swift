//
//  HttpClient.swift
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


@objc(HttpClient)
class HttpClient: NSObject {
  override init(){}
  
  @objc
  public static func  hello(){
    print("AAAAAA")
  }
  
  static func dataRequest<T: Decodable>(with url: String, headers: [String: Any?]?, body: [String: Any?]?, objectType: T.Type, completion: @escaping (Result<T>) -> Void) {
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
                 let decodedObject = try JSONDecoder().decode(objectType.self, from: data)
                 completion(Result.success(decodedObject))
             } catch let error {
                 completion(Result.failure(AppError.jsonParsingError(error as! DecodingError)))
             }
         })
         task.resume()
     }
}
