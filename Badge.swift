//
//  Badge.swift
//  StaffingAgencyApp
//
//  Created by Harshith Kalluri on 3/17/26.
//

import Foundation
import SwiftUI

struct Badge: View {
    let text: String
    var color: Color = .blue
    var style: BadgeStyle = .filled
    
    enum BadgeStyle {
        case filled
        case outlined
    }
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(style == .filled ? color.opacity(0.15) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color, lineWidth: style == .outlined ? 1.5 : 0)
                    )
            )
            .foregroundColor(color)
    }
}
