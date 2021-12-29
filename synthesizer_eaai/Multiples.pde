/*Multiples.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 November 27

Class for a multiples component within a synthesized instrument.
This component simply copies a wave input to allow multiple copies of it as outputs.

NOTE: To allow compact options (for component limit), have a 1->8 and a 2->4 version
*/

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the VCO class below
public static class Multiples1to8_CONSTANTS
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
  public static final int TOTAL_PATCHOUT = PATCHOUT_COPY7 + 1;
}

public class Multiples1to8 extends SynthComponent
{
  //Internal UGen Objects that compose the component's "circuit"
  //A Summer that only has one input effectively copies the waveform (like an identity function)
  private Summer identity;
  
  //Default Constructor - set up all the patches and knobs
  public Multiples1to8()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(Multiples1to8_CONSTANTS.TOTAL_PATCHIN, Multiples1to8_CONSTANTS.TOTAL_PATCHOUT, Multiples1to8_CONSTANTS.TOTAL_KNOB);

    //Set up the internals of the component with the UGen elements from Minim
    identity = new Summer();
    
    //With the UGens all setup, fill in the external-facing ones for input/output
    patchIn[Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL] = identity;
    //Everything points to the identity input, which mimics that one input as the output
    patchOut[Multiples1to8_CONSTANTS.PATCHOUT_COPY0] = patchIn[Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL];
    patchOut[Multiples1to8_CONSTANTS.PATCHOUT_COPY1] = patchIn[Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL];
    patchOut[Multiples1to8_CONSTANTS.PATCHOUT_COPY2] = patchIn[Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL];
    patchOut[Multiples1to8_CONSTANTS.PATCHOUT_COPY3] = patchIn[Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL];
    patchOut[Multiples1to8_CONSTANTS.PATCHOUT_COPY4] = patchIn[Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL];
    patchOut[Multiples1to8_CONSTANTS.PATCHOUT_COPY5] = patchIn[Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL];
    patchOut[Multiples1to8_CONSTANTS.PATCHOUT_COPY6] = patchIn[Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL];
    patchOut[Multiples1to8_CONSTANTS.PATCHOUT_COPY7] = patchIn[Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL];
  
    //Labels for the patches in the GUI
    componentName = "Multiples (1->8)";
    patchInLabel[Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL] = "WAVE IN";
    patchOutLabel[Multiples1to8_CONSTANTS.PATCHOUT_COPY0] = "WAVE OUT";
    patchOutLabel[Multiples1to8_CONSTANTS.PATCHOUT_COPY1] = "WAVE OUT";
    patchOutLabel[Multiples1to8_CONSTANTS.PATCHOUT_COPY2] = "WAVE OUT";
    patchOutLabel[Multiples1to8_CONSTANTS.PATCHOUT_COPY3] = "WAVE OUT";
    patchOutLabel[Multiples1to8_CONSTANTS.PATCHOUT_COPY4] = "WAVE OUT";
    patchOutLabel[Multiples1to8_CONSTANTS.PATCHOUT_COPY5] = "WAVE OUT";
    patchOutLabel[Multiples1to8_CONSTANTS.PATCHOUT_COPY6] = "WAVE OUT";
    patchOutLabel[Multiples1to8_CONSTANTS.PATCHOUT_COPY7] = "WAVE OUT";
  }
  
  //Implement in each component to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public void draw_update()
  {
    //Nothing here yet, knob updates are now done in Knob class (as they should)
  }
}

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the VCO class below
public static class Multiples2to4_CONSTANTS
{
  //Indeces for input patches - this is the original wave to copy
  public static final int PATCHIN_ORIGINAL0 = 0;
  public static final int PATCHIN_ORIGINAL1 = PATCHIN_ORIGINAL0 + 1;
  public static final int TOTAL_PATCHIN = PATCHIN_ORIGINAL1 + 1;
  
  //No knobs
  public static final int TOTAL_KNOB = 0;
  
  //Indeces for output patches - these are the copies of the input waveform
  public static final int PATCHOUT_COPY00 = 0;
  public static final int PATCHOUT_COPY01 = PATCHOUT_COPY00 + 1;
  public static final int PATCHOUT_COPY02 = PATCHOUT_COPY01 + 1;
  public static final int PATCHOUT_COPY03 = PATCHOUT_COPY02 + 1;
  public static final int PATCHOUT_COPY10 = PATCHOUT_COPY03 + 1;
  public static final int PATCHOUT_COPY11 = PATCHOUT_COPY10 + 1;
  public static final int PATCHOUT_COPY12 = PATCHOUT_COPY11 + 1;
  public static final int PATCHOUT_COPY13 = PATCHOUT_COPY12 + 1;
  public static final int TOTAL_PATCHOUT = PATCHOUT_COPY13 + 1;
}

