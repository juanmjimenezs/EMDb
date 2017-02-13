//
//  LocalCoreDataService.swift
//  EMDb
//
//  Aquí lo que hacemos es convertir los diccionarios entregados por RemoteiTunesMovieService en arreglos de objetos que pueda entender nuestra app
//
//  Created by Juan Manuel Jimenez Sanchez on 11/02/17.
//  Copyright © 2017 Juan Manuel Jimenez Sanchez. All rights reserved.
//

import Foundation
import CoreData

class LocalCoreDataService {
    let remoteMovieService = RemoteiTunesMovieService()
    let stack = CoreDataStack.sharedInstance
    
    ///Obtenemos desde el WS las peliculas que coincidan con el termino pasado por parametro
    func searchMovies(byTerm: String, remoteHandler: @escaping ([Movie]?) -> Void) {
        self.remoteMovieService.searchMovies(byTerm: byTerm) { (movies) in
            if let movies = movies {
                var modelMovies = [Movie]()
                for movie in movies {
                    let modelMovie = Movie(id: movie["id"], title: movie["title"], order: nil, summary: movie["summary"], image: movie["image"], category: movie["category"], director: movie["director"])
                    modelMovies.append(modelMovie)
                }
                remoteHandler(modelMovies)
            } else {
                print("Error mientras consultamos los servicios REST")
                remoteHandler(nil)
            }
        }
    }

    ///Consultamos primero el top peliculas desde Core Data y luego desde el WS para actualizar las que tenemos en Core Data
    func getTopMovies(localHandler: @escaping ([Movie]?) -> Void, remoteHandler: @escaping ([Movie]?) -> Void) {
        
        //Obtenemos las peliculas desde Core Data
        localHandler(self.queryTopMovies())
        
        //Obtenemos las peliculas desde el WS (array de diccionarios)
        self.remoteMovieService.getTopMovies { (movies) in
            if let movies = movies {
                //Marcamos todas las peliculas no favoritas en Core Data como: no sincronizadas
                self.markAllMoviesAsUnsync()
                
                var order = 1
                //Recorremos el arreglo de diccionarios (cada pelicula quedará marcada como sincronizada)...
                for movieDictionary in movies {
                    //Si la pelicula ya existía en Core Data entonces la actualizamos ya que el ranking puedo haber cambiado...
                    if let movie = self.getMovieById(id: movieDictionary["id"]!, favorite: false) {
                        self.updateMovie(movieDictionary: movieDictionary, movie: movie, order: order)
                    } else {//De lo contrario la creamos...
                        self.insertMovie(movieDictionary: movieDictionary, order: order)
                    }
                    
                    order += 1
                }
                //Ahora borramos las peliculas no sincronizadas que no son favoritas (estas son las peliculas que pudieron haber salido del top 99)
                self.removeOldNotFavoritedMovies()
                //Como ya actualizamos Core Data entonces devolvemos los datos de allí
                remoteHandler(self.queryTopMovies())
            } else {
                remoteHandler(nil)
            }
        }
    }
    
    ///Consultamos a Core Data por las peliculas favoritas
    func getFavoriteMovies() -> [Movie]? {
        let context = stack.persistentContainer.viewContext
        let request: NSFetchRequest<MovieManaged> = MovieManaged.fetchRequest()
        
        let predicate = NSPredicate(format: "favorite = \(true)")
        request.predicate = predicate
        
        do {
            let fechedMovies = try context.fetch(request)
            
            var movies: [Movie] = [Movie]()
            for managedMovie in fechedMovies {
                movies.append(managedMovie.mappedObject())
            }
            
            return movies
        } catch {
            print("Error obteniendo las peliculas favoritas")
            return nil
        }
    }
    
    ///Obtenemos las peliculas desde Core Data
    func queryTopMovies() -> [Movie]? {
        let context = stack.persistentContainer.viewContext
        let request: NSFetchRequest<MovieManaged> = MovieManaged.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        let predicate = NSPredicate(format: "favorite = \(false)")
        request.predicate = predicate
        
        do {
            let fetchedMovies = try context.fetch(request)
            
            var movies = [Movie]()
            for managedMovie in fetchedMovies {
                movies.append(managedMovie.mappedObject())
            }
            return movies
        } catch {
            print("Error obteniendo las peliculas de Core Data")
            return nil
        }
    }
    
