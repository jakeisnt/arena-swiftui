//
//  SearchChannels.swift
//  Arena
//
//  Created by Yihui Hu on 19/10/23.
//

import SwiftUI
import DebouncedOnChange
import Kingfisher
import SmoothGradient

struct SearchView: View {
    @State private var searchTerm: String = ""
    @State private var selection: String = "Channels"
    @State private var changedSelection: Bool = false
    @State private var isButtonFaded = false
    @StateObject private var searchData: SearchData
    @State private var scrollOffset: CGFloat = 0
    @State private var showGradient = false
    
    init() {
        self._searchData = StateObject(wrappedValue: SearchData())
    }
    
    let options = ["Channels", "Blocks", "Users"]
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 16) {
                    TextField("Search...", text: $searchTerm)
                        .onChange(of: searchTerm, debounceTime: .seconds(0.5)) { newValue in
                            searchData.searchTerm = newValue
                            searchData.refresh()
                        }
                        .textFieldStyle(SearchBarStyle())
                        .autocorrectionDisabled()
                        .onAppear {
                            UITextField.appearance().clearButtonMode = .always
                        }
                    
                    if searchTerm != "" {
                        HStack(spacing: 8) {
                            ForEach(options, id: \.self) { option in
                                Button(action: {
                                    selection = option
                                }) {
                                    Text("\(option)")
                                        .foregroundStyle(selection == option ? Color("text-primary") : Color("surface-text-secondary"))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(selection == option ? "surface-tertiary" : "surface"))
                                .cornerRadius(16)
                            }
                            .opacity(isButtonFaded ? 1 : 0)
                            .onAppear {
                                withAnimation(.easeIn(duration: 0.1)) {
                                    isButtonFaded = true
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fontDesign(.rounded)
                        .fontWeight(.semibold)
                        .font(.system(size: 15))
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                
                ZStack {
                    GeometryReader { geometry in
                        LinearGradient(
                            gradient: .smooth(from: Color("background"), to: Color("modal").opacity(0), curve: .easeInOut),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 88)
                        .position(x: geometry.size.width / 2, y: 44)
                        .opacity(showGradient ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3))
                    }
                    .zIndex(2)
                    
                    ScrollView {
                        ScrollViewReader { proxy in
                            LazyVStack(alignment: .leading, spacing: 8) {
                                if let searchResults = searchData.searchResults, searchTerm != "" {
                                    if selection == "Channels" {
                                        ForEach(searchResults.channels, id: \.id) { channel in
                                            NavigationLink(destination: ChannelView(channelSlug: channel.slug)) {
                                                SearchChannelPreview(channel: channel)
                                            }
                                            .onAppear {
                                                if searchResults.channels.last?.id ?? -1 == channel.id {
                                                    if !searchData.isLoading {
                                                        searchData.loadMore()
                                                    }
                                                }
                                            }
                                        }
                                    } else if selection == "Blocks" {
                                        ForEach(searchResults.blocks, id: \.id) { block in
                                            NavigationLink(destination: SingleBlockView(blockId: block.id)) {
                                                SearchBlockPreview(searchBlock: block)
                                            }
                                            .onAppear {
                                                if searchResults.blocks.last?.id ?? -1 == block.id {
                                                    if !searchData.isLoading {
                                                        searchData.loadMore()
                                                    }
                                                }
                                            }
                                        }
                                    } else if selection == "Users" {
                                        ForEach(searchResults.users, id: \.id) { user in
                                            NavigationLink(destination: UserView(userId: user.id)) {
                                                SearchUserPreview(searchUser: user)
                                            }
                                            .onAppear {
                                                if searchResults.users.last?.id ?? -1 == user.id {
                                                    if !searchData.isLoading {
                                                        searchData.loadMore()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .onChange(of: scrollOffset) { offset in
                                withAnimation {
                                    showGradient = offset > -8
                                }
                            }
                            .background(GeometryReader { proxy -> Color in
                                DispatchQueue.main.async {
                                    scrollOffset = -proxy.frame(in: .named("scroll")).origin.y
                                }
                                return Color.clear
                            })
                        }
                        
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .coordinateSpace(name: "scroll")
                }
            }
            .padding(.bottom, 8)
            .onChange(of: selection, initial: true) { oldSelection, newSelection in
                if oldSelection != newSelection {
                    searchData.selection = newSelection
                    searchData.refresh()
                }
            }
        }
        .contentMargins(.leading, 0, for: .scrollIndicators)
        .contentMargins(16)
    }
}
struct SearchChannelPreview: View {
    let channel: ArenaSearchedChannel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                if channel.status != "closed" {
                    Image(systemName: "circle.fill")
                        .scaleEffect(0.5)
                        .foregroundColor(channel.status == "public" ? Color.green : Color.red)
                }
                
                Text("\(channel.title)")
                    .font(.system(size: 16))
                    .lineLimit(1)
                    .fontDesign(.rounded)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Text("\(channel.user.username) • \(channel.length) items")
                .font(.system(size: 14))
                .lineLimit(1)
                .foregroundStyle(Color("surface-text-secondary"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color("surface"))
        .cornerRadius(16)
    }
}

struct SearchUserPreview: View {
    let searchUser: ArenaSearchedUser
    
    var body: some View {
        HStack(spacing: 12) {
            ProfilePic(imageURL: searchUser.avatarImage.thumb, initials: searchUser.initials)
            
            Text("\(searchUser.username)")
                .lineLimit(1)
                .fontWeight(.medium)
                .fontDesign(.rounded)
        }
    }
}

struct SearchBlockPreview: View {
    let searchBlock: ArenaSearchedBlock
    
    var body: some View {
        HStack(spacing: 12) {
            KFImage(URL(string: searchBlock.image?.thumb.url ?? ""))
                .placeholder {
                    Image(systemName: "photo")
                        .foregroundColor(Color("surface-text-secondary"))
                        .frame(width: 40, height: 40)
                        .background(Color("surface"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .retry(maxCount: 3, interval: .seconds(5))
                .resizable()
                .animation(nil) // TODO: Fix unpredictable KFImage animation
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text("\(searchBlock.title)")
                .lineLimit(1)
                .fontWeight(.medium)
                .fontDesign(.rounded)
        }
    }
}

struct SearchBarStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.leading, 20)
            .padding(.trailing, 12)
            .padding(.vertical, 12)
            .foregroundColor(Color("text-primary"))
            .background(Color("surface"))
            .cornerRadius(50)
            .fontDesign(.rounded)
            .fontWeight(.medium)
    }
}

#Preview {
    SearchView()
}