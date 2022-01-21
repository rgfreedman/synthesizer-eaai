/*VCF.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2022 January 21

Class for a voltage-controlled filter (VCF) module within a synthesized instrument.
This module simply removes frequencies with respect to specified intervals (usually applies to noise inputs with a variety of frequencies).

---------------------------------------------------------------------
Copyright 2022 Richard (Rick) G. Freedman

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the VCO class below
public static class VCF_CONSTANTS
{
  //Indeces for input patches - these are the oscillator parameters
  public static final int PATCHIN_WAVE = 0;
  public static final int PATCHIN_FREQ = PATCHIN_WAVE + 1;
  public static final int PATCHIN_RES = PATCHIN_FREQ + 1;
  public static final int TOTAL_PATCHIN = PATCHIN_RES + 1;
  
  //Indeces for knobs - same as input patches in this case
  //NOTE: Offset in index allows nicer spacing
  public static final int KNOB_FREQ = 1; //0;
  public static final int KNOB_RES = KNOB_FREQ + 1;
  public static final int KNOB_PASS = KNOB_RES + 1;
  public static final int TOTAL_KNOB = KNOB_PASS + 1;
  
  //Indeces for output patches - these are the waveforms
  public static final int PATCHOUT_WAVE = 0;
  public static final int TOTAL_PATCHOUT = PATCHOUT_WAVE + 1;
}

public class VCF extends SynthModule
{
  //Internal UGen Objects that compose the module's "circuit"
  //Summer combines the input patch and knob values when mapping to the same feature
  private Summer totalFrequency;
  private Summer totalResonance;
  //Input for frequency is assumed to be in volts, but need in Hertz
  private Multiplier fromVolts;
  
  //MoogFilter performs the actual modification to the waveform's volume, and is output
  private MoogFilter waveFilter;
  
  //Default Constructor - set up all the patches and knobs
  public VCF()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(VCF_CONSTANTS.TOTAL_PATCHIN, VCF_CONSTANTS.TOTAL_PATCHOUT, VCF_CONSTANTS.TOTAL_KNOB);

    //Now fill in the knobs
    knobs[VCF_CONSTANTS.KNOB_FREQ] = new Knob(Audio_CONSTANTS.MIN_FREQ, Audio_CONSTANTS.MAX_FREQ); //Audible frequencies... 22000 hurts the ears... piano goes to about 4200... let's cap it off just a bit above that
    knobs[VCF_CONSTANTS.KNOB_RES] = new Knob(0.0, 1.0); //Resonance is in [0,1]
    knobs[VCF_CONSTANTS.KNOB_PASS] = new Knob(0.0, 3.0); //Resonance is in {0,1,2}, which is based on truncation from [0,3)
    
    //Label for knob in GUI
    knobsLabel[VCF_CONSTANTS.KNOB_FREQ] = "FREQ";
    knobsLabel[VCF_CONSTANTS.KNOB_RES] = "RESONANCE";
    knobsLabel[VCF_CONSTANTS.KNOB_PASS] = "PASS";

    //Set up the internals of the module with the UGen elements from Minim
    totalFrequency = new Summer();
    totalResonance = new Summer();
    waveFilter = new MoogFilter(0.0, 0.0); //Low-pass filter by default, set via pass knob
    fromVolts = new Multiplier(Audio_CONSTANTS.MAX_FREQ / Audio_CONSTANTS.MAX_VOLT);
    //Converts the volts to Hertz before reaching frequency
    fromVolts.patch(totalFrequency);
    
    //With the UGens all setup, fill in the external-facing ones for input/output
    patchIn[VCF_CONSTANTS.PATCHIN_WAVE] = waveFilter;
    patchIn[VCF_CONSTANTS.PATCHIN_FREQ] = fromVolts;
    patchIn[VCF_CONSTANTS.PATCHIN_RES] = totalResonance;
    patchOut[VCF_CONSTANTS.PATCHOUT_WAVE] = waveFilter;
    
    //Label for patches in GUI
    patchInLabel[VCF_CONSTANTS.PATCHIN_WAVE] = "WAVE IN";
    patchInLabel[VCF_CONSTANTS.PATCHIN_FREQ] = "CV IN";
    patchInLabel[VCF_CONSTANTS.PATCHIN_RES] = "RES IN";
    patchOutLabel[VCF_CONSTANTS.PATCHOUT_WAVE] = "WAVE OUT";
    moduleName = "VCF";
    
    //Setup the patchwork for the internal modules
    knobs[VCF_CONSTANTS.KNOB_FREQ].getCurrentValue().patch(totalFrequency);
    totalFrequency.patch(waveFilter.frequency);
    
    knobs[VCF_CONSTANTS.KNOB_RES].getCurrentValue().patch(totalResonance);
    totalResonance.patch(waveFilter.resonance);
  }
  
  //Implement in each module to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public void draw_update()
  {
    //Set the filter's type to the value (discretized) of the pass knob
    float passKnobVal = knobs[VCF_CONSTANTS.KNOB_PASS].getCurrentValue_float();
    if((passKnobVal >= 0.0) && (passKnobVal < 1.0))
    {
      waveFilter.type = MoogFilter.Type.LP;
    }
    else if((passKnobVal >= 1.0) && (passKnobVal < 2.0))
    {
      waveFilter.type = MoogFilter.Type.BP;
    }
    else //if((passKnobVal >= 2.0) && (passKnobVal < 3.0))
    {
      waveFilter.type = MoogFilter.Type.HP;
    }
  }
}
