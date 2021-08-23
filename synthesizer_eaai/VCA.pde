/*VCA.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 August 22

Class for a voltage-controlled amplifier (VCA) component within a synthesized instrument.
This component simply modifies the amplitude of an input wave.
*/

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the VCO class below
public static class VCA_CONSTANTS
{
  //Indeces for input patches - these are the waveform and amplitude modification
  public static final int PATCHIN_WAVE = 0;
  public static final int PATCHIN_AMP = PATCHIN_WAVE + 1;
  public static final int TOTAL_PATCHIN = PATCHIN_AMP + 1;
  
  //No gates
  public static final int TOTAL_GATE = 0;
  
  //Indeces for knobs - just the amplitude for a constant modification (can also make
  //                    > 1 via the knob for frequency modulation purposes)
  public static final int KNOB_AMP = 0;
  public static final int TOTAL_KNOB = KNOB_AMP + 1;
  
  //Indeces for output patches - this is the modified waveform
  public static final int PATCHOUT_WAVE = 0;
  public static final int TOTAL_PATCHOUT = PATCHOUT_WAVE + 1;
}

public class VCA extends SynthComponent
{
  //Internal UGen Objects that compose the component's "circuit"
  //Summer combines the input patch and knob values when mapping to the same feature
  private Summer totalAmplitude;
  //Multiplier performs the actual modification to the waveform's volume, and is output
  private Multiplier waveModifier;
  
  //Default Constructor - set up all the patches and knobs
  public VCA()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(VCA_CONSTANTS.TOTAL_PATCHIN, VCA_CONSTANTS.TOTAL_PATCHOUT, VCA_CONSTANTS.TOTAL_GATE, VCA_CONSTANTS.TOTAL_KNOB);

    //Now fill in the knobs
    knobs[VCA_CONSTANTS.KNOB_AMP] = new Knob(0.0, 100.0); //Amplitude is in [0,100]

    //Set up the internals of the component with the UGen elements from Minim
    totalAmplitude = new Summer();
    waveModifier = new Multiplier();
    
    //With the UGens all setup, fill in the external-facing ones for input/output
    patchIn[VCA_CONSTANTS.PATCHIN_WAVE] = waveModifier;
    patchIn[VCA_CONSTANTS.PATCHIN_AMP] = totalAmplitude;
    patchOut[VCA_CONSTANTS.PATCHOUT_WAVE] = waveModifier;
    
    //Setup the patchwork for the internal components
    knobs[VCA_CONSTANTS.KNOB_AMP].getCurrentValue().patch(totalAmplitude);
    totalAmplitude.patch(waveModifier.amplitude);
  }
  
  //Implement in each component to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public void draw_update()
  {
    //Nothing here yet, knob updates are now done in Knob class (as they should)
  }
}
