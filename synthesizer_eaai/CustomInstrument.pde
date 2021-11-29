/*CustomInstrument.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 November 28

Class for a synthesized instrument.  Rather than pre-designed content, the components
are loosely available for patching and adjusting during execution!  The patching order
is maintained using a tree-like data structure (parent patches into all children).
Because of recursive nature of patching, it seems easier to implement the tree as a 
map from the parent to a list of children.
*/

import java.util.HashMap;
import java.util.ArrayList;

import java.lang.Exception; //Needed for a special case that should only scream at the code developers for not keeping features up-to-date, not at anyone using the code as-is

public class CustomInstrument implements Instrument
{
  //NOTE: Keep patchTree, components, patches, and root for DEBUG legacy only---no longer used in the actual code
  //Encode the tree object, including the root as the starting point for patching
  private HashMap<UGen, ArrayList<UGen>> patchTree;
  private SynthComponent[] components;
  //Keep track of the patches through copies of the pointers
  private PatchCable[] patches;
  //private UGen root;
  private SynthComponent root;
  
  //All components and patch cables are stored in respective ArrayList objects for dynamic support
  private ArrayList<SynthComponent> componentsList;
  private ArrayList<PatchCable> patchesList;
  //The one exception is the keyboard, which is included as a default component outside the list
  private Keyboard keyboard;
  
  //In order to capture polyphony (simultaneous keyboard notes at once), need copies of
  //  the instrument, each using a unique keyboard out patch
  //This means we need to apply changes in the instrument across all copies; synced via a map
  private HashMap<SynthComponent, SynthComponent[]> polyphonicCompClones;
  private HashMap<PatchCable, PatchCable[]> polyphonicPatchClones;
  
  //Unique feature outside tree data structure is that the leaves producing audio all
  //  patch to the Summer UGen (which adds the soundwaves together) for output
  private Summer toAudioOutput;
  
  public CustomInstrument()
  {
    //Initialize the map, but there are no components yet to set up mappings (outdated, keep for debug code legacy)
    patchTree = new HashMap();
    root = null;
    
    //Initialize data structures that will store the synth components (currently used)
    componentsList = new ArrayList();
    patchesList = new ArrayList();
    keyboard = new Keyboard();
    
    //Initialize the polyphonic clone data structure, which will interact with the keyboard
    polyphonicCompClones = new HashMap();
    polyphonicPatchClones = new HashMap();
    
    //Initialize the summer so that there is something that tries to play when ready
    toAudioOutput = new Summer();
    
    //Due to the design of this synthesizer, patching is maintained even when notes do not play
    toAudioOutput.patch(allInstruments_toOut);
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
    //Allow each component to update
    for(int i = 0; i < componentsList.size(); i++)
    {
      //Make sure the component exists first (just in case it is null)
      if(componentsList.get(i) != null)
      {
        componentsList.get(i).draw_update();
      }
    }
    
    //The keyboard is standalone => call its update separately
    if(keyboard != null)
    {
      keyboard.draw_update();
    }
  }
  
  //Renders the components of this instrument
  public void render()
  {
    //Need to compute global position of component in GUI
    int xOffset = Render_CONSTANTS.LEFT_BORDER_WIDTH;
    int yOffset = Render_CONSTANTS.UPPER_BORDER_HEIGHT;
    int horizSlot = 0;
    int vertSlot = 0;
    
    //Iterate over components and calculate their global offset (since rendered locally)
    for(int i = 0; i < componentsList.size(); i++)
    {
      //Make sure the component exists first (just in case it is null)
      if(componentsList.get(i) != null)
      {
        componentsList.get(i).render(xOffset, yOffset);
      }
      
      //Shift offsets based on tiled components
      horizSlot++;
      if(horizSlot >= Render_CONSTANTS.TILE_HORIZ_COUNT)
      {
        horizSlot = 0;
        vertSlot++;
        xOffset = Render_CONSTANTS.LEFT_BORDER_WIDTH;
        yOffset += Render_CONSTANTS.COMPONENT_HEIGHT;
        
        //If the vertical offset is too great, then abandon generating more components
        if(vertSlot >= Render_CONSTANTS.TILE_VERT_COUNT)
        {
          break;
        }
      }
      else
      {
        xOffset += Render_CONSTANTS.COMPONENT_WIDTH;
      }
    }
    
    //The keyboard is standalone => call its render separately
    if(keyboard != null)
    {
      keyboard.render(Render_CONSTANTS.APP_WIDTH - Render_CONSTANTS.LOWER_BORDER_WIDTH, Render_CONSTANTS.APP_HEIGHT - Render_CONSTANTS.LOWER_BORDER_HEIGHT);
    }
    
    //Iterate over patches (they are rendered globally)
    for(int i = 0; i < patchesList.size(); i++)
    {
      //Make sure the component exists first (just in case it is null)
      if(patchesList.get(i) != null)
      {
        patchesList.get(i).render();
      }
    }
  }
  
