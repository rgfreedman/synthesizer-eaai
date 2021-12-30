/*Mixer.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 December 29

Class for a mixer component within a synthesized instrument.
This component simply merges wave inputs to allow all of them in a single output.

NOTE: To allow compact options (for component limit), have a 8->1 and a 4->2 version
NOTE: To complete the instrument output, have an exclusive version for the instrument
*/

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the VCO class below
public static class Mixer8to1_CONSTANTS
{
  //Indeces for input patches - these are the original waves to merge
  public static final int PATCHIN_ORIGINAL0 = 0;
  public static final int PATCHIN_ORIGINAL1 = PATCHIN_ORIGINAL0 + 1;
  public static final int PATCHIN_ORIGINAL2 = PATCHIN_ORIGINAL1 + 1;
  public static final int PATCHIN_ORIGINAL3 = PATCHIN_ORIGINAL2 + 1;
  public static final int PATCHIN_ORIGINAL4 = PATCHIN_ORIGINAL3 + 1;
  public static final int PATCHIN_ORIGINAL5 = PATCHIN_ORIGINAL4 + 1;
  public static final int PATCHIN_ORIGINAL6 = PATCHIN_ORIGINAL5 + 1;
  public static final int PATCHIN_ORIGINAL7 = PATCHIN_ORIGINAL6 + 1;
  public static final int TOTAL_PATCHIN = PATCHIN_ORIGINAL7 + 1;
  
  //Indeces for knobs - these adjust the volume of each input for blending the merged output
  public static final int KNOB_VOL0 = 0;
  public static final int KNOB_VOL1 = KNOB_VOL0 + 1;
  public static final int KNOB_VOL2 = KNOB_VOL1 + 1;
  public static final int KNOB_VOL3 = KNOB_VOL2 + 1;
  public static final int KNOB_VOL4 = KNOB_VOL3 + 1;
  public static final int KNOB_VOL5 = KNOB_VOL4 + 1;
  public static final int KNOB_VOL6 = KNOB_VOL5 + 1;
  public static final int KNOB_VOL7 = KNOB_VOL6 + 1;
  public static final int TOTAL_KNOB = KNOB_VOL7 + 1;
  
  //Indeces for output patches - this is the merged input waveform
  public static final int PATCHOUT_MERGE = 0;
  public static final int TOTAL_PATCHOUT = PATCHOUT_MERGE + 1;
}

public class Mixer8to1 extends SynthComponent
{
  //Internal UGen Objects that compose the component's "circuit"
  //A Summer that will merge the input waveforms
  private Summer blender;
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
  public Mixer8to1()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(Mixer8to1_CONSTANTS.TOTAL_PATCHIN, Mixer8to1_CONSTANTS.TOTAL_PATCHOUT, Mixer8to1_CONSTANTS.TOTAL_KNOB);

