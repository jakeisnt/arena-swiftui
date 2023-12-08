//
//  ChannelView.swift
//  Arena
//
//  Created by Yihui Hu on 14/10/23.
//

import SwiftUI
import WrappingHStack
import Defaults

enum SortOption: String, CaseIterable {
    case position = "Position"
    case newest = "Newest First"
    case oldest = "Oldest First"
}

enum DisplayOption: String, CaseIterable {
    case grid = "Grid"
    case largeGrid = "Large Grid"
    case feed = "Feed"
    case table = "Table"
}

enum ContentOption: String, CaseIterable {
    case all = "All"
    case blocks = "Blocks"
    case channels = "Channels"
    case connections = "Connections"
}

struct ChannelView: View {
    @StateObject private var channelData: ChannelData
    let channelSlug: String
    
    @State private var selection = SortOption.position
    @State private var display = DisplayOption.grid
    @State private var content = ContentOption.all
    let sortOptions = SortOption.allCases
    let displayOptions = DisplayOption.allCases
    let contentOptions = ContentOption.allCases
    
    @State private var presentingConnectSheet: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    init(channelSlug: String) {
        self.channelSlug = channelSlug
        self._channelData = StateObject(wrappedValue: ChannelData(channelSlug: channelSlug, selection: SortOption.position))
    }
    
    var displayLabel: some View {
        switch display {
        case .grid:
            return Image(systemName: "square.grid.2x2")
                .resizable()
                .scaledToFit()
                .fontWeight(.semibold)
                .frame(width: 18, height: 18)
        case .largeGrid:
            return Image(systemName: "square.grid.3x3")
                .resizable()
                .scaledToFit()
                .fontWeight(.semibold)
                .frame(width: 18, height: 18)
        case .table:
            return Image(systemName: "rectangle.grid.1x2")
                .resizable()
                .scaledToFit()
                .fontWeight(.semibold)
                .frame(width: 18, height: 18)
        case .feed:
            return Image(systemName: "square")
                .resizable()
                .scaledToFit()
                .fontWeight(.semibold)
                .frame(width: 18, height: 18)
        }
    }
    
    @ViewBuilder
    private func destinationView(for block: Block, channelData: ChannelData, channelSlug: String) -> some View {
        if block.baseClass == "Block" {
            BlockView(blockData: block, channelData: channelData, channelSlug: channelSlug)
        } else {
            ChannelView(channelSlug: block.slug ?? "")
        }
    }
    
    @ViewBuilder
    private func ChannelViewContents(gridItemSize: CGFloat) -> some View {
        ForEach(channelData.contents ?? [], id: \.self.id) { block in
            NavigationLink(destination: destinationView(for: block, channelData: channelData, channelSlug: channelSlug)) {
                ChannelContentPreview(block: block, channelData: channelData, channelSlug: channelSlug, gridItemSize: gridItemSize, display: display.rawValue, presentingConnectSheet: $presentingConnectSheet)
            }
            .onAppear {
                loadMoreChannelData(channelData: channelData, channelSlug: self.channelSlug, block: block)
            }
        }
    }
    