  //For polyphonic purposes, create a synth component's clones all at once when setting up
  //  Each has an input parameter for the component
  //  Each returns a boolean, which is false when there are no more synth component slots
  public boolean addSynthComponent(SynthComponent sc) throws Exception
  {
    //Do not continue any further if out of synth components
    if(componentsList.size() >= Render_CONSTANTS.MAX_SYNTH_COMPONENTS)
    {
      return false;
    }
    
    //Append the component to the list
    componentsList.add(sc);
    
    //Now produce the clones as an array and then map them all together
    SynthComponent[] scClones = new SynthComponent[Keyboard_CONSTANTS.TOTAL_PATCHOUT];
    //First entry is the identity, which aligns the keyboard out patch indeces for polyphony
    scClones[Keyboard_CONSTANTS.PATCHOUT_KEY0] = sc;
    for(int i = Keyboard_CONSTANTS.PATCHOUT_KEY1; i < scClones.length; i++)
    {
      //NOTE: Need to prepare additional cases if more SynthComponent subclasses are ever made!
      if(sc instanceof EnvelopeGenerator)
      {
        scClones[i] = new EnvelopeGenerator();
      }
      if(sc instanceof Keyboard)
      {
        //The one exception to the rule... keyboards should be unique and external to this portion
        throw new Exception("Cannot include a Keyboard or its subclass (" + sc.getClass() + ") in instrument");
      }
      else if(sc instanceof LFO)
      {
        scClones[i] = new LFO();
      }
      else if(sc instanceof Multiples)
      {
        scClones[i] = new Multiples();
      }
      else if(sc instanceof NoiseGenerator)
      {
        scClones[i] = new NoiseGenerator();
      }
      else if(sc instanceof Power)
      {
        scClones[i] = new Power();
      }
      else if(sc instanceof VCA)
      {
        scClones[i] = new VCA();
      }
      else if(sc instanceof VCF)
      {
        scClones[i] = new VCF();
      }
      else if(sc instanceof VCO)
      {
        scClones[i] = new VCO();
      }
      else
      {
        throw new Exception("No such subclass of SynthComponent: " + sc.getClass());
      }
      
      //Set the unique name to be a numbered clone (just in case it appears in the GUI)
      scClones[i].setUniqueName(sc.getUniqueName() + " [Clone #" + i + "]");
    }
    
    //Set up the mapping for future use when syncing changes to the instrument
    polyphonicCompClones.put(sc, scClones);
    
    //By this point, the cloning was successful
    return true;
  }
  
  //For polyphonic purposes, create a patch cable's clones all at once when setting up
  //  Each has an input parameter for the patch cable
  //  Due to limitless patches, returns true only
  public boolean addPatchCable(PatchCable pc)
  {
    //Append the component to the list
    patchesList.add(pc);
    
    //Now produce the clones as an array and then map them all together
    PatchCable[] pcClones = new PatchCable[Keyboard_CONSTANTS.TOTAL_PATCHOUT];
    //First entry is the identity, which aligns the keyboard out patch indeces for polyphony
    pcClones[Keyboard_CONSTANTS.PATCHOUT_KEY0] = pc;
    for(int i = Keyboard_CONSTANTS.PATCHOUT_KEY1; i < pcClones.length; i++)
    {
      pcClones[i] = new PatchCable();
    }
    
    //Set up the mapping for future use when syncing changes to the instrument
    polyphonicPatchClones.put(pc, pcClones);
    
    //We will reach this point no matter what, but follow suit of cloning synth components
    return true;
  }
  
