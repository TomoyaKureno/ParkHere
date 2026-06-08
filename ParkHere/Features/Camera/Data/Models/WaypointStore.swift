//
//  WaypointStore.swift
//  ParkHere
//
//  Created by Kelly Angeline on 08/06/26.
//

import Combine
import SwiftUI

final class WaypointStore: ObservableObject {
    
    @Published var capturedImages: [UIImage] = []
    
    func addWaypoint (_ image:UIImage){
        capturedImages.append(image)
    }
    
    func removeWaypoint (at index: Int){
        guard index >= 0 && index < capturedImages.count else { return }
        capturedImages.remove(at:index)
    }
    
    func clearWaypoints() {
        capturedImages.removeAll()
    }
}
