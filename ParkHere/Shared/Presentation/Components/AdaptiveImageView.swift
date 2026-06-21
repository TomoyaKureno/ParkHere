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
    let backgroundColor: Color

    init(
        uiImage: UIImage,
        width: CGFloat? = nil,
        height: CGFloat,
        cornerRadius: CGFloat = 0,
        alignment: Alignment = .center,
        backgroundColor: Color = .black
    ) {
        self.uiImage = uiImage
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.alignment = alignment
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        let isLandscape = uiImage.size.width > uiImage.size.height
        let shape = RoundedRectangle(cornerRadius: cornerRadius)

        ZStack(alignment: alignment) {
            backgroundColor

            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: isLandscape ? .fit : .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        }
        .frame(width: width, height: height)
        .frame(maxWidth: width == nil ? .infinity : width)
        .clipShape(shape)
    }
}

#Preview {
    VStack {
        AdaptiveImageView(
            uiImage: UIImage(resource: .carImg),
            width: 200,
            height: 200,
            cornerRadius: 20,
            alignment: .center
        )

        AdaptiveImageView(
            uiImage: UIImage(resource: .imgLandmark),
            height: 300,
            cornerRadius: 20,
            alignment: .center
        )
    }
}