  //To maintain polyphony, apply changes to all cloned instruments as well as ordinary ones
  //Return false when the setting fails (non-existent component OR non-existent thing to change)
  public boolean setKnob(int componentIndex, int knobIndex, float position)
  {
    //Cannot set a component if its index does not exist
    if((componentIndex < componentsList.size()) || (componentIndex >= componentsList.size()))
    {
      return false;
    }
    
    //Work with reference to the component because we will use it several times
    SynthComponent sc = componentsList.get(componentIndex);
    
    //Cannot set the knob if it does not exist, the accessor would return null
    if(sc.getKnob(knobIndex) == null)
    {
      return false;
    }
    
    //Iterate over all the clones (first clone is the original sc) and set the knob value
    for(SynthComponent scClone : polyphonicCompClones.get(sc))
    {
      scClone.getKnob(knobIndex).setCurrentPosition(position);
    }
    
    //Knob settings complete---return true for success!
    return true;
  }
  
  //To maintain polyphony, apply changes to all cloned instruments as well as ordinary ones
  //Return false when the setting fails (non-existent component OR non-existent thing to change)
  public boolean setPatchOut(int componentIndex, int patchoutIndex, PatchCable pc)
  {
    //Cannot set a component if its index does not exist
    if((componentIndex < componentsList.size()) || (componentIndex >= componentsList.size()))
    {
      return false;
    }
    
    //Work with reference to the component because we will use it several times
    SynthComponent sc = componentsList.get(componentIndex);
    
    //Cannot set the patchOut if it does not exist, the accessor would return null
    if(sc.getPatchOut(patchoutIndex) == null)
    {
      return false;
    }
    
    //Also cannot plug into a patch if it already has another cable plugged in (already being plugged in itself is fine)
    if((sc.getCableOut(patchoutIndex) != null) || (sc.getCableOut(patchoutIndex) != pc))
    {
      return false;
    }
    
    //Iterate over all the clones (first clone is the original sc and pc) and set the patchOut
    SynthComponent[] scClone = polyphonicCompClones.get(sc);
    PatchCable[] pcClone = polyphonicPatchClones.get(pc);
    
    for(int i = 0; i < scClone.length; i++)
    {
      //The patch cable's setPatchOut method also stores itself in the synth component
      pcClone[i].setPatchOut(scClone[i], patchoutIndex);
    }
    
    //Patch-out settings complete---return true for success!
    return true;
  }
  
  //To maintain polyphony, apply changes to all cloned instruments as well as ordinary ones
  //Return false when the setting fails (non-existent component OR non-existent thing to change)
  public boolean setPatchIn(int componentIndex, int patchinIndex, PatchCable pc)
  {
    //Cannot set a component if its index does not exist
    if((componentIndex < componentsList.size()) || (componentIndex >= componentsList.size()))
    {
      return false;
    }
    
    //Work with reference to the component because we will use it several times
    SynthComponent sc = componentsList.get(componentIndex);
    
    //Cannot set the patchIn if it does not exist, the accessor would return null
    if(sc.getPatchOut(patchinIndex) == null)
    {
      return false;
    }
    
    //Also cannot plug into a patch if it already has another cable plugged in (already being plugged in itself is fine)
    if((sc.getCableOut(patchinIndex) != null) || (sc.getCableOut(patchinIndex) != pc))
    {
      return false;
    }
    
    //Iterate over all the clones (first clone is the original sc and pc) and set the patchOut
    SynthComponent[] scClone = polyphonicCompClones.get(sc);
    PatchCable[] pcClone = polyphonicPatchClones.get(pc);
    
    for(int i = 0; i < scClone.length; i++)
    {
      //The patch cable's setPatchIn method also stores itself in the synth component
      pcClone[i].setPatchIn(scClone[i], patchinIndex);
    }
    
    //Patch-in settings complete---return true for success!
    return true;
  }
  
