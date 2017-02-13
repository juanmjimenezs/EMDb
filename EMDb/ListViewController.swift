//
//  ListViewController.swift
//  EMDb
//
//  Created by Juan Manuel Jimenez Sanchez on 12/02/17.
//  Copyright © 2017 Juan Manuel Jimenez Sanchez. All rights reserved.
//

import UIKit
import Kingfisher

class ListViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var movies: [Movie] = [Movie]()
    var collectionViewPadding: CGFloat = 0
    let refresh = UIRefreshControl()
    let dataProvider = LocalCoreDataService()
    
    var tapGesture: UITapGestureRecognizer! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        self.searchBar.delegate = self
        
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        
        self.loadData()
        
        self.refresh.addTarget(self, action: #selector(loadData), for: UIControlEvents.valueChanged)
        self.collectionView.refreshControl?.tintColor = UIColor.white
        self.collectionView.refreshControl = refresh
        
        self.setCollectionViewPadding()
    }

    func setCollectionViewPadding() {
        let screenWidth = self.view.frame.width
        self.collectionViewPadding = (screenWidth - (3 * 113)) / 4
    }
    
    func loadData() {
        self.dataProvider.getTopMovies(localHandler: { (movies) in
            if let movies = movies {
                self.movies = movies
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            } else {
                print("No hay registros en Core Data")
            }
        }, remoteHandler: { (movies) in
            if let movies = movies {
                self.movies = movies
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.refresh.endRefreshing()
                }
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailSegue" {
            if let indexPathSelected = self.collectionView.indexPathsForSelectedItems?.last {
                let selectedMovie = movies[indexPathSelected.row]
                let detailVC = segue.destination as! MovieViewController
                detailVC.movie = selectedMovie
            }
            self.hideKeyboard()
        }
    }
}

extension ListViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    //Aquí definimos el ancho de los bordes de cada celda
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: self.collectionViewPadding, left: self.collectionViewPadding, bottom: self.collectionViewPadding, right: self.collectionViewPadding)
    }
    
    //Aquí definimos el espacio entre lineas
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.collectionViewPadding
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 113, height: 170)
    }
}

extension ListViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.view.addGestureRecognizer(self.tapGesture)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            self.loadData()
        }
    }
    
    func hideKeyboard() {
        self.searchBar.resignFirstResponder()
        self.view.removeGestureRecognizer(self.tapGesture)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let term = searchBar.text {
            self.dataProvider.searchMovies(byTerm: term, remoteHandler: { (movies) in
                if let movies = movies {
                    self.movies = movies
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        searchBar.resignFirstResponder()
                    }
                }
            })
        }
    }
}
