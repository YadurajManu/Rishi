import SwiftUI

struct CountrySelector: View {
    @EnvironmentObject private var userSettings: UserSettings
    @Binding var isPresented: Bool
    @State private var searchText = ""
    
    private var filteredCountries: [Country] {
        if searchText.isEmpty {
            return CountryList.countries
        } else {
            return CountryList.countries.filter { 
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.id.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search countries", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Country list
                List {
                    ForEach(filteredCountries) { country in
                        Button(action: {
                            userSettings.selectedCountry = country
                            isPresented = false
                        }) {
                            HStack(spacing: 16) {
                                Text(country.flag)
                                    .font(.title)
                                
                                Text(country.name)
                                    .font(.body)
                                
                                Spacer()
                                
                                if userSettings.selectedCountry.id == country.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Select Region")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
} 