    //Now fill in the knobs
    knobs[Mixer8to1_CONSTANTS.KNOB_VOL0] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Mixer8to1_CONSTANTS.KNOB_VOL1] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Mixer8to1_CONSTANTS.KNOB_VOL2] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Mixer8to1_CONSTANTS.KNOB_VOL3] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Mixer8to1_CONSTANTS.KNOB_VOL4] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Mixer8to1_CONSTANTS.KNOB_VOL5] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Mixer8to1_CONSTANTS.KNOB_VOL6] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Mixer8to1_CONSTANTS.KNOB_VOL7] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    
    //Labels for the knobs in the GUI
    knobsLabel[Mixer8to1_CONSTANTS.KNOB_VOL0] = "VOL (0)";
    knobsLabel[Mixer8to1_CONSTANTS.KNOB_VOL1] = "VOL (1)";
    knobsLabel[Mixer8to1_CONSTANTS.KNOB_VOL2] = "VOL (2)";
    knobsLabel[Mixer8to1_CONSTANTS.KNOB_VOL3] = "VOL (3)";
    knobsLabel[Mixer8to1_CONSTANTS.KNOB_VOL4] = "VOL (4)";
    knobsLabel[Mixer8to1_CONSTANTS.KNOB_VOL5] = "VOL (5)";
    knobsLabel[Mixer8to1_CONSTANTS.KNOB_VOL6] = "VOL (6)";
    knobsLabel[Mixer8to1_CONSTANTS.KNOB_VOL7] = "VOL (7)";
    
    //Set up the internals of the component with the UGen elements from Minim
    blender = new Summer();
    volModifier0 = new Multiplier();
    volModifier1 = new Multiplier();
    volModifier2 = new Multiplier();
    volModifier3 = new Multiplier();
    volModifier4 = new Multiplier();
    volModifier5 = new Multiplier();
    volModifier6 = new Multiplier();
    volModifier7 = new Multiplier();
    
    //With the UGens all setup, fill in the external-facing ones for input/output
    patchIn[Mixer8to1_CONSTANTS.PATCHIN_ORIGINAL0] = volModifier0;
    patchIn[Mixer8to1_CONSTANTS.PATCHIN_ORIGINAL1] = volModifier1;
    patchIn[Mixer8to1_CONSTANTS.PATCHIN_ORIGINAL2] = volModifier2;
    patchIn[Mixer8to1_CONSTANTS.PATCHIN_ORIGINAL3] = volModifier3;
    patchIn[Mixer8to1_CONSTANTS.PATCHIN_ORIGINAL4] = volModifier4;
    patchIn[Mixer8to1_CONSTANTS.PATCHIN_ORIGINAL5] = volModifier5;
    patchIn[Mixer8to1_CONSTANTS.PATCHIN_ORIGINAL6] = volModifier6;
    patchIn[Mixer8to1_CONSTANTS.PATCHIN_ORIGINAL7] = volModifier7;
    patchOut[Mixer8to1_CONSTANTS.PATCHOUT_MERGE] = blender;
    
    //Labels for the patches in the GUI
    componentName = "Mixer (8->1)";
    patchInLabel[Mixer8to1_CONSTANTS.PATCHIN_ORIGINAL0] = "WAVE IN (0)";
    patchInLabel[Mixer8to1_CONSTANTS.PATCHIN_ORIGINAL1] = "WAVE IN (1)";
    patchInLabel[Mixer8to1_CONSTANTS.PATCHIN_ORIGINAL2] = "WAVE IN (2)";
    patchInLabel[Mixer8to1_CONSTANTS.PATCHIN_ORIGINAL3] = "WAVE IN (3)";
    patchInLabel[Mixer8to1_CONSTANTS.PATCHIN_ORIGINAL4] = "WAVE IN (4)";
    patchInLabel[Mixer8to1_CONSTANTS.PATCHIN_ORIGINAL5] = "WAVE IN (5)";
    patchInLabel[Mixer8to1_CONSTANTS.PATCHIN_ORIGINAL6] = "WAVE IN (6)";
    patchInLabel[Mixer8to1_CONSTANTS.PATCHIN_ORIGINAL7] = "WAVE IN (7)";
    patchOutLabel[Mixer8to1_CONSTANTS.PATCHOUT_MERGE] = "WAVE OUT";
    
    //Setup the patchwork for the internal components
    knobs[Mixer8to1_CONSTANTS.KNOB_VOL0].getCurrentValue().patch(volModifier0.amplitude);
    knobs[Mixer8to1_CONSTANTS.KNOB_VOL1].getCurrentValue().patch(volModifier1.amplitude);
    knobs[Mixer8to1_CONSTANTS.KNOB_VOL2].getCurrentValue().patch(volModifier2.amplitude);
    knobs[Mixer8to1_CONSTANTS.KNOB_VOL3].getCurrentValue().patch(volModifier3.amplitude);
    knobs[Mixer8to1_CONSTANTS.KNOB_VOL4].getCurrentValue().patch(volModifier4.amplitude);
    knobs[Mixer8to1_CONSTANTS.KNOB_VOL5].getCurrentValue().patch(volModifier5.amplitude);
    knobs[Mixer8to1_CONSTANTS.KNOB_VOL6].getCurrentValue().patch(volModifier6.amplitude);
    knobs[Mixer8to1_CONSTANTS.KNOB_VOL7].getCurrentValue().patch(volModifier7.amplitude);
    volModifier0.patch(blender);
    volModifier1.patch(blender);
    volModifier2.patch(blender);
    volModifier3.patch(blender);
    volModifier4.patch(blender);
    volModifier5.patch(blender);
    volModifier6.patch(blender);
    volModifier7.patch(blender);
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
public static class Mixer4to2_CONSTANTS
{
  //Indeces for input patches - these are the original waves to merge
  public static final int PATCHIN_ORIGINAL0 = 0;
  public static final int PATCHIN_ORIGINAL1 = PATCHIN_ORIGINAL0 + 1;
  public static final int PATCHIN_ORIGINAL2 = PATCHIN_ORIGINAL1 + 1;
  public static final int PATCHIN_ORIGINAL3 = PATCHIN_ORIGINAL2 + 1;
  public static final int PATCHIN_ORIGINAL4 = PATCHIN_ORIGINAL3 + 1;
  public static final int PATCHIN_ORIGINAL5 = PATCHIN_ORIGINAL4 + 1;
  public static final int PATCHIN_ORIGINAL6 = PATCHIN_ORIGINAL5 + 1;
  public static final int PATCHIN_ORIGINAL7 = PATCHIN_ORIGINAL6 + 1;
  public static final int TOTAL_PATCHIN = PATCHIN_ORIGINAL7 + 1;
  
