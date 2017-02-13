//
//  MovieViewController.swift
//  EMDb
//
//  Created by Juan Manuel Jimenez Sanchez on 12/02/17.
//  Copyright © 2017 Juan Manuel Jimenez Sanchez. All rights reserved.
//

import UIKit
import Kingfisher

class MovieViewController: UIViewController {

    @IBOutlet weak var btnFavorite: UIButton!
    @IBOutlet weak var movieImage: UIImageView!
    @IBOutlet weak var movieSummary: UITextView!
    @IBOutlet weak var movieTitle: UILabel!
    @IBOutlet weak var movieCategory: UILabel!
    @IBOutlet weak var movieDirector: UILabel!
    
    let dataProvider = LocalCoreDataService()
    var movie: Movie?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let movie = movie {
            if let image = movie.image {
                self.movieImage.kf.setImage(with: ImageResource(downloadURL: URL(string: image)!))
            }
            
            self.title = movie.title
            self.movieTitle.text = movie.title
            self.movieSummary.text = movie.summary
            self.movieCategory.text = movie.category
            self.movieDirector.text = movie.director
            
            self.configurefavoritebutton()
        }
    }

    func configurefavoritebutton() {
        if let movie = self.movie {
            if self.dataProvider.isMovieFavorite(movie: movie) {
                self.btnFavorite.setBackgroundImage(#imageLiteral(resourceName: "btn-on"), for: .normal)
                self.btnFavorite.setTitle("¡Quiero verla!", for: .normal)
            } else {
                self.btnFavorite.setBackgroundImage(#imageLiteral(resourceName: "btn-off"), for: .normal)
                self.btnFavorite.setTitle("No me interesa", for: .normal)
            }
        }
    }
    
    @IBAction func favoritePressed(_ sender: UIButton) {
        if let movie = self.movie {
            self.dataProvider.markUnmarkFavorite(movie: movie)
            self.configurefavoritebutton()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.movieSummary.scrollRangeToVisible(NSMakeRange(0,0))
    }
}