  //=========================DEBUG FUNCTIONS BELOW============================//
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
    //setupDebugKeyboard();
    //setupDebugVCF();
    
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
    //drawDebugKeyboard();
    //drawDebugVCF();
    
    //Can now test rendering, no matter what components are shown (copied here from 
    //  render(...) above due to change from components to componentsList data structure
    //Need to compute global position of component in GUI
    int xOffset = Render_CONSTANTS.LEFT_BORDER_WIDTH;
    int yOffset = Render_CONSTANTS.UPPER_BORDER_HEIGHT;
    int horizSlot = 0;
    int vertSlot = 0;
    
    //Allow each component (root should be redundant) to update
    for(int i = 0; i < components.length; i++)
    {
      components[i].draw_update();
      components[i].render(xOffset, yOffset);
      
      //Shift offsets based on tiled components
      horizSlot++;
      if(horizSlot >= Render_CONSTANTS.TILE_HORIZ_COUNT)
      {
        horizSlot = 0;
        vertSlot++;
        xOffset = Render_CONSTANTS.LEFT_BORDER_WIDTH;
        yOffset += Render_CONSTANTS.COMPONENT_HEIGHT;
        
        //If the vertical offset is too great, then abandon generating more components
        if(vertSlot >= Render_CONSTANTS.TILE_VERT_COUNT)
        {
          break;
        }
      }
      else
      {
        xOffset += Render_CONSTANTS.COMPONENT_WIDTH;
      }
    }
    
    //The keyboard is standalone => call its update separately
    if(keyboard != null)
    {
      keyboard.draw_update();
      keyboard.render(Render_CONSTANTS.APP_WIDTH - Render_CONSTANTS.LOWER_BORDER_WIDTH, Render_CONSTANTS.APP_HEIGHT - Render_CONSTANTS.LOWER_BORDER_HEIGHT);
    }
    
    //Iterate over patches (they are rendered globally)
    for(int i = 0; i < patches.length; i++)
    {
      //Make sure the component exists first (just in case it is null)
      if(patches[i] != null)
      {
        patches[i].render();
      }
    }
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
  
