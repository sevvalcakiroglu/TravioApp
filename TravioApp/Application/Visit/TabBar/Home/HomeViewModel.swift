//
//  HomeViewModel.swift
//  TravioApp
//
//  Created by Şevval Çakıroğlu on 30.08.2023.
//

import Foundation
import Alamofire

class HomeViewModel {
    
// TODO: --ViewModel-Controller yenilenecek.
//    var popularPlacesArray: [HomePlace] = []
//    var popularPlaces: HomeResponse? {
//        didSet {
//            guard let popularPlaces = popularPlaces else { return }
//            popularPlacesArray = popularPlaces.data.places
//        }
//    }
//
    var lastPlaces: HomeResponse?
    var popularPlaces: HomeResponse?
    
    func getPopulerPlaces(limit: Int, callback: @escaping (HomeResponse?,Error?) -> Void) {
        
        let params = ["limit":limit]
        
        NetworkingHelper.shared.objectRequestRouter(request: MyAPIRouter.getPopularPlaces(parameters: params), callback: { (result: Result<HomeResponse, Error>) in
            switch result {
            case .success(let popularPlaces):
                self.popularPlaces = popularPlaces
                callback(popularPlaces,nil)
            case .failure(let error):
                callback(nil,error)
            }
        })

    }
    
    func getLastPlaces(limit: Int, callback: @escaping (HomeResponse?,Error?) -> Void) {
        
        let params = ["limit":limit]
        
        NetworkingHelper.shared.objectRequestRouter(request: MyAPIRouter.getLastPlaces(parameters: params), callback: { (result: Result<HomeResponse, Error>) in
            switch result {
            case .success(let lastPlaces):
                self.lastPlaces = lastPlaces
                callback(lastPlaces,nil)
            case .failure(let error):
                callback(nil,error)
            }
        })
        
    }
    
}

