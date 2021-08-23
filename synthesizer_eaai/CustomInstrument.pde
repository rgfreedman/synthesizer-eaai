/*CustomInstrument.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 August 22

Class for a synthesized instrument.  Rather than pre-designed content, the components
are loosely available for patching and adjusting during execution!  The patching order
is maintained using a tree-like data structure (parent patches into all children).
Because of recursive nature of patching, it seems easier to implement the tree as a 
map from the parent to a list of children.
*/

import java.util.HashMap;
import java.util.ArrayList;

public class CustomInstrument implements Instrument
{
  //Encode the tree object, including the root as the starting point for patching
  private HashMap<UGen, ArrayList<UGen>> patchTree;
  private SynthComponent[] components;
  //Keep track of the patches through copies of the pointers
  private PatchCable[] patches;
  //private UGen root;
  private SynthComponent root;
  
  //Unique feature outside tree data structure is that the leaves producing audio all
  //  patch to the Summer UGen (which adds the soundwaves together) for output
  private Summer toAudioOutput;
  
  public CustomInstrument()
  {
    //Initialize the map, but there are no components yet to set up mappings
    patchTree = new HashMap();
    root = null;
    
    //Initialize the summer so that there is something that tries to play when ready
    toAudioOutput = new Summer();
  }
  
  //Methods needed for the Instrument interface
  
  //Patch the summer with the final components of the patch tree (the leaves)
  //  to the audio output [a.k.a. plug the instrument's local Summer into the
  //  global Summer that's plugged into the output]
  public void noteOn(float dur)
  {
    toAudioOutput.patch(allInstruments_toOut);
  }
  
  //Unpatch the summer from the audio output [a.k.a. unplug the local Summer 
  //  from the global Summer that's plugged into the output]
  public void noteOff()
  {
    toAudioOutput.unpatch(allInstruments_toOut);
  }
  
  //Performs updates to the instrument (via updates to each component) in the draw iteration
  public void draw_update()
  {
    //Allow each component (root should be redundant) to update
    for(int i = 0; i < components.length; i++)
    {
      components[i].draw_update();
    }
  }
  
  //Used to setup a simple preloaded patch, intended to make debugging quick
  public void setupDebugPatch()
  {
    //Toggle the component tests, but ideally just one to avoid variable overwriting!
    //setupDebugVCO();
    //setupDebugLFO();
    //setupDebugPower();
    //setupDebugNoiseGenerator();
    //setupDebugPatchCable();
    //setupDebugMultiples();
    //setupDebugVCA();
    setupDebugEG_ADSR();
    
    //Just patch an oscilator at a constant frequency directly to the local Summer
    //root = new Oscil(Frequency.ofPitch("A4"), 1, Waves.SQUARE);
    //root.patch(toAudioOutput);
  }
  
  public void drawDebugPatch()
  {
    //Toggle the component tests, but ideally just one to avoid variable overwriting!
    //drawDebugVCO();
    //drawDebugLFO();
    //drawDebugPower();
    //drawDebugNoiseGenerator();
    //drawDebugPatchCable();
    //drawDebugMultiples();
    //drawDebugVCA();
    drawDebugEG_ADSR();
  }

