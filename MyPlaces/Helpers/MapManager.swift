//
//  MapManager.swift
//  MyPlaces
//
//  Created by Pavel Ryabov on 23.01.2021.
//

import MapKit
import UIKit

class MapManager {
    let locationManager1 = CLLocationManager()
    
    private var placeCoordinate: CLLocationCoordinate2D?
    private let regionInMeteres = 1000.00
    private var directionsArray: [MKDirections] = []
    
    func setupPlacemark (place: Place, mapView: MKMapView) {
        guard let location = place.location else { return }
        let geocoder = CLGeocoder ()
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            if let error = error {
                print(error)
                return
            }
            guard let placemarks = placemarks else {return}
            
            let placemark = placemarks.first
            
            let annotation = MKPointAnnotation ()
            annotation.title = place.name
            annotation.subtitle = place.type
            
            guard let placeMarkLocation = placemark?.location else {return}
            annotation.coordinate = placeMarkLocation.coordinate
            self.placeCoordinate = placeMarkLocation.coordinate
            
            mapView.showAnnotations([annotation], animated: true)
            mapView.selectAnnotation(annotation, animated: true)
        }
    }
    func checkLocationServices(mapView: MKMapView, segueIdentifier: String, closure: () -> ()) {
        if CLLocationManager.locationServicesEnabled() {
            locationManager1.desiredAccuracy = kCLLocationAccuracyBest
            checkLocationAuthorization(mapView: mapView, segueIdentfier: segueIdentifier)
            closure()
            
        } else {
            
        }
    }
    
    func checkLocationAuthorization (mapView: MKMapView, segueIdentfier: String) {
        switch CLLocationManager.authorizationStatus() {
        
        case .notDetermined:
            locationManager1.requestWhenInUseAuthorization()
        case .restricted:
            break
        case .denied:
            
            break
        case .authorizedAlways:
            break
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if segueIdentfier == "getAddress" { showUserLocation(mapView: mapView)}
        @unknown default:
            break
        }
    }
    func showUserLocation (mapView: MKMapView) {
        if let location = locationManager1.location?.coordinate {
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMeteres,
                                            longitudinalMeters: regionInMeteres)
            mapView.setRegion(region, animated: true)
        }
        
    }
    func getDirections (for mapView: MKMapView, previousLocation: (CLLocation) -> ()) {
        
        guard let location = locationManager1.location?.coordinate else {return}
        
        locationManager1.startUpdatingLocation()
        
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
        
        guard let request = createDirectionsRequest(from: location) else {return}
        
        
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions, mapView: mapView)
        
        directions.calculate { (response, error) in
            if let error = error {
                print(error)
                return
            }
            guard let response = response else {return}
            for route in response.routes {
                mapView.addOverlay(route.polyline)
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                let distance = String (format: "%.1f", route.distance / 1000)
                let timeInterval = route.expectedTravelTime / 60
                print ("Расстояние до места \(distance) км.")
                print("Ехать до места \(timeInterval) минут")
            }
        }
    }
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        guard let destinationCoordinate = placeCoordinate else {return nil}
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        return request
        
    }
    
    func startTrackingUserLocation(for mapView: MKMapView, and location: CLLocation?, closure: (_ currentLocation: CLLocation) -> ()) {
        guard let location = location else {return}
        let center = getCenterLocation(for: mapView)
        guard center.distance(from: location) > 50 else {return}
        closure (center)
        
    }
    func resetMapView (withNew directions: MKDirections, mapView: MKMapView) {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map {$0.cancel()}
        directionsArray.removeAll()
    }
    func getCenterLocation (for mapView: MKMapView) -> CLLocation{
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        return CLLocation (latitude: latitude, longitude: longitude)
    }
    
}


