// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/
// This file was auto-autogenerated by scripts and templates at http://github.com/AudioKit/AudioKitDevTools/

import AVFoundation
import CAudioKit

/// An automatic wah effect, ported from Guitarix via Faust.
public class AutoWah: Node, AudioUnitContainer, Tappable, Toggleable {

    public static let ComponentDescription = AudioComponentDescription(effect: "awah")

    public typealias AudioUnitType = InternalAU

    public private(set) var internalAU: AudioUnitType?

    // MARK: - Parameters

    public static let wahDef = NodeParameterDef(
        identifier: "wah",
        name: "Wah Amount",
        address: akGetParameterAddress("AutoWahParameterWah"),
        range: 0.0 ... 1.0,
        unit: .generic,
        flags: .default)

    /// Wah Amount
    @Parameter public var wah: AUValue

    public static let mixDef = NodeParameterDef(
        identifier: "mix",
        name: "Dry/Wet Mix",
        address: akGetParameterAddress("AutoWahParameterMix"),
        range: 0.0 ... 1.0,
        unit: .percent,
        flags: .default)

    /// Dry/Wet Mix
    @Parameter public var mix: AUValue

    public static let amplitudeDef = NodeParameterDef(
        identifier: "amplitude",
        name: "Overall level",
        address: akGetParameterAddress("AutoWahParameterAmplitude"),
        range: 0.0 ... 1.0,
        unit: .generic,
        flags: .default)

    /// Overall level
    @Parameter public var amplitude: AUValue

    // MARK: - Audio Unit

    public class InternalAU: AudioUnitBase {

        public override func getParameterDefs() -> [NodeParameterDef] {
            [AutoWah.wahDef,
             AutoWah.mixDef,
             AutoWah.amplitudeDef]
        }

        public override func createDSP() -> DSPRef {
            akCreateDSP("AutoWahDSP")
        }
    }

    // MARK: - Initialization

    /// Initialize this autoWah node
    ///
    /// - Parameters:
    ///   - input: Input node to process
    ///   - wah: Wah Amount
    ///   - mix: Dry/Wet Mix
    ///   - amplitude: Overall level
    ///
    public init(
        _ input: Node,
        wah: AUValue = 0.0,
        mix: AUValue = 1.0,
        amplitude: AUValue = 0.1
        ) {
        super.init(avAudioNode: AVAudioNode())

        instantiateAudioUnit { avAudioUnit in
            self.avAudioUnit = avAudioUnit
            self.avAudioNode = avAudioUnit

            guard let audioUnit = avAudioUnit.auAudioUnit as? AudioUnitType else {
                fatalError("Couldn't create audio unit")
            }
            self.internalAU = audioUnit

            self.wah = wah
            self.mix = mix
            self.amplitude = amplitude
        }
        connections.append(input)
    }
}
