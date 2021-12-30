/*Mixer.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 December 29

Class for a mixer component within a synthesized instrument.
This component simply merges wave inputs to allow all of them in a single output.

NOTE: To allow compact options (for component limit), have a 8->1 and a 4->2 version
NOTE: To complete the instrument output, have an exclusive version for the instrument
*/

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the Mixer8to1 class below
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
  
  //Indeces for output patches - this is the merged waveform
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
//  This contains the static constants for the Mixer4to2 class below
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
  
  //Indeces for output patches - this is the merged waveform
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

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the MixerInstruments class below
public static class MixerInstrument_CONSTANTS
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
  public static final int PATCHIN_ORIGINAL8 = PATCHIN_ORIGINAL7 + 1;
  public static final int PATCHIN_ORIGINAL9 = PATCHIN_ORIGINAL8 + 1;
  public static final int PATCHIN_ORIGINAL10 = PATCHIN_ORIGINAL9 + 1;
  public static final int PATCHIN_ORIGINAL11 = PATCHIN_ORIGINAL10 + 1;
  public static final int PATCHIN_ORIGINAL12 = PATCHIN_ORIGINAL11 + 1;
  public static final int PATCHIN_ORIGINAL13 = PATCHIN_ORIGINAL12 + 1;
  public static final int PATCHIN_ORIGINAL14 = PATCHIN_ORIGINAL13 + 1;
  public static final int PATCHIN_ORIGINAL15 = PATCHIN_ORIGINAL14 + 1;
  public static final int TOTAL_PATCHIN = PATCHIN_ORIGINAL15 + 1;
  
  //Indeces for knobs - these adjust the volume of each input for blending the merged output
  public static final int KNOB_VOL0 = 0;
  public static final int KNOB_VOL1 = KNOB_VOL0 + 1;
  public static final int KNOB_VOL2 = KNOB_VOL1 + 1;
  public static final int KNOB_VOL3 = KNOB_VOL2 + 1;
  public static final int KNOB_VOL4 = KNOB_VOL3 + 1;
  public static final int KNOB_VOL5 = KNOB_VOL4 + 1;
  public static final int KNOB_VOL6 = KNOB_VOL5 + 1;
  public static final int KNOB_VOL7 = KNOB_VOL6 + 1;
  public static final int KNOB_VOL8 = KNOB_VOL7 + 1;
  public static final int KNOB_VOL9 = KNOB_VOL8 + 1;
  public static final int KNOB_VOL10 = KNOB_VOL9 + 1;
  public static final int KNOB_VOL11 = KNOB_VOL10 + 1;
  public static final int KNOB_VOL12 = KNOB_VOL11 + 1;
  public static final int KNOB_VOL13 = KNOB_VOL12 + 1;
  public static final int KNOB_VOL14 = KNOB_VOL13 + 1;
  public static final int KNOB_VOL15 = KNOB_VOL14 + 1;
  public static final int TOTAL_KNOB = KNOB_VOL15 + 1;
  
  //Indeces for output patches - this is the merged waveform
  public static final int PATCHOUT_MERGE = 0;
  public static final int TOTAL_PATCHOUT = PATCHOUT_MERGE + 1;
}

