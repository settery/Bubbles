//
//  Webservice.swift
//  Bubbles
//
//  Created by Петр Михеев on 10.12.2023.
//

import Foundation


class Webservice {
    
    private func getCurrentToken() -> String {
        return UserDefaults.standard.string(forKey: "accessToken") ?? ""
    }
    
    
    
    func uploadAvatar(accessToken: String, imageData: Data, completion: @escaping (Result<UploadImageResponse, AuthenticationError>) -> Void) {
        guard let url = URL(string: "http://100.77.33.118:5000/api/users/upload-image") else {
            completion(.failure(.custom(errorMessage: "URL is not correct")))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        let boundaryPrefix = "--\(boundary)\r\n"
        
        body.append(imageData)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(.failure(.NoData))
                return
            }
            
            guard let avatarResponse = try? JSONDecoder().decode(UploadImageResponse.self, from: data) else {
                completion(.failure(.invalidCredentials))
                return
            }
            
            completion(.success(avatarResponse))
            
        }.resume()
    }
    
    func login(email: String, password: String, completion: @escaping (Result<AuthResponse, AuthenticationError>) -> Void) {
        
        guard let url = URL(string: "http://100.77.33.118:5000/api/auth/login") else {
            completion(.failure(.custom(errorMessage: "URL is not correct")))
            return
        }
        
        let body = LoginRequestBody(email: email, password: password)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(.failure(.custom(errorMessage: "No data")))
                return
            }
            
            guard let authResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) else {
                completion(.failure(.invalidCredentials))
                return
            }
            
            
            completion(.success(authResponse))
            
        }.resume()
    }
    
    func register(email: String, username: String, password: String, completion: @escaping (Result<AuthResponse, RegistrationError>) -> Void) {
        guard let url = URL(string: "http://100.77.33.118:5000/api/auth/registration") else {
            completion(.failure(.custom(errorMessage: "URL is not correct")))
            return
        }
        
        let body = RegisterRequestBody(email: email, username: username, password: password)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(.failure(.custom(errorMessage: "No data")))
                return
            }
            
            guard let authResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) else {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 409 {
                    completion(.failure(.emailExists))
                } else {
                    completion(.failure(.serverError(description: "Server error")))
                }
                return
            }
            
            guard let _ = authResponse.accessToken else {
                completion(.failure(.custom(errorMessage: "No access token")))
                return
            }
            completion(.success(authResponse))
        }.resume()
    }
    
    func fetchUserInfo(accessToken: String, completion: @escaping (Result<User, AuthenticationError>) -> Void) {
        guard let url = URL(string: "http://100.77.33.118:5000/api/users/me") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard let data = data, error == nil else {
                completion(.failure(.NoData))
                return
            }
            
            guard let user = try? JSONDecoder().decode(User.self, from: data) else {
                completion(.failure(.custom(errorMessage: "Decoding error")))
                return
            }
            
            completion(.success(user))
            
            
        }.resume()
    }
    
    func searchPlace(query: String, tags: [String], accessToken: String, completion: @escaping (Result<[Place], AuthenticationError>) -> Void) {
        var urlString = "http://100.77.33.118:5000/api/place/search?"
        
        // Добавляем параметр query
        if !query.isEmpty {
            urlString += "query=\(query)&"
        }
        
        // Добавляем параметр tags
        if !tags.isEmpty {
            let tagsString = tags.joined(separator: ",")
            urlString += "tags=\(tagsString)"
        }
        
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard let data = data, error == nil else {
                completion(.failure(.NoData))
                return
            }
            
            guard let response = try? JSONDecoder().decode(SearchResult.self, from: data) else {
                completion(.failure(.custom(errorMessage: "Decoding error")))
                return
            }
            
            completion(.success(response.result))
        }.resume()
    }
    
    func getPlaces(accessToken: String, completion: @escaping (Result<[Place], AuthenticationError>) -> Void) {
        let urlString = "http://100.77.33.118:5000/api/place/all"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard let data = data, error == nil else {
                completion(.failure(.NoData))
                return
            }
            
            guard let response = try? JSONDecoder().decode(SearchResult.self, from: data) else {
                completion(.failure(.custom(errorMessage: "Decoding error")))
                return
            }
            
            completion(.success(response.result))
        }.resume()
    }
    
    func getPlace(id: String, accessToken: String, completion: @escaping (Result<Place, AuthenticationError>) -> Void) {
        var urlString = "http://100.77.33.118:5000/api/place/id/"
        
        if (!id.isEmpty) {
            urlString += id
        }
        
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard let data = data, error == nil else {
                completion(.failure(.NoData))
                return
            }
            
            guard let response = try? JSONDecoder().decode(Place.self, from: data) else {
                completion(.failure(.custom(errorMessage: "Decoding error")))
                return
            }
            
            completion(.success(response))
        }.resume()
        
    }
    
}
