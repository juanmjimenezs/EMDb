//
//  RemoteiTunesMovieService.swift
//  EMDb
//
//  Created by Juan Manuel Jimenez Sanchez on 11/02/17.
//  Copyright © 2017 Juan Manuel Jimenez Sanchez. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class RemoteiTunesMovieService {
    
    /**
     Nos va a traer en un array de diccionarios el top de peliculas y en el bloque
     de completación se podrán realizar las operaciones necesarias sobre el resultado.
     
     - parameters: 
        - completionHandler: array de diccionarios disponible en un bloque de completación
     */
    func getTopMovies(completionHandler: @escaping ([[String:String]]?) -> Void) {
        let url = URL(string: "https://itunes.apple.com/es/rss/topmovies/limit=99/json")!
        
        Alamofire.request(url, method: .get).validate().responseJSON() { response in
            switch response.result {
            case .success:
                if let value = response.result.value {
                    let json = JSON(value)
                    var result = [[String:String]]()
                    
                    let entries = json["feed"]["entry"].arrayValue
                    
                    for entry in entries {
                        var movie = [String:String]()
                        movie["id"] = entry["id"]["attributes"]["im:id"].stringValue
                        movie["title"] = entry["im:name"]["label"].stringValue
                        movie["summary"] = entry["summary"]["label"].stringValue
                        movie["image"] = entry["im:image"][0]["label"].stringValue.replacingOccurrences(of: "60x60", with: "500x500")
                        movie["category"] = entry["category"]["attributes"]["label"].stringValue
                        movie["director"] = entry["im:artist"]["label"].stringValue
                        
                        result.append(movie)
                    }
                    
                    completionHandler(result)
                }
            case .failure(let error):
                print(error)
                completionHandler(nil)
            }
        }
    }
    
    /**
     Nos va a traer en un array de diccionarios con las peliculas filtradas según el dato pasado por parametro
     y en el bloquede completación se podrán realizar las operaciones necesarias sobre el resultado.
     
     - parameters:
        - byTerm: el string que por el que queremos filtrar resultados
        - completionHandler: array de diccionarios disponible en un bloque de completación
     */
    func searchMovies(byTerm: String, completionHandler: @escaping ([[String:String]]?) -> Void) {
        let url = URL(string: "https://itunes.apple.com/search")!
        
        Alamofire.request(url, method: .get, parameters: ["media":"movie", "attribute":"movieTerm", "country":"es", "term":byTerm], encoding: URLEncoding.default, headers: nil).validate().responseJSON() { response in
            switch response.result {
            case .success:
                if let value = response.result.value {
                    let json = JSON(value)
                    var result = [[String:String]]()
                    
                    let entries = json["results"].arrayValue
                    
                    for entry in entries {
                        var movie = [String:String]()
                        movie["id"] = entry["trackId"].stringValue
                        movie["title"] = entry["trackName"].stringValue
                        movie["summary"] = entry["longDescription"].stringValue
                        movie["image"] = entry["artworkUrl100"].stringValue.replacingOccurrences(of: "100x100", with: "500x500")
                        movie["category"] = entry["primaryGenreName"].stringValue
                        movie["director"] = entry["artistName"].stringValue
                        
                        result.append(movie)
                    }
                    completionHandler(result)
                }
            case .failure(let error):
                print(error)
                completionHandler(nil)
            }
        }
    }
}