    var body: some View {
        // Setting up grid
        let gridGap: CGFloat = 8
        let gridSpacing = display.rawValue != "Large Grid" ? gridGap + 8 : gridGap
        let gridColumns: [GridItem] =
        Array(repeating:
                .init(.flexible(), spacing: gridGap),
              count:
                display.rawValue == "Grid" ? 2 :
                display.rawValue == "Large Grid" ? 3 :
                1)
        let displayWidth = UIScreen.main.bounds.width
        let gridItemSize =
        display.rawValue == "Grid" ? (displayWidth - (gridGap * 3)) / 2 :
        display.rawValue == "Large Grid" ? (displayWidth - (gridGap * 4)) / 3 :
        (displayWidth - (gridGap * 2))
        
        ScrollViewReader { proxy in
            ScrollView {
                ZStack {}.id(0) // Hacky implementation of scroll to top when switching sorting option
                
                ChannelViewHeader(channelData: channelData, content: $content, contentOptions: contentOptions)
                
                if display.rawValue == "Table" {
                    LazyVStack(spacing: 8) {
                        ChannelViewContents(gridItemSize: gridItemSize)
                    }
                } else {
                    LazyVGrid(columns: gridColumns, spacing: gridSpacing) {
                        ChannelViewContents(gridItemSize: gridItemSize)
                    }
                }
                
                if (channelData.isLoading || channelData.isContentsLoading) {
                    CircleLoadingSpinner()
                        .padding(.vertical, 12)
                }
                
                if let channelContents = channelData.contents, channelContents.isEmpty {
                    EmptyChannel()
                } else if channelData.currentPage > channelData.totalPages {
                    EndOfChannel()
                }
            }
            .sheet(isPresented: $presentingConnectSheet) {
                ConnectExistingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .presentationDetents([.fraction(0.64), .large])
                    .presentationContentInteraction(.scrolls)
                    .presentationCornerRadius(32)
                    .contentMargins(16)
            }
            .padding(.bottom, 4)
            .background(Color("background"))
            .contentMargins(gridGap)
            .contentMargins(.leading, 0, for: .scrollIndicators)
            .refreshable {
                do { try await Task.sleep(nanoseconds: 500_000_000) } catch {}
                channelData.refresh(channelSlug: self.channelSlug, selection: selection)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        BackButton()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        Button(action: {
                            togglePin(channelData.channel?.id ?? 0)
                        }) {
                            Image(systemName: Defaults[.pinnedChannels].contains(channelData.channel?.id ?? 0) ? "pin.slash.fill" : "pin.fill")
                                .resizable()
                                .scaledToFit()
                                .fontWeight(.semibold)
                                .frame(width: 20, height: 20)
                        }
                        
                        Menu {
                            Picker("Select a display mode", selection: $display) {
                                ForEach(displayOptions, id: \.self) {
                                    Text($0.rawValue)
                                }
                            }
                        } label: {
                            displayLabel
                        }
                        
                        Menu {
                            Picker("Select a sort order", selection: $selection) {
                                ForEach(sortOptions, id: \.self) {
                                    Text($0.rawValue)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .resizable()
                                .scaledToFit()
                                .fontWeight(.semibold)
                                .frame(width: 20, height: 20)
                        }
                    }
                    .foregroundStyle(Color("surface-text-secondary"))
                }
            }
            .toolbarBackground(Color("background"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onChange(of: selection, initial: true) { oldSelection, newSelection in
                if oldSelection != newSelection {
                    proxy.scrollTo(0) // TODO: Decide if want withAnimation { proxy.scrollTo(0) }
                    channelData.selection = newSelection
                    channelData.refresh(channelSlug: self.channelSlug, selection: newSelection)
                }
            }
            .onChange(of: display, initial: true) { oldDisplay, newDisplay in
                if oldDisplay != newDisplay {
                    proxy.scrollTo(0)
                }
            }
        }
    }
    
    private func loadMoreChannelData(channelData: ChannelData, channelSlug: String, block: Block) {
        if let contents = channelData.contents,
           contents.count >= 8,
           contents[contents.count - 8].id == block.id,
           !channelData.isContentsLoading {
            channelData.loadMore(channelSlug: channelSlug)
        }
    }
    
    private func togglePin(_ channelId: Int) {
        if Defaults[.pinnedChannels].contains(channelId) {
            Defaults[.pinnedChannels].removeAll { $0 == channelId }
        } else {
            Defaults[.pinnedChannels].append(channelId)
        }
        Defaults[.pinnedChannelsChanged] = true
    }
}

struct ChannelViewHeader: View {
    @StateObject var channelData: ChannelData
    @Binding var content: ContentOption
    @State var descriptionExpanded = false
    var contentOptions: [ContentOption]
    
    var body: some View {
        let channelTitle = channelData.channel?.title ?? ""
        let channelCreatedAt = channelData.channel?.createdAt ?? ""
        let channelCreated = dateFromString(string: channelCreatedAt)
        let channelUpdatedAt = channelData.channel?.updatedAt ?? ""
        let channelUpdated = relativeTime(channelUpdatedAt)
        let channelStatus = channelData.channel?.status ?? ""
        let channelDescription = channelData.channel?.metadata?.description ?? ""
        let channelOwner = channelData.channel?.user.fullName ?? ""
        let channelOwnerId = channelData.channel?.user.id ?? 0
        let channelCollaborators = channelData.channel?.collaborators ?? []
        
        VStack(spacing: 16) {
            // MARK: Channel Title / Dates
            HStack {
                if !channelTitle.isEmpty {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            if channelStatus != "closed" {
                                Image(systemName: "circle.fill")
                                    .scaleEffect(0.5)
                                    .foregroundColor(channelStatus == "public" ? Color.green : Color.red)
                            }
                            Text("\(channelTitle)")
                                .foregroundColor(Color("text-primary"))
                                .font(.system(size: 18))
                                .fontWeight(.semibold)
                        }
                        
                        Text("started ")
                            .foregroundColor(Color("text-secondary"))
                            .font(.system(size: 14)) +
                        Text(channelCreated, style: .date)
                            .foregroundStyle(Color("text-secondary"))
                            .font(.system(size: 14)) +
                        Text(" • updated \(channelUpdated)")
                            .foregroundColor(Color("text-secondary"))
                            .font(.system(size: 14))
                    }
                } else {
                    Text("loading...")
                        .font(.system(size: 18))
                        .fontWeight(.semibold)
                }
            }
            .fontDesign(.rounded)
            .foregroundColor(Color("text-primary"))
            .lineLimit(2)
            .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                // MARK: Channel Description
                if !channelDescription.isEmpty {
                    Text(.init(channelDescription))
                        .tint(Color.primary)
                        .font(.system(size: 15))
                        .fontWeight(.regular)
                        .fontDesign(.default)
                        .foregroundColor(Color("text-secondary"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(descriptionExpanded ? nil : 2)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                descriptionExpanded.toggle()
                            }
                        }
                        .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.4), trigger: descriptionExpanded)
                }
                