public class Multiples2to4 extends SynthComponent
{
  //Internal UGen Objects that compose the component's "circuit"
  //A Summer that only has one input effectively copies the waveform (like an identity function)
  private Summer identity0;
  private Summer identity1;
  
  //Default Constructor - set up all the patches and knobs
  public Multiples2to4()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(Multiples2to4_CONSTANTS.TOTAL_PATCHIN, Multiples2to4_CONSTANTS.TOTAL_PATCHOUT, Multiples2to4_CONSTANTS.TOTAL_KNOB);

    //Set up the internals of the component with the UGen elements from Minim
    identity0 = new Summer();
    identity1 = new Summer();
    
    //With the UGens all setup, fill in the external-facing ones for input/output
    patchIn[Multiples2to4_CONSTANTS.PATCHIN_ORIGINAL0] = identity0;
    patchIn[Multiples2to4_CONSTANTS.PATCHIN_ORIGINAL1] = identity1;
    //Everything points to the identity input, which mimics that one input as the output
    patchOut[Multiples2to4_CONSTANTS.PATCHOUT_COPY00] = patchIn[Multiples2to4_CONSTANTS.PATCHIN_ORIGINAL0];
    patchOut[Multiples2to4_CONSTANTS.PATCHOUT_COPY01] = patchIn[Multiples2to4_CONSTANTS.PATCHIN_ORIGINAL0];
    patchOut[Multiples2to4_CONSTANTS.PATCHOUT_COPY02] = patchIn[Multiples2to4_CONSTANTS.PATCHIN_ORIGINAL0];
    patchOut[Multiples2to4_CONSTANTS.PATCHOUT_COPY03] = patchIn[Multiples2to4_CONSTANTS.PATCHIN_ORIGINAL0];
    patchOut[Multiples2to4_CONSTANTS.PATCHOUT_COPY10] = patchIn[Multiples2to4_CONSTANTS.PATCHIN_ORIGINAL1];
    patchOut[Multiples2to4_CONSTANTS.PATCHOUT_COPY11] = patchIn[Multiples2to4_CONSTANTS.PATCHIN_ORIGINAL1];
    patchOut[Multiples2to4_CONSTANTS.PATCHOUT_COPY12] = patchIn[Multiples2to4_CONSTANTS.PATCHIN_ORIGINAL1];
    patchOut[Multiples2to4_CONSTANTS.PATCHOUT_COPY13] = patchIn[Multiples2to4_CONSTANTS.PATCHIN_ORIGINAL1];
  
    //Labels for the patches in the GUI
    componentName = "Multiples (2->4)";
    patchInLabel[Multiples2to4_CONSTANTS.PATCHIN_ORIGINAL0] = "WAVE IN (1)";
    patchInLabel[Multiples2to4_CONSTANTS.PATCHIN_ORIGINAL1] = "WAVE IN (2)";
    patchOutLabel[Multiples2to4_CONSTANTS.PATCHOUT_COPY00] = "WAVE OUT (1)";
    patchOutLabel[Multiples2to4_CONSTANTS.PATCHOUT_COPY01] = "WAVE OUT (1)";
    patchOutLabel[Multiples2to4_CONSTANTS.PATCHOUT_COPY02] = "WAVE OUT (1)";
    patchOutLabel[Multiples2to4_CONSTANTS.PATCHOUT_COPY03] = "WAVE OUT (1)";
    patchOutLabel[Multiples2to4_CONSTANTS.PATCHOUT_COPY10] = "WAVE OUT (2)";
    patchOutLabel[Multiples2to4_CONSTANTS.PATCHOUT_COPY11] = "WAVE OUT (2)";
    patchOutLabel[Multiples2to4_CONSTANTS.PATCHOUT_COPY12] = "WAVE OUT (2)";
    patchOutLabel[Multiples2to4_CONSTANTS.PATCHOUT_COPY13] = "WAVE OUT (2)";
  }
  
  //Implement in each component to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public void draw_update()
  {
    //Nothing here yet, knob updates are now done in Knob class (as they should)
  }
}
