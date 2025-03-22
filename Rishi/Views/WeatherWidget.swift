import SwiftUI

struct WeatherWidget: View {
    @ObservedObject var viewModel: WeatherViewModel
    @EnvironmentObject private var userSettings: UserSettings
    @State private var isExpanded = false
    @State private var refreshRotation = 0.0
    @State private var isForecastVisible = false
    @State private var sunAnimationScale = 1.0
    
    var body: some View {
        VStack(spacing: 8) {
            if viewModel.isLoading {
                loadingView
            } else if let weather = viewModel.currentWeather {
                VStack(spacing: 0) {
                    // Main weather card
                    mainWeatherCard(weather)
                    
                    // Forecast section
                    if isForecastVisible && !viewModel.forecast.isEmpty {
                        forecastView
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else {
                placeholderView
            }
        }
    }
    
    // MARK: - Component Views
    
    private var loadingView: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Loading weather...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 25)
            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private func mainWeatherCard(_ weather: WeatherResponse) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isExpanded.toggle()
                isForecastVisible = isExpanded
            }
            
            withAnimation(.easeInOut(duration: 0.5)) {
                sunAnimationScale = isExpanded ? 1.1 : 1.0
            }
            
            // Refresh weather data when expanding
            if isExpanded {
                refreshWeather()
            }
        }) {
            VStack(spacing: 0) {
                // Top section
                HStack(spacing: 16) {
                    // Weather icon and temperature
                    HStack(spacing: 8) {
                        if let iconURL = viewModel.getWeatherIconURL() {
                            AsyncImage(url: iconURL) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 60, height: 60)
                                        .scaleEffect(sunAnimationScale)
                                } else {
                                    Image(systemName: "sun.max.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.yellow)
                                        .scaleEffect(sunAnimationScale)
                                }
                            }
                        } else {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.yellow)
                                .scaleEffect(sunAnimationScale)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(weather.main.temp))°")
                                .font(.system(size: 36, weight: .semibold))
                            
                            Text(weather.weather.first?.main ?? "")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Location and high/low temps
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(weather.name)")
                            .font(.headline)
                        
                        Text("H: \(Int(weather.main.temp_max))° L: \(Int(weather.main.temp_min))°")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Only show feels like if expanded or different from actual temp
                        if isExpanded || abs(weather.main.temp - weather.main.feels_like) > 2.0 {
                            Text("Feels like: \(Int(weather.main.feels_like))°")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .transition(.opacity)
                        }
                    }
                    
                    // Refresh button
                    Button(action: refreshWeather) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(refreshRotation))
                    }
                    .padding(.leading, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Additional weather details when expanded
                if isExpanded {
                    Divider()
                        .padding(.horizontal)
                    
                    VStack(spacing: 10) {
                        HStack(spacing: 24) {
                            weatherDetailItem(
                                icon: "wind",
                                title: "Wind",
                                value: "\(Int(weather.wind?.speed ?? 0)) km/h \(viewModel.getWindDirection(degrees: weather.wind?.deg ?? 0))"
                            )
                            
                            weatherDetailItem(
                                icon: "humidity",
                                title: "Humidity",
                                value: "\(weather.main.humidity)%"
                            )
                            
                            weatherDetailItem(
                                icon: "gauge",
                                title: "Pressure",
                                value: "\(weather.main.pressure) hPa"
                            )
                        }
                        
                        if let sunrise = weather.sys?.sunrise, let sunset = weather.sys?.sunset {
                            HStack(spacing: 24) {
                                weatherDetailItem(
                                    icon: "sunrise.fill",
                                    title: "Sunrise",
                                    value: viewModel.getFormattedSunTime(for: sunrise)
                                )
                                
                                weatherDetailItem(
                                    icon: "sunset.fill",
                                    title: "Sunset",
                                    value: viewModel.getFormattedSunTime(for: sunset)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .transition(.opacity)
                }
                
                // Show expand indicator
                HStack {
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                        .padding(.top, isExpanded ? 0 : 4)
                    Spacer()
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var forecastView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hourly Forecast")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 12)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.forecast) { item in
                        VStack(spacing: 8) {
                            Text(item.hour)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let icon = item.weather.first?.icon {
                                AsyncImage(url: viewModel.getIconURL(for: icon)) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40, height: 40)
                                    } else {
                                        Image(systemName: "cloud")
                                            .font(.title2)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .frame(width: 40, height: 40)
                            }
                            
                            Text("\(Int(item.main.temp))°")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(item.day)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 70)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6).opacity(0.5))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.top, 8)
    }
    
    private func errorView(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Weather unavailable")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                if isExpanded {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .transition(.opacity)
                }
            }
            
            Spacer()
            
            Button(action: refreshWeather) {
                Text("Retry")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .onTapGesture {
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
        }
    }
    
    private var placeholderView: some View {
        HStack {
            Spacer()
            Text("Weather data unavailable")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private func weatherDetailItem(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Actions
    
    private func refreshWeather() {
        withAnimation(.linear(duration: 1)) {
            refreshRotation += 360
        }
        
        if let lat = userSettings.selectedCountry.id == "in" ? 28.6139 : 37.0902,
           let lon = userSettings.selectedCountry.id == "in" ? 77.2090 : -95.7129 {
            viewModel.fetchWeather(lat: lat, lon: lon)
        }
    }
} 