                // MARK: Channel Attribution
                if !channelOwner.isEmpty {
                    let ownerLink = NavigationLink(destination: UserView(userId: channelOwnerId)) {
                        Text("\(channelOwner)")
                            .foregroundColor(Color("text-primary"))
                    }
                    
                    let collaboratorLinks = channelCollaborators.map { collaborator in
                        NavigationLink(destination: UserView(userId: collaborator.id)) {
                            Text("\(collaborator.fullName)")
                                .fontDesign(.rounded)
                                .fontWeight(.medium)
                                .foregroundColor(Color("text-primary"))
                        }
                    }
        
                    WrappingHStack(alignment: .leading, horizontalSpacing: 4) {
                        Text("by")
                            .foregroundColor(Color("text-secondary"))
                        
                        ownerLink
                        
                        if !collaboratorLinks.isEmpty {
                            Text("with")
                                .foregroundColor(Color("text-secondary"))
                            ForEach(collaboratorLinks.indices, id: \.self) { index in
                                if index > 0 {
                                    Text("&")
                                        .foregroundColor(Color("text-secondary"))
                                }
                                collaboratorLinks[index]
                            }
                        }
                    }
                    .font(.system(size: 15))
                    .fontDesign(.rounded)
                    .fontWeight(.medium)
                } else {
                    Text("by ...")
                        .font(.system(size: 15))
                        .fontDesign(.default)
                        .fontWeight(.regular)
                        .foregroundColor(Color("text-secondary"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
        }
        .padding(12)
        
        // MARK: Channel Content Options
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(contentOptions, id: \.self) { option in
                    Button(action: {
                        content = option
                    }) {
                        HStack(spacing: 8) {
                            Text("\(option.rawValue)")
                                .foregroundStyle(Color(content == option ? "background" : "surface-text-secondary"))

                            if option.rawValue == "All", let channelLength = channelData.channel?.length {
                                Text("\(channelLength)")
                                    .foregroundStyle(Color(content == option ? "surface-text-secondary" : "surface-tertiary"))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(content == option ? "text-primary" : "surface"))
                    .cornerRadius(16)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fontDesign(.rounded)
            .fontWeight(.semibold)
            .font(.system(size: 15))
        }
        .scrollIndicators(.hidden)
        .padding(.bottom, 4)
    }
}

#Preview {
    NavigationView {
        // ChannelView(channelSlug: "hi-christina-will-you-go-out-with-me")
        ChannelView(channelSlug: "posterikas")
        // ChannelView(channelSlug: "competitive-design-website-repo")
        // ChannelView(channelSlug: "christina-bgfz4hkltss")
        // ChannelView(channelSlug: "arena-swift-models-test")
    }
}

