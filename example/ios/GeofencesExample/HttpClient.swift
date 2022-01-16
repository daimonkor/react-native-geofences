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
}
