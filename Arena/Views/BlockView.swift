//
//  BlockView.swift
//  Arena
//
//  Created by Yihui Hu on 14/10/23.
//

import SwiftUI
import VTabView
import Modals

struct BlockView: View {
    let blockData: Block
    let channelSlug: String
    @ObservedObject private var channelData: ChannelData
    @State private var currentIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    @State var isInfoModalPresented: Bool = false
    
    init(blockData: Block, channelData: ChannelData, channelSlug: String) {
        self.blockData = blockData
        self.channelData = channelData
        self.channelSlug = channelSlug
        _currentIndex = State(initialValue: channelData.contents?.firstIndex(where: { $0.id == blockData.id }) ?? 0)
    }
    
    var body: some View {
        ZStack {
            VTabView(selection: $currentIndex) {
                ForEach(channelData.contents ?? [], id: \.self.id) { block in
                    let screenHeight = UIScreen.main.bounds.size.height
                    let maxPreviewHeight = screenHeight * 0.6
                    
                    // Display the block content
                    HStack {
                        BlockPreview(blockData: block, fontSize: 16)
                            .frame(maxHeight: maxPreviewHeight)
                    }
                    .foregroundColor(Color("text-primary"))
                    .tag(channelData.contents?.firstIndex(of: block) ?? 0)
                    .onAppear {
                        if channelData.contents?.last?.id ?? -1 == block.id {
                            if !channelData.isContentsLoading {
                                // Load more content when the last block is reached
                                channelData.loadMore(channelSlug: self.channelSlug)
                                print(channelData.contents?.count ?? "")
                            }
                        }
                    }
                }
            }
//            .modal(isPresented: $isInfoModalPresented, size: .small, options: [.prefersDragHandle]) {
//                VStack(spacing: 4) {
//                    // TODO: Handle channels (!)
//                    let title = channelData.contents?[currentIndex].title ?? ""
//                    let description = channelData.contents?[currentIndex].description ?? ""
//                    let createdAt = channelData.contents?[currentIndex].createdAt ?? ""
//                    let connectedBy = channelData.contents?[currentIndex].connectedByUsername ?? ""
//                    
//                    Text("\(title != "" ? title : "No title")")
//                        .frame(maxWidth: .infinity, alignment: .topLeading)
//                    Text("\(description != "" ? description : "No description")")
//                        .frame(maxWidth: .infinity, alignment: .topLeading)
//                    Text("\(createdAt != "" ? createdAt : "Unknown creation date")")
//                        .frame(maxWidth: .infinity, alignment: .topLeading)
//                    Text("Connected by \(connectedBy != "" ? connectedBy : "unknown")")
//                        .frame(maxWidth: .infinity, alignment: .topLeading)
//                }
//                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
//                .padding(.horizontal, 20)
//                .padding(.top, 64)
//            }
            .modal(isPresented: $isInfoModalPresented, size: .small, options: [.prefersDragHandle, .disableContentDragging]) {
                ScrollView {
                    VStack(spacing: 20) {
                        // TODO: Handle channels (!)
                        let currentBlock = channelData.contents?[currentIndex]
                        let title = currentBlock?.title ?? ""
                        let description = currentBlock?.description ?? ""
                        let createdAt = currentBlock?.createdAt ?? ""
                        let updatedAt = currentBlock?.updatedAt ?? ""
                        let connectedBy = currentBlock?.connectedByUsername ?? ""
                        let source = currentBlock?.source?.title ?? currentBlock?.source?.url ?? ""
                        let connections = currentBlock?.connections ?? []
                        
                        VStack(spacing: 4) {
                            Text("\(title != "" ? title : "No title")")
                                .fontDesign(.rounded)
                                .fontWeight(.semibold)
                                .font(.system(size: 18))
                                .lineLimit(2) // TODO: Add ability to expand title
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                            Text("\(description != "" ? description : "No description")")
                                .font(.system(size: 16))
                                .lineLimit(3) // TODO: Add ability to expand description
                                .foregroundStyle(Color("surface-text-secondary"))
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                        
                        VStack(spacing: 4) {
                            HStack(spacing: 20) {
                                Text("Added")
                                    .fontDesign(.rounded)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(createdAt != "" ? createdAt : "unknown")")
                                    .foregroundStyle(Color("surface-text-secondary"))
                            }
                            Divider()
                            
                            HStack(spacing: 20) {
                                Text("Updated")
                                    .fontDesign(.rounded)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(updatedAt != "" ? updatedAt : "unknown")")
                                    .foregroundStyle(Color("surface-text-secondary"))
                            }
                            Divider()
                            
                            HStack(spacing: 20) {
                                Text("Connected by")
                                    .fontDesign(.rounded)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(connectedBy != "" ? connectedBy : "unknown")")
                                    .fontWeight(.medium)
                            }
                            Divider()
                            
                            HStack(spacing: 20) {
                                Text("Source")
                                    .fontDesign(.rounded)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(source != "" ? source : "unknown")")
                                    .lineLimit(1)
                                    .fontWeight(.medium)
                            }
                            Divider()
                            
                            // TODO: Handle different block types (dimensions for images, fileSize for attachments, etc.)
    //                        HStack(spacing: 20) {
    //                            Text("Dimensions")
    //                                .fontDesign(.rounded)
    //                                .fontWeight(.semibold)
    //                            Spacer()
    //                            Text("656 x 454")
    //                                .foregroundStyle(Color("surface-text-secondary"))
    //                        }
    //                        Divider()
                        }
                        .font(.system(size: 16))
                        
                        HStack {
                            Button(action: {
                                print("Connect")
                            }) {
                                Text("Connect")
                                    .fontDesign(.rounded)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("surface"))
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color("backdrop-inverse"))
                            .cornerRadius(16)
                            
                            Spacer().frame(width: 16)
                            
                            Button(action: {
                                print("Actions")
                            }) {
                                Text("Actions")
                                    .fontDesign(.rounded)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("text-primary"))
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color("backdrop-inverse"), lineWidth: 2)
                            )
                            .cornerRadius(16)
                        }
                        
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: { print("Comments") }) {
                                    Text("Connections (200)")
                                        .frame(maxWidth: .infinity)
                                }
                                Spacer()
                                Button(action: { print("Comments") }) {
                                    Text("Comments (200)")
                                        .frame(maxWidth: .infinity)
                                        .foregroundStyle(Color("surface-text-secondary"))
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .font(.system(size: 14))
                            
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color("text-primary"))
                                    .frame(maxWidth: .infinity, maxHeight: 1)
                                Rectangle()
                                    .fill(Color("surface"))
                                    .frame(maxWidth: .infinity, maxHeight: 1)
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(connections, id: \.self.id) { connection in
                                    VStack(spacing: 4) {
                                        Text("\(connection.title)")
                                            .font(.system(size: 16))
                                            .fontDesign(.rounded)
                                            .fontWeight(.medium)
                                            .frame(maxWidth: .infinity, alignment: .leading)
//                                        Text("\(connection.userId) • \(connection.length) items") // TODO: Fetch username from userId?
//                                            .font(.system(size: 14))
//                                            .foregroundStyle(Color("surface-text-secondary"))
//                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color("surface"), lineWidth: 2)
                                    )
                                }
                            }
                            .padding(.top, 12)
                        }
                        .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.horizontal, 20)
                    .padding(.top, 64)
                }
            }
            .padding(.bottom, 50)
            .background(Color("background"))
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                    }
                }
            }
            .toolbarBackground(Color("background"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .overlay(alignment: .top) {
                Color.clear
                    .background(Color("background"))
                    .ignoresSafeArea(edges: .top)
                    .frame(height: 0)
            }
            
            HStack(spacing: 8) {
                Button(action: {
                    print("Connect")
                }) {
                    Image(systemName: "arrow.right.square")
                        .frame(width: 36, height: 36)
                        .background(Color("surface"))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    isInfoModalPresented = true
                }) {
                    Image(systemName: "info.circle")
                        .frame(width: 36, height: 36)
                        .background(Color("surface"))
                        .clipShape(Circle())
                }
            }
            .frame(maxWidth: .infinity, alignment: .bottomTrailing)
            .padding(.top, UIScreen.main.bounds.size.height * 0.64)
            .padding(.bottom, 16)
            .padding(.trailing, 20)
            .foregroundStyle(Color("surface-text-secondary"))
        }
    }
}

