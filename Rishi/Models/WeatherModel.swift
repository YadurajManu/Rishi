import Foundation
import Combine

struct WeatherResponse: Codable {
    let main: WeatherMain
    let weather: [WeatherInfo]
    let name: String
    let sys: WeatherSys?
    let wind: WindInfo?
}

struct WeatherMain: Codable {
    let temp: Double
    let feels_like: Double
    let temp_min: Double
    let temp_max: Double
    let humidity: Int
    let pressure: Int
}

struct WeatherInfo: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct WeatherSys: Codable {
    let country: String?
    let sunrise: Int?
    let sunset: Int?
}

struct WindInfo: Codable {
    let speed: Double
    let deg: Int
}

struct ForecastResponse: Codable {
    let list: [ForecastItem]
    let city: ForecastCity
}

struct ForecastItem: Codable, Identifiable {
    let dt: Int
    let main: WeatherMain
    let weather: [WeatherInfo]
    let wind: WindInfo
    let dt_txt: String
    
    var id: Int { dt }
    
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(dt))
    }
    
    var hour: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: date)
    }
    
    var day: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

struct ForecastCity: Codable {
    let name: String
    let country: String
}

class WeatherService {
    // Replace with your actual OpenWeatherMap API key
    private let apiKey = "7c0c5224a43461f08c7bd34ed0118e55"
    
    func fetchWeather(lat: Double, lon: Double) -> AnyPublisher<WeatherResponse, Error> {
        let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&units=metric&appid=\(apiKey)")!
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WeatherResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func fetchForecast(lat: Double, lon: Double) -> AnyPublisher<ForecastResponse, Error> {
        let url = URL(string: "https://api.openweathermap.org/data/2.5/forecast?lat=\(lat)&lon=\(lon)&units=metric&cnt=8&appid=\(apiKey)")!
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: ForecastResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func getWeatherIconURL(icon: String) -> URL {
        return URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png")!
    }
}

class WeatherViewModel: ObservableObject {
    @Published var currentWeather: WeatherResponse?
    @Published var forecast: [ForecastItem] = []
    @Published var isLoading = false
    @Published var isForecastLoading = false
    @Published var errorMessage: String?
    @Published var forecastErrorMessage: String?
    
    private let weatherService = WeatherService()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchWeather(lat: Double, lon: Double) {
        isLoading = true
        errorMessage = nil
        
        weatherService.fetchWeather(lat: lat, lon: lon)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.currentWeather = response
                
                // After successful weather fetch, get the forecast
                self?.fetchForecast(lat: lat, lon: lon)
            }
            .store(in: &cancellables)
    }
    
    func fetchForecast(lat: Double, lon: Double) {
        isForecastLoading = true
        forecastErrorMessage = nil
        
        weatherService.fetchForecast(lat: lat, lon: lon)
            .sink { [weak self] completion in
                self?.isForecastLoading = false
                if case .failure(let error) = completion {
                    self?.forecastErrorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.forecast = response.list
            }
            .store(in: &cancellables)
    }
    
    func getWeatherIconURL() -> URL? {
        guard let icon = currentWeather?.weather.first?.icon else { return nil }
        return weatherService.getWeatherIconURL(icon: icon)
    }
    
    func getIconURL(for icon: String) -> URL {
        return weatherService.getWeatherIconURL(icon: icon)
    }
    
    func getFormattedSunTime(for timestamp: Int?) -> String {
        guard let timestamp = timestamp else { return "N/A" }
        
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    func getWindDirection(degrees: Int) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((Double(degrees) + 22.5) / 45.0) % 8
        return directions[index]
    }
} 