public class MixerInstrument extends SynthComponent
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
  private Multiplier volModifier8;
  private Multiplier volModifier9;
  private Multiplier volModifier10;
  private Multiplier volModifier11;
  private Multiplier volModifier12;
  private Multiplier volModifier13;
  private Multiplier volModifier14;
  private Multiplier volModifier15;
  
  //Default Constructor - set up all the patches and knobs
  public MixerInstrument()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(MixerInstrument_CONSTANTS.TOTAL_PATCHIN, MixerInstrument_CONSTANTS.TOTAL_PATCHOUT, MixerInstrument_CONSTANTS.TOTAL_KNOB);

    //Now fill in the knobs
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL0] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL1] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL2] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL3] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL4] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL5] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL6] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL7] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL8] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL9] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL10] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL11] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL12] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL13] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL14] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL15] = new Knob(0.0, 2.0); //Volume modification can be in [0,2]
    
    //Labels for the knobs in the GUI
    knobsLabel[MixerInstrument_CONSTANTS.KNOB_VOL0] = "VOL (0)";
    knobsLabel[MixerInstrument_CONSTANTS.KNOB_VOL1] = "VOL (1)";
    knobsLabel[MixerInstrument_CONSTANTS.KNOB_VOL2] = "VOL (2)";
    knobsLabel[MixerInstrument_CONSTANTS.KNOB_VOL3] = "VOL (3)";
    knobsLabel[MixerInstrument_CONSTANTS.KNOB_VOL4] = "VOL (4)";
    knobsLabel[MixerInstrument_CONSTANTS.KNOB_VOL5] = "VOL (5)";
    knobsLabel[MixerInstrument_CONSTANTS.KNOB_VOL6] = "VOL (6)";
    knobsLabel[MixerInstrument_CONSTANTS.KNOB_VOL7] = "VOL (7)";
    knobsLabel[MixerInstrument_CONSTANTS.KNOB_VOL8] = "VOL (8)";
    knobsLabel[MixerInstrument_CONSTANTS.KNOB_VOL9] = "VOL (9)";
    knobsLabel[MixerInstrument_CONSTANTS.KNOB_VOL10] = "VOL (10)";
    knobsLabel[MixerInstrument_CONSTANTS.KNOB_VOL11] = "VOL (11)";
    knobsLabel[MixerInstrument_CONSTANTS.KNOB_VOL12] = "VOL (12)";
    knobsLabel[MixerInstrument_CONSTANTS.KNOB_VOL13] = "VOL (13)";
    knobsLabel[MixerInstrument_CONSTANTS.KNOB_VOL14] = "VOL (14)";
    knobsLabel[MixerInstrument_CONSTANTS.KNOB_VOL15] = "VOL (15)";
    
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
    volModifier8 = new Multiplier();
    volModifier9 = new Multiplier();
    volModifier10 = new Multiplier();
    volModifier11 = new Multiplier();
    volModifier12 = new Multiplier();
    volModifier13 = new Multiplier();
    volModifier14 = new Multiplier();
    volModifier15 = new Multiplier();
    
    //With the UGens all setup, fill in the external-facing ones for input/output
    patchIn[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL0] = volModifier0;
    patchIn[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL1] = volModifier1;
    patchIn[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL2] = volModifier2;
    patchIn[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL3] = volModifier3;
    patchIn[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL4] = volModifier4;
    patchIn[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL5] = volModifier5;
    patchIn[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL6] = volModifier6;
    patchIn[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL7] = volModifier7;
    patchIn[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL8] = volModifier8;
    patchIn[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL9] = volModifier9;
    patchIn[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL10] = volModifier10;
    patchIn[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL11] = volModifier11;
    patchIn[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL12] = volModifier12;
    patchIn[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL13] = volModifier13;
    patchIn[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL14] = volModifier14;
    patchIn[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL15] = volModifier15;
    patchOut[MixerInstrument_CONSTANTS.PATCHOUT_MERGE] = blender;
    
    //Labels for the patches in the GUI
    componentName = "Mixer (to Speaker)";
    patchInLabel[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL0] = "WAVE IN (0)";
    patchInLabel[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL1] = "WAVE IN (1)";
    patchInLabel[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL2] = "WAVE IN (2)";
    patchInLabel[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL3] = "WAVE IN (3)";
    patchInLabel[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL4] = "WAVE IN (4)";
    patchInLabel[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL5] = "WAVE IN (5)";
    patchInLabel[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL6] = "WAVE IN (6)";
    patchInLabel[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL7] = "WAVE IN (7)";
    patchInLabel[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL8] = "WAVE IN (8)";
    patchInLabel[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL9] = "WAVE IN (9)";
    patchInLabel[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL10] = "WAVE IN (10)";
    patchInLabel[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL11] = "WAVE IN (11)";
    patchInLabel[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL12] = "WAVE IN (12)";
    patchInLabel[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL13] = "WAVE IN (13)";
    patchInLabel[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL14] = "WAVE IN (14)";
    patchInLabel[MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL15] = "WAVE IN (15)";
    patchOutLabel[MixerInstrument_CONSTANTS.PATCHOUT_MERGE] = "WAVE OUT";
    
    //Setup the patchwork for the internal components
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL0].getCurrentValue().patch(volModifier0.amplitude);
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL1].getCurrentValue().patch(volModifier1.amplitude);
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL2].getCurrentValue().patch(volModifier2.amplitude);
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL3].getCurrentValue().patch(volModifier3.amplitude);
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL4].getCurrentValue().patch(volModifier4.amplitude);
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL5].getCurrentValue().patch(volModifier5.amplitude);
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL6].getCurrentValue().patch(volModifier6.amplitude);
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL7].getCurrentValue().patch(volModifier7.amplitude);
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL8].getCurrentValue().patch(volModifier8.amplitude);
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL9].getCurrentValue().patch(volModifier9.amplitude);
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL10].getCurrentValue().patch(volModifier10.amplitude);
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL11].getCurrentValue().patch(volModifier11.amplitude);
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL12].getCurrentValue().patch(volModifier12.amplitude);
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL13].getCurrentValue().patch(volModifier13.amplitude);
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL14].getCurrentValue().patch(volModifier14.amplitude);
    knobs[MixerInstrument_CONSTANTS.KNOB_VOL15].getCurrentValue().patch(volModifier15.amplitude);
    volModifier0.patch(blender);
    volModifier1.patch(blender);
    volModifier2.patch(blender);
    volModifier3.patch(blender);
    volModifier4.patch(blender);
    volModifier5.patch(blender);
    volModifier6.patch(blender);
    volModifier7.patch(blender);
    volModifier8.patch(blender);
    volModifier9.patch(blender);
    volModifier10.patch(blender);
    volModifier11.patch(blender);
    volModifier12.patch(blender);
    volModifier13.patch(blender);
    volModifier14.patch(blender);
    volModifier15.patch(blender);
  }
  
  //Implement in each component to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public void draw_update()
  {
    //Nothing here yet, knob updates are now done in Knob class (as they should)
  }
  
  //Override the render command for SynthComponent superclass because this mixer is
  //  very different in design (hide output patches) and should be part of all 
  //  instruments (rather than as a possible component)
  public void render(int xOffset, int yOffset)
  {
    //As the lowest layer of the GUI image for the component,
    //  render the component's box as a rectangle (rather than a component, fills lower border)
    stroke(0, 0, 0); //Black stroke
    fill(128, 128, 128); //light-grey fill
    rect(xOffset, yOffset, Render_CONSTANTS.RIGHT_BORDER_WIDTH, Render_CONSTANTS.RIGHT_BORDER_HEIGHT - Render_CONSTANTS.UPPER_BORDER_HEIGHT - Render_CONSTANTS.LOWER_BORDER_HEIGHT);
    
    //All text should be centered about the specified (x,y) coordinates per text() call
    textAlign(CENTER, CENTER);
    //Like font, set the size of all text on this component (measured in pixels)
    //For simplicity, make the same size as a knob (since portrayed as a slider)
    textSize(Render_CONSTANTS.KNOB_HEIGHT);
    
    //Next, render the component name in the top-center of the component
    if(componentName != null)
    {
      fill(0, 0, 0); //Black text
      text(componentName, xOffset + (Render_CONSTANTS.RIGHT_BORDER_WIDTH / 2), yOffset + Render_CONSTANTS.KNOB_HEIGHT);
    }
    
    //Despite all the output patches, these are to allow instrument polyphony (simultaneous
    //  notes at once) => only allow one of these patches (the first) to be used in the GUI
    //Each patch is a uniformly-sized circle, set to be solid black (like a hole)
    fill(0, 0, 0);
    stroke(0, 0, 0);
    
    //For simplicity, make the labels half the size of a knob (since portrayed as a slider)
    textSize(Render_CONSTANTS.KNOB_HEIGHT / 2);
    
    for(int i = 0; i < ((patchIn != null) ? patchIn.length : 0); i++)
    {
      //Render a patch hole if a patch is defined in this entry
      //  This is to avoid putting a cable into nothing, or can align holes to pretty-print component
      if(patchIn[i] != null)
      {
        //If provided, include label for the patch
        if((patchInLabel != null) && (patchInLabel[i] != null))
        {
          text(patchInLabel[i], xOffset + (Render_CONSTANTS.RIGHT_BORDER_WIDTH / 5), yOffset + Render_CONSTANTS.PATCH_RADIUS + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)));
        }
        //First two values are center, width and height are equal for circle
        ellipse(xOffset + (Render_CONSTANTS.RIGHT_BORDER_WIDTH / 5), yOffset + (3 * Render_CONSTANTS.PATCH_RADIUS) + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)), Render_CONSTANTS.PATCH_DIAMETER, Render_CONSTANTS.PATCH_DIAMETER);
        
        //Also send the center values to the patch cable, if one exists that is plugged into this patch
        if((patchInCable != null) && (patchInCable[i] != null))
        {
          patchInCable[i].setRenderIn(xOffset + (Render_CONSTANTS.RIGHT_BORDER_WIDTH / 5), yOffset + (3 * Render_CONSTANTS.PATCH_RADIUS) + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)));
        }
      }
    }
    
    //Do not render the patch out (merged goes into audio, not a patch itself)
    
    //Now render the knobs, laying them out along the component
    //  Each knob is a rectangle to resemble a slider, including a "cursor" for the position
    for(int i = 0; i < ((knobs != null) ? knobs.length : 0); i++)
    {
      //Render a knob if a patch is defined in this entry
      //  This is to avoid sliding on nothing, or can align knobs to pretty-print component
      if(knobs[i] != null)
      {
        //If provided, include label for the patch
        if((knobsLabel != null) && (knobsLabel[i] != null))
        {
          //Reset colors to black since knob cursor is red, but label should be black
          fill(0, 0, 0);
          stroke(0, 0, 0);
          text(knobsLabel[i], xOffset + ((Render_CONSTANTS.RIGHT_BORDER_WIDTH * 2) / 3), yOffset + (Render_CONSTANTS.KNOB_HEIGHT / 2) + ((i + 1) * 2 * (Render_CONSTANTS.KNOB_HEIGHT + Render_CONSTANTS.VERT_SPACE)));
        }
        //Unlike the ellipse, these are the top-left corner of the rectangle
        knobs[i].render(xOffset + ((Render_CONSTANTS.RIGHT_BORDER_WIDTH * 2) / 3) - (Render_CONSTANTS.KNOB_WIDTH / 2), yOffset + Render_CONSTANTS.KNOB_HEIGHT + ((i + 1) * 2 * (Render_CONSTANTS.KNOB_HEIGHT + Render_CONSTANTS.VERT_SPACE)));
      }
    }
  }
  
  //Override the getElementAt command for SynthComponent superclass because the instrument
  //  mixer is very different in design (hide output patches) and should be part of all 
  //  instruments (rather than as a possible component)
  //Output format is a length-2 integer array: [element_type, index]
  //NOTE: The output format will have some helpful magic numbers defined in Render_CONSTANTS
  //NOTE: The inputs x and y are relative to the top-left corner of this SynthComponent
  public int[] getElementAt(int x, int y)
  {
    //Setup the output array first, fill in just before returning (set to default, the "null")
    int[] toReturn = new int[Render_CONSTANTS.SYNTHCOMPONENT_TOTAL_FOCUS];
    toReturn[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] = Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_NONE;
    toReturn[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX] = -1;
    
    //Before starting, return nothing relevant if outside the bounds of the component
    if((x < 0) || (x >= Render_CONSTANTS.RIGHT_BORDER_WIDTH) || (y < 0) || (y >= (Render_CONSTANTS.RIGHT_BORDER_HEIGHT - Render_CONSTANTS.UPPER_BORDER_HEIGHT - Render_CONSTANTS.LOWER_BORDER_HEIGHT)))
    {
      return toReturn;
    }
    
    //First, consider the point being aligned with some in patch
    if(patchIn != null)
    {
      for(int i = 0; i < patchIn.length; i++)
      {
        //The patch is just a circle
        if(Render_CONSTANTS.circ_contains_point(Render_CONSTANTS.RIGHT_BORDER_WIDTH / 5, (3 * Render_CONSTANTS.PATCH_RADIUS) + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)), Render_CONSTANTS.PATCH_RADIUS, x, y))
        {
          toReturn[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] = Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_PATCHIN;
          toReturn[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX] = i;
          return toReturn;
        }
      }
    }
    //Second, consider the point being aligned with some knob
    if(knobs != null)
    {
      for(int i = 0; i < knobs.length; i++)
      {
        //Because the knob can locally check the point for containment, set the top-left for containment
        if((knobs[i] != null) && knobs[i].contains_point(x - (((Render_CONSTANTS.RIGHT_BORDER_WIDTH * 2) / 3) - (Render_CONSTANTS.KNOB_WIDTH / 2)), y - (Render_CONSTANTS.KNOB_HEIGHT + ((i + 1) * 2 * (Render_CONSTANTS.KNOB_HEIGHT + Render_CONSTANTS.VERT_SPACE)))))
        {
          toReturn[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] = Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_KNOB;
          toReturn[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX] = i;
          return toReturn;
        }
      }
    }
    //Do not consider the point being aligned with some out patch since hidden
    
    //At this point, the point did not fit into any elements => return nothing
    return toReturn;
  }
}
