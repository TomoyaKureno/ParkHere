//
//  PedometerService.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 08/06/26.
//

import CoreMotion
import Observation

@MainActor
@Observable
final class PedometerService {

    private let pedometer = CMPedometer()
    let isFloorCountingAvailable = CMPedometer.isFloorCountingAvailable()

    private(set) var liveFloorsAscended: Int = 0
    private(set) var liveFloorsDescended: Int = 0

    var netFloors: Int { liveFloorsAscended - liveFloorsDescended }

    func startLiveUpdates() {
        guard isFloorCountingAvailable else { return }
        liveFloorsAscended = 0
        liveFloorsDescended = 0
        pedometer.startUpdates(from: .now) { [weak self] data, _ in
            guard let self, let data else { return }
            Task { @MainActor in
                self.liveFloorsAscended = data.floorsAscended?.intValue ?? 0
                self.liveFloorsDescended = data.floorsDescended?.intValue ?? 0
            }
        }
    }

    func stopLiveUpdates() {
        pedometer.stopUpdates()
    }
}
