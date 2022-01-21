/*Multiples.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2022 January 20

Class for a multiples module within a synthesized instrument.
This module simply copies a wave input to allow multiple copies of it as outputs.

NOTE: To allow compact options (for module limit), have a 1->8 and a 2->4 version
*/

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the VCO class below
public static class Multiples1to8_CONSTANTS
{
  //Indeces for input patches - this is the original wave to copy
  public static final int PATCHIN_ORIGINAL = 0;
  public static final int TOTAL_PATCHIN = PATCHIN_ORIGINAL + 1;
  
  //Indeces for knobs - these adjust the volume of each output for attenuation or scaled modulation
  public static final int KNOB_VOL0 = 0;
  public static final int KNOB_VOL1 = KNOB_VOL0 + 1;
  public static final int KNOB_VOL2 = KNOB_VOL1 + 1;
  public static final int KNOB_VOL3 = KNOB_VOL2 + 1;
  public static final int KNOB_VOL4 = KNOB_VOL3 + 1;
  public static final int KNOB_VOL5 = KNOB_VOL4 + 1;
  public static final int KNOB_VOL6 = KNOB_VOL5 + 1;
  public static final int KNOB_VOL7 = KNOB_VOL6 + 1;
  public static final int TOTAL_KNOB = KNOB_VOL7 + 1;
  
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

public class Multiples1to8 extends SynthModule
{
  //Internal UGen Objects that compose the module's "circuit"
  //A Summer that only has one input effectively copies the waveform (like an identity function)
  private Summer identity;
  //Multiplier performs the volume modification to each waveform's volume
  private Multiplier volModifier0;
  private Multiplier volModifier1;
  private Multiplier volModifier2;
  private Multiplier volModifier3;
  private Multiplier volModifier4;
  private Multiplier volModifier5;
  private Multiplier volModifier6;
  private Multiplier volModifier7;
  
  //Default Constructor - set up all the patches and knobs
  public Multiples1to8()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(Multiples1to8_CONSTANTS.TOTAL_PATCHIN, Multiples1to8_CONSTANTS.TOTAL_PATCHOUT, Multiples1to8_CONSTANTS.TOTAL_KNOB);

    //Set up the internals of the module with the UGen elements from Minim
    identity = new Summer();
    volModifier0 = new Multiplier();
    volModifier1 = new Multiplier();
    volModifier2 = new Multiplier();
    volModifier3 = new Multiplier();
    volModifier4 = new Multiplier();
    volModifier5 = new Multiplier();
    volModifier6 = new Multiplier();
    volModifier7 = new Multiplier();
    
