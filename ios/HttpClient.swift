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

func dataRequest<T: Decodable>(with url: String, objectType: T.Type, completion: @escaping (Result<T>) -> Void) {
    let dataURL = URL(string: url)!
    let session = URLSession.shared
    let request = URLRequest(url: dataURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
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
