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

struct ResourceRequest<ResourceType> where ResourceType: Codable {
  private let resourceURL: URL
  
  init(resourcePath: String) {
    guard let baseURL = URL(string: ResourcePaths.base) else {
      fatalError("Could not convert baseURLString to baseURL")
    }
    self.resourceURL = baseURL.appendingPathComponent(resourcePath)
  }
  
  func getAll(completion: @escaping (Result<[ResourceType], ResourceRequestError>) -> Void) {
    let dataTask = URLSession.shared
      .dataTask(with: resourceURL) { data, _, _ in
        guard let jsonData = data else {
          completion(.failure(.noData))
          return
        }
        do {
          let resources = try JSONDecoder().decode([ResourceType].self, from: jsonData)
          completion(.success(resources))
        } catch {
          completion(.failure(.decodingError))
        }
      }
    dataTask.resume()
  }
  
  func getWithID(
    _ id: String,
    completion: @escaping (Result<ResourceType, ResourceRequestError>) -> Void
  ) {
    let url = resourceURL.appendingPathComponent(id)
    let dataTask = URLSession.shared
      .dataTask(with: url) { data, _, _ in
        guard let jsonData = data else {
          completion(.failure(.noData))
          return
        }
        do {
          let resources = try JSONDecoder().decode(ResourceType.self, from: jsonData)
          completion(.success(resources))
        } catch {
          completion(.failure(.decodingError))
        }
        
      }
    dataTask.resume()
  }
  
  func getFirst(completion: @escaping (Result<ResourceType, ResourceRequestError>) -> Void) {
    let url = resourceURL.appendingPathComponent("first")
    let dataTask = URLSession.shared
      .dataTask(with: url) { data, _, _ in
        guard let jsonData = data else {
          completion(.failure(.noData))
          return
        }
        do {
          let resources = try JSONDecoder().decode(ResourceType.self, from: jsonData)
          completion(.success(resources))
        } catch {
          completion(.failure(.decodingError))
        }
        
      }
    dataTask.resume()
  }
  
  func saveData<CreateType>(
    _ saveData: CreateType,
    completion: @escaping (Result<ResourceType, ResourceRequestError>) -> Void
  ) where CreateType: Codable {
    do {
      var urlRequest = URLRequest(url: resourceURL)
      urlRequest.httpMethod = "POST"
      urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
      urlRequest.httpBody = try JSONEncoder().encode(saveData)
      
      let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, _ in
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let jsonData = data
        else {
          completion(.failure(.noData))
          return
        }
        
        do {
          let resource = try JSONDecoder().decode(ResourceType.self, from: jsonData)
          completion(.success(resource))
        } catch {
          completion(.failure(.decodingError))
        }
      }
      dataTask.resume()
    } catch {
      completion(.failure(.encodingError))
    }
  }
}
