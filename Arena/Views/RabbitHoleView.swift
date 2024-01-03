//
//  RabbitHoleView.swift
//  Arena
//
//  Created by Yihui Hu on 20/12/23.
//

import SwiftUI
import Defaults

struct RabbitHoleView: View {
    @Default(.rabbitHole) var rabbitHole
    @Default(.pinnedChannels) var pinnedChannels
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(rabbitHole, id: \.self.id) { rabbitHoleItem in
                        if rabbitHoleItem.type == "channel" {
                            NavigationLink(destination: ChannelView(channelSlug: rabbitHoleItem.itemId)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 16) {
                                        HStack(alignment: .center, spacing: 4) {
                                            if rabbitHoleItem.subtype != "closed" {
                                                Image(systemName: "circle.fill")
                                                    .scaleEffect(0.5)
                                                    .foregroundColor(rabbitHoleItem.subtype == "public" ? Color.green : Color.red)
                                            }
                                            Text("\(rabbitHoleItem.mainText)")
                                                .font(.system(size: 16))
                                                .foregroundStyle(Color("text-primary"))
                                                .fontDesign(.rounded)
                                                .fontWeight(.medium)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Text("\(rabbitHoleItem.subText) items")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color("text-secondary"))
                                    }
                                    
                                    Text("\(rabbitHoleItem.timestamp)")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color("text-secondary"))
                                        .opacity(0.6)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: 88, alignment: .leading)
                            .padding(12)
                            .background(Color("surface"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .contentShape(ContentShapeKinds.contextMenuPreview, RoundedRectangle(cornerRadius: 8))
                            .contextMenu {
                                Button {
                                    Defaults[.connectSheetOpen] = true
                                    Defaults[.connectItemId] = Int(rabbitHoleItem.id) ?? 0
                                    Defaults[.connectItemType] = "Channel"
                                } label: {
                                    Label("Connect", systemImage: "arrow.right")
                                }
                                
                                Button {
                                    togglePin(Int(rabbitHoleItem.id) ?? 0)
                                } label: {
                                    Label(pinnedChannels.contains(Int(rabbitHoleItem.id) ?? 0) ? "Unpin" : "Pin", systemImage: pinnedChannels.contains(Int(rabbitHoleItem.id) ?? 0) ? "heart.fill" : "heart")
                                }
                            }
                        } else if rabbitHoleItem.type == "user" {
                            NavigationLink(destination: UserView(userId: Int(rabbitHoleItem.itemId) ?? 0)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 12) {
                                        ProfilePic(imageURL: rabbitHoleItem.imageUrl, initials: rabbitHoleItem.subText)
                                            .clipShape(Circle())
                                        
                                        VStack(alignment: .leading) {
                                            Text("\(rabbitHoleItem.mainText)")
                                                .multilineTextAlignment(.leading)
                                                .font(.system(size: 16))
                                                .foregroundStyle(Color("text-primary"))
                                                .fontDesign(.rounded)
                                                .fontWeight(.medium)
                                        }
                                    }
                                    
                                    Text("\(rabbitHoleItem.timestamp)")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color("text-secondary"))
                                        .opacity(0.6)
                                }
                                .frame(maxWidth: .infinity, maxHeight: 88, alignment: .leading)
                                .padding(12)
                                .background(Color("surface"))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        } else if rabbitHoleItem.type == "block" {
                            NavigationLink(destination: HistorySingleBlockView(blockId: Int(rabbitHoleItem.itemId) ?? 0)) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .center, spacing: 12) {
                                        if rabbitHoleItem.subtype == "attachment" || rabbitHoleItem.subtype == "text" {
                                            Text(.init(rabbitHoleItem.subText))
                                                .padding(16)
                                                .foregroundStyle(Color("text-primary"))
                                                .frame(width: 112, height: 112)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color("surface-secondary"))
                                                )
                                                .font(.system(size: 10))
                                                .tint(.primary)
                                        } else {
                                            ImagePreview(imageURL: rabbitHoleItem.imageUrl, isChannelCard: true)
                                                .frame(maxWidth: 112, maxHeight: 112)
                                                .background(Color("surface-secondary"))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        
                                        VStack {
                                            Text(.init(rabbitHoleItem.mainText))
                                                .font(.system(size: 16))
                                                .foregroundStyle(Color("text-primary"))
                                                .fontDesign(.rounded)
                                                .fontWeight(.medium)
                                                .tint(.primary)
                                        }
                                    }
                                    
                                    Text("\(rabbitHoleItem.timestamp)")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color("text-secondary"))
                                        .opacity(0.6)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: 144, alignment: .leading)
                            .padding(12)
                            .background(Color("surface"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }
            .padding(.bottom, 4)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("History")
                        .foregroundStyle(Color("text-primary"))
                        .font(.system(size: 20))
                        .fontDesign(.rounded)
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        rabbitHole = []
                    }) {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(Color("red"))
                            .font(.system(size: 14))
                            .fontWeight(.bold)
                    }
                }
            }
            .toolbarBackground(Color("background"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .background(Color("background"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color("background"))
        .contentMargins(.leading, 0, for: .scrollIndicators)
        .contentMargins(16)
    }
    
    private func togglePin(_ channelId: Int) {
        if Defaults[.pinnedChannels].contains(channelId) {
            Defaults[.pinnedChannels].removeAll { $0 == channelId }
            Defaults[.toastMessage] = "Unpinned!"
        } else {
            Defaults[.pinnedChannels].append(channelId)
            Defaults[.toastMessage] = "Pinned!"
        }
        Defaults[.showToast] = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            Defaults[.showToast] = false
        }
        Defaults[.pinnedChannelsChanged] = true
    }
}

#Preview {
    RabbitHoleView()
}
