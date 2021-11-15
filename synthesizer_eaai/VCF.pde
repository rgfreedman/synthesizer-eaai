/*VCO.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 November 15

Class for a voltage-controlled filter (VCF) component within a synthesized instrument.
This component simply removes frequencies with respect to specified intervals (usually applies to noise inputs with a variety of frequencies).
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
  
  //No gates
  public static final int TOTAL_GATE = 0;
  
  //Indeces for knobs - same as input patches in this case
  public static final int KNOB_FREQ = 0;
  public static final int KNOB_RES = KNOB_FREQ + 1;
  public static final int KNOB_PASS = KNOB_RES + 1;
  public static final int TOTAL_KNOB = KNOB_PASS + 1;
  
  //Indeces for output patches - these are the waveforms
  public static final int PATCHOUT_WAVE = 0;
  public static final int TOTAL_PATCHOUT = PATCHOUT_WAVE + 1;
}

public class VCF extends SynthComponent
{
  //Internal UGen Objects that compose the component's "circuit"
  //Summer combines the input patch and knob values when mapping to the same feature
  private Summer totalFrequency;
  private Summer totalResonance;
  
  //MoogFilter performs the actual modification to the waveform's volume, and is output
  private MoogFilter waveFilter;
  
  //Default Constructor - set up all the patches and knobs
  public VCF()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(VCF_CONSTANTS.TOTAL_PATCHIN, VCF_CONSTANTS.TOTAL_PATCHOUT, VCF_CONSTANTS.TOTAL_GATE, VCF_CONSTANTS.TOTAL_KNOB);

    //Now fill in the knobs
    knobs[VCF_CONSTANTS.KNOB_FREQ] = new Knob(0.0, 6000.0); //Audible frequencies... 22000 hurts the ears... piano goes to about 4200... let's cap it off just a bit above that
    knobs[VCF_CONSTANTS.KNOB_RES] = new Knob(0.0, 1.0); //Resonance is in [0,1]
    knobs[VCF_CONSTANTS.KNOB_PASS] = new Knob(0.0, 3.0); //Resonance is in {0,1,2}, which is based on truncation from [0,3)

    //Set up the internals of the component with the UGen elements from Minim
    totalFrequency = new Summer();
    totalResonance = new Summer();
    waveFilter = new MoogFilter(0.0, 0.0); //Low-pass filter by default, set via pass knob
    
    //With the UGens all setup, fill in the external-facing ones for input/output
    patchIn[VCF_CONSTANTS.PATCHIN_WAVE] = waveFilter;
    patchIn[VCF_CONSTANTS.PATCHIN_FREQ] = totalFrequency;
    patchIn[VCF_CONSTANTS.PATCHIN_RES] = totalResonance;
    patchOut[VCF_CONSTANTS.PATCHOUT_WAVE] = waveFilter;
    
    //Setup the patchwork for the internal components
    knobs[VCF_CONSTANTS.KNOB_FREQ].getCurrentValue().patch(totalFrequency);
    totalFrequency.patch(waveFilter.frequency);
    
    knobs[VCF_CONSTANTS.KNOB_RES].getCurrentValue().patch(totalResonance);
    totalResonance.patch(waveFilter.resonance);
  }
  
  //Implement in each component to do any per-draw-iteration updates
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
