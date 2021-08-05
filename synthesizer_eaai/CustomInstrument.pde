/*CustomInstrument.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 July 25

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
  //private UGen root;
  public SynthComponent root; //WARNING: Reset to private... this is a quick debug test
  
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
    //WARNING: Incomplete for now... just updating root
    root.draw_update();
  }
  
  //Used to setup a simple preloaded patch, intended to make debugging quick
  public void setupDebugPatch()
  {
    //Toggle the component tests, but ideally just one to avoid variable overwriting!
    setupDebugVCO();
    //Just patch an oscilator at a constant frequency directly to the local Summer
    //root = new Oscil(Frequency.ofPitch("A4"), 1, Waves.SQUARE);
    //root.patch(toAudioOutput);
  }
  
  public void drawDebugPatch()
  {
    //Toggle the component tests, but ideally just one to avoid variable overwriting!
    drawDebugVCO();
  }

  //For debugging of components, setup and draw functions that specifically test them
  private void setupDebugVCO()
  {
    root = new VCO();
    root.getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(allInstruments_toOut);
    //Not using the instrument version, so have to patch to the speaker outselves
    toAudioOutput.patch(allInstruments_toOut);
  }
  private void drawDebugVCO()
  {
    root.getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)mouseX / (float)width);
    root.getKnob(VCO_CONSTANTS.KNOB_AMP).setCurrentPosition((float)mouseY / (float)height);
    draw_update();
  }
}