    //Now fill in the knobs
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL0] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL1] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL2] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL3] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL4] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL5] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL6] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL7] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    //For the Multiples, should be a default of 1.0 amplitude setting (preserves original input)
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL0].setCurrentPosition(0.5);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL1].setCurrentPosition(0.5);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL2].setCurrentPosition(0.5);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL3].setCurrentPosition(0.5);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL4].setCurrentPosition(0.5);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL5].setCurrentPosition(0.5);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL6].setCurrentPosition(0.5);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL7].setCurrentPosition(0.5);
    
    //Labels for the knobs in the GUI
    knobsLabel[Multiples1to8_CONSTANTS.KNOB_VOL0] = "VOL (0)";
    knobsLabel[Multiples1to8_CONSTANTS.KNOB_VOL1] = "VOL (1)";
    knobsLabel[Multiples1to8_CONSTANTS.KNOB_VOL2] = "VOL (2)";
    knobsLabel[Multiples1to8_CONSTANTS.KNOB_VOL3] = "VOL (3)";
    knobsLabel[Multiples1to8_CONSTANTS.KNOB_VOL4] = "VOL (4)";
    knobsLabel[Multiples1to8_CONSTANTS.KNOB_VOL5] = "VOL (5)";
    knobsLabel[Multiples1to8_CONSTANTS.KNOB_VOL6] = "VOL (6)";
    knobsLabel[Multiples1to8_CONSTANTS.KNOB_VOL7] = "VOL (7)";
    
    //With the UGens all setup, fill in the external-facing ones for input/output
    patchIn[Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL] = identity;
    //Every Multiplier points to the identity input, which mimics that one input as the output
    patchOut[Multiples1to8_CONSTANTS.PATCHOUT_COPY0] = volModifier0;
    patchOut[Multiples1to8_CONSTANTS.PATCHOUT_COPY1] = volModifier1;
    patchOut[Multiples1to8_CONSTANTS.PATCHOUT_COPY2] = volModifier2;
    patchOut[Multiples1to8_CONSTANTS.PATCHOUT_COPY3] = volModifier3;
    patchOut[Multiples1to8_CONSTANTS.PATCHOUT_COPY4] = volModifier4;
    patchOut[Multiples1to8_CONSTANTS.PATCHOUT_COPY5] = volModifier5;
    patchOut[Multiples1to8_CONSTANTS.PATCHOUT_COPY6] = volModifier6;
    patchOut[Multiples1to8_CONSTANTS.PATCHOUT_COPY7] = volModifier7;
    
    //Setup the patchwork for the internal modules
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL0].getCurrentValue().patch(volModifier0.amplitude);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL1].getCurrentValue().patch(volModifier1.amplitude);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL2].getCurrentValue().patch(volModifier2.amplitude);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL3].getCurrentValue().patch(volModifier3.amplitude);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL4].getCurrentValue().patch(volModifier4.amplitude);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL5].getCurrentValue().patch(volModifier5.amplitude);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL6].getCurrentValue().patch(volModifier6.amplitude);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL7].getCurrentValue().patch(volModifier7.amplitude);
    identity.patch(volModifier0);
    identity.patch(volModifier1);
    identity.patch(volModifier2);
    identity.patch(volModifier3);
    identity.patch(volModifier4);
    identity.patch(volModifier5);
    identity.patch(volModifier6);
    identity.patch(volModifier7);
  
    //Labels for the patches in the GUI
    moduleName = "Multiples (1->8)";
    patchInLabel[Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL] = "IN (0-7)";
    patchOutLabel[Multiples1to8_CONSTANTS.PATCHOUT_COPY0] = "OUT (0)";
    patchOutLabel[Multiples1to8_CONSTANTS.PATCHOUT_COPY1] = "OUT (1)";
    patchOutLabel[Multiples1to8_CONSTANTS.PATCHOUT_COPY2] = "OUT (2)";
    patchOutLabel[Multiples1to8_CONSTANTS.PATCHOUT_COPY3] = "OUT (3)";
    patchOutLabel[Multiples1to8_CONSTANTS.PATCHOUT_COPY4] = "OUT (4)";
    patchOutLabel[Multiples1to8_CONSTANTS.PATCHOUT_COPY5] = "OUT (5)";
    patchOutLabel[Multiples1to8_CONSTANTS.PATCHOUT_COPY6] = "OUT (6)";
    patchOutLabel[Multiples1to8_CONSTANTS.PATCHOUT_COPY7] = "OUT (7)";
  }
  
  //Implement in each module to do any per-draw-iteration updates
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
  //NOTE: Offset in index allows nicer spacing
  public static final int PATCHIN_ORIGINAL0 = 0;
  public static final int PATCHIN_ORIGINAL1 = 4; //PATCHIN_ORIGINAL0 + 1;
  public static final int TOTAL_PATCHIN = PATCHIN_ORIGINAL1 + 1;
  
  //Indeces for knobs - these adjust the volume of each output for attenuation or scaled modulation
  public static final int KNOB_VOL0 = 0;
  public static final int KNOB_VOL1 = KNOB_VOL0 + 1;
  public static final int KNOB_VOL2 = KNOB_VOL1 + 1;
  public static final int KNOB_VOL3 = KNOB_VOL2 + 1;
  public static final int KNOB_VOL4 = KNOB_VOL3 + 1;
  public static final int KNOB_VOL5 = KNOB_VOL4 + 1;
  public static final int KNOB_VOL6 = KNOB_VOL5 + 1;
  public static final int KNOB_VOL7 = KNOB_VOL6 + 1;
  public static final int TOTAL_KNOB = KNOB_VOL7 + 1;
  
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