    ///Marcamos todas las peliculas no favoritas en Core Data como: no sincronizadas
    func markAllMoviesAsUnsync() {
        let context = stack.persistentContainer.viewContext
        let request: NSFetchRequest<MovieManaged> = MovieManaged.fetchRequest()
        
        let predicate = NSPredicate(format: "favorite = \(false)")
        request.predicate = predicate
        
        do {
            let fetchedMovies = try context.fetch(request)

            for managedMovie in fetchedMovies {
                managedMovie.sync = false
            }
            
            try context.save()
        } catch {
            print("Error actualizando las peliculas de Core Data")
        }
    }
    
    ///Consultamos la pelicula en Core Data
    func getMovieById(id: String, favorite: Bool) -> MovieManaged? {
        let context = stack.persistentContainer.viewContext
        let request: NSFetchRequest<MovieManaged> = MovieManaged.fetchRequest()

        let predicate = NSPredicate(format: "id = \(id) AND favorite = \(favorite)")
        request.predicate = predicate
        
        do {
            let fetchedMovies = try context.fetch(request)
            if fetchedMovies.count > 0 {
                return fetchedMovies.last
            } else {
                return nil
            }
        } catch {
            print("Error obteniendo la pelicula desde Core Data")
            return nil
        }
    }
    
    ///Insertamos la nueva pelicula en Core Data
    func insertMovie(movieDictionary: [String:String], order: Int) {
        let context = stack.persistentContainer.viewContext
        let movie = MovieManaged(context: context)
        
        movie.id = movieDictionary["id"]
        
        //Como el resto de linas son las mismas de updateMovie, entonces llamamos esta función para reutilizar código
        self.updateMovie(movieDictionary: movieDictionary, movie: movie, order: order)
    }
    
    ///Actualizamos la pelicula en Core Data
    func updateMovie(movieDictionary: [String:String], movie: MovieManaged, order: Int) {
        let context = stack.persistentContainer.viewContext
        
        movie.order = Int16(order)
        
        movie.title = movieDictionary["title"]
        movie.summary = movieDictionary["summary"]
        movie.category = movieDictionary["category"]
        movie.director = movieDictionary["director"]
        movie.image = movieDictionary["image"]
        movie.sync = true//Se marcar como sincronizada porque las que no lo estén, deben ser eliminadas
        
        do {
            try context.save()
        } catch {
            print("Error mietras actualizabamos Core Data")
        }
    }
    
    ///Eliminamos todas las peliculas que no estén sincronizadas y que no sean favoritas (esto se da porque el top de peliculas va cambiando, unas entran, otra salen)
    func removeOldNotFavoritedMovies() {
        let context = stack.persistentContainer.viewContext
        let request: NSFetchRequest<MovieManaged> = MovieManaged.fetchRequest()
        
        let predicate = NSPredicate(format: "favorite = \(false)")
        request.predicate = predicate
        
        do {
            let fetchedMovies = try context.fetch(request)
            for managedMovie in fetchedMovies {
                if !managedMovie.sync {
                    context.delete(managedMovie)
                }
            }
            
            try context.save()
        } catch {
            print("Error mientras borrabamos de Core Data")
        }
    }
    
    ///Retorna si la pelicula es o no favorita
    func isMovieFavorite(movie: Movie) -> Bool {
        if let _ = self.getMovieById(id: movie.id!, favorite: true) {
            return true
        } else {
            return false
        }
    }
    
    ///Si la pelicula está marcada como favorita entonces la elimina sino entonces la agrega a Core Data
    func markUnmarkFavorite(movie: Movie) {
        let context = stack.persistentContainer.viewContext
        
        if let exist = self.getMovieById(id: movie.id!, favorite: true) {
            context.delete(exist)
        } else {
            let favorite = MovieManaged(context: context)
            
            favorite.id = movie.id
            favorite.title = movie.title
            favorite.summary = movie.summary
            favorite.category = movie.category
            favorite.director = movie.director
            favorite.image = movie.image
            favorite.favorite = true
            
            do {
                try context.save()
            } catch {
                print("Error marcando la pelicula como favorita")
            }
        }
        
        self.updateFavoritesBadge()//Enviamos una notificación con el número de peliculas favoritas
    }
    
    ///Enviamos una notificación con el número de peliculas favoritas
    func updateFavoritesBadge() {
        if let totalFavorites = self.getFavoriteMovies()?.count {
            let notification = Notification(name: Notification.Name("updateFavoritesBadgeNotification"), object: totalFavorites, userInfo: nil)
            NotificationCenter.default.post(notification)
        }
    }
}
