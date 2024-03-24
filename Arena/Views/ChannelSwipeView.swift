//
//  ContentView.swift
//  TinderCardsDemo
//
//  og source: https://gist.github.com/dmr121/b5e0311c08e1c65a99af27ae1c45878f#file-tinderswiper-swift-L214
//  Created by David Rozmajzl on 11/28/23.
//

import SwiftUI

struct ChannelSwipeView: View {
    @State private var customColors = [
        CustomColor(value: .red),
        CustomColor(value: .orange),
        CustomColor(value: .yellow),
        CustomColor(value: .green),
        CustomColor(value: .blue),
        CustomColor(value: .purple),
        CustomColor(value: .pink),
        CustomColor(value: .black)
    ]
    @State private var visibleCardCount = 4
    @State private var direction: SwipeDirection?
    @State private var isLoading: boolean
    
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                Text(direction?.rawValue ?? "")
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(direction == nil ? .clear: direction == .right ? .green: .red)
                    .clipShape(Capsule())
                    .animation(.spring, value: direction)
                    .padding(.bottom)
                
                CardStack(data: customColors, visibleCardCount: visibleCardCount, onSwipe: { direction in
                    self.direction = direction
                }) { color in
                    ZStack {
                        color.value
                        
                        Text(color.value.description)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .blendMode(.difference)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 15)
                    .transition(.slide)
                }
                .frame(width: geometry.size.width, height: 425)
                
                IntSlider(score: $visibleCardCount)
                    .padding(.top, 40)
                
                Button {
                    withAnimation {
                        customColors.append([
                            CustomColor(value: .red),
                            CustomColor(value: .orange),
                            CustomColor(value: .yellow),
                            CustomColor(value: .green),
                            CustomColor(value: .blue),
                            CustomColor(value: .purple),
                            CustomColor(value: .pink),
                            CustomColor(value: .black)
                        ].randomElement()!)
                    }
                } label: {
                    HStack {
                        Spacer()
                        
                        Text("Add")
                            .foregroundStyle(.white)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                    .frame(height: 55)
                    .background(.blue)
                    .clipShape(Capsule())
                }
                
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Fetch search results
    final func fetchSearchResults() {
        guard !isLoading else {
            return
        }
        
        self.isLoading = true
        let errorMessage = nil
        
        let option: String = "blocks"
        
        let searchTerm = "hi"
        let currentPage = 0
        
        guard let url = URL(string: "https://api.are.na/v2/search/\(option)?q=\(searchTerm)&page=\(currentPage)&per=20") else {
            self.isLoading = false
            errorMessage = "Invalid URL"
            return
        }
                
        // Create a URLRequest and set the "Authorization" header with your bearer token
        var request = URLRequest(url: url)
        request.setValue("Bearer \(Defaults[.accessToken])", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { [unowned self] (data, response, error) in
            if error != nil {
                errorMessage = "Error retrieving data."
                return
            }
            
            if let data = data {
                let decoder = JSONDecoder()
                do {
                    // Attempt to decode the data
                    let searchResults = try decoder.decode(ArenaSearchResults.self, from: data)
                    DispatchQueue.main.async {
                        if self.searchResults != nil {
                            self.searchResults?.channels.append(contentsOf: searchResults.channels)
                            self.searchResults?.blocks.append(contentsOf: searchResults.blocks)
                            self.searchResults?.users.append(contentsOf: searchResults.users)
                        } else {
                            self.searchResults = searchResults
                        }
                        self.totalPages = searchResults.totalPages
                        self.currentPage += 1
                    }
                } catch let decodingError {
                    // Print the decoding error for debugging
                    print("Decoding Error: \(decodingError)")
                    errorMessage = "Error decoding data: \(decodingError.localizedDescription)"
                    return
                }
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        task.resume()
    }
}

struct IntSlider: View {
    @Binding var score: Int
    var intProxy: Binding<Double>{
        Binding<Double>(get: {
            //returns the score as a Double
            return Double(score)
        }, set: {
            //rounds the double to an Int
            print($0.description)
            score = Int($0)
        })
    }
    var body: some View {
        VStack{
            Slider(value: intProxy , in: 0.0...10.0, step: 1.0, onEditingChanged: {_ in
                print(score.description)
            })
        }
    }
}

#Preview {
    ChannelSwipeView()
}

enum SwipeDirection: String {
    case right = "Right"
    case left = "Left"
    case up = "Up"
    case down = "Down"
}

struct CustomColor: Identifiable, Hashable {
    let id = UUID()
    let value: Color
}

struct CardStack<Content, Item: Identifiable & Hashable>: View where Content: View {
    private let data: [Item]
    private let visibleCardCount: Int
    private let onSwipe: (SwipeDirection) -> ()
    private let cardBuilder: (Item) -> Content
    
    init(
        data: [Item],
        visibleCardCount: Int = 4,
        onSwipe: @escaping (SwipeDirection) -> (),
        _ cardBuilder: @escaping (Item) -> Content
    ) {
        self.data = data
        self.visibleCardCount = max(1, visibleCardCount)
        self.onSwipe = onSwipe
        self.cardBuilder = cardBuilder
    }
    
    @State private var shownIndex = 0
    @State private var removingTopCard = false
    @State private var offset = CGSize.zero
    @State private var verticalOffset: CGFloat?
    
    var slice: [Item] {
        let sliceCount = removingTopCard ? visibleCardCount + 1: visibleCardCount
        let endIndex = min(data.count, shownIndex + sliceCount)
        return Array(data[shownIndex..<endIndex])
    }
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(slice) { item in
                Card(item, geometry, cardBuilder)
            }
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                    }
                    .onEnded {
                        onEnded($0, geometry)
                    }
            )
        }
    }
}

