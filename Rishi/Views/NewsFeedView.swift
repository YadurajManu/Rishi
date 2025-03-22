import SwiftUI

struct NewsFeedView: View {
    @StateObject private var viewModel = NewsViewModel()
    @State private var searchText = ""
    
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
                .padding(.top)
                
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
        }
    }
} 