public class Multiples2to4 extends SynthModule
{
  //Internal UGen Objects that compose the module's "circuit"
  //A Summer that only has one input effectively copies the waveform (like an identity function)
  private Summer identity0;
  private Summer identity1;
  //Multiplier performs the volume modification to each waveform's volume
  private Multiplier volModifier0;
  private Multiplier volModifier1;
  private Multiplier volModifier2;
  private Multiplier volModifier3;
  private Multiplier volModifier4;
  private Multiplier volModifier5;
  private Multiplier volModifier6;
  private Multiplier volModifier7;
  
  //Default Constructor - set up all the patches and knobs
  public Multiples2to4()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(Multiples2to4_CONSTANTS.TOTAL_PATCHIN, Multiples2to4_CONSTANTS.TOTAL_PATCHOUT, Multiples2to4_CONSTANTS.TOTAL_KNOB);

    //Set up the internals of the module with the UGen elements from Minim
    identity0 = new Summer();
    identity1 = new Summer();
    volModifier0 = new Multiplier();
    volModifier1 = new Multiplier();
    volModifier2 = new Multiplier();
    volModifier3 = new Multiplier();
    volModifier4 = new Multiplier();
    volModifier5 = new Multiplier();
    volModifier6 = new Multiplier();
    volModifier7 = new Multiplier();
    
