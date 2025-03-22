import SwiftUI

struct InterestSelectorView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @Binding var isPresented: Bool
    @State private var selectedCategory: String? = nil
    @State private var searchText = ""
    @State private var animateChanges = false
    @State private var showConfetti = false
    
    private var filteredInterests: [String] {
        var interests: [String]
        
        if selectedCategory == nil {
            interests = userSettings.getSuggestedInterests()
        } else {
            interests = userSettings.getSuggestedInterests(forCategory: selectedCategory!)
        }
        
        if !searchText.isEmpty {
            interests = interests.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
        
        return interests
    }
    
    private let categories = [
        "business", "technology", "health", "sports", "entertainment", "science"
    ]
    
    private let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search interests", text: $searchText)
                    
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
                .padding(.top, 10)
                
                // Category selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation {
                                selectedCategory = nil
                            }
                        }) {
                            Text("All")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCategory == nil ? Color.blue : Color(.systemGray6))
                                .foregroundColor(selectedCategory == nil ? .white : .primary)
                                .cornerRadius(8)
                        }
                        
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                withAnimation {
                                    selectedCategory = category
                                    animateChanges.toggle()
                                }
                            }) {
                                Text(category.capitalized)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.blue : Color(.systemGray6))
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                
                // Selected interests
                if !userSettings.interests.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Your Interests")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    userSettings.clearAllInterests()
                                }
                            }) {
                                Text("Clear All")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(userSettings.interests, id: \.self) { interest in
                                    Button(action: {
                                        withAnimation {
                                            userSettings.toggleInterest(interest)
                                        }
                                    }) {
                                        HStack {
                                            Text(interest)
                                            Image(systemName: "xmark")
                                                .font(.caption)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                    }
                    .padding(.top, 8)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Interest suggestions
                if filteredInterests.isEmpty {
                    Spacer()
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("No interests found")
                            .font(.headline)
                        
                        Text("Try a different search term or category")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredInterests, id: \.self) { interest in
                                let isSelected = userSettings.isInterestSelected(interest)
                                
                                Button(action: {
                                    withAnimation(.spring()) {
                                        userSettings.toggleInterest(interest)
                                        if !isSelected {
                                            showConfetti = true
                                            // Reset confetti after delay
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                showConfetti = false
                                            }
                                        }
                                    }
                                }) {
                                    Text(interest)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(isSelected ? Color.blue : Color(.systemGray6))
                                        .foregroundColor(isSelected ? .white : .primary)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .scaleEffect(isSelected ? 1.05 : 1.0)
                                .id("\(interest)-\(animateChanges)")
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding()
                        .animation(.spring(), value: filteredInterests)
                    }
                }
            }
            .navigationTitle("Your Interests")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .overlay(
                ZStack {
                    if showConfetti {
                        ConfettiView()
                            .allowsHitTesting(false)
                    }
                }
            )
        }
    }
}

struct ConfettiView: View {
    @State private var animate = false
    
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    
    var body: some View {
        ZStack {
            ForEach(0..<60) { i in
                Circle()
                    .fill(colors.randomElement()!)
                    .frame(width: CGFloat.random(in: 5...8), height: CGFloat.random(in: 5...8))
                    .position(
                        x: animate ? CGFloat.random(in: -100...500) : CGFloat.random(in: 100...300),
                        y: animate ? CGFloat.random(in: 800...1000) : CGFloat.random(in: -100...100)
                    )
                    .opacity(animate ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animate = true
            }
        }
    }
} 