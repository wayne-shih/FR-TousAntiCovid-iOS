// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  HapticManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 30/06/2021 - for the TousAntiCovid project.
//

import Foundation
import CoreHaptics

@available(iOS 13.0, *)
class HapticManager {

    static let shared: HapticManager = HapticManager()

    private var engine: CHHapticEngine?

    func hapticFirework() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        var events = [CHHapticEvent]()
        var curves = [CHHapticParameterCurve]()

        // create one continuous buzz that fades out
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)

        let start = CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 1)
        let end = CHHapticParameterCurve.ControlPoint(relativeTime: 1.5, value: 0)

        let parameter = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [start, end], relativeTime: 0)
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [sharpness, intensity], relativeTime: 0, duration: 1.5)
        events.append(event)
        curves.append(parameter)

        for _ in 1...16 {
            // make some sparkles
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1)
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [sharpness, intensity], relativeTime: TimeInterval.random(in: 0.1...1))
            events.append(event)
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: curves)
            engine = try CHHapticEngine()
            try engine?.start()
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {}
    }
}