  private void setupDebugKeyboard()
  {
    root = new Keyboard();
    components = new SynthComponent[31]; //Yes, it is a lot because we need one envelope, multiple, and oscillator per key
    patches = new PatchCable[40]; //Because each key's setup needs 4 patches, phew!
    components[0] = root;
    for(int i = Keyboard_CONSTANTS.PATCHOUT_KEY0; i < Keyboard_CONSTANTS.TOTAL_PATCHOUT; i++)
    {
      //Instantiate the trio of components that go with a single key
      components[1 + (3 * i)] = new Multiples();
      components[2 + (3 * i)] = new EnvelopeGenerator();
      components[3 + (3 * i)] = new VCO();
      //Simple patch to make an enveloped square wave play for the key
      patches[4 * i] = new PatchCable(components[0], i, components[1 + (3 * i)], Multiples_CONSTANTS.PATCHIN_ORIGINAL);
      patches[1 + (4 * i)] = new PatchCable(components[1 + (3 * i)], Multiples_CONSTANTS.PATCHOUT_COPY0, components[2 + (3 * i)], EnvelopeGenerator_CONSTANTS.PATCHIN_GATE);
      patches[2 + (4 * i)] = new PatchCable(components[1 + (3 * i)], Multiples_CONSTANTS.PATCHOUT_COPY1, components[3 + (3 * i)], VCO_CONSTANTS.PATCHIN_FREQ);
      patches[3 + (4 * i)] = new PatchCable(components[3 + (3 * i)], VCO_CONSTANTS.PATCHOUT_SQUARE, components[2 + (3 * i)], EnvelopeGenerator_CONSTANTS.PATCHIN_WAVE);
      
      //Patch cable still cannot connect to speaker since it is not a component... perhaps worth making it one?
      components[2 + (3 * i)].getPatchOut(EnvelopeGenerator_CONSTANTS.PATCHOUT_WAVE).patch(toAudioOutput);
      
      //Force the unmodified knobs to have fixed values for testing purposes (ADSR has too many on its own)
      components[3 + (3 * i)].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition(0.0); //Only Keyboard sets the frequency
      components[3 + (3 * i)].getKnob(VCO_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0);
      components[2 + (3 * i)].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_STARTAMP).setCurrentPosition(0.0);
      components[2 + (3 * i)].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_ENDAMP).setCurrentPosition(0.0);
      components[2 + (3 * i)].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_MAXAMP).setCurrentPosition(1.0);
      components[2 + (3 * i)].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_SUSTAIN).setCurrentPosition(0.5);
      components[2 + (3 * i)].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_DECAY).setCurrentPosition(0.333333); //Since [0,3], this should be about 1 second
      components[2 + (3 * i)].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_ATTACK).setCurrentPosition(0.16667); //Since [0,3], this should be about 0.5 seconds
      components[2 + (3 * i)].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_RELEASE).setCurrentPosition(0.666667); //Since [0,3], this should be about 2 seconds
    }
    
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.patch(allInstruments_toOut);
  }
  private void drawDebugKeyboard()
  {
    //To avoid needing to integrate the test with the keyPress and keyRelease listeners,
    //  simply assume the lowercase turns a note on and uppercase turns it off (use the
    //  lowercase character for the sake of binding)
    if(Character.isLowerCase(key))
    {
      int assignedIndex = ((Keyboard)components[0]).set_key(key, Frequency.ofMidiNote(60.0 + Character.getNumericValue(key)).asHz());
      if(assignedIndex >= 0)
      {
        System.out.println("Playing key " + assignedIndex + " bound to " + key + " (midi #" + Character.getNumericValue(key) + " => " + Frequency.ofMidiNote(60.0 + Character.getNumericValue(key)).asHz() + " Hz)");
      }
    }
    else if(Character.isUpperCase(key))
    {
      boolean unassignedIndex = ((Keyboard)components[0]).unset_key(Character.toLowerCase(key));
      if(unassignedIndex)
      {
        System.out.println("Stopping key bound to " + key + " (midi #" + Character.getNumericValue(key) + " => " + Frequency.ofMidiNote(60.0 + Character.getNumericValue(key)).asHz() + " Hz)");
      }
    }
    
    draw_update();
  }
  
  private void setupDebugVCF()
  {
    //Rather than another boring volume change, let's use the extremely large amplitudes
    //  for a noticeable frequency modulation!
    root = new VCF();
    components = new SynthComponent[3];
    components[0] = root;
    components[1] = new VCA();
    components[2] = new NoiseGenerator();
    patches = new PatchCable[2];
    patches[0] = new PatchCable(components[2], NoiseGenerator_CONSTANTS.PATCHOUT_PINK, components[0], VCF_CONSTANTS.PATCHIN_WAVE);
    patches[1] = new PatchCable(components[0], VCF_CONSTANTS.PATCHOUT_WAVE, components[1], VCA_CONSTANTS.PATCHIN_WAVE);
    //Patch cable still cannot connect to speaker since it is not a component... perhaps worth making it one?
    components[1].getPatchOut(VCA_CONSTANTS.PATCHOUT_WAVE).patch(toAudioOutput);
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.patch(allInstruments_toOut);
    
    //Force the non-modulated knobs to have fixed values for testing purposes
    root.getKnob(VCF_CONSTANTS.KNOB_RES).setCurrentPosition(0.0); //No resonance
    components[1].getKnob(VCA_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0); //Set the volume all the way up
    components[2].getKnob(NoiseGenerator_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0); //Set the volume all the way up
  }
  private void drawDebugVCF()
  {
    root.getKnob(VCF_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)mouseY / (float)height);
    root.getKnob(VCF_CONSTANTS.KNOB_PASS).setCurrentPosition((float)mouseX / (float)width);
    draw_update();
  }
}
