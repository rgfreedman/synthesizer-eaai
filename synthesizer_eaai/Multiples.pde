/*Multiples.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 August 22

Class for a multiples component within a synthesized instrument.
This component simply copies a wave input to allow multiple copies of it as outputs.
*/

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the VCO class below
public static class Multiples_CONSTANTS
{
  //Indeces for input patches - this is the original wave to copy
  public static final int PATCHIN_ORIGINAL = 0;
  public static final int TOTAL_PATCHIN = PATCHIN_ORIGINAL + 1;
  
  //No knobs
  public static final int TOTAL_KNOB = 0;
  
  //Indeces for output patches - these are the copies of the input waveform
  public static final int PATCHOUT_COPY0 = 0;
  public static final int PATCHOUT_COPY1 = PATCHOUT_COPY0 + 1;
  public static final int PATCHOUT_COPY2 = PATCHOUT_COPY1 + 1;
  public static final int PATCHOUT_COPY3 = PATCHOUT_COPY2 + 1;
  public static final int PATCHOUT_COPY4 = PATCHOUT_COPY3 + 1;
  public static final int PATCHOUT_COPY5 = PATCHOUT_COPY4 + 1;
  public static final int PATCHOUT_COPY6 = PATCHOUT_COPY5 + 1;
  public static final int PATCHOUT_COPY7 = PATCHOUT_COPY6 + 1;
  public static final int PATCHOUT_COPY8 = PATCHOUT_COPY7 + 1;
  public static final int TOTAL_PATCHOUT = PATCHOUT_COPY8 + 1;
}

public class Multiples extends SynthComponent
{
  //Internal UGen Objects that compose the component's "circuit"
  //A Summer that only has one input effectively copies the waveform (like an identity function)
  private Summer identity;
  
  //Default Constructor - set up all the patches and knobs
  public Multiples()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(Multiples_CONSTANTS.TOTAL_PATCHIN, Multiples_CONSTANTS.TOTAL_PATCHOUT, Multiples_CONSTANTS.TOTAL_KNOB);

    //Set up the internals of the component with the UGen elements from Minim
    identity = new Summer();
    
    //With the UGens all setup, fill in the external-facing ones for input/output
    patchIn[Multiples_CONSTANTS.PATCHIN_ORIGINAL] = identity;
    //Everything points to the identity input, which mimics that one input as the output
    patchOut[Multiples_CONSTANTS.PATCHOUT_COPY0] = patchIn[Multiples_CONSTANTS.PATCHIN_ORIGINAL];
    patchOut[Multiples_CONSTANTS.PATCHOUT_COPY1] = patchIn[Multiples_CONSTANTS.PATCHIN_ORIGINAL];
    patchOut[Multiples_CONSTANTS.PATCHOUT_COPY2] = patchIn[Multiples_CONSTANTS.PATCHIN_ORIGINAL];
    patchOut[Multiples_CONSTANTS.PATCHOUT_COPY3] = patchIn[Multiples_CONSTANTS.PATCHIN_ORIGINAL];
    patchOut[Multiples_CONSTANTS.PATCHOUT_COPY4] = patchIn[Multiples_CONSTANTS.PATCHIN_ORIGINAL];
    patchOut[Multiples_CONSTANTS.PATCHOUT_COPY5] = patchIn[Multiples_CONSTANTS.PATCHIN_ORIGINAL];
    patchOut[Multiples_CONSTANTS.PATCHOUT_COPY6] = patchIn[Multiples_CONSTANTS.PATCHIN_ORIGINAL];
    patchOut[Multiples_CONSTANTS.PATCHOUT_COPY7] = patchIn[Multiples_CONSTANTS.PATCHIN_ORIGINAL];
    patchOut[Multiples_CONSTANTS.PATCHOUT_COPY8] = patchIn[Multiples_CONSTANTS.PATCHIN_ORIGINAL];
  
    //Labels for the patches in the GUI
    componentName = "Multiples";
    patchInLabel[Multiples_CONSTANTS.PATCHIN_ORIGINAL] = "WAVE IN";
    patchOutLabel[Multiples_CONSTANTS.PATCHOUT_COPY0] = "WAVE OUT";
    patchOutLabel[Multiples_CONSTANTS.PATCHOUT_COPY1] = "WAVE OUT";
    patchOutLabel[Multiples_CONSTANTS.PATCHOUT_COPY2] = "WAVE OUT";
    patchOutLabel[Multiples_CONSTANTS.PATCHOUT_COPY3] = "WAVE OUT";
    patchOutLabel[Multiples_CONSTANTS.PATCHOUT_COPY4] = "WAVE OUT";
    patchOutLabel[Multiples_CONSTANTS.PATCHOUT_COPY5] = "WAVE OUT";
    patchOutLabel[Multiples_CONSTANTS.PATCHOUT_COPY6] = "WAVE OUT";
    patchOutLabel[Multiples_CONSTANTS.PATCHOUT_COPY7] = "WAVE OUT";
    patchOutLabel[Multiples_CONSTANTS.PATCHOUT_COPY8] = "WAVE OUT";
  }
  
  //Implement in each component to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public void draw_update()
  {
    //Nothing here yet, knob updates are now done in Knob class (as they should)
  }
}
