//
//  VisitsDetailVC.swift
//  TravioApp
//
//  Created by Şevval Çakıroğlu on 29.08.2023.
//


import UIKit
import MapKit
import SnapKit



class VisitsDetailVC: UIViewController {
    
    var viewModel = VisitsViewModel()
    var placeId = ""
    var visitImages : [Image]?
    var detailVisit: Visit?
    var visits: [Visit]?
    
    private lazy var gradient:UIImageView = {
        let img = UIImageView()
        img.image = UIImage(named: "Rectangle")
        return img
    }()

    private lazy var collectionView:UICollectionView = {
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 10
        layout.scrollDirection = .horizontal
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = Color.darkGray.color
        cv.contentInsetAdjustmentBehavior = .never
        cv.showsHorizontalScrollIndicator = false
        cv.isPagingEnabled = true
        cv.register(VisitsDetailCell.self, forCellWithReuseIdentifier: "CustomCell")
      
        return cv
    }()
    
    private lazy var pageControl:UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPage = 0
        pageControl.backgroundColor = Color.lightGray.color
        pageControl.allowsContinuousInteraction = false
        pageControl.layer.cornerRadius = 12
        pageControl.pageIndicatorTintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        pageControl.currentPageIndicatorTintColor = .black
        pageControl.addTarget(self, action: #selector(pageControlValueChanged), for: .valueChanged)
        return pageControl
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = Color.lightGray.color
        scrollView.isScrollEnabled = true
        return scrollView
    }()
    
