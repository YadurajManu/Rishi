import SwiftUI

struct NewsFeedView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @StateObject private var viewModel: NewsViewModel
    @State private var searchText = ""
    @State private var showCountrySelector = false
    
    init() {
        // Will be updated in onAppear with userSettings
        _viewModel = StateObject(wrappedValue: NewsViewModel())
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search news", text: $searchText)
                        .onSubmit {
                            viewModel.searchNews(query: searchText)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            viewModel.fetchTopHeadlines()
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
                .padding(.top, 10)
                
                // Location selector button
                Button(action: {
                    showCountrySelector = true
                }) {
                    HStack {
                        Text(userSettings.selectedCountry.flag)
                            .font(.title3)
                        
                        Text("News for \(userSettings.selectedCountry.name)")
                            .font(.caption)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                Divider()
                    .padding(.bottom, 5)
                
                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text("Error loading news")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            if searchText.isEmpty {
                                viewModel.fetchTopHeadlines()
                            } else {
                                viewModel.searchNews(query: searchText)
                            }
                        }) {
                            Text("Try Again")
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.top)
                    }
                    Spacer()
                } else if viewModel.articles.isEmpty {
                    Spacer()
                    VStack {
                        Image(systemName: "newspaper")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("No news found")
                            .font(.headline)
                        
                        if !searchText.isEmpty {
                            Text("Try another search term or region")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        } else {
                            Text("Try selecting a different region")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        
                        Button(action: {
                            showCountrySelector = true
                        }) {
                            Text("Select Region")
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.top, 16)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.articles) { article in
                            NavigationLink {
                                ArticleDetailView(article: article)
                            } label: {
                                ArticleCard(article: article)
                                    .listRowInsets(EdgeInsets())
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        if searchText.isEmpty {
                            viewModel.fetchTopHeadlines()
                        } else {
                            viewModel.searchNews(query: searchText)
                        }
                    }
                }
            }
            .navigationTitle("Rishi News")
            .sheet(isPresented: $showCountrySelector) {
                CountrySelector(isPresented: $showCountrySelector)
                    .environmentObject(userSettings)
            }
            .onAppear {
                // Create new viewModel with correct settings when the view appears
                let newViewModel = NewsViewModel(userSettings: userSettings)
                
                // Use reflection to set the StateObject - hacky but works
                if let mirror = Mirror(reflecting: _viewModel).children.first,
                   let binding = mirror.value as? ReferenceWritableKeyPath<NewsFeedView, NewsViewModel> {
                    self[keyPath: binding] = newViewModel
                }
            }
        }
    }
}
