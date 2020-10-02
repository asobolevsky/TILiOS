/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation

struct AcronymRequest {
  private let resource: URL
  
  init(acronymID: UUID) {
    guard let baseURL = URL(string: ResourcePaths.base) else {
      fatalError("Unable to create URL")
    }
    self.resource = baseURL
      .appendingPathComponent(Paths.acronyms)
      .appendingPathComponent(acronymID.uuidString)
  }
  
  func getUser(completion: @escaping (Result<User, ResourceRequestError>) -> Void) {
    genericGetRequest(Paths.user, completion: completion)
  }
  
  func getCategories(completion: @escaping (Result<[Category], ResourceRequestError>) -> Void) {
    genericGetRequest(Paths.categories, completion: completion)
  }
  
  func update(
    with updatedData: CreateAcronymData,
    completion: @escaping (Result<Acronym, ResourceRequestError>) -> Void
  ) {
    do {
      var urlRequest = URLRequest(url: resource)
      urlRequest.httpMethod = "PUT"
      urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
      urlRequest.httpBody = try JSONEncoder().encode(updatedData)
      let dataTask = URLSession.shared
        .dataTask(with: urlRequest) { data, response, _ in
          guard
            let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200,
            let jsonData = data
          else {
            completion(.failure(.noData))
            return
          }
          do {
            let acronym = try JSONDecoder().decode(Acronym.self, from: jsonData)
            completion(.success(acronym))
          } catch {
            completion(.failure(.decodingError))
          }
        }
      dataTask.resume()
    } catch {
      completion(.failure(.encodingError))
    }
  }
  
  private func genericGetRequest<RequestDataType>(
    _ path: String,
    completion: @escaping (Result<RequestDataType, ResourceRequestError>) -> Void
  ) where RequestDataType: Decodable {
    let url = resource.appendingPathComponent(path)
    let dataTask = URLSession.shared
      .dataTask(with: url) { data, _, _ in
        guard let json = data else {
          completion(.failure(.noData))
          return
        }
        do {
          let result = try JSONDecoder().decode(RequestDataType.self, from: json)
          completion(.success(result))
        } catch {
          completion(.failure(.decodingError))
        }
      }
    dataTask.resume()
  }
  
  struct Paths {
    static let acronyms = "acronyms"
    static let categories = "categories"
    static let user = "user"
  }
}
