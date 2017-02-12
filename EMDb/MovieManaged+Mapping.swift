//
//  MovieManaged+Mapping.swift
//  EMDb
//  
//  Esta es una extensión del modelo que se generó automaticamente para Movie de Core Data
//
//  Created by Juan Manuel Jimenez Sanchez on 11/02/17.
//  Copyright © 2017 Juan Manuel Jimenez Sanchez. All rights reserved.
//

import Foundation

extension MovieManaged {
    func mappedObject() -> Movie {
        return Movie(id: self.id, title: self.title, order: Int(self.order), summary: self.summary, image: self.image, category: self.category, director: self.director)
    }
}
