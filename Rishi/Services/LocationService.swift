import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var currentCountry: String = "us" // Default to US
    @Published var currentCountryName: String = "United States"
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // Don't need high precision for country
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        isLoading = true
        error = nil
        locationManager.startUpdatingLocation()
    }
    
    private func fetchCountryFromLocation(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error
                    return
                }
                
                guard let placemark = placemarks?.first,
                      let countryCode = placemark.isoCountryCode?.lowercased(),
                      let country = placemark.country else {
                    return
                }
                
                self?.currentCountry = countryCode
                self?.currentCountryName = country
                print("Location detected: Country code: \(countryCode), Country: \(country)")
            }
        }
    }
    
    func useDefaultCountry() {
        // Use default if user denies location permission
        currentCountry = "us"
        currentCountryName = "United States"
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        locationManager.stopUpdatingLocation() // Only need one update
        fetchCountryFromLocation(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.error = error
            self.useDefaultCountry()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startLocationUpdates()
            case .denied, .restricted:
                self.useDefaultCountry()
            default:
                break
            }
        }
    }
} 