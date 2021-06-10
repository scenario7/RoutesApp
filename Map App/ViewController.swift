//
//  ViewController.swift
//  Map App
//
//  Created by Kevin Thomas on 09/06/21.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var mapview: MKMapView!
    @IBOutlet weak var locateButton: UIButton!
    @IBOutlet weak var addressView: UIView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var addressButton: UIButton!
    @IBOutlet weak var mapPin: UIImageView!
    @IBOutlet weak var getDirectionsButton: UIButton!
    
    let locationManager = CLLocationManager()
    var previousLocation : CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapview.delegate = self
        checkLocationServices()
        mapview.layer.cornerRadius = 20
        locateButton.layer.cornerRadius = 20
        addressView.layer.cornerRadius = 20
        addressButton.layer.cornerRadius = 20
        mapPin.isHidden = true
        addressView.isHidden = true
        getDirectionsButton.layer.cornerRadius = 20
        
    }
    
    func setupLocationManager(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func checkLocationServices(){
        if CLLocationManager.locationServicesEnabled(){
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            
        }

        }
    func centerViewUserLocation(){
        if let location = locationManager.location?.coordinate{
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: 10000, longitudinalMeters: 10000)
            mapview.setRegion(region, animated: true)
        }
    }
    
    func checkLocationAuthorization(){
        switch CLLocationManager().authorizationStatus{
        case .authorizedWhenInUse:
            startTrackingUserLocation()
            break
        case .denied:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            break
        case .authorizedAlways:
            break
        }
    }
    
    func getDirections(){
        guard let location = locationManager.location?.coordinate else {
            return
        }
        let request = createDirectionsRequest(from: location)
        let directions = MKDirections(request: request)
        
        directions.calculate {[unowned self] response, error in
            guard let response = response else {return}
            
            for route in response.routes{
                self.mapview.addOverlay(route.polyline)
                self.mapview.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func createDirectionsRequest(from coordinate:CLLocationCoordinate2D) -> MKDirections.Request{
        let destinationCoordinate = getCenterLocation(for: mapview).coordinate
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        
        return request
    }
    
    func startTrackingUserLocation(){
        mapview.showsUserLocation = true
        centerViewUserLocation()
        previousLocation = getCenterLocation(for: mapview)
    }

    @IBAction func locateButtonTapped(_ sender: Any) {
        centerViewUserLocation()
    }
    
    @IBAction func addressButtonTapped(_ sender: Any) {
        mapPin.isHidden.toggle()
        addressView.isHidden.toggle()
    }
    func getCenterLocation(for mapView:MKMapView) -> CLLocation {
        let latitude = mapview.centerCoordinate.latitude
        let longitude = mapview.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }

    @IBAction func getDirectionsTapped(_ sender: Any) {
        getDirections()
        mapPin.isHidden = true
        addressView.isHidden = true
        
    }
}

extension ViewController : CLLocationManagerDelegate{
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}

extension ViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterLocation(for: mapview)
        let geoCoder = CLGeocoder()
        guard let previousLocation2 = self.previousLocation else {return}
        guard center.distance(from: previousLocation2) > 50 else {return}
        previousLocation = center
        
        geoCoder.reverseGeocodeLocation(center) { [weak self]placemarks, error in
            guard let self = self else {return}
            if let _ = error {
                return
            }
            guard let placemark = placemarks?.first else {
                return
            }
            let area = placemark.subLocality ?? ""
            let city = placemark.locality ?? ""
            
            DispatchQueue.main.async {
                self.addressLabel.text = "\(area),\(city)"
            }
        }
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.lineWidth = 2
        renderer.strokeColor = .green
        
        return renderer
    }
}
