// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/
// This file was auto-autogenerated by scripts and templates at http://github.com/AudioKit/AudioKitDevTools/

import AVFoundation
import CAudioKit

/// Analogue model of the Korg 35 Lowpass Filter
public class KorgLowPassFilter: Node, AudioUnitContainer, Tappable, Toggleable {

    public static let ComponentDescription = AudioComponentDescription(effect: "klpf")

    public typealias AudioUnitType = InternalAU

    public private(set) var internalAU: AudioUnitType?

    // MARK: - Parameters

    public static let cutoffFrequencyDef = NodeParameterDef(
        identifier: "cutoffFrequency",
        name: "Filter cutoff",
        address: akGetParameterAddress("KorgLowPassFilterParameterCutoffFrequency"),
        range: 0.0 ... 22_050.0,
        unit: .hertz,
        flags: .default)

    /// Filter cutoff
    @Parameter public var cutoffFrequency: AUValue

    public static let resonanceDef = NodeParameterDef(
        identifier: "resonance",
        name: "Filter resonance (should be between 0-2)",
        address: akGetParameterAddress("KorgLowPassFilterParameterResonance"),
        range: 0.0 ... 2.0,
        unit: .generic,
        flags: .default)

    /// Filter resonance (should be between 0-2)
    @Parameter public var resonance: AUValue

    public static let saturationDef = NodeParameterDef(
        identifier: "saturation",
        name: "Filter saturation.",
        address: akGetParameterAddress("KorgLowPassFilterParameterSaturation"),
        range: 0.0 ... 10.0,
        unit: .generic,
        flags: .default)

    /// Filter saturation.
    @Parameter public var saturation: AUValue

    // MARK: - Audio Unit

    public class InternalAU: AudioUnitBase {

        public override func getParameterDefs() -> [NodeParameterDef] {
            [KorgLowPassFilter.cutoffFrequencyDef,
             KorgLowPassFilter.resonanceDef,
             KorgLowPassFilter.saturationDef]
        }

        public override func createDSP() -> DSPRef {
            akCreateDSP("KorgLowPassFilterDSP")
        }
    }

    // MARK: - Initialization

    /// Initialize this filter node
    ///
    /// - Parameters:
    ///   - input: Input node to process
    ///   - cutoffFrequency: Filter cutoff
    ///   - resonance: Filter resonance (should be between 0-2)
    ///   - saturation: Filter saturation.
    ///
    public init(
        _ input: Node,
        cutoffFrequency: AUValue = 1_000.0,
        resonance: AUValue = 1.0,
        saturation: AUValue = 0.0
        ) {
        super.init(avAudioNode: AVAudioNode())

        instantiateAudioUnit { avAudioUnit in
            self.avAudioUnit = avAudioUnit
            self.avAudioNode = avAudioUnit

            guard let audioUnit = avAudioUnit.auAudioUnit as? AudioUnitType else {
                fatalError("Couldn't create audio unit")
            }
            self.internalAU = audioUnit

            self.cutoffFrequency = cutoffFrequency
            self.resonance = resonance
            self.saturation = saturation
        }
        connections.append(input)
    }
}
