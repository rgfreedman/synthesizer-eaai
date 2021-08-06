/*NoiseGenerator.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 August 06

Class for a noise-generating oscillator component within a synthesized instrument.
This component simply generates noise with specified properties.  Unlike the VCO and LFO,
the output is noise rather than a single tone.
*/

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the VCO class below
public static class NoiseGenerator_CONSTANTS
{
  //Indeces for input patches - these are the oscillator parameters
  public static final int PATCHIN_AMP = 0;
  public static final int TOTAL_PATCHIN = PATCHIN_AMP + 1;
  
  //No gates
  public static final int TOTAL_GATE = 0;
  
  //Indeces for knobs - same as input patches in this case
  public static final int KNOB_AMP = 0;
  public static final int TOTAL_KNOB = KNOB_AMP + 1;
  
  //Indeces for output patches - these are the noise types/tints
  public static final int PATCHOUT_WHITE = 0;
  public static final int PATCHOUT_PINK = PATCHOUT_WHITE + 1;
  public static final int PATCHOUT_BROWN = PATCHOUT_PINK + 1;
  public static final int TOTAL_PATCHOUT = PATCHOUT_BROWN + 1;
}

public class NoiseGenerator extends SynthComponent
{
  //Internal UGen Objects that compose the component's "circuit"
  //Summer combines the input patch and knob values when mapping to the same feature
  private Summer totalAmplitude;
  
  //"Oscillators" for each wave output
  private Noise out_white;
  private Noise out_pink;
  private Noise out_brown;
  
  //Default Constructor - set up all the patches and knobs
  public NoiseGenerator()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(NoiseGenerator_CONSTANTS.TOTAL_PATCHIN, NoiseGenerator_CONSTANTS.TOTAL_PATCHOUT, NoiseGenerator_CONSTANTS.TOTAL_GATE, NoiseGenerator_CONSTANTS.TOTAL_KNOB);

    //Now fill in the knobs
    knobs[NoiseGenerator_CONSTANTS.KNOB_AMP] = new Knob(0.0, 1.0); //Amplitude is in [0,1]

    //Set up the internals of the component with the UGen elements from Minim
    totalAmplitude = new Summer();
    //NOTE: No frequency or amplitude for the output waveforms yet
    out_white = new Noise(0.0, Noise.Tint.WHITE);
    out_pink = new Noise(0.0, Noise.Tint.PINK);
    out_brown = new Noise(0.0, Noise.Tint.BROWN);
    
    //With the UGens all setup, fill in the external-facing ones for input/output
    patchIn[NoiseGenerator_CONSTANTS.PATCHIN_AMP] = totalAmplitude;
    patchOut[NoiseGenerator_CONSTANTS.PATCHOUT_WHITE] = out_white;
    patchOut[NoiseGenerator_CONSTANTS.PATCHOUT_PINK] = out_pink;
    patchOut[NoiseGenerator_CONSTANTS.PATCHOUT_BROWN] = out_brown;
    
    //Setup the patchwork for the internal components
    knobs[NoiseGenerator_CONSTANTS.KNOB_AMP].getCurrentValue().patch(totalAmplitude);
    totalAmplitude.patch(out_white.amplitude);
    totalAmplitude.patch(out_pink.amplitude);
    totalAmplitude.patch(out_brown.amplitude);
  }
  
  //Implement in each component to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public void draw_update()
  {
    //Nothing here yet, knob updates are now done in Knob class (as they should)
  }
}