  //Indeces for knobs - these adjust the volume of each input for blending the merged output
  public static final int KNOB_VOL0 = 0;
  public static final int KNOB_VOL1 = KNOB_VOL0 + 1;
  public static final int KNOB_VOL2 = KNOB_VOL1 + 1;
  public static final int KNOB_VOL3 = KNOB_VOL2 + 1;
  public static final int KNOB_VOL4 = KNOB_VOL3 + 1;
  public static final int KNOB_VOL5 = KNOB_VOL4 + 1;
  public static final int KNOB_VOL6 = KNOB_VOL5 + 1;
  public static final int KNOB_VOL7 = KNOB_VOL6 + 1;
  public static final int TOTAL_KNOB = KNOB_VOL7 + 1;
  
  //Indeces for output patches - this is the merged input waveform
  public static final int PATCHOUT_MERGE0 = 0;
  public static final int PATCHOUT_MERGE1 = PATCHOUT_MERGE0 + 1;
  public static final int TOTAL_PATCHOUT = PATCHOUT_MERGE1 + 1;
}

public class Mixer4to2 extends SynthComponent
{
  //Internal UGen Objects that compose the component's "circuit"
  //A Summer that will merge the input waveforms
  private Summer blender0;
  private Summer blender1;
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
  public Mixer4to2()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(Mixer4to2_CONSTANTS.TOTAL_PATCHIN, Mixer4to2_CONSTANTS.TOTAL_PATCHOUT, Mixer4to2_CONSTANTS.TOTAL_KNOB);