    private lazy var scrollContentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.darkGray.color
        label.font = Font.semiBold(size: 30).font
        return label
    }()
    
    private lazy var dateLabel:UILabel = {
        let label = UILabel()
        label.text = detailVisit?.created_at
        label.textColor = Color.darkGray.color
        label.font = Font.regular(size: 14).font
        return label
    }()
    
    private lazy var labelAddedBy: UILabel = {
        let label = UILabel()
        label.font = Font.regular(size: 10).font
        label.textColor = .systemGray
        return label
    }()
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        mapView.delegate = self
        return mapView
        
    }()
    
    private lazy var descriptionLbl: UILabel = {
        let label = UILabel()
        label.textColor = Color.darkGray.color
        label.font = Font.regular(size: 12).font
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var buttonBack: UIButton = {
        let  button = UIButton()
        button.setImage(UIImage(named: "backButton"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(buttonBackTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var addVisit: UIButton = {
        let  button = UIButton()
        button.setImage(UIImage(named: "addVisit"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(addVisits), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private lazy var deleteVisit: UIButton = {
        let  button = UIButton()
        button.setImage(UIImage(named: "deleteVisit"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(deleteVisits), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let ac = UIActivityIndicatorView()
        ac.style = .large
        ac.color = .gray
        ac.translatesAutoresizingMaskIntoConstraints = false
        return ac
    }()
    
    @objc func buttonBackTapped() {
        navigationController?.popViewController(animated: true)
    }
    

    @objc func pageControlValueChanged(){
        let currentPage = pageControl.currentPage
        let indexPath = IndexPath(item: currentPage, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: scrollContentView.frame.height)
    }
    
    override func viewDidLayoutSubviews() {
        mapView.roundCorners(corners: [.bottomLeft,.topLeft,.topRight], radius: 16)
        addVisit.roundCorners(corners: [.bottomLeft,.topLeft,.topRight], radius: 16)
        deleteVisit.roundCorners(corners: [.bottomLeft,.topLeft,.topRight], radius: 16)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        setupView()
        
        darkMode()
        
        getDetailPageInf()
      
    }
    
    func getDetailPageInf(){
        
        viewModel.updateLoadingStatus = { [weak self] () in
            DispatchQueue.main.async {
                let isLoading = self?.viewModel.isLoading ?? false
                if isLoading {
                    self?.activityIndicator.startAnimating()
                    UIView.animate(withDuration: 0.2, animations: {
                        self?.view.alpha = 0.0
                    })
                }else {
                    self?.activityIndicator.stopAnimating()
                    UIView.animate(withDuration: 0.2, animations: {
                        self?.view.alpha = 1.0
                    })
                }
            }
        }
        
        getTravelDetail()
        
        getDetail()
    }
    
    func setupView() {
 
        self.view.backgroundColor = Color.lightGray.color
        
        self.navigationController?.navigationBar.isHidden = true
        
        self.view.addSubviews(collectionView,
                              gradient,
                              buttonBack,
                              pageControl,
                              scrollView,
                              addVisit,
                              deleteVisit,
                              activityIndicator)
        
        scrollView.addSubview(scrollContentView)
        
        scrollContentView.addSubviews(titleLabel,
                                      dateLabel,
                                      labelAddedBy,
                                      mapView,
                                      descriptionLbl)
        
        setupLayout()
    }
    
    func setupLayout(){
        
        gradient.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().offset(0)
            make.bottom.equalTo(collectionView.snp.bottom)
            make.height.equalTo(110)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(250)
        }
        

        addVisit.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(50)
            make.width.equalTo(50)
        }
        
        deleteVisit.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(50)
            make.width.equalTo(50)
        }

        
        buttonBack.snp.makeConstraints { make in
            make.top.equalTo(addVisit.snp.top)
            make.leading.equalToSuperview().offset(24)
        }
        
        pageControl.snp.makeConstraints { make in
            make.bottom.equalTo(collectionView.snp.bottom).offset(-10)
            make.centerX.equalToSuperview()
            make.width.equalTo(74)
            make.height.equalTo(24)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        scrollContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(self.view)
            // FIXME: --kontrol edilecek
            make.bottom.equalTo(descriptionLbl.snp.bottom).offset(15)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.equalToSuperview().offset(24)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.leading.equalToSuperview().offset(26)
        }
        
        labelAddedBy.snp.makeConstraints { label in
            label.top.equalTo(dateLabel.snp.bottom)
            label.leading.equalTo(dateLabel.snp.leading)
        }
        
        mapView.snp.makeConstraints { make in
            make.top.equalTo(labelAddedBy.snp.bottom).offset(9)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(227)
        }
        
        descriptionLbl.snp.makeConstraints { make in
            make.top.equalTo(mapView.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        activityIndicator.snp.makeConstraints{make in
            make.centerX.centerY.equalToSuperview()
        }

    }
 
    /// Description
    /// - Parameters:
    ///   - visitDate: visitDate description
    ///   - label: label description
    ///
    func dateFormatter(visitDate: String, label: UILabel) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        if let date = dateFormatter.date(from: visitDate) {
            dateFormatter.dateFormat = "dd MMMM yyyy"
            label.text = dateFormatter.string(from: date)
        }
    }
    
    func setMapView(latitude:Double, longitude:Double, title: String) {
        let locationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = locationCoordinate
        annotation.title = title
        mapView.addAnnotation(annotation)
        let region = MKCoordinateRegion(center: locationCoordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        mapView.setRegion(region, animated: true)
    }

    func getTravelDetail() {
        viewModel.getVisitImage(placeId: placeId) { result, error in
            if let error = error {
                CustomAlert.showAlert(
                    in: self,
                    title: "Error!",
                    message: error.localizedDescription,
                    okActionTitle: "Ok"
                )
                
            }
            if let result = result{
                guard let images = self.viewModel.images else { return }
                self.visitImages = images.data.images
                self.collectionView.reloadData()
            }


        }
    }
    
    func getDetail(){
        
        viewModel.checkVisitByID(placeId: placeId) { response, error in
            if let response = response{
                if response.status == "success"{
                    self.deleteVisit.isHidden = false
                } else if response.status == "error"{
                    self.addVisit.isHidden = false
                }
            }
            if let error = error {
                CustomAlert.showAlert(
                    in: self,
                    title: "Error!",
                    message: error.localizedDescription,
                    okActionTitle: "Ok"
                )
                
            }
        }
        
        viewModel.getPlaceById(placeId: placeId) { result, error in
            if let result = result{
                let result = result.data.place
                
                self.titleLabel.text = result.title
                self.dateFormatter(visitDate: result.created_at, label: self.dateLabel)
                self.descriptionLbl.text = result.description
                self.labelAddedBy.text = "Added by \(result.creator)"
                self.setMapView(latitude: result.latitude, longitude: result.longitude, title: result.title)
            }
            
            if let error = error {
                CustomAlert.showAlert(
                    in: self,
                    title: "Error!",
                    message: error.localizedDescription,
                    okActionTitle: "Ok"
                )
                
            }
        }
    }
    
    @objc func deleteVisits(){
        
        CustomAlert.showAlert(
            in: self,
            title: "Alert",
            message: "Delete Visit?",
            okActionTitle: "Ok",
            cancelActionTitle: "Cancel",
            okCompletion: {
                self.viewModel.deleteVisit(placeId: self.placeId) { result, error in
                    if let result = result{
                        self.addVisit.isHidden = false
                        self.deleteVisit.isHidden = true
                    }
                    if let error = error {
                        CustomAlert.showAlert(
                            in: self,
                            title: "Error!",
                            message: error.localizedDescription,
                            okActionTitle: "Ok"
                        )
                        
                    }

                }
            }
        )
        
    }
    
    @objc func addVisits(){
        
        CustomAlert.showAlert(
            in: self,
            title: "Alert",
            message: "Add Visit",
            okActionTitle: "Ok",
            cancelActionTitle: "Cancel",
            okCompletion: {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                let today = Date()
                let formattedDate = dateFormatter.string(from: today)

                let param: [String : Any] = ["place_id":self.placeId, "visited_at": formattedDate ]
                
                self.viewModel.postVisit(parameters: param) { result, error in
                    if let result = result{
                        self.addVisit.isHidden = true
                        self.deleteVisit.isHidden = false
                    }
                   
                    if let error = error {
                        CustomAlert.showAlert(
                            in: self,
                            title: "Error!",
                            message: error.localizedDescription,
                            okActionTitle: "Ok"
                        )
                        
                    }
                }
            }
        )
        
    }
    
    func darkMode() {
        if traitCollection.userInterfaceStyle == .dark {
            // Dark mode ise
            gradient.image = UIImage(named: "gradient")
        } else {
            // Light mode ise
            gradient.image = UIImage(named: "Rectangle")
        }
    }

}
 
extension VisitsDetailVC:UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = CGSize(width: view.frame.width, height: collectionView.frame.height)
        return size
    }
}

extension VisitsDetailVC:UICollectionViewDataSource{
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let visitImages = visitImages else {return 0}
        
        return visitImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomCell", for: indexPath) as? VisitsDetailCell else { return UICollectionViewCell() }

        if let visitImages {
            
            cell.configure(with: (visitImages[indexPath.row]))
            
            pageControl.numberOfPages = visitImages.count
        }

        return cell
    }
}

extension VisitsDetailVC: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let identifier = "locationMarker"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? CustomMapPinView
        
        if annotationView == nil {
            annotationView = CustomMapPinView(annotation: annotation, reuseIdentifier: identifier) // Özel pin oluşturma
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

    
}
