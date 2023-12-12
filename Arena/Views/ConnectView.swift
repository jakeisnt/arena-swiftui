//
//  ConnectView.swift
//  Arena
//
//  Created by Yihui Hu on 6/12/23.
//

import SwiftUI
import Defaults
import RiveRuntime
import PhotosUI

struct ConnectItem: View {
    var text: String
    var icon: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color("surface-text-secondary"))
                .frame(width: 40, height: 40)
                .background(Color("surface-secondary"))
                .clipShape(Circle())
            
            Text(text)
                .foregroundStyle(Color("text-primary"))
                .fontWeight(.medium)
                .fontDesign(.rounded)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ConnectView: View {
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedPhotosData: [Data] = []
    @State private var showConnectImagesView = false
    @State private var showConnectTextView = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                ConnectFlower()
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    Button(action: {
                        
                    }) {
                        ConnectItem(text: "New channel", icon: "square.grid.2x2.fill")
                    }
                    .buttonStyle(ConnectButtonStyle())
                    
                    Button(action: {
                        showConnectTextView = true
                    }) {
                        ConnectItem(text: "New text block", icon: "text.alignleft")
                    }
                    .buttonStyle(ConnectButtonStyle())
                    
                    Button(action: {
                        
                    }) {
                        ConnectItem(text: "Add link", icon: "link")
                    }
                    .buttonStyle(ConnectButtonStyle())
                    
                    Button(action: {}) {
                        PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 10, matching: .images) {
                            ConnectItem(text: "Add images", icon: "photo.fill")
                        }
                        .onChange(of: selectedPhotos) { _, newItems in
                            selectedPhotos = []
                            selectedPhotosData = []
                            for newItem in newItems {
                                Task {
                                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                                        selectedPhotosData.append(data)
                                    }
                                }
                            }
                            showConnectImagesView = true
                        }
                    }
                    .buttonStyle(ConnectButtonStyle())
                }
                .frame(maxWidth: 400)
                .padding(16)
                .background(Color("modal"))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(16)
            }
            .padding(.bottom, 32)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Connect")
                        .foregroundStyle(Color("text-primary"))
                        .font(.system(size: 20))
                        .fontDesign(.rounded)
                        .fontWeight(.semibold)
                }
            }
            .toolbarBackground(Color("background"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .background(Color("background"))
            .navigationDestination(isPresented: $showConnectImagesView) {
                ConnectImagesView(selectedPhotos: $selectedPhotos, selectedPhotosData: $selectedPhotosData)
            }
            .navigationDestination(isPresented: $showConnectTextView) {
                ConnectTextView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color("background"))
        .contentMargins(.leading, 0, for: .scrollIndicators)
        .contentMargins(16)
    }
}

#Preview {
    ConnectView()
}
