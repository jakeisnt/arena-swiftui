//
//  ContentPreview.swift
//  Arena
//
//  Created by Yihui Hu on 22/10/23.
//

import SwiftUI

// Used in ChannelView
struct ChannelContentPreview: View {
    let block: Block
    let gridItemSize: CGFloat
    
    var body: some View {
        if block.baseClass == "Block" {
            ChannelViewBlockPreview(blockData: block, fontSize: 16)
                .frame(width: gridItemSize, height: gridItemSize)
                .border(Color("surface-secondary"))
        } else {
            ChannelPreview(blockData: block, fontSize: 16)
                .frame(width: gridItemSize, height: gridItemSize)
                .border(Color("arena-orange"))
        }
    }
}
