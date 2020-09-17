// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

#import "SynthDSP.h"
#include <math.h>

AKDSPRef akAKSynthCreateDSP() {
    return new AKSynthDSP();
}

void akSynthPlayNote(AKDSPRef pDSP, UInt8 noteNumber, UInt8 velocity, float noteFrequency)
{
    ((AKSynthDSP*)pDSP)->playNote(noteNumber, velocity, noteFrequency);
}

void akSynthStopNote(AKDSPRef pDSP, UInt8 noteNumber, bool immediate)
{
    ((AKSynthDSP*)pDSP)->stopNote(noteNumber, immediate);
}

void akSynthSustainPedal(AKDSPRef pDSP, bool pedalDown)
{
    ((AKSynthDSP*)pDSP)->sustainPedal(pedalDown);
}


AKSynthDSP::AKSynthDSP() : AKDSPBase(/*inputBusCount*/0), AKCoreSynth()
{
    masterVolumeRamp.setTarget(1.0, true);
    pitchBendRamp.setTarget(0.0, true);
    vibratoDepthRamp.setTarget(0.0, true);
    filterCutoffRamp.setTarget(1000.0, true);
    filterResonanceRamp.setTarget(1.0, true);
}

void AKSynthDSP::init(int channelCount, double sampleRate)
{
    AKDSPBase::init(channelCount, sampleRate);
    AKCoreSynth::init(sampleRate);
}

void AKSynthDSP::deinit()
{
    AKDSPBase::deinit();
    AKCoreSynth::deinit();
}

void AKSynthDSP::setParameter(uint64_t address, float value, bool immediate)
{
    switch (address) {
        case AKSynthParameterRampDuration:
            masterVolumeRamp.setRampDuration(value, sampleRate);
            pitchBendRamp.setRampDuration(value, sampleRate);
            vibratoDepthRamp.setRampDuration(value, sampleRate);
            filterCutoffRamp.setRampDuration(value, sampleRate);
            filterResonanceRamp.setRampDuration(value, sampleRate);
            break;

        case AKSynthParameterMasterVolume:
            masterVolumeRamp.setTarget(value, immediate);
            break;
        case AKSynthParameterPitchBend:
            pitchBendRamp.setTarget(value, immediate);
            break;
        case AKSynthParameterVibratoDepth:
            vibratoDepthRamp.setTarget(value, immediate);
            break;
        case SynthParameterFilterCutoff:
            filterCutoffRamp.setTarget(value, immediate);
            break;
        case SynthParameterFilterStrength:
            filterStrengthRamp.setTarget(value, immediate);
            break;
        case SynthParameterFilterResonance:
            filterResonanceRamp.setTarget(pow(10.0, -0.05 * value), immediate);
            break;

        case AKSynthParameterAttackDuration:
            setAmpAttackDurationSeconds(value);
            break;
        case AKSynthParameterDecayDuration:
            setAmpDecayDurationSeconds(value);
            break;
        case AKSynthParameterSustainLevel:
            setAmpSustainFraction(value);
            break;
        case AKSynthParameterReleaseDuration:
            setAmpReleaseDurationSeconds(value);
            break;

        case SynthParameterFilterAttackDuration:
            setFilterAttackDurationSeconds(value);
            break;
        case SynthParameterFilterDecayDuration:
            setFilterDecayDurationSeconds(value);
            break;
        case SynthParameterFilterSustainLevel:
            setFilterSustainFraction(value);
            break;
        case SynthParameterFilterReleaseDuration:
            setFilterReleaseDurationSeconds(value);
            break;
    }
}

float AKSynthDSP::getParameter(uint64_t address)
{
    switch (address) {
        case AKSynthParameterRampDuration:
            return pitchBendRamp.getRampDuration(sampleRate);

        case AKSynthParameterMasterVolume:
            return masterVolumeRamp.getTarget();
        case AKSynthParameterPitchBend:
            return pitchBendRamp.getTarget();
        case AKSynthParameterVibratoDepth:
            return vibratoDepthRamp.getTarget();
        case SynthParameterFilterCutoff:
            return filterCutoffRamp.getTarget();
        case SynthParameterFilterStrength:
            return filterStrengthRamp.getTarget();
        case SynthParameterFilterResonance:
            return -20.0f * log10(filterResonanceRamp.getTarget());

        case AKSynthParameterAttackDuration:
            return getAmpAttackDurationSeconds();
        case AKSynthParameterDecayDuration:
            return getAmpDecayDurationSeconds();
        case AKSynthParameterSustainLevel:
            return getAmpSustainFraction();
        case AKSynthParameterReleaseDuration:
            return getAmpReleaseDurationSeconds();

        case SynthParameterFilterAttackDuration:
            return getFilterAttackDurationSeconds();
        case SynthParameterFilterDecayDuration:
            return getFilterDecayDurationSeconds();
        case SynthParameterFilterSustainLevel:
            return getFilterSustainFraction();
        case SynthParameterFilterReleaseDuration:
            return getFilterReleaseDurationSeconds();
    }
    return 0;
}

void AKSynthDSP::process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset)
{

    float *pLeft = (float *)outputBufferList->mBuffers[0].mData + bufferOffset;
    float *pRight = (float *)outputBufferList->mBuffers[1].mData + bufferOffset;

    memset(pLeft, 0, frameCount * sizeof(float));
    memset(pRight, 0, frameCount * sizeof(float));
    
    // process in chunks of maximum length CHUNKSIZE
    for (int frameIndex = 0; frameIndex < frameCount; frameIndex += AKSYNTH_CHUNKSIZE) {
        int frameOffset = int(frameIndex + bufferOffset);
        int chunkSize = frameCount - frameIndex;
        if (chunkSize > AKSYNTH_CHUNKSIZE) chunkSize = AKSYNTH_CHUNKSIZE;

        // ramp parameters
        masterVolumeRamp.advanceTo(now + frameOffset);
        masterVolume = (float)masterVolumeRamp.getValue();
        pitchBendRamp.advanceTo(now + frameOffset);
        pitchOffset = (float)pitchBendRamp.getValue();
        vibratoDepthRamp.advanceTo(now + frameOffset);
        vibratoDepth = (float)vibratoDepthRamp.getValue();
        filterCutoffRamp.advanceTo(now + frameOffset);
        cutoffMultiple = (float)filterCutoffRamp.getValue();
        filterStrengthRamp.advanceTo(now + frameOffset);
        cutoffEnvelopeStrength = (float)filterStrengthRamp.getValue();
        filterResonanceRamp.advanceTo(now + frameOffset);
        linearResonance = (float)filterResonanceRamp.getValue();

        // get data
        float *outBuffers[2];
        outBuffers[0] = (float *)outputBufferList->mBuffers[0].mData + frameOffset;
        outBuffers[1] = (float *)outputBufferList->mBuffers[1].mData + frameOffset;
        unsigned channelCount = outputBufferList->mNumberBuffers;
        AKCoreSynth::render(channelCount, chunkSize, outBuffers);
    }
}