  /*--For debugging of components, setup and draw functions that specifically test them--*/
  private void setupDebugVCO()
  {
    root = new VCO();
    components = new SynthComponent[1];
    components[0] = root;
    root.getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput);
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.patch(allInstruments_toOut);
  }
  private void drawDebugVCO()
  {
    root.getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)mouseX / (float)width);
    root.getKnob(VCO_CONSTANTS.KNOB_AMP).setCurrentPosition((float)mouseY / (float)height);
    draw_update();
  }
  
  private void setupDebugLFO()
  {
    root = new LFO();
    components = new SynthComponent[2];
    components[0] = root;
    components[1] = new VCO();
    //Patch the VCO to the speaker and the LFO to the VCO's amplitude (for tremolo effect)
    root.getPatchOut(LFO_CONSTANTS.PATCHOUT_SINE).patch(components[1].getPatchIn(VCO_CONSTANTS.PATCHIN_AMP));
    components[1].getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput);
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.patch(allInstruments_toOut);
    
    //To have the VCO kept constant, set the VCO knobs once and leave alone afterwards
    components[1].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition(440.0 / 6000.0); //NOTE: Maybe allow knob to be directly set to a value?
  }
  private void drawDebugLFO()
  {
    root.getKnob(LFO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)mouseX / (float)width);
    root.getKnob(LFO_CONSTANTS.KNOB_AMP).setCurrentPosition((float)mouseY / (float)height);
    draw_update();
  }
  
  private void setupDebugPower()
  {
    root = new Power();
    components = new SynthComponent[2];
    components[0] = root;
    components[1] = new VCO();
    //Patch the VCO to the speaker and the LFO to the VCO's amplitude (for tremolo effect)
    root.getPatchOut(Power_CONSTANTS.PATCHOUT_POWER).patch(components[1].getPatchIn(VCO_CONSTANTS.PATCHIN_FREQ));
    components[1].getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput);
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.patch(allInstruments_toOut);
    
    //To have the VCO kept constant, set the VCO knobs once and leave alone afterwards
    components[1].getKnob(VCO_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0); //NOTE: Maybe allow knob to be directly set to a value?
  }
  private void drawDebugPower()
  {
    root.getKnob(Power_CONSTANTS.KNOB_POWER).setCurrentPosition((float)mouseX / (float)width);
    draw_update();
  }
  
  private void setupDebugNoiseGenerator()
  {
    root = new NoiseGenerator();
    components = new SynthComponent[1];
    components[0] = root;
    root.getPatchOut(NoiseGenerator_CONSTANTS.PATCHOUT_PINK).patch(toAudioOutput);
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.patch(allInstruments_toOut);
  }
  private void drawDebugNoiseGenerator()
  {
    root.getKnob(NoiseGenerator_CONSTANTS.KNOB_AMP).setCurrentPosition((float)mouseY / (float)height);
    draw_update();
  }
  
  private void setupDebugPatchCable()
  {
    root = new LFO();
    components = new SynthComponent[2];
    components[0] = root;
    components[1] = new VCO();
    //Patch cable assigns itself and we do not need to track it (so it can garbage collect if replaced)
    //  => simply instantiate it without assigning to a variable
    patches = new PatchCable[1];
    patches[0] = new PatchCable(components[0], LFO_CONSTANTS.PATCHOUT_TRIANGLE, components[1], VCO_CONSTANTS.PATCHIN_AMP);
    //Patch cable still cannot connect to speaker since it is not a component... perhaps worth making it one?
    components[1].getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput);
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.patch(allInstruments_toOut);
    
    //Force the LFO to have max amplitude for maximum tremolo
    root.getKnob(LFO_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0);
  }
  private void drawDebugPatchCable()
  {
    components[1].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)mouseX / (float)width);
    root.getKnob(LFO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)mouseY / (float)height);
    draw_update();
  }
  
  private void setupDebugMultiples()
  {
    //For test purposes, patch the LFO to three different oscillators for a synced chord
    //  with dynamic rate of tremolo
    root = new LFO();
    components = new SynthComponent[5];
    components[0] = root;
    components[1] = new Multiples();
    components[2] = new VCO();
    components[3] = new VCO();
    components[4] = new VCO();
    patches = new PatchCable[4];
    patches[0] = new PatchCable(components[0], LFO_CONSTANTS.PATCHOUT_TRIANGLE, components[1], Multiples_CONSTANTS.PATCHIN_ORIGINAL);
    patches[1] = new PatchCable(components[1], Multiples_CONSTANTS.PATCHOUT_COPY0, components[2], VCO_CONSTANTS.PATCHIN_AMP);
    patches[2] = new PatchCable(components[1], Multiples_CONSTANTS.PATCHOUT_COPY1, components[3], VCO_CONSTANTS.PATCHIN_AMP);
    patches[3] = new PatchCable(components[1], Multiples_CONSTANTS.PATCHOUT_COPY2, components[4], VCO_CONSTANTS.PATCHIN_AMP);
    //Patch cable still cannot connect to speaker since it is not a component... perhaps worth making it one?
    components[2].getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput);
    components[3].getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput);
    components[4].getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput);
    //Set the frequency knobs of the VCOs to be constant, forcing a harmonic chord
    components[2].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)440 / (float)components[2].getKnob(VCO_CONSTANTS.KNOB_FREQ).getMaximumValue());
    components[3].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)(440 * pow(pow(2,1.0/12.0),5)) / (float)components[3].getKnob(VCO_CONSTANTS.KNOB_FREQ).getMaximumValue());
    components[4].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)(440 * pow(pow(2,1.0/12.0),9)) / (float)components[4].getKnob(VCO_CONSTANTS.KNOB_FREQ).getMaximumValue());
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.patch(allInstruments_toOut);
    
    //Force the LFO to have max amplitude for maximum tremolo
    root.getKnob(LFO_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0);
  }
  private void drawDebugMultiples()
  {
    root.getKnob(LFO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)mouseY / (float)height);
    draw_update();
  }
  
  private void setupDebugVCA()
  {
    //Rather than another boring volume change, let's use the extremely large amplitudes
    //  for a noticeable frequency modulation!
    root = new VCO();
    components = new SynthComponent[3];
    components[0] = root;
    components[1] = new VCA();
    components[2] = new VCO();
    patches = new PatchCable[2];
    patches[0] = new PatchCable(components[0], VCO_CONSTANTS.PATCHOUT_SINE, components[1], VCA_CONSTANTS.PATCHIN_WAVE);
    patches[1] = new PatchCable(components[1], VCA_CONSTANTS.PATCHOUT_WAVE, components[2], VCO_CONSTANTS.PATCHIN_FREQ);
    //Patch cable still cannot connect to speaker since it is not a component... perhaps worth making it one?
    components[2].getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput);
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.patch(allInstruments_toOut);
    
    //Force the non-modulated knobs to have fixed values for testing purposes
    root.getKnob(VCO_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0);
    components[2].getKnob(VCO_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0);
    components[2].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)440 / (float)components[2].getKnob(VCO_CONSTANTS.KNOB_FREQ).getMaximumValue()); //Need a base frequency
  }
  private void drawDebugVCA()
  {
    root.getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)mouseY / (float)height);
    components[1].getKnob(VCA_CONSTANTS.KNOB_AMP).setCurrentPosition((float)mouseX / (float)width);
    draw_update();
  }
  
  private void setupDebugEG_ADSR()
  {
    root = new Power(); //Pseudo-keyboard, will flip like a switch instead of knob
    components = new SynthComponent[4];
    components[0] = root;
    components[1] = new VCO();
    components[2] = new Multiples(); //Will copy the power to use for frequency and gate
    components[3] = new EnvelopeGenerator();
    patches = new PatchCable[4];
    patches[0] = new PatchCable(components[0], Power_CONSTANTS.PATCHOUT_POWER, components[2], Multiples_CONSTANTS.PATCHIN_ORIGINAL);
    patches[1] = new PatchCable(components[2], Multiples_CONSTANTS.PATCHOUT_COPY0, components[1], VCO_CONSTANTS.PATCHIN_FREQ);
    //patches[2] = new PatchCable(components[2], Multiples_CONSTANTS.PATCHOUT_COPY1, components[3], EnvelopeGenerator_CONSTANTS.GATE_PLAYNOTE);
    patches[2] = new PatchCable(components[2], Multiples_CONSTANTS.PATCHOUT_COPY1, components[3], EnvelopeGenerator_CONSTANTS.PATCHIN_GATE);
    patches[3] = new PatchCable(components[1], VCO_CONSTANTS.PATCHOUT_SQUARE, components[3], EnvelopeGenerator_CONSTANTS.PATCHIN_WAVE);
    
    //Patch cable still cannot connect to speaker since it is not a component... perhaps worth making it one?
    components[3].getPatchOut(EnvelopeGenerator_CONSTANTS.PATCHOUT_WAVE).patch(toAudioOutput);
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.patch(allInstruments_toOut);
    
    //Force the unmodified knobs to have fixed values for testing purposes (ADSR has too many on its own)
    components[1].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition(0.0); //Only Power sets the frequency
    components[1].getKnob(VCO_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0);
    components[3].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_STARTAMP).setCurrentPosition(0.0);
    components[3].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_ENDAMP).setCurrentPosition(0.0);
    components[3].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_MAXAMP).setCurrentPosition(1.0);
    components[3].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_SUSTAIN).setCurrentPosition(0.5);
    components[3].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_DECAY).setCurrentPosition(0.333333); //Since [0,3], this should be about 1 second
  }
  private void drawDebugEG_ADSR()
  {
    //Set the attack and release based on the mouse position
    components[3].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_ATTACK).setCurrentPosition((float)mouseX / (float)width);
    components[3].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_RELEASE).setCurrentPosition((float)mouseY / (float)height);
    //Use the square brackets to set the power knob, acting more like a switch flip
    if(key == '[')
    {
      components[0].getKnob(Power_CONSTANTS.KNOB_POWER).setCurrentPosition((float)440 / (float)components[0].getKnob(Power_CONSTANTS.KNOB_POWER).getMaximumValue());
      System.out.println("Turn on the power!");
    }
    else if(key == ']')
    {
      components[0].getKnob(Power_CONSTANTS.KNOB_POWER).setCurrentPosition(0.0);
      System.out.println("Turn off the power!");
    }
    draw_update();
  }
}
