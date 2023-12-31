//
//  MapVC.swift
//  TravioApp
//
//  Created by Şevval Çakıroğlu on 29.08.2023.
//


import UIKit
import MapKit
import SnapKit
import CoreLocation

class MapVC: UIViewController {
    
    var viewModel = MapViewModel()
    var address:String?
    
    private lazy var mapView: MKMapView = {
        let map = MKMapView(frame: self.view.frame)
        self.view.addSubview(map)

        let rotation = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(getLocationLongPress))
        map.addGestureRecognizer(longPressGesture)
        
        let region = MKCoordinateRegion(center: rotation, latitudinalMeters: 100000, longitudinalMeters: 100000)
        map.setRegion(region, animated: true)
        map.delegate = self
        
        return map
        
    }()
    
    private lazy var collectionView:UICollectionView = {
        
        //MARK: -- CollectionView arayüzü için sağlanan layout protocolü.
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 18
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .clear
        cv.contentInsetAdjustmentBehavior = .never
        cv.showsHorizontalScrollIndicator = false
        cv.register(MapCollectionViewCell.self, forCellWithReuseIdentifier: "CustomCell")
        
        return cv
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let ac = UIActivityIndicatorView()
        ac.style = .large
        ac.color = .gray
        ac.translatesAutoresizingMaskIntoConstraints = false
        return ac
    }()

    override func viewWillAppear(_ animated: Bool) {

        getAllPlace()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
    
        setupView()
        
        getAllPlace()
        
    }
    
    func getAllPlace() {
        
        viewModel.updateLoadingStatus = { [weak self] () in
            DispatchQueue.main.async {
                let isLoading = self?.viewModel.isLoading ?? false
                if isLoading {
                    self?.activityIndicator.startAnimating()
                    UIView.animate(withDuration: 0.2, animations: {
                        self?.mapView.alpha = 0.0
                    })
                }else {
                    self?.activityIndicator.stopAnimating()
                    UIView.animate(withDuration: 0.2, animations: {
                        self?.mapView.alpha = 1.0
                    })
                }
            }
        }
        
        viewModel.getAllPlace { error in
            if let error = error {
                CustomAlert.showAlert(
                    in: self,
                    title: "Error!",
                    message: error.localizedDescription,
                    okActionTitle: "Ok"
                )
            }else{
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                self.addPinsToMap()
            }

        }
    }
    
    func addPinsToMap() {
        
        guard let allPlaces = viewModel.placeArr else { return }
        
        for place in allPlaces {
            guard let latitude = place.latitude, let longitude = place.longitude else { return }
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            annotation.title = place.title
            annotation.subtitle = place.description
            mapView.addAnnotation(annotation)
        }
        
    }

    
    @objc func getLocationLongPress(sender: UILongPressGestureRecognizer) /*-> CLLocationCoordinate2D*/{

        if sender.state == .began {
            let touchPoint = sender.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            // Create a map annotation
            let annotation = MKPointAnnotation()
            
            annotation.coordinate = coordinate
            annotation.title = "New Place"
            annotation.subtitle = "Description"
            
            // Add the annotation to the map view
            //mapView.addAnnotation(annotation)
            
            let location = CLLocation(latitude:coordinate.latitude, longitude: coordinate.longitude)
            let geocoder = CLGeocoder()
            
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                if let error = error {
                    CustomAlert.showAlert(in: self, title: "Hata!", message: error.localizedDescription, okActionTitle: "Ok")
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    CustomAlert.showAlert(in: self, title: "Hata!", message: "Yer bulunamadı.", okActionTitle: "Ok")
                    return
                }
                
                if let name = placemark.name,
                   let locality = placemark.locality ,
                   let city = placemark.administrativeArea,
                   let country = placemark.country {
                    self.address = "\(city),\(country)"
                } else {
                    CustomAlert.showAlert(in: self, title: "Hata!", message: "Yer bilgileri alınamadı.", okActionTitle: "Ok")
                }
                
                let vc = AddNewPlaceVC()
                vc.preferredContentSize = CGSize(width: 390, height: 790)
                vc.placeCoordinate = self.address
                vc.longitude = coordinate.longitude
                vc.latitude = coordinate.latitude
                vc.delegate = self
//                vc.completionHandler = {
//                    self.mapView.addAnnotation(annotation) // Pin ekleme
////                    DispatchQueue.main.async {
////                        self.collectionView.reloadData()
////                    }
//                    //self.collectionView.reloadData()
//                    self.getAllPlace()
//                }
                
                self.present(vc, animated: true, completion: nil)
   
            }

        }

    }
    
    func setupView(){
        
        navigationController?.isNavigationBarHidden = true
        
        view.addSubviews(mapView,activityIndicator)
        
        mapView.addSubview(collectionView)
        
        setupLayout()
    }
    
    
    func setupLayout(){
        
        mapView.snp.makeConstraints({make in
            make.edges.equalToSuperview()
        })
        
        collectionView.snp.makeConstraints({make in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(-16)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(178)
            
        })
        
        activityIndicator.snp.makeConstraints({make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        })
        
    }
}


extension MapVC: UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let size = CGSize(width: collectionView.frame.width * 0.79 , height: collectionView.frame.height )
        return size
    }
    
}

extension MapVC: UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let allPlaces = viewModel.placeArr else {return 0}
        return allPlaces.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomCell", for: indexPath) as? MapCollectionViewCell else { return UICollectionViewCell() }
        
        guard let allPlaces = viewModel.placeArr else {return  UICollectionViewCell() }

        let places = allPlaces[indexPath.item]
        
        cell.configure(with: places)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let data = viewModel.placeArr else { return }
        let visitData = data[indexPath.row]
        let placeId = visitData.id
        
        let vc = VisitsDetailVC()
        guard let placeId = placeId else { return }
        vc.placeId = placeId
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
}

extension MapVC: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let identifier = "locationMarker"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? CustomMapPinView
        
        if annotationView == nil {
            annotationView = CustomMapPinView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        if let pinImage = UIImage(named: "annotation") {
            let size = CGSize(width: 32, height: 42)
            
            UIGraphicsBeginImageContext(size)
            pinImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            annotationView?.image = resizedImage
        }
        return annotationView
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // Pin tıklandığında yapılacak işlemleri burada gerçekleştirin.
        if let annotation = view.annotation as? MKPointAnnotation {
            let coordinate = annotation.coordinate
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            
            let region = MKCoordinateRegion(center: coordinate, span: span)
            mapView.setRegion(region, animated: true)
            
            guard let allPlaces = viewModel.placeArr else { return }
            if let index = allPlaces.firstIndex(where: {$0.latitude == annotation.coordinate.latitude && $0.longitude == annotation.coordinate.longitude}) {
                let indexPath = IndexPath(item: index, section: 0)
                collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
        }
    }
}

extension MapVC: AddNewPlaceDelegate {
    func didAddNewPlace() {
        self.getAllPlace()
    }
}