// MARK: Views
extension CardStack {
    @ViewBuilder
    private func Card(_ item: Item, _ geometry: GeometryProxy, _ cardBuilder: @escaping (Item) -> Content) -> some View {
        let index = slice.firstIndex(of: item)!
        let workingIndex = index - (removingTopCard ? 1: 0)
        let heightFactor = CGFloat(1.0 - (0.03 * CGFloat(workingIndex)))
        let widthFactor = CGFloat(1.0 - (0.05 * CGFloat(workingIndex)))
        let heightOffset = CGFloat(geometry.size.height * 0.02)
        
        let doMove = index == 0
        let xOffset = doMove ? offset.width: 0
        let yOffset = doMove ? offset.height: 0
        let maxAbsDegrees = xOffset < 0 ? max(-5, xOffset * 0.05): min(5, xOffset * 0.05)
        let angle = doMove ? Angle(degrees: maxAbsDegrees): Angle.zero
        
        
        cardBuilder(item)
            .scaleEffect(CGSize(width: widthFactor, height: heightFactor), anchor: .bottom)
            .offset(x: 0, y: CGFloat(workingIndex) * heightOffset)
            .zIndex(-Double(index))
            .offset(x: xOffset, y: yOffset)
            .rotationEffect(angle, anchor: .bottom)
            .opacity(doMove && removingTopCard ? 0: 1)
    }
}

// MARK: Private methods
extension CardStack {
    private func onEnded(_ gesture: _ChangedGesture<DragGesture>.Value, _ geometry: GeometryProxy) {
        if abs(gesture.predictedEndTranslation.height) > abs(geometry.size.height) {
            if gesture.predictedEndTranslation.height < 0 {
                onSwipe(.up)
            } else {
                onSwipe(.down)
            }
            
            // Remove the card
            withAnimation(.easeInOut(duration: 0.3)) {
                removingTopCard = true
                offset = CGSize(
                    width: gesture.predictedEndTranslation.width * 2.0,
                    height: gesture.predictedEndTranslation.height * 2.0
                )
            }
            
            // Get rid of top card and show new card on bottom
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                offset = .zero
                withAnimation(.easeInOut(duration: 3)) {
                    shownIndex += 1
                    removingTopCard = false
                }
            }
        }
        
        else if abs(gesture.predictedEndTranslation.width) > abs(geometry.size.width) {
            if gesture.predictedEndTranslation.width < 0 {
                onSwipe(.left)
            } else {
                onSwipe(.right)
            }
            
            // Remove the card
            withAnimation(.easeInOut(duration: 0.3)) {
                removingTopCard = true
                offset = CGSize(
                    width: gesture.predictedEndTranslation.width * 2.0,
                    height: gesture.predictedEndTranslation.height * 2.0
                )
            }
            
            // Get rid of top card and show new card on bottom
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                offset = .zero
                withAnimation(.easeInOut(duration: 3)) {
                    shownIndex += 1
                    removingTopCard = false
                }
            }
        } else {
            withAnimation(.spring) {
                offset = .zero
            }
        }
    }
}
