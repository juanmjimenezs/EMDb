//
//  FavoritesViewController.swift
//  EMDb
//
//  Created by Juan Manuel Jimenez Sanchez on 12/02/17.
//  Copyright © 2017 Juan Manuel Jimenez Sanchez. All rights reserved.
//

import UIKit
import Kingfisher

class FavoritesViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var collectionViewPadding: CGFloat = 0
    var dataProvider = LocalCoreDataService()
    var movies: [Movie] = [Movie]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        //Esto ya lo organicé por el storyboard pero es porque me estaba dejando un espacio arriba del collection
        //self.automaticallyAdjustsScrollViewInsets = false
        
        self.setCollectionViewPadding()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadData()
    }

    func setCollectionViewPadding() {
        let screenWidth = self.view.frame.width
        self.collectionViewPadding = (screenWidth - (3 * 113)) / 4
    }
    
    func loadData() {
        if let movies = dataProvider.getFavoriteMovies() {
            self.movies = movies
            self.collectionView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailSegue" {
            if let indexPathSelected = self.collectionView.indexPathsForSelectedItems?.last {
                let selectedMovie = movies[indexPathSelected.row]
                let detailVC = segue.destination as! MovieViewController
                detailVC.movie = selectedMovie
            }
        }
    }
}

extension FavoritesViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.movies.count > 0 {
            self.collectionView.backgroundView = nil
        } else {
            let imageView = UIImageView(image: UIImage(named: "sin-favoritas"))
            imageView.contentMode = .center
            self.collectionView.backgroundView = imageView
        }
        
        return movies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath) as! MovieCell
        
        let movie = self.movies[indexPath.row]
        
        self.configureCell(cell, withMovie: movie)
        
        return cell
    }
    
    ///Le asignamos a la celda los valores que tengamos para ella
    func configureCell(_ cell: MovieCell, withMovie movie: Movie) {
        if let imageData = movie.image {
            //A través de Kingfisher le asignamos la imagen al imageView pero manejando caché
            cell.movieImage.kf.setImage(with: ImageResource(downloadURL: URL(string: imageData)!), placeholder: #imageLiteral(resourceName: "img-loading"), options: nil, progressBlock: nil, completionHandler: nil)
        }
    }
    
    //Aquí definimos el ancho de los bordes de cada celda
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: self.collectionViewPadding, left: self.collectionViewPadding, bottom: self.collectionViewPadding, right: self.collectionViewPadding)
    }
    
    //Aquí definimos el espacio entre lineas
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.collectionViewPadding
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 113, height: 170)
    }
}
