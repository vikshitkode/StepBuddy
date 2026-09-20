//
//  Color+Ext.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 9/19/26.
//

import Foundation
import SwiftUI

extension LinearGradient {
    
    static var customGradientColor: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.70, blue: 0.20),
                Color(red: 0.99, green: 0.30, blue: 0.50),
                Color(red: 0.32, green: 0.57, blue: 1.0),
                Color(red: 0.30, green: 0.80, blue: 0.90)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
}