     //Now fill in the knobs
    knobs[Multiples2to4_CONSTANTS.KNOB_VOL0] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Multiples2to4_CONSTANTS.KNOB_VOL1] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Multiples2to4_CONSTANTS.KNOB_VOL2] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Multiples2to4_CONSTANTS.KNOB_VOL3] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Multiples2to4_CONSTANTS.KNOB_VOL4] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Multiples2to4_CONSTANTS.KNOB_VOL5] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Multiples2to4_CONSTANTS.KNOB_VOL6] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Multiples2to4_CONSTANTS.KNOB_VOL7] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    //For the Multiples, should be a default of 1.0 amplitude setting (preserves original input)
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL0].setCurrentPosition(0.5);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL1].setCurrentPosition(0.5);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL2].setCurrentPosition(0.5);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL3].setCurrentPosition(0.5);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL4].setCurrentPosition(0.5);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL5].setCurrentPosition(0.5);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL6].setCurrentPosition(0.5);
    knobs[Multiples1to8_CONSTANTS.KNOB_VOL7].setCurrentPosition(0.5);
    
    //Labels for the knobs in the GUI
    knobsLabel[Multiples2to4_CONSTANTS.KNOB_VOL0] = "VOL (0)";
    knobsLabel[Multiples2to4_CONSTANTS.KNOB_VOL1] = "VOL (1)";
    knobsLabel[Multiples2to4_CONSTANTS.KNOB_VOL2] = "VOL (2)";
    knobsLabel[Multiples2to4_CONSTANTS.KNOB_VOL3] = "VOL (3)";
    knobsLabel[Multiples2to4_CONSTANTS.KNOB_VOL4] = "VOL (4)";
    knobsLabel[Multiples2to4_CONSTANTS.KNOB_VOL5] = "VOL (5)";
    knobsLabel[Multiples2to4_CONSTANTS.KNOB_VOL6] = "VOL (6)";
    knobsLabel[Multiples2to4_CONSTANTS.KNOB_VOL7] = "VOL (7)";
    
    //With the UGens all setup, fill in the external-facing ones for input/output
    patchIn[Multiples2to4_CONSTANTS.PATCHIN_ORIGINAL0] = identity0;
    patchIn[Multiples2to4_CONSTANTS.PATCHIN_ORIGINAL1] = identity1;
    //Every Multiplier points to the identity input, which mimics that one input as the output
    patchOut[Multiples2to4_CONSTANTS.PATCHOUT_COPY00] = volModifier0;
    patchOut[Multiples2to4_CONSTANTS.PATCHOUT_COPY01] = volModifier1;
    patchOut[Multiples2to4_CONSTANTS.PATCHOUT_COPY02] = volModifier2;
    patchOut[Multiples2to4_CONSTANTS.PATCHOUT_COPY03] = volModifier3;
    patchOut[Multiples2to4_CONSTANTS.PATCHOUT_COPY10] = volModifier4;
    patchOut[Multiples2to4_CONSTANTS.PATCHOUT_COPY11] = volModifier5;
    patchOut[Multiples2to4_CONSTANTS.PATCHOUT_COPY12] = volModifier6;
    patchOut[Multiples2to4_CONSTANTS.PATCHOUT_COPY13] = volModifier7;
    
    //Setup the patchwork for the internal modules
    knobs[Multiples2to4_CONSTANTS.KNOB_VOL0].getCurrentValue().patch(volModifier0.amplitude);
    knobs[Multiples2to4_CONSTANTS.KNOB_VOL1].getCurrentValue().patch(volModifier1.amplitude);
    knobs[Multiples2to4_CONSTANTS.KNOB_VOL2].getCurrentValue().patch(volModifier2.amplitude);
    knobs[Multiples2to4_CONSTANTS.KNOB_VOL3].getCurrentValue().patch(volModifier3.amplitude);
    knobs[Multiples2to4_CONSTANTS.KNOB_VOL4].getCurrentValue().patch(volModifier4.amplitude);
    knobs[Multiples2to4_CONSTANTS.KNOB_VOL5].getCurrentValue().patch(volModifier5.amplitude);
    knobs[Multiples2to4_CONSTANTS.KNOB_VOL6].getCurrentValue().patch(volModifier6.amplitude);
    knobs[Multiples2to4_CONSTANTS.KNOB_VOL7].getCurrentValue().patch(volModifier7.amplitude);
    identity0.patch(volModifier0);
    identity0.patch(volModifier1);
    identity0.patch(volModifier2);
    identity0.patch(volModifier3);
    identity1.patch(volModifier4);
    identity1.patch(volModifier5);
    identity1.patch(volModifier6);
    identity1.patch(volModifier7);
  
    //Labels for the patches in the GUI
    moduleName = "Multiples (2->4)";
    patchInLabel[Multiples2to4_CONSTANTS.PATCHIN_ORIGINAL0] = "IN (0-3)";
    patchInLabel[Multiples2to4_CONSTANTS.PATCHIN_ORIGINAL1] = "IN (4-7)";
    patchOutLabel[Multiples2to4_CONSTANTS.PATCHOUT_COPY00] = "OUT (0)";
    patchOutLabel[Multiples2to4_CONSTANTS.PATCHOUT_COPY01] = "OUT (1)";
    patchOutLabel[Multiples2to4_CONSTANTS.PATCHOUT_COPY02] = "OUT (2)";
    patchOutLabel[Multiples2to4_CONSTANTS.PATCHOUT_COPY03] = "OUT (3)";
    patchOutLabel[Multiples2to4_CONSTANTS.PATCHOUT_COPY10] = "OUT (4)";
    patchOutLabel[Multiples2to4_CONSTANTS.PATCHOUT_COPY11] = "OUT (5)";
    patchOutLabel[Multiples2to4_CONSTANTS.PATCHOUT_COPY12] = "OUT (6)";
    patchOutLabel[Multiples2to4_CONSTANTS.PATCHOUT_COPY13] = "OUT (7)";
  }
  
  //Implement in each module to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public void draw_update()
  {
    //Nothing here yet, knob updates are now done in Knob class (as they should)
  }
}
