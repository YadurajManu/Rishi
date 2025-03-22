import SwiftUI

struct NewsFeedView: View {
    @EnvironmentObject private var locationService: LocationService
    @StateObject private var viewModel: NewsViewModel
    @State private var searchText = ""
    
    init() {
        // Initialize with nil for now, will be set in onAppear
        _viewModel = StateObject(wrappedValue: NewsViewModel())
    }
    
    var body: some View {
        NavigationView {
            VStack {
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
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Location indicator
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    Text("News for \(viewModel.userCountryName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    if locationService.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .padding(.trailing, 5)
                    }
                }
                .padding(.horizontal)
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
                    }
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
            .onAppear {
                // Create a new viewModel with the correct locationService when the view appears
                // This is necessary because we can't access @EnvironmentObject in the init
                if viewModel.userCountry == "us" && locationService.currentCountry != "us" {
                    let newViewModel = NewsViewModel(locationService: locationService)
                    // Copy over any state that needs to be preserved
                    newViewModel.isLoading = viewModel.isLoading
                    newViewModel.errorMessage = viewModel.errorMessage
                    // Use reflection to set the StateObject - hacky but works
                    if let mirror = Mirror(reflecting: _viewModel).children.first,
                       let binding = mirror.value as? ReferenceWritableKeyPath<NewsFeedView, NewsViewModel> {
                        self[keyPath: binding] = newViewModel
                    }
                }
            }
        }
    }
}
