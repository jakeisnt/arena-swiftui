//
//  ChannelCardContentPreview.swift
//  Arena
//
//  Created by Yihui Hu on 22/10/23.
//

import SwiftUI

// Used to display content in each ChannelCard
struct ChannelCardContentPreview: View {
    let block: Block
    
    var body: some View {
        VStack {
            if block.baseClass == "Block" {
                ChannelCardBlockPreview(blockData: block, fontSize: 14)
                    .frame(maxWidth: 250)
                    .background(Color("surface-secondary"))
            } else {
                ChannelPreview(blockData: block, fontSize: 14, display: "Default")
                    .frame(width: 132, height: 132)
                    .background(Color("surface-secondary"))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