    //Now fill in the knobs
    knobs[Mixer4to2_CONSTANTS.KNOB_VOL0] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Mixer4to2_CONSTANTS.KNOB_VOL1] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Mixer4to2_CONSTANTS.KNOB_VOL2] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Mixer4to2_CONSTANTS.KNOB_VOL3] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Mixer4to2_CONSTANTS.KNOB_VOL4] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Mixer4to2_CONSTANTS.KNOB_VOL5] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Mixer4to2_CONSTANTS.KNOB_VOL6] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[Mixer4to2_CONSTANTS.KNOB_VOL7] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    
    //Labels for the knobs in the GUI
    knobsLabel[Mixer4to2_CONSTANTS.KNOB_VOL0] = "VOL (0)";
    knobsLabel[Mixer4to2_CONSTANTS.KNOB_VOL1] = "VOL (1)";
    knobsLabel[Mixer4to2_CONSTANTS.KNOB_VOL2] = "VOL (2)";
    knobsLabel[Mixer4to2_CONSTANTS.KNOB_VOL3] = "VOL (3)";
    knobsLabel[Mixer4to2_CONSTANTS.KNOB_VOL4] = "VOL (4)";
    knobsLabel[Mixer4to2_CONSTANTS.KNOB_VOL5] = "VOL (5)";
    knobsLabel[Mixer4to2_CONSTANTS.KNOB_VOL6] = "VOL (6)";
    knobsLabel[Mixer4to2_CONSTANTS.KNOB_VOL7] = "VOL (7)";
    
    //Set up the internals of the component with the UGen elements from Minim
    blender0 = new Summer();
    blender1 = new Summer();
    volModifier0 = new Multiplier();
    volModifier1 = new Multiplier();
    volModifier2 = new Multiplier();
    volModifier3 = new Multiplier();
    volModifier4 = new Multiplier();
    volModifier5 = new Multiplier();
    volModifier6 = new Multiplier();
    volModifier7 = new Multiplier();
    
    //With the UGens all setup, fill in the external-facing ones for input/output
    patchIn[Mixer4to2_CONSTANTS.PATCHIN_ORIGINAL0] = volModifier0;
    patchIn[Mixer4to2_CONSTANTS.PATCHIN_ORIGINAL1] = volModifier1;
    patchIn[Mixer4to2_CONSTANTS.PATCHIN_ORIGINAL2] = volModifier2;
    patchIn[Mixer4to2_CONSTANTS.PATCHIN_ORIGINAL3] = volModifier3;
    patchIn[Mixer4to2_CONSTANTS.PATCHIN_ORIGINAL4] = volModifier4;
    patchIn[Mixer4to2_CONSTANTS.PATCHIN_ORIGINAL5] = volModifier5;
    patchIn[Mixer4to2_CONSTANTS.PATCHIN_ORIGINAL6] = volModifier6;
    patchIn[Mixer4to2_CONSTANTS.PATCHIN_ORIGINAL7] = volModifier7;
    patchOut[Mixer4to2_CONSTANTS.PATCHOUT_MERGE0] = blender0;
    patchOut[Mixer4to2_CONSTANTS.PATCHOUT_MERGE1] = blender1;
    
    //Labels for the patches in the GUI
    componentName = "Mixer (4->2)";
    patchInLabel[Mixer4to2_CONSTANTS.PATCHIN_ORIGINAL0] = "WAVE IN (0)";
    patchInLabel[Mixer4to2_CONSTANTS.PATCHIN_ORIGINAL1] = "WAVE IN (1)";
    patchInLabel[Mixer4to2_CONSTANTS.PATCHIN_ORIGINAL2] = "WAVE IN (2)";
    patchInLabel[Mixer4to2_CONSTANTS.PATCHIN_ORIGINAL3] = "WAVE IN (3)";
    patchInLabel[Mixer4to2_CONSTANTS.PATCHIN_ORIGINAL4] = "WAVE IN (4)";
    patchInLabel[Mixer4to2_CONSTANTS.PATCHIN_ORIGINAL5] = "WAVE IN (5)";
    patchInLabel[Mixer4to2_CONSTANTS.PATCHIN_ORIGINAL6] = "WAVE IN (6)";
    patchInLabel[Mixer4to2_CONSTANTS.PATCHIN_ORIGINAL7] = "WAVE IN (7)";
    patchOutLabel[Mixer4to2_CONSTANTS.PATCHOUT_MERGE0] = "WAVE OUT (0-3)";
    patchOutLabel[Mixer4to2_CONSTANTS.PATCHOUT_MERGE1] = "WAVE OUT (4-7)";
    
    //Setup the patchwork for the internal components
    knobs[Mixer4to2_CONSTANTS.KNOB_VOL0].getCurrentValue().patch(volModifier0.amplitude);
    knobs[Mixer4to2_CONSTANTS.KNOB_VOL1].getCurrentValue().patch(volModifier1.amplitude);
    knobs[Mixer4to2_CONSTANTS.KNOB_VOL2].getCurrentValue().patch(volModifier2.amplitude);
    knobs[Mixer4to2_CONSTANTS.KNOB_VOL3].getCurrentValue().patch(volModifier3.amplitude);
    knobs[Mixer4to2_CONSTANTS.KNOB_VOL4].getCurrentValue().patch(volModifier4.amplitude);
    knobs[Mixer4to2_CONSTANTS.KNOB_VOL5].getCurrentValue().patch(volModifier5.amplitude);
    knobs[Mixer4to2_CONSTANTS.KNOB_VOL6].getCurrentValue().patch(volModifier6.amplitude);
    knobs[Mixer4to2_CONSTANTS.KNOB_VOL7].getCurrentValue().patch(volModifier7.amplitude);
    volModifier0.patch(blender0);
    volModifier1.patch(blender0);
    volModifier2.patch(blender0);
    volModifier3.patch(blender0);
    volModifier4.patch(blender1);
    volModifier5.patch(blender1);
    volModifier6.patch(blender1);
    volModifier7.patch(blender1);
  }
  
  //Implement in each component to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public void draw_update()
  {
    //Nothing here yet, knob updates are now done in Knob class (as they should)
  }
}
