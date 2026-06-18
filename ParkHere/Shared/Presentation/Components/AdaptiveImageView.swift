//
//  AdaptiveImageView.swift
//  ParkHere
//
//  Created by Kelly Angeline on 18/06/26.
//

import SwiftUI

struct AdaptiveImageView: View {
    let uiImage: UIImage
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    let alignment: Alignment
    
    init(
        uiImage: UIImage,
        width: CGFloat? = nil,
        height: CGFloat,
        cornerRadius: CGFloat = 0,
        alignment: Alignment = .center
    ) {
        self.uiImage = uiImage
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.alignment = alignment
    }
    
    var body: some View {
        let isLandscape = uiImage.size.width > uiImage.size.height
        
        Group {
            if isLandscape {
                ZStack(alignment: alignment) {
                    Color.black
                    
                    Image(uiImage:uiImage)
                        .resizable()
                        .scaledToFit()
                }
                .frame(width:width, height:height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                Image(uiImage: uiImage)
                     .resizable()
                     .scaledToFill()
                     .frame(width: width, height: height)
                     .clipped()
                     .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        }
    }
}
