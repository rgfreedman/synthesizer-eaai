/*CustomInstrument.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2022 January 21

Class for a synthesized instrument.  Rather than pre-designed content, the modules
are loosely available for patching and adjusting during execution!  The patching order
is maintained using a tree-like data structure (parent patches into all children).
Because of recursive nature of patching, it seems easier to implement the tree as a 
map from the parent to a list of children.

---------------------------------------------------------------------
Copyright 2022 Richard (Rick) G. Freedman

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import java.util.HashMap;
import java.util.ArrayList;

import java.lang.Exception; //Needed for a special case that should only scream at the code developers for not keeping features up-to-date, not at anyone using the code as-is

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the CustomInstrument class below
public static class CustomInstrument_CONSTANTS
{
  //The keyboard is not part of the list of modules, and thus has its own offset index
  public static final int KEYBOARD_INDEX = -1;
  //The instrument's mixer is not part of the list of modules, and thus has its own offset index
  public static final int MIXERINSTRUMENT_INDEX = KEYBOARD_INDEX - 1;
  //This means checking for a bad module is not as simple as < 0, making it the next offset index
  public static final int NO_SUCH_INDEX = MIXERINSTRUMENT_INDEX - 1;
  
  //Constants for SynthModule class IDs, both as strings and integers
  public static final int SYNTHCOMP_ENVGEN_ID = 0;
  public static final int SYNTHCOMP_LFO_ID = SYNTHCOMP_ENVGEN_ID + 1;
  public static final int SYNTHCOMP_MIX1_8_ID = SYNTHCOMP_LFO_ID + 1;
  public static final int SYNTHCOMP_MIX4_2_ID = SYNTHCOMP_MIX1_8_ID + 1;
  public static final int SYNTHCOMP_MULT1_8_ID = SYNTHCOMP_MIX4_2_ID + 1;
  public static final int SYNTHCOMP_MULT2_4_ID = SYNTHCOMP_MULT1_8_ID + 1;
  public static final int SYNTHCOMP_NOISEGEN_ID = SYNTHCOMP_MULT2_4_ID + 1;
  public static final int SYNTHCOMP_POWER_ID = SYNTHCOMP_NOISEGEN_ID + 1;
  public static final int SYNTHCOMP_VCA_ID = SYNTHCOMP_POWER_ID + 1;
  public static final int SYNTHCOMP_VCF_ID = SYNTHCOMP_VCA_ID + 1;
  public static final int SYNTHCOMP_VCO_ID = SYNTHCOMP_VCF_ID + 1;
  public static final int TOTAL_SYNTHCOMP = SYNTHCOMP_VCO_ID + 1;
  public static final String[] SYNTHCOMP_LABELS = {"ENVGEN", "LFO", "MIX1_8", "MIX4_2", "MULT1_8", "MULT2_4", "NOISEGEN", "POWER", "VCA", "VCF", "VCO"};
}

public class CustomInstrument implements Instrument
{
  //NOTE: Keep modules, patches, and root for DEBUG legacy only---no longer used in the actual code
  //Encode the tree object, including the root as the starting point for patching
  private SynthModule[] modules;
  //Keep track of the patches through copies of the pointers
  private PatchCable[] patches;
  //private UGen root;
  private SynthModule root;
  
  //All modules and patch cables are stored in respective ArrayList objects for dynamic support
  private ArrayList<SynthModule> modulesList;
  private ArrayList<PatchCable> patchesList;
  //The one exception is the keyboard, which is included as a default module outside the list
  private Keyboard keyboard;
  //The other exception is the instrument's mixer, also included as a default module outside the list
  private MixerInstrument toAudioOutput;
  
  //A menu that will appear to enable selecting modules for adding instruments
  private ModuleChooser chooser;
  
  //In order to capture polyphony (simultaneous keyboard notes at once), need copies of
  //  the instrument, each using a unique keyboard out patch
  //This means we need to apply changes in the instrument across all copies; synced via a map
  private HashMap<SynthModule, SynthModule[]> polyphonicCompClones;
  private HashMap<PatchCable, PatchCable[]> polyphonicPatchClones;
  
  public CustomInstrument()
  {
    //Initialize, but there are no modules yet to set up arrays (outdated, keep for debug code legacy)
    root = null;
    
    //Initialize data structures that will store the synth modules (currently used)
    modulesList = new ArrayList();
    patchesList = new ArrayList();
    keyboard = new Keyboard();
    
    //Initialize the instrument's mixer so that there is a connection to the audio output
    toAudioOutput = new MixerInstrument();
    
    //Initialize the menu for listing modules that could be added
    chooser = new ModuleChooser();
    
    //Initialize the polyphonic clone data structure, which will interact with the keyboard
    polyphonicCompClones = new HashMap();
    polyphonicPatchClones = new HashMap();

    //NOTE: To handle the patching with polyphony, toAudioOutput has clones unlike the keyboard
    MixerInstrument[] taoClones = new MixerInstrument[Keyboard_CONSTANTS.TOTAL_PATCHOUT];
    taoClones[0] = toAudioOutput;
    for(int i = 1; i < taoClones.length; i++)
    {
      taoClones[i] = new MixerInstrument();
    }
    polyphonicCompClones.put(toAudioOutput, taoClones);
    
    //Due to the design of this synthesizer, patching is maintained even when notes do not play
    //NOTE: This means all the polyphonic clones patch out together (no visible patch means we do this manually here)
    for(int i = 0; i < taoClones.length; i++)
    {
      taoClones[i].getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE).patch(allInstruments_toOut);
    }
  }
  
  //Methods needed for the Instrument interface
  
  //Patch the summer with the final modules of the patch tree (the leaves)
  //  to the audio output [a.k.a. plug the instrument's local Summer into the
  //  global Summer that's plugged into the output]
  public void noteOn(float dur)
  {
    //NOTE: This should call set_key, but a note is assumed to already be assigned...
    /*
    SynthModule[] taoClones = polyphonicCompClones.get(toAudioOutput);
    for(int i = 0; i < taoClones.length; i++)
    {
      taoClones[i].getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE).patch(allInstruments_toOut);
    }
    */
  }
  
  //Unpatch the summer from the audio output [a.k.a. unplug the local Summer 
  //  from the global Summer that's plugged into the output]
  public void noteOff()
  {
    //NOTE: This should call unset_key, but a note is assumed to already be assigned...
    /*
    SynthModule[] taoClones = polyphonicCompClones.get(toAudioOutput);
    for(int i = 0; i < taoClones.length; i++)
    {
      taoClones[i].getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE).unpatch(allInstruments_toOut);
    }
    */
  }
  
  //Performs updates to the instrument (via updates to each module) in the draw iteration
  public void draw_update()
  {
    //Allow each module to update
    for(int i = 0; i < modulesList.size(); i++)
    {
      //Make sure the module exists first (just in case it is null)
      if(modulesList.get(i) != null)
      {
        //modulesList.get(i).draw_update(); //Commented out since duplicated in loop below
        
        //Do not forget to let all of its clones run draw_update as well!
        //NOTE: The first clone is the same as the one in modulesList (so comment out above to avoid duplicate execution)
        for(SynthModule cloneSC : polyphonicCompClones.get(modulesList.get(i)))
        {
          cloneSC.draw_update();
        }
      }
    }
    
    //The keyboard is standalone => call its update separately
    if(keyboard != null)
    {
      keyboard.draw_update();
    }
    //The instrument's mixer is also standalone => call its render separately
    if(toAudioOutput != null)
    {
      for(SynthModule cloneTAO : polyphonicCompClones.get(toAudioOutput))
      {
        cloneTAO.draw_update();
      }
    }
  }
  
  //Renders the modules of this instrument
  public void render()
  {
    //Need to compute global position of module in GUI
    int xOffset = Render_CONSTANTS.LEFT_BORDER_WIDTH;
    int yOffset = Render_CONSTANTS.UPPER_BORDER_HEIGHT;
    int horizSlot = 0;
    int vertSlot = 0;
    
    //Iterate over modules and calculate their global offset (since rendered locally)
    for(int i = 0; i < modulesList.size(); i++)
    {
      //Make sure the module exists first (just in case it is null)
      if(modulesList.get(i) != null)
      {
        modulesList.get(i).render(xOffset, yOffset);
      }
      
      //Shift offsets based on tiled modules
      horizSlot++;
      if(horizSlot >= Render_CONSTANTS.TILE_HORIZ_COUNT)
      {
        horizSlot = 0;
        vertSlot++;
        xOffset = Render_CONSTANTS.LEFT_BORDER_WIDTH;
        yOffset += Render_CONSTANTS.MODULE_HEIGHT;
        
        //If the vertical offset is too great, then abandon generating more modules
        if(vertSlot >= Render_CONSTANTS.TILE_VERT_COUNT)
        {
          break;
        }
      }
      else
      {
        xOffset += Render_CONSTANTS.MODULE_WIDTH;
      }
    }
    //Special case: render a chooser menu when there is room for another module
    //  and the list is exhausted (loop computed the next xOffset and yOffset before exiting)
    if(modulesList.size() < Render_CONSTANTS.MAX_SYNTH_MODULES)
    {
      chooser.render(xOffset, yOffset);
    }
    
    //The keyboard is standalone => call its render separately
    if(keyboard != null)
    {
      keyboard.render(Render_CONSTANTS.APP_WIDTH - Render_CONSTANTS.LOWER_BORDER_WIDTH, Render_CONSTANTS.APP_HEIGHT - Render_CONSTANTS.LOWER_BORDER_HEIGHT);
    }
    //The instrument's mixer is also standalone => call its render separately
    if(toAudioOutput != null)
    {
      toAudioOutput.render(Render_CONSTANTS.APP_WIDTH - Render_CONSTANTS.RIGHT_BORDER_WIDTH, Render_CONSTANTS.UPPER_BORDER_HEIGHT);
    }
    
    //Iterate over patches (they are rendered globally)
    for(int i = 0; i < patchesList.size(); i++)
    {
      //Make sure the module exists first (just in case it is null)
      if(patchesList.get(i) != null)
      {
        patchesList.get(i).render();
      }
    }
  }
  
  //Reverse engineering of the rendering process to identify the focus
  //  (what module is at some pixel location)
  public SynthModule getSynthModuleAt(int x, int y)
  {
    //If the point is out-of-bounds of the application, immediately return null
    if((x < 0) || (x >= Render_CONSTANTS.APP_WIDTH) || (y < 0) || (y >= Render_CONSTANTS.APP_HEIGHT))
    {
      return null;
    }
    
    //Quick case: if the point is within the lower border, then the keyboard has focus
    if(Render_CONSTANTS.rect_contains_point(Render_CONSTANTS.APP_WIDTH - Render_CONSTANTS.LOWER_BORDER_WIDTH, Render_CONSTANTS.APP_HEIGHT - Render_CONSTANTS.LOWER_BORDER_HEIGHT, Render_CONSTANTS.LOWER_BORDER_WIDTH, Render_CONSTANTS.LOWER_BORDER_HEIGHT, x, y))
    {
      return keyboard;
    }
    
    //Quick case: if the point is within the right-center border, then the instrument's mixer has focus
    if(Render_CONSTANTS.rect_contains_point(Render_CONSTANTS.APP_WIDTH - Render_CONSTANTS.RIGHT_BORDER_WIDTH, Render_CONSTANTS.UPPER_BORDER_HEIGHT, Render_CONSTANTS.RIGHT_BORDER_WIDTH, Render_CONSTANTS.RIGHT_BORDER_HEIGHT, x, y))
    {
      return toAudioOutput;
    }
    
    //Longer case: iterate over the modules in the list and identify if any of them have focus
    for(int r = 0; r < Render_CONSTANTS.TILE_VERT_COUNT; r++)
    {
      for(int c = 0; c < Render_CONSTANTS.TILE_HORIZ_COUNT; c++)
      {
        if(Render_CONSTANTS.rect_contains_point(Render_CONSTANTS.LEFT_BORDER_WIDTH + (c * Render_CONSTANTS.MODULE_WIDTH), Render_CONSTANTS.UPPER_BORDER_HEIGHT + (r * Render_CONSTANTS.MODULE_HEIGHT), Render_CONSTANTS.MODULE_WIDTH, Render_CONSTANTS.MODULE_HEIGHT, x, y))
        {
          //If that module actually does not exist, then make sure null is returned
          if(((r * Render_CONSTANTS.TILE_HORIZ_COUNT) + c) > modulesList.size())
          {
            return null;
          }
          //If that module is one module outside the list, then it is the menu to choose a module
          //  Do not need to check Render_CONSTANTS.MAX_SYNTH_MODULES here since the HORIZ and VERT limits enforce it
          else if(((r * Render_CONSTANTS.TILE_HORIZ_COUNT) + c) == modulesList.size())
          {
            return chooser;
          }
          else
          {
            //When the module is not defined, but the list has an entry, then conveniently returns null
            return modulesList.get((r * Render_CONSTANTS.TILE_HORIZ_COUNT) + c);
          }
        }
      }
    }
    
    //If nothing matched, then in some unused region or an unused border
    return null;
  }
  
  //Some methods need the index of a SynthModule rather than the componet itself
  //NOTE: Finds the exact match of sc (via == for pointer, not .equals for features)
  //NOTE: Returns CustomInstrument_CONSTANTS.NO_SUCH_INDEX when no match was found, 
  //      the keyboard via CustomInstrument_CONSTANTS.KEYBOARD_INDEX, and the
  //      instrument's mixer via CustomInstrument_CONSTANTS.MIXERINSTRUMENT_INDEX
  public int findSynthModuleIndex(SynthModule sc)
  {
    //Special case of the keyboard (not in modulesList)
    if(keyboard == sc)
    {
      return CustomInstrument_CONSTANTS.KEYBOARD_INDEX;
    }
    //Special case of the instrument's mixer (not in modulesList)
    if(toAudioOutput == sc)
    {
      return CustomInstrument_CONSTANTS.MIXERINSTRUMENT_INDEX;
    }
    //Special case of the chooser menu for modules (not in modulesList)
    //  NOTE: Only allow the chooser to be selectable when there is room to add another module
    if((chooser == sc) && (modulesList.size() < Render_CONSTANTS.MAX_SYNTH_MODULES))
    {
      return modulesList.size();
    }
    
    for(int i = 0; i < modulesList.size(); i++)
    {
      if(modulesList.get(i) == sc)
      {
        return i;
      }
    }
    
    //Failed to find a match at this point...
    return CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
  }
  
  //Invert findSynthModuleIndex to get the module specified at the index
  //NOTE: Returns null when CustomInstrument_CONSTANTS.NO_SUCH_INDEX or other invalid index is provided
  public SynthModule getSynthModule(int index)
  {
    //Special case of the keyboard (not in modulesList)
    if(index == CustomInstrument_CONSTANTS.KEYBOARD_INDEX)
    {
      return keyboard;
    }
    //Special case of the instrument's mixer (not in modulesList)
    if(index == CustomInstrument_CONSTANTS.MIXERINSTRUMENT_INDEX)
    {
      return toAudioOutput;
    }
    //Special case of the chooser menu for modules (not in modulesList)
    //  NOTE: Only allow the chooser to be selectable when there is room to add another module
    if((index == modulesList.size()) && (modulesList.size() < Render_CONSTANTS.MAX_SYNTH_MODULES))
    {
      return chooser;
    }
    
    //General case returns the module at the specified index if within bounds
    if((index >= 0) && (index < modulesList.size()))
    {
      return modulesList.get(index);
    }
    
    //Failed to find a match at this point...
    return null;
  }
  
  //To adjust the mouse cursor's position within a module, we need its rectangle information
  //NOTE: Two versions, one with input as a SynthModule object and the other as an indexed module in the list
  //This is the top-left corner of the module's bounding rectangle's X-value
  public int getModuleTopLeftX(SynthModule sc)
  {
    int compIndex = findSynthModuleIndex(sc);
    return getModuleTopLeftX(compIndex);
  }
  public int getModuleTopLeftX(int compIndex)
  {
    //If a non-existent module, then return an impossible value
    if(compIndex == CustomInstrument_CONSTANTS.NO_SUCH_INDEX)
    {
      return Render_CONSTANTS.INVALID_VALUE;
    }
    //Keyboard is a special case because it is below the module grid
    else if(compIndex == CustomInstrument_CONSTANTS.KEYBOARD_INDEX)
    {
      return (Render_CONSTANTS.APP_WIDTH - Render_CONSTANTS.LOWER_BORDER_WIDTH);
    }
    //Instrument's mixer is a special case because it is beside the module grid
    else if(compIndex == CustomInstrument_CONSTANTS.MIXERINSTRUMENT_INDEX)
    {
      return (Render_CONSTANTS.APP_WIDTH - Render_CONSTANTS.RIGHT_BORDER_WIDTH);
    }
    //Everything else is in the module grid, which is just a tiled layout
    else
    {
      return (Render_CONSTANTS.LEFT_BORDER_WIDTH + (Render_CONSTANTS.MODULE_WIDTH * (compIndex % Render_CONSTANTS.TILE_HORIZ_COUNT)));
    }
  }
  //This is the top-left corner of the module's bounding rectangle's Y-value
  public int getModuleTopLeftY(SynthModule sc)
  {
    int compIndex = findSynthModuleIndex(sc);
    return getModuleTopLeftY(compIndex);
  }
  public int getModuleTopLeftY(int compIndex)
  {
    //If a non-existent module, then return an impossible value
    if(compIndex == CustomInstrument_CONSTANTS.NO_SUCH_INDEX)
    {
      return Render_CONSTANTS.INVALID_VALUE;
    }
    //Keyboard is a special case because it is below the module grid
    else if(compIndex == CustomInstrument_CONSTANTS.KEYBOARD_INDEX)
    {
      return (Render_CONSTANTS.APP_HEIGHT - Render_CONSTANTS.LOWER_BORDER_HEIGHT);
    }
    //Instrument's mixer is a special case because it is beside the module grid
    else if(compIndex == CustomInstrument_CONSTANTS.MIXERINSTRUMENT_INDEX)
    {
      return (Render_CONSTANTS.UPPER_BORDER_HEIGHT);
    }
    //Everything else is in the module grid, which is just a tiled layout
    else
    {
      return (Render_CONSTANTS.UPPER_BORDER_HEIGHT + (Render_CONSTANTS.MODULE_HEIGHT * (compIndex / Render_CONSTANTS.TILE_HORIZ_COUNT)));
    }
  }
  public int getModuleWidth(SynthModule sc)
  {
    int compIndex = findSynthModuleIndex(sc);
    return getModuleWidth(compIndex);
  }
  //This is the width of the module's bounding rectangle
  public int getModuleWidth(int compIndex)
  {
    //If a non-existent module, then return an impossible value
    if(compIndex == CustomInstrument_CONSTANTS.NO_SUCH_INDEX)
    {
      return Render_CONSTANTS.INVALID_VALUE;
    }
    //Keyboard is a special case because it is below the module grid
    else if(compIndex == CustomInstrument_CONSTANTS.KEYBOARD_INDEX)
    {
      return Render_CONSTANTS.LOWER_BORDER_WIDTH;
    }
    //Instrument's mixer is a special case because it is beside the module grid
    else if(compIndex == CustomInstrument_CONSTANTS.MIXERINSTRUMENT_INDEX)
    {
      return Render_CONSTANTS.RIGHT_BORDER_WIDTH;
    }
    //Everything else is in the module grid, which is just a tiled layout
    else
    {
      return Render_CONSTANTS.MODULE_WIDTH;
    }
  }
  public int getModuleHeight(SynthModule sc)
  {
    int compIndex = findSynthModuleIndex(sc);
    return getModuleHeight(compIndex);
  }
  //This is the height of the module's bounding rectangle
  public int getModuleHeight(int compIndex)
  {
    //If a non-existent module, then return an impossible value
    if(compIndex == CustomInstrument_CONSTANTS.NO_SUCH_INDEX)
    {
      return Render_CONSTANTS.INVALID_VALUE;
    }
    //Keyboard is a special case because it is below the module grid
    else if(compIndex == CustomInstrument_CONSTANTS.KEYBOARD_INDEX)
    {
      return Render_CONSTANTS.LOWER_BORDER_HEIGHT;
    }
    //Instrument's mixer is a special case because it is beside the module grid
    else if(compIndex == CustomInstrument_CONSTANTS.MIXERINSTRUMENT_INDEX)
    {
      return Render_CONSTANTS.RIGHT_BORDER_HEIGHT - Render_CONSTANTS.UPPER_BORDER_HEIGHT - Render_CONSTANTS.LOWER_BORDER_HEIGHT;
    }
    //Everything else is in the module grid, which is just a tiled layout
    else
    {
      return Render_CONSTANTS.MODULE_HEIGHT;
    }
  }
  
  //For polyphonic purposes, create a synth module's clones all at once when setting up
  //  Each has an input parameter for the module
  //  Each returns a boolean, which is false when there are no more synth module slots
  //This version takes a label for the module name (should match one in CustomInstrument_CONSTANTS.SYNTHCOMP_LABELS
  public boolean addSynthModule(String scLabel)
  {
    //No idea whether the IDs correspond to lexical ordering of the labels... use a linear search
    int moduleID = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
    for(int i = 0; i < CustomInstrument_CONSTANTS.SYNTHCOMP_LABELS.length; i++)
    {
      if(scLabel.equals(CustomInstrument_CONSTANTS.SYNTHCOMP_LABELS[i]))
      {
        moduleID = i;
        break;
      }
    }
    //Make sure the ID for the label was found first; otherwise the add failed
    if(moduleID == CustomInstrument_CONSTANTS.NO_SUCH_INDEX)
    {
      return false;
    }
    return addSynthModule(moduleID);
  }
  //This version takes an ID for the module class (should match one in CustomInstrument_CONSTANTS.SYNTHCOMP_X_ID
  public boolean addSynthModule(int scID)
  {
    switch(scID)
    {
      case CustomInstrument_CONSTANTS.SYNTHCOMP_ENVGEN_ID:
        try
        {
          addSynthModule(new EnvelopeGenerator());
        }
        //This should not occur since the SynthModule class is legal, but one can never be too safe with potential bugs and future code changes
        catch(Exception e)
        {
          System.out.println("ERROR: " + e + "\n\tWhen adding EnvelopeGenerator to instrument via ID " + scID);
        }
        break;
      case CustomInstrument_CONSTANTS.SYNTHCOMP_LFO_ID:
        try
        {
          addSynthModule(new LFO());
        }
        //This should not occur since the SynthModule class is legal, but one can never be too safe with potential bugs and future code changes
        catch(Exception e)
        {
          System.out.println("ERROR: " + e + "\n\tWhen adding LFO to instrument via ID " + scID);
        }
        break;
      case CustomInstrument_CONSTANTS.SYNTHCOMP_MIX1_8_ID:
        try
        {
          addSynthModule(new Mixer8to1());
        }
        //This should not occur since the SynthModule class is legal, but one can never be too safe with potential bugs and future code changes
        catch(Exception e)
        {
          System.out.println("ERROR: " + e + "\n\tWhen adding Mixer8to1 to instrument via ID " + scID);
        }
        break;
      case CustomInstrument_CONSTANTS.SYNTHCOMP_MIX4_2_ID:
        try
        {
          addSynthModule(new Mixer4to2());
        }
        //This should not occur since the SynthModule class is legal, but one can never be too safe with potential bugs and future code changes
        catch(Exception e)
        {
          System.out.println("ERROR: " + e + "\n\tWhen adding Mixer4to2 to instrument via ID " + scID);
        }
        break;
      case CustomInstrument_CONSTANTS.SYNTHCOMP_MULT1_8_ID:
        try
        {
          addSynthModule(new Multiples1to8());
        }
        //This should not occur since the SynthModule class is legal, but one can never be too safe with potential bugs and future code changes
        catch(Exception e)
        {
          System.out.println("ERROR: " + e + "\n\tWhen adding Multiples1to8 to instrument via ID " + scID);
        }
        break;
      case CustomInstrument_CONSTANTS.SYNTHCOMP_MULT2_4_ID:
        try
        {
          addSynthModule(new Multiples2to4());
        }
        //This should not occur since the SynthModule class is legal, but one can never be too safe with potential bugs and future code changes
        catch(Exception e)
        {
          System.out.println("ERROR: " + e + "\n\tWhen adding Multiples2to4 to instrument via ID " + scID);
        }
        break;
      case CustomInstrument_CONSTANTS.SYNTHCOMP_NOISEGEN_ID:
        try
        {
          addSynthModule(new NoiseGenerator());
        }
        //This should not occur since the SynthModule class is legal, but one can never be too safe with potential bugs and future code changes
        catch(Exception e)
        {
          System.out.println("ERROR: " + e + "\n\tWhen adding NoiseGenerator to instrument via ID " + scID);
        }
        break;
      case CustomInstrument_CONSTANTS.SYNTHCOMP_POWER_ID:
        try
        {
          addSynthModule(new Power());
        }
        //This should not occur since the SynthModule class is legal, but one can never be too safe with potential bugs and future code changes
        catch(Exception e)
        {
          System.out.println("ERROR: " + e + "\n\tWhen adding Power to instrument via ID " + scID);
        }
        break;
      case CustomInstrument_CONSTANTS.SYNTHCOMP_VCA_ID:
        try
        {
          addSynthModule(new VCA());
        }
        //This should not occur since the SynthModule class is legal, but one can never be too safe with potential bugs and future code changes
        catch(Exception e)
        {
          System.out.println("ERROR: " + e + "\n\tWhen adding VCA to instrument via ID " + scID);
        }
        break;
      case CustomInstrument_CONSTANTS.SYNTHCOMP_VCF_ID:
        try
        {
          addSynthModule(new VCF());
        }
        //This should not occur since the SynthModule class is legal, but one can never be too safe with potential bugs and future code changes
        catch(Exception e)
        {
          System.out.println("ERROR: " + e + "\n\tWhen adding VCF to instrument via ID " + scID);
        }
        break;
      case CustomInstrument_CONSTANTS.SYNTHCOMP_VCO_ID:
        try
        {
          addSynthModule(new VCO());
        }
        //This should not occur since the SynthModule class is legal, but one can never be too safe with potential bugs and future code changes
        catch(Exception e)
        {
          System.out.println("ERROR: " + e + "\n\tWhen adding VCO to instrument via ID " + scID);
        }
        break;
      //If no matching module ID, then failed to add it
      default:
        return false;
    }
    //At this point, non-default cases reach here, successfully added module
    return true;
  }
  //This one adds an actual SynthModule object and generates the clones
  //  Some SynthModule classes are not allowed in the instrument's modules list, and these will throw an error
  //NOTE: Use the String and int versions above to avoid the error since they restrict the available modules
  public boolean addSynthModule(SynthModule sc) throws Exception
  {
    //Do not continue any further if out of synth modules
    if(modulesList.size() >= Render_CONSTANTS.MAX_SYNTH_MODULES)
    {
      return false;
    }
    
    //Append the module to the list
    modulesList.add(sc);
    
    //Now produce the clones as an array and then map them all together
    SynthModule[] scClones = new SynthModule[Keyboard_CONSTANTS.TOTAL_PATCHOUT];
    //First entry is the identity, which aligns the keyboard out patch indeces for polyphony
    scClones[Keyboard_CONSTANTS.PATCHOUT_KEY0] = sc;
    for(int i = Keyboard_CONSTANTS.PATCHOUT_KEY1; i < scClones.length; i++)
    {
      //NOTE: Need to prepare additional cases if more SynthModule subclasses are ever made!
      if(sc instanceof ModuleChooser)
      {
        //Yet another exception to the rule... module choosers should be unique and external to this portion
        throw new Exception("Cannot include a ModuleChooser or its subclass (" + sc.getClass() + ") in instrument");
      }
      else if(sc instanceof EnvelopeGenerator)
      {
        scClones[i] = new EnvelopeGenerator();
      }
      else if(sc instanceof Keyboard)
      {
        //The one exception to the rule... keyboards should be unique and external to this portion
        throw new Exception("Cannot include a Keyboard or its subclass (" + sc.getClass() + ") in instrument");
      }
      else if(sc instanceof LFO)
      {
        scClones[i] = new LFO();
      }
      else if(sc instanceof Mixer8to1)
      {
        scClones[i] = new Mixer8to1();
      }
      else if(sc instanceof Mixer4to2)
      {
        scClones[i] = new Mixer4to2();
      }
      else if(sc instanceof MixerInstrument)
      {
        //The other exception to the rule... instrument mixers should be unique and external to this portion
        throw new Exception("Cannot include a MixerInstrument or its subclass (" + sc.getClass() + ") in instrument");
      }
      else if(sc instanceof Multiples1to8)
      {
        scClones[i] = new Multiples1to8();
      }
      else if(sc instanceof Multiples2to4)
      {
        scClones[i] = new Multiples2to4();
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
        throw new Exception("No such subclass of SynthModule: " + sc.getClass());
      }
      
      //Set the unique name to be a numbered clone (just in case it appears in the GUI)
      scClones[i].setUniqueName(sc.getUniqueName() + " [Clone #" + i + "]");
    }
    
    //Set up the mapping for future use when syncing changes to the instrument
    polyphonicCompClones.put(sc, scClones);
    
    //By this point, the cloning was successful
    return true;
  }
  
  //For polyphonic purposes, remove a synth module's clones all at once when deleting
  //  Each has an input parameter for the module
  //  Each returns a boolean, which is false when the specified module does not exist to remove
  //This one removes an actual SynthModule object and all the respective clones
  //  Some SynthModule objects are not allowed in the instrument's modules list, and these will also return false
  public boolean removeSynthModule(SynthModule sc)
  {
    //Return false if no synth module provided
    if(sc == null)
    {
      return false;
    }
    
    //Need the index of the module to call the fleshed out remove command
    int scIndex = findSynthModuleIndex(sc);
    
    //Do not continue any further if not included in the list of synth modules
    //NOTE: This captures the unique modules like keyboard, intrument's mixer, and module chooser
    if((scIndex < 0) || (scIndex >= modulesList.size()))
    {
      return false;
    }
    else
    {
      return removeSynthModule(scIndex);
    }
  }
  public boolean removeSynthModule(int scIndex)
  {
    //First, get the respective synth module after checking for its existence
    if((scIndex < 0) || (scIndex >= modulesList.size()))
    {
      return false;
    }
    SynthModule sc = getSynthModule(scIndex);
    
    //Return false if no synth module at the specified index
    if(sc == null)
    {
      return false;
    }
    
    //Retrieve the clones since they are mapped together
    SynthModule[] scClones = polyphonicCompClones.get(sc);
    
    //Now delete the clones as an array and remove the mapping
    for(int i = Keyboard_CONSTANTS.PATCHOUT_KEY0; i < scClones.length; i++)
    {
      //First, remove all the patches that plug into the module
      for(int j = 0; j < scClones[i].getTotalPatchIn(); j++)
      {
        //NOTE: This handles the null cable case by returning false and not removing anything
        removePatchCable(scClones[i].getCableIn(j));
      }
      for(int j = 0; j < scClones[i].getTotalPatchOut(); j++)
      {
        //NOTE: This handles the null cable case by returning false and not removing anything
        removePatchCable(scClones[i].getCableOut(j));
      }
      
      //Now safe to forget about this array pointer (for the garbage collector)
      scClones[i] = null;
    }
    //Remove the mapping to leave stuff available for the garbage collector
    polyphonicCompClones.remove(sc);
    
    //Remove the module from the list as well
    modulesList.remove(scIndex);
    
    //By this point, the removal was successful
    return true;
  }
  
  //For polyphonic purposes, create a patch cable's clones all at once when setting up
  //  Each has an input parameter for the patch cable
  //  Due to limitless patches, returns false only if the patch cable is null
  public boolean addPatchCable(PatchCable pc)
  {
    //Return false if no patch cable provided
    if(pc == null)
    {
      return false;
    }
    
    //Append the module to the list
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
    
    //If the provided patch cable already set its in-patch or out-patch, then mirror across the clones
    if(pc.getPatchInModule() != null)
    {
      setPatchIn(findSynthModuleIndex(pc.getPatchInModule()), pc.getPatchInIndex(), pc);
    }
    if(pc.getPatchOutModule() != null)
    {
      setPatchOut(findSynthModuleIndex(pc.getPatchOutModule()), pc.getPatchOutIndex(), pc);
    }
    
    //We will reach this point no matter what unless pc was null, but follow suit of cloning synth modules
    return true;
  }
  
  //For polyphonic purposes, remove a patch cable's clones all at once when deleting
  //  Each has an input parameter for the patch cable
  //  Returns false if the patch is null or not included in the instrument
  public boolean removePatchCable(PatchCable pc)
  {
    //Return false if no patch cable provided
    if((pc == null) || (!patchesList.contains(pc)))
    {
      return false;
    }
    
    //If the provided patch cable already set its in-patch or out-patch, then remove across the clones
    if(pc.getPatchInModule() != null)
    {
      unsetPatchIn(findSynthModuleIndex(pc.getPatchInModule()), pc.getPatchInIndex());
    }
    if(pc.getPatchOutModule() != null)
    {
      unsetPatchOut(findSynthModuleIndex(pc.getPatchOutModule()), pc.getPatchOutIndex());
    }
    
    //Now delete the clones as an array and remove the mapping
    PatchCable[] pcClones = polyphonicPatchClones.get(pc);
    for(int i = Keyboard_CONSTANTS.PATCHOUT_KEY0; i < pcClones.length; i++)
    {
      pcClones[i] = null;
    }
    //Remove the mapping to leave stuff available for the garbage collector
    polyphonicPatchClones.remove(pc);
    
    //Delete the module from the list
    patchesList.remove(pc);
    
    //By this point, removal was successful
    return true;
  }
  
  //To maintain polyphony, apply changes to all cloned instruments as well as ordinary ones
  //Return false when the setting fails (non-existent module OR non-existent thing to change)
  public boolean setKnob(int moduleIndex, int knobIndex, float position)
  {
    //Cannot set a module if its index does not exist (no knobs on keyboard)
    if((moduleIndex <= CustomInstrument_CONSTANTS.NO_SUCH_INDEX) || (moduleIndex >= modulesList.size()))
    {
      if(DEBUG_INTERFACE_KNOB)
      {
        println("[setKnob] moduleIndex " + moduleIndex + " is out of bounds (modulesList size " + modulesList.size() + ") => failed to set knob");
      }
      return false;
    }
    
    //Work with reference to the module because we will use it several times
    SynthModule sc = (moduleIndex == CustomInstrument_CONSTANTS.KEYBOARD_INDEX) ? keyboard : (moduleIndex == CustomInstrument_CONSTANTS.MIXERINSTRUMENT_INDEX) ? toAudioOutput : modulesList.get(moduleIndex);
    
    //Cannot set the knob if it does not exist, the accessor would return null
    if(sc.getKnob(knobIndex) == null)
    {
      if(DEBUG_INTERFACE_KNOB)
      {
        println("[setKnob] knobIndex " + knobIndex + " is out of bounds for moduleIndex " + moduleIndex + " => failed to set knob");
      }
      return false;
    }
    
    //Iterate over all the clones (first clone is the original sc) and set the knob value
    for(SynthModule scClone : polyphonicCompClones.get(sc))
    {
      scClone.getKnob(knobIndex).setCurrentPosition(position);
      
      if(DEBUG_INTERFACE_KNOB)
      {
        println("[setKnob] knobIndex " + knobIndex + " on module clone " + scClone + " is set to position " + scClone.getKnob(knobIndex).getCurrentPosition());
      }
    }
    
    //Knob settings complete---return true for success!
    return true;
  }
  
  //Plugs a patch cable into the given out patch
  //To maintain polyphony, apply changes to all cloned instruments as well as ordinary ones
  //Return false when the setting fails (non-existent module OR non-existent thing to change)
  public boolean setPatchOut(int moduleIndex, int patchoutIndex, PatchCable pc)
  {
    //Cannot set a module if its index does not exist
    if((moduleIndex <= CustomInstrument_CONSTANTS.NO_SUCH_INDEX) || (moduleIndex >= modulesList.size()))
    {
      if(DEBUG_INTERFACE_PATCH)
      {
        println("[setPatchOut] moduleIndex " + moduleIndex + " is out of bounds (modulesList size " + modulesList.size() + ") => failed to patch out");
      }
      return false;
    }
    
    //Work with reference to the module because we will use it several times
    SynthModule sc = getSynthModule(moduleIndex); //(moduleIndex == CustomInstrument_CONSTANTS.KEYBOARD_INDEX) ? keyboard : (moduleIndex == CustomInstrument_CONSTANTS.MIXERINSTRUMENT_INDEX) ? toAudioOutput : modulesList.get(moduleIndex);
    
    //Cannot set the patchOut if it does not exist, the accessor would return null
    if(sc.getPatchOut(patchoutIndex) == null)
    {
      if(DEBUG_INTERFACE_PATCH)
      {
        println("[setPatchOut] patchoutIndex " + patchoutIndex + " is out of bounds for moduleIndex " + moduleIndex + " => failed to patch out");
      }
      return false;
    }
    
    //Also cannot plug into a patch if it already has another cable plugged in (already being plugged in itself is fine)
    if((sc.getCableOut(patchoutIndex) != null) && (sc.getCableOut(patchoutIndex) != pc))
    {
      if(DEBUG_INTERFACE_PATCH)
      {
        println("[setPatchOut] patchoutIndex " + patchoutIndex + " is already used for moduleIndex " + moduleIndex + " => failed to patch out");
      }
      return false;
    }
    
    //Patching in keyboard case because it is not cloned
    //NOTE: patchoutIndex should be either Keyboard_CONSTANTS.PATCHOUT_KEY0 or Keyboard_CONSTANTS.PATCHOUT_GATE0, and the rest is looping for polyphony
    if(sc == keyboard)
    {
      //Iterate over all the patch cable clones and set the patchOut to the next keyboard patch
      PatchCable[] pcClone = polyphonicPatchClones.get(pc);
    
      for(int i = Keyboard_CONSTANTS.PATCHOUT_KEY0; i < Keyboard_CONSTANTS.TOTAL_PATCHOUT; i++)
      {
        if(DEBUG_INTERFACE_PATCH)
        {
          println("[setPatchOut] patchoutIndex " + (i + patchoutIndex) + " of keyboard " + sc + " will plug into patch cable clone " + i + " (" + pcClone[i] + ")...");
        }
        
        //The patch cable's setPatchOut method also stores itself in the synth module
        pcClone[i].setPatchOut(sc, i + patchoutIndex);
        
        if(DEBUG_INTERFACE_PATCH)
        {
          println("\t => successful patch out? pcClone[" + i + "] plugs into " + pcClone[i].getPatchOutModule() + ", index " + pcClone[i].getPatchOutIndex());
        }
      }
    }
    //For non-keyboard, including the instrument mixer (since it is cloned)
    else
    {
      //Iterate over all the clones (first clone is the original sc and pc) and set the patchOut
      SynthModule[] scClone = polyphonicCompClones.get(sc);
      PatchCable[] pcClone = polyphonicPatchClones.get(pc);
    
      for(int i = 0; i < scClone.length; i++)
      {
        if(DEBUG_INTERFACE_PATCH)
        {
          println("[setPatchOut] patchoutIndex " + patchoutIndex + " of module clone " + i + " (" + scClone[i] + ") will plug into patch cable clone " + i + " (" + pcClone[i] + ")...");
        }
        
        //The patch cable's setPatchOut method also stores itself in the synth module
        pcClone[i].setPatchOut(scClone[i], patchoutIndex);
        
        if(DEBUG_INTERFACE_PATCH)
        {
          println("\t => successful patch out? pcClone[" + i + "] plugs into " + pcClone[i].getPatchOutModule() + ", index " + pcClone[i].getPatchOutIndex());
        }
      }
    }
    
    //Patch-out settings complete---return true for success!
    return true;
  }
  
  //Plugs a patch cable into the given in patch
  //To maintain polyphony, apply changes to all cloned instruments as well as ordinary ones
  //Return false when the setting fails (non-existent module OR non-existent thing to change)
  public boolean setPatchIn(int moduleIndex, int patchinIndex, PatchCable pc)
  {
    //Cannot set a module if its index does not exist
    if((moduleIndex <= CustomInstrument_CONSTANTS.NO_SUCH_INDEX) || (moduleIndex >= modulesList.size()))
    {
      if(DEBUG_INTERFACE_PATCH)
      {
        println("[setPatchIn] moduleIndex " + moduleIndex + " is out of bounds (modulesList size " + modulesList.size() + ") => failed to patch in");
      }
      return false;
    }
    
    //Work with reference to the module because we will use it several times
    SynthModule sc = getSynthModule(moduleIndex); //(moduleIndex == CustomInstrument_CONSTANTS.KEYBOARD_INDEX) ? keyboard : (moduleIndex == CustomInstrument_CONSTANTS.MIXERINSTRUMENT_INDEX) ? toAudioOutput : modulesList.get(moduleIndex);
    
    //Cannot set the patchIn if it does not exist, the accessor would return null
    if(sc.getPatchIn(patchinIndex) == null)
    {
      if(DEBUG_INTERFACE_PATCH)
      {
        println("[setPatchIn] patchinIndex " + patchinIndex + " is out of bounds for moduleIndex " + moduleIndex + " => failed to patch in");
      }
      return false;
    }
    
    //Also cannot plug into a patch if it already has another cable plugged in (already being plugged in itself is fine)
    if((sc.getCableIn(patchinIndex) != null) && (sc.getCableIn(patchinIndex) != pc))
    {
      if(DEBUG_INTERFACE_PATCH)
      {
        println("[setPatchIn] patchinIndex " + patchinIndex + " is already used for moduleIndex " + moduleIndex + " => failed to patch in");
      }
      return false;
    }
    
    //Patching in keyboard case because it is not cloned---awkwardly, there are no patch-ins on the keyboard (so dead code for now)
    //NOTE: patchinIndex should be either Keyboard_CONSTANTS.PATCHOUT_KEY0 or Keyboard_CONSTANTS.PATCHOUT_GATE0, and the rest is looping for polyphony
    if(sc == keyboard)
    {
      //Iterate over all the patch cable clones and set the patchOut to the next keyboard patch
      PatchCable[] pcClone = polyphonicPatchClones.get(pc);
    
      for(int i = 0; i < Keyboard_CONSTANTS.TOTAL_PATCHIN; i++)
      {
        if(DEBUG_INTERFACE_PATCH)
        {
          println("[setPatchIn] patchinIndex " + (i + patchinIndex) + " of keyboard " + sc + " will plug into patch cable clone " + i + " (" + pcClone[i] + ")...");
        }
        
        //The patch cable's setPatchIn method also stores itself in the synth module
        pcClone[i].setPatchIn(sc, i + patchinIndex);
        
        if(DEBUG_INTERFACE_PATCH)
        {
          println("\t => successful patch in? pcClone[" + i + "] plugs into " + pcClone[i].getPatchInModule() + ", index " + pcClone[i].getPatchInIndex());
        }
      }
    }
    //For non-keyboard, including the instrumet mixer because it is cloned
    else
    {
      //Iterate over all the clones (first clone is the original sc and pc) and set the patchOut
      SynthModule[] scClone = polyphonicCompClones.get(sc);
      PatchCable[] pcClone = polyphonicPatchClones.get(pc);
    
      for(int i = 0; i < scClone.length; i++)
      {
        if(DEBUG_INTERFACE_PATCH)
        {
          println("[setPatchIn] patchinIndex " + patchinIndex + " of module clone " + i + " (" + scClone[i] + ") will plug into patch cable clone " + i + " (" + pcClone[i] + ")...");
        }
        
        //The patch cable's setPatchIn method also stores itself in the synth module
        pcClone[i].setPatchIn(scClone[i], patchinIndex);
        
        if(DEBUG_INTERFACE_PATCH)
        {
          println("\t => successful patch in? pcClone[" + i + "] plugs into " + pcClone[i].getPatchInModule() + ", index " + pcClone[i].getPatchInIndex());
        }
      }
    }
    
    //Patch-in settings complete---return true for success!
    return true;
  }
  
  //Unplugs a patch cable from the given out patch
  //To maintain polyphony, apply changes to all cloned instruments as well as ordinary ones
  //Return false when the setting fails (non-existent module OR non-existent thing to change)
  public boolean unsetPatchOut(int moduleIndex, int patchoutIndex)
  {
    //Cannot set a module if its index does not exist
    if((moduleIndex <= CustomInstrument_CONSTANTS.NO_SUCH_INDEX) || (moduleIndex >= modulesList.size()))
    {
      if(DEBUG_INTERFACE_PATCH)
      {
        println("[unsetPatchOut] moduleIndex " + moduleIndex + " is out of bounds (modulesList size " + modulesList.size() + ") => failed to unpatch out");
      }
      return false;
    }
    
    //Work with reference to the module because we will use it several times
    SynthModule sc = getSynthModule(moduleIndex); //(moduleIndex == CustomInstrument_CONSTANTS.KEYBOARD_INDEX) ? keyboard : (moduleIndex == CustomInstrument_CONSTANTS.MIXERINSTRUMENT_INDEX) ? toAudioOutput : modulesList.get(moduleIndex);
    
    //Cannot unset the patchOut if it does not exist, the accessor would return null
    if(sc.getPatchOut(patchoutIndex) == null)
    {
      if(DEBUG_INTERFACE_PATCH)
      {
        println("[unsetPatchOut] patchoutIndex " + patchoutIndex + " is out of bounds for moduleIndex " + moduleIndex + "(" + sc + ") => failed to unpatch out");
      }
      return false;
    }
    
    //Also cannot unplug into a patch if it already lacks a plugged-in cable
    if(sc.getCableOut(patchoutIndex) == null)
    {
      if(DEBUG_INTERFACE_PATCH)
      {
        println("[unsetPatchOut] patchoutIndex " + patchoutIndex + " is already unused for moduleIndex " + moduleIndex + " => failed to unpatch out");
      }
      return false;
    }
    
    //Removing patch out keyboard case because it is not cloned
    //NOTE: patchoutIndex should be either Keyboard_CONSTANTS.PATCHOUT_KEY0 or Keyboard_CONSTANTS.PATCHOUT_GATE0, and the rest is looping for polyphony
    if(sc == keyboard)
    {
      //Iterate over all the patch cable clones currently plugged in and set the patchOut to null
      PatchCable[] pcClone = polyphonicPatchClones.get(keyboard.getCableOut(patchoutIndex));
      
      for(int i = Keyboard_CONSTANTS.PATCHOUT_KEY0; i < Keyboard_CONSTANTS.TOTAL_PATCHOUT; i++)
      {
        if(DEBUG_INTERFACE_PATCH)
        {
          println("[unsetPatchOut] patchoutIndex " + (i + patchoutIndex) + " of keyboard " + sc + " will unplug patch cable clone " + i + " (" + pcClone[i] + ")...");
        }
        
        //The patch cable's setPatchOut method also stores itself in the synth module
        pcClone[i].setPatchOut(null, -1);
        
        if(DEBUG_INTERFACE_PATCH)
        {
          println("\t => successful unpatch out? pcClone[" + i + "] plugs into " + pcClone[i].getPatchOutModule() + ", index " + pcClone[i].getPatchOutIndex());
        }
      }
    }
    //For non-keyboard, including the instrument mixer (since it is cloned)
    else
    {
      //Iterate over all the clones (first clone is the original sc and the patch cable plugged into it) and set the patchOut to null
      SynthModule[] scClone = polyphonicCompClones.get(sc);
      PatchCable[] pcClone = polyphonicPatchClones.get(sc.getCableOut(patchoutIndex));
    
      for(int i = 0; i < scClone.length; i++)
      {
        if(DEBUG_INTERFACE_PATCH)
        {
          println("[unsetPatchOut] patchoutIndex " + patchoutIndex + " of module clone " + i + " (" + scClone[i] + ") will unplug patch cable clone " + i + " (" + pcClone[i] + ")...");
        }
        
        //The patch cable's setPatchOut method also stores itself in the synth module
        pcClone[i].setPatchOut(null, -1);
        
        if(DEBUG_INTERFACE_PATCH)
        {
          println("\t => successful unpatch out? pcClone[" + i + "] plugs into " + pcClone[i].getPatchOutModule() + ", index " + pcClone[i].getPatchOutIndex());
        }
      }
    }
    
    //Patch-out settings complete---return true for success!
    return true;
  }
  
  //Unplugs a patch cable from the given in patch
  //To maintain polyphony, apply changes to all cloned instruments as well as ordinary ones
  //Return false when the setting fails (non-existent module OR non-existent thing to change)
  public boolean unsetPatchIn(int moduleIndex, int patchinIndex)
  {
    //Cannot set a module if its index does not exist
    if((moduleIndex <= CustomInstrument_CONSTANTS.NO_SUCH_INDEX) || (moduleIndex >= modulesList.size()))
    {
      if(DEBUG_INTERFACE_PATCH)
      {
        println("[unsetPatchIn] moduleIndex " + moduleIndex + " is out of bounds (modulesList size " + modulesList.size() + ") => failed to unpatch in");
      }
      return false;
    }
    
    //Work with reference to the module because we will use it several times
    SynthModule sc = getSynthModule(moduleIndex); //(moduleIndex == CustomInstrument_CONSTANTS.KEYBOARD_INDEX) ? keyboard : (moduleIndex == CustomInstrument_CONSTANTS.MIXERINSTRUMENT_INDEX) ? toAudioOutput : modulesList.get(moduleIndex);
    
    //Cannot set the patchIn if it does not exist, the accessor would return null
    if(sc.getPatchIn(patchinIndex) == null)
    {
      if(DEBUG_INTERFACE_PATCH)
      {
        println("[unsetPatchIn] patchinIndex " + patchinIndex + " is out of bounds for moduleIndex " + moduleIndex + "(" + sc + ") => failed to unpatch in");
      }
      return false;
    }
    
    //Also cannot unplug into a patch if it already lacks a plugged-in cable
    if(sc.getCableIn(patchinIndex) == null)
    {
      if(DEBUG_INTERFACE_PATCH)
      {
        println("[unsetPatchIn] patchinIndex " + patchinIndex + " is already unused for moduleIndex " + moduleIndex + " => failed to unpatch in");
      }
      return false;
    }
    
    //Removing patch in keyboard case because it is not cloned---awkwardly, there are no patch-ins on the keyboard (so dead code for now)
    //NOTE: patchinIndex should be either Keyboard_CONSTANTS.PATCHOUT_KEY0 or Keyboard_CONSTANTS.PATCHOUT_GATE0, and the rest is looping for polyphony
    if(sc == keyboard)
    {
      //Iterate over all the patch cable clones currently plugged in and set the patchOut to null
      PatchCable[] pcClone = polyphonicPatchClones.get(keyboard.getCableIn(patchinIndex));
      
      for(int i = 0; i < Keyboard_CONSTANTS.TOTAL_PATCHIN; i++)
      {
        if(DEBUG_INTERFACE_PATCH)
        {
          println("[unsetPatchIn] patchinIndex " + (i + patchinIndex) + " of keyboard " + sc + " will unplug patch cable clone " + i + " (" + pcClone[i] + ")...");
        }
        
        //The patch cable's setPatchIn method also stores itself in the synth module
        pcClone[i].setPatchIn(null, -1);
        
        if(DEBUG_INTERFACE_PATCH)
        {
          println("\t => successful unpatch in? pcClone[" + i + "] plugs into " + pcClone[i].getPatchInModule() + ", index " + pcClone[i].getPatchInIndex());
        }
      }
    }
    //For non-keyboard, including the instrumet mixer because it is cloned
    else
    {
      //Iterate over all the clones (first clone is the original sc and the patch cable plugged into it) and set the patchIn to null
      SynthModule[] scClone = polyphonicCompClones.get(sc);
      PatchCable[] pcClone = polyphonicPatchClones.get(sc.getCableIn(patchinIndex));
    
      for(int i = 0; i < scClone.length; i++)
      {
        if(DEBUG_INTERFACE_PATCH)
        {
          println("[unsetPatchIn] patchinIndex " + patchinIndex + " of module clone " + i + " (" + scClone[i] + ") will unplug patch cable clone " + i + " (" + pcClone[i] + ")...");
        }
        
        //The patch cable's setPatchIn method also stores itself in the synth module
        pcClone[i].setPatchIn(null, -1);
        
        if(DEBUG_INTERFACE_PATCH)
        {
          println("\t => successful unpatch in? pcClone[" + i + "] plugs into " + pcClone[i].getPatchInModule() + ", index " + pcClone[i].getPatchInIndex());
        }
      }
    }
    
    //Patch-in settings complete---return true for success!
    return true;
  }
  
  //=========================DEBUG FUNCTIONS BELOW============================//
  //Used to setup a simple preloaded patch, intended to make debugging quick
  public void setupDebugPatch()
  {
    //Toggle the module tests, but ideally just one to avoid variable overwriting!
    //setupDebugVCO();
    //setupDebugLFO();
    //setupDebugPower();
    //setupDebugNoiseGenerator();
    //setupDebugPatchCable();
    //setupDebugMultiples1to8();
    //setupDebugMultiples2to4();
    //setupDebugVCA();
    //setupDebugEG_ADSR();
    //setupDebugKeyboard();
    //setupDebugVCF();
    //setupDebugList();
    //setupDebugPolyphonic();
    //setupDebugMixer8to1();
    //setupDebugMixer4to2();
    //setupDebugMixerInstrument();
    
    //Just patch an oscilator at a constant frequency directly to the local Summer
    //root = new Oscil(Frequency.ofPitch("A4"), 1, Waves.SQUARE);
    //root.patch(toAudioOutput);
  }
  
  public void drawDebugPatch()
  {
    //Toggle the module tests, but ideally just one to avoid variable overwriting!
    //drawDebugVCO();
    //drawDebugLFO();
    //drawDebugPower();
    //drawDebugNoiseGenerator();
    //drawDebugPatchCable();
    //drawDebugMultiples1to8();
    //drawDebugMultiples2to4();
    //drawDebugVCA();
    //drawDebugEG_ADSR();
    //drawDebugKeyboard();
    //drawDebugVCF();
    //drawDebugList();
    //drawDebugPolyphonic();
    //drawDebugMixer8to1();
    //drawDebugMixer4to2();
    //drawDebugMixerInstrument();
    drawDebugReverseFocus(); //Unlike other debug tests, this one lacks a setup and needs to use one from above!
    
    //Can now test rendering, no matter what modules are shown (copied here from 
    //  render(...) above due to change from modules to modulesList data structure
    //Need to compute global position of module in GUI
    int xOffset = Render_CONSTANTS.LEFT_BORDER_WIDTH;
    int yOffset = Render_CONSTANTS.UPPER_BORDER_HEIGHT;
    int horizSlot = 0;
    int vertSlot = 0;
    
    if(modules != null)
    {
      //Allow each module (root should be redundant) to update
      for(int i = 0; i < modules.length; i++)
      {
        if(modules[i] != null)
        {
          modules[i].draw_update();
          modules[i].render(xOffset, yOffset);
        }
      
        //Shift offsets based on tiled modules
        horizSlot++;
        if(horizSlot >= Render_CONSTANTS.TILE_HORIZ_COUNT)
        {
          horizSlot = 0;
          vertSlot++;
          xOffset = Render_CONSTANTS.LEFT_BORDER_WIDTH;
          yOffset += Render_CONSTANTS.MODULE_HEIGHT;
        
          //If the vertical offset is too great, then abandon generating more modules
          if(vertSlot >= Render_CONSTANTS.TILE_VERT_COUNT)
          {
            break;
          }
        }
        else
        {
          xOffset += Render_CONSTANTS.MODULE_WIDTH;
        }
      }
    }
    
    //The keyboard is standalone => call its update separately
    if(keyboard != null)
    {
      keyboard.draw_update();
      keyboard.render(Render_CONSTANTS.APP_WIDTH - Render_CONSTANTS.LOWER_BORDER_WIDTH, Render_CONSTANTS.APP_HEIGHT - Render_CONSTANTS.LOWER_BORDER_HEIGHT);
    }
    
    //Iterate over patches (they are rendered globally)
    if(patches != null)
    {
      for(int i = 0; i < patches.length; i++)
      {
        //Make sure the module exists first (just in case it is null)
        if(patches[i] != null)
        {
          patches[i].render();
        }
      }
    }
  }

  /*--For debugging of modules, setup and draw functions that specifically test them--*/
  private void setupDebugVCO()
  {
    root = new VCO();
    modules = new SynthModule[1];
    modules[0] = root;
    root.getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE).patch(allInstruments_toOut);
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
    modules = new SynthModule[2];
    modules[0] = root;
    modules[1] = new VCO();
    //Patch the VCO to the speaker and the LFO to the VCO's amplitude (for tremolo effect)
    root.getPatchOut(LFO_CONSTANTS.PATCHOUT_SINE).patch(modules[1].getPatchIn(VCO_CONSTANTS.PATCHIN_AMP));
    modules[1].getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE).patch(allInstruments_toOut);
    
    //To have the VCO kept constant, set the VCO knobs once and leave alone afterwards
    modules[1].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition(440.0 / 6000.0); //NOTE: Maybe allow knob to be directly set to a value?
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
    modules = new SynthModule[2];
    modules[0] = root;
    modules[1] = new VCO();
    //Patch the VCO to the speaker and the LFO to the VCO's amplitude (for tremolo effect)
    root.getPatchOut(Power_CONSTANTS.PATCHOUT_POWER).patch(modules[1].getPatchIn(VCO_CONSTANTS.PATCHIN_FREQ));
    modules[1].getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE).patch(allInstruments_toOut);
    
    //To have the VCO kept constant, set the VCO knobs once and leave alone afterwards
    modules[1].getKnob(VCO_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0); //NOTE: Maybe allow knob to be directly set to a value?
  }
  private void drawDebugPower()
  {
    root.getKnob(Power_CONSTANTS.KNOB_POWER).setCurrentPosition((float)mouseX / (float)width);
    draw_update();
  }
  
  private void setupDebugNoiseGenerator()
  {
    root = new NoiseGenerator();
    modules = new SynthModule[1];
    modules[0] = root;
    root.getPatchOut(NoiseGenerator_CONSTANTS.PATCHOUT_PINK).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE).patch(allInstruments_toOut);
  }
  private void drawDebugNoiseGenerator()
  {
    root.getKnob(NoiseGenerator_CONSTANTS.KNOB_AMP).setCurrentPosition((float)mouseY / (float)height);
    draw_update();
  }
  
  private void setupDebugPatchCable()
  {
    root = new LFO();
    modules = new SynthModule[2];
    modules[0] = root;
    modules[1] = new VCO();
    //Patch cable assigns itself and we do not need to track it (so it can garbage collect if replaced)
    //  => simply instantiate it without assigning to a variable
    patches = new PatchCable[1];
    patches[0] = new PatchCable(modules[0], LFO_CONSTANTS.PATCHOUT_TRIANGLE, modules[1], VCO_CONSTANTS.PATCHIN_AMP);
    //Patch cable still cannot connect to speaker since it is not a module... perhaps worth making it one?
    modules[1].getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE).patch(allInstruments_toOut);
    
    //Force the LFO to have max amplitude for maximum tremolo
    root.getKnob(LFO_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0);
  }
  private void drawDebugPatchCable()
  {
    modules[1].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)mouseX / (float)width);
    root.getKnob(LFO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)mouseY / (float)height);
    draw_update();
  }
  
  private void setupDebugMultiples1to8()
  {
    //For test purposes, patch the LFO to three different oscillators for a synced chord
    //  with dynamic rate of tremolo
    root = new LFO();
    modules = new SynthModule[5];
    modules[0] = root;
    modules[1] = new Multiples1to8();
    modules[2] = new VCO();
    modules[3] = new VCO();
    modules[4] = new VCO();
    patches = new PatchCable[4];
    patches[0] = new PatchCable(modules[0], LFO_CONSTANTS.PATCHOUT_TRIANGLE, modules[1], Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL);
    patches[1] = new PatchCable(modules[1], Multiples1to8_CONSTANTS.PATCHOUT_COPY0, modules[2], VCO_CONSTANTS.PATCHIN_AMP);
    patches[2] = new PatchCable(modules[1], Multiples1to8_CONSTANTS.PATCHOUT_COPY1, modules[3], VCO_CONSTANTS.PATCHIN_AMP);
    patches[3] = new PatchCable(modules[1], Multiples1to8_CONSTANTS.PATCHOUT_COPY2, modules[4], VCO_CONSTANTS.PATCHIN_AMP);
    //Patch cable still cannot connect to speaker since it is not a module... perhaps worth making it one?
    modules[2].getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    modules[3].getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    modules[4].getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    //Set the frequency knobs of the VCOs to be constant, forcing a harmonic chord
    modules[2].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)440 / (float)modules[2].getKnob(VCO_CONSTANTS.KNOB_FREQ).getMaximumValue());
    modules[3].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)(440 * pow(pow(2,1.0/12.0),5)) / (float)modules[3].getKnob(VCO_CONSTANTS.KNOB_FREQ).getMaximumValue());
    modules[4].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)(440 * pow(pow(2,1.0/12.0),9)) / (float)modules[4].getKnob(VCO_CONSTANTS.KNOB_FREQ).getMaximumValue());
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE).patch(allInstruments_toOut);
    
    //Force the LFO to have max amplitude for maximum tremolo
    root.getKnob(LFO_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0);
  }
  private void drawDebugMultiples1to8()
  {
    root.getKnob(LFO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)mouseY / (float)height);
    draw_update();
  }
  
  private void setupDebugMultiples2to4()
  {
    //For test purposes, patch the LFO to three different oscillators for a synced chord
    //  with dynamic rate of tremolo; do this with two different LFOs
    root = new LFO();
    modules = new SynthModule[9];
    modules[0] = root;
    modules[1] = new Multiples2to4();
    modules[2] = new VCO();
    modules[3] = new VCO();
    modules[4] = new VCO();
    modules[5] = new LFO();
    modules[6] = new VCO();
    modules[7] = new VCO();
    modules[8] = new VCO();
    patches = new PatchCable[8];
    patches[0] = new PatchCable(modules[0], LFO_CONSTANTS.PATCHOUT_TRIANGLE, modules[1], Multiples2to4_CONSTANTS.PATCHIN_ORIGINAL0);
    patches[1] = new PatchCable(modules[1], Multiples2to4_CONSTANTS.PATCHOUT_COPY00, modules[2], VCO_CONSTANTS.PATCHIN_AMP);
    patches[2] = new PatchCable(modules[1], Multiples2to4_CONSTANTS.PATCHOUT_COPY01, modules[3], VCO_CONSTANTS.PATCHIN_AMP);
    patches[3] = new PatchCable(modules[1], Multiples2to4_CONSTANTS.PATCHOUT_COPY02, modules[4], VCO_CONSTANTS.PATCHIN_AMP);
    patches[4] = new PatchCable(modules[5], LFO_CONSTANTS.PATCHOUT_SQUARE, modules[1], Multiples2to4_CONSTANTS.PATCHIN_ORIGINAL1);
    patches[5] = new PatchCable(modules[1], Multiples2to4_CONSTANTS.PATCHOUT_COPY10, modules[6], VCO_CONSTANTS.PATCHIN_AMP);
    patches[6] = new PatchCable(modules[1], Multiples2to4_CONSTANTS.PATCHOUT_COPY11, modules[7], VCO_CONSTANTS.PATCHIN_AMP);
    patches[7] = new PatchCable(modules[1], Multiples2to4_CONSTANTS.PATCHOUT_COPY12, modules[8], VCO_CONSTANTS.PATCHIN_AMP);
    //Patch cable still cannot connect to speaker since it is not a module... perhaps worth making it one?
    modules[2].getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    modules[3].getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    modules[4].getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    modules[6].getPatchOut(VCO_CONSTANTS.PATCHOUT_TRIANGLE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    modules[7].getPatchOut(VCO_CONSTANTS.PATCHOUT_TRIANGLE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    modules[8].getPatchOut(VCO_CONSTANTS.PATCHOUT_TRIANGLE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    //Set the frequency knobs of the VCOs to be constant, forcing a harmonic chord
    modules[2].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)440 / (float)modules[2].getKnob(VCO_CONSTANTS.KNOB_FREQ).getMaximumValue());
    modules[3].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)(440 * pow(pow(2,1.0/12.0),5)) / (float)modules[3].getKnob(VCO_CONSTANTS.KNOB_FREQ).getMaximumValue());
    modules[4].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)(440 * pow(pow(2,1.0/12.0),9)) / (float)modules[4].getKnob(VCO_CONSTANTS.KNOB_FREQ).getMaximumValue());
    modules[6].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)220 / (float)modules[6].getKnob(VCO_CONSTANTS.KNOB_FREQ).getMaximumValue());
    modules[7].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)(220 * pow(pow(2,1.0/12.0),5)) / (float)modules[7].getKnob(VCO_CONSTANTS.KNOB_FREQ).getMaximumValue());
    modules[8].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)(220 * pow(pow(2,1.0/12.0),9)) / (float)modules[8].getKnob(VCO_CONSTANTS.KNOB_FREQ).getMaximumValue());
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE).patch(allInstruments_toOut);
    
    //Force the LFO to have max amplitude for maximum tremolo
    root.getKnob(LFO_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0);
    modules[5].getKnob(LFO_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0);
  }
  private void drawDebugMultiples2to4()
  {
    root.getKnob(LFO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)mouseY / (float)height);
    modules[5].getKnob(LFO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)mouseX / (float)width);
    draw_update();
  }
  
  private void setupDebugVCA()
  {
    //Rather than another boring volume change, let's use the extremely large amplitudes
    //  for a noticeable frequency modulation!
    root = new VCO();
    modules = new SynthModule[3];
    modules[0] = root;
    modules[1] = new VCA();
    modules[2] = new VCO();
    patches = new PatchCable[2];
    patches[0] = new PatchCable(modules[0], VCO_CONSTANTS.PATCHOUT_SINE, modules[1], VCA_CONSTANTS.PATCHIN_WAVE);
    patches[1] = new PatchCable(modules[1], VCA_CONSTANTS.PATCHOUT_WAVE, modules[2], VCO_CONSTANTS.PATCHIN_FREQ);
    //Patch cable still cannot connect to speaker since it is not a module... perhaps worth making it one?
    modules[2].getPatchOut(VCO_CONSTANTS.PATCHOUT_SQUARE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE).patch(allInstruments_toOut);
    
    //Force the non-modulated knobs to have fixed values for testing purposes
    root.getKnob(VCO_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0);
    modules[2].getKnob(VCO_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0);
    modules[2].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)440 / (float)modules[2].getKnob(VCO_CONSTANTS.KNOB_FREQ).getMaximumValue()); //Need a base frequency
  }
  private void drawDebugVCA()
  {
    root.getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)mouseY / (float)height);
    modules[1].getKnob(VCA_CONSTANTS.KNOB_AMP).setCurrentPosition((float)mouseX / (float)width);
    draw_update();
  }
  
  private void setupDebugEG_ADSR()
  {
    root = new Power(); //Pseudo-keyboard, will flip like a switch instead of knob
    modules = new SynthModule[4];
    modules[0] = root;
    modules[1] = new VCO();
    modules[2] = new Multiples1to8(); //Will copy the power to use for frequency and gate
    modules[3] = new EnvelopeGenerator();
    patches = new PatchCable[4];
    patches[0] = new PatchCable(modules[0], Power_CONSTANTS.PATCHOUT_POWER, modules[2], Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL);
    patches[1] = new PatchCable(modules[2], Multiples1to8_CONSTANTS.PATCHOUT_COPY0, modules[1], VCO_CONSTANTS.PATCHIN_FREQ);
    //patches[2] = new PatchCable(modules[2], Multiples_CONSTANTS.PATCHOUT_COPY1, modules[3], EnvelopeGenerator_CONSTANTS.GATE_PLAYNOTE);
    patches[2] = new PatchCable(modules[2], Multiples1to8_CONSTANTS.PATCHOUT_COPY1, modules[3], EnvelopeGenerator_CONSTANTS.PATCHIN_GATE);
    patches[3] = new PatchCable(modules[1], VCO_CONSTANTS.PATCHOUT_SQUARE, modules[3], EnvelopeGenerator_CONSTANTS.PATCHIN_WAVE);
    
    //Patch cable still cannot connect to speaker since it is not a module... perhaps worth making it one?
    modules[3].getPatchOut(EnvelopeGenerator_CONSTANTS.PATCHOUT_WAVE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE).patch(allInstruments_toOut);
    
    //Force the unmodified knobs to have fixed values for testing purposes (ADSR has too many on its own)
    modules[1].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition(0.0); //Only Power sets the frequency
    modules[1].getKnob(VCO_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0);
    modules[3].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_STARTAMP).setCurrentPosition(0.0);
    modules[3].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_ENDAMP).setCurrentPosition(0.0);
    modules[3].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_MAXAMP).setCurrentPosition(1.0);
    modules[3].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_SUSTAIN).setCurrentPosition(0.5);
    modules[3].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_DECAY).setCurrentPosition(0.333333); //Since [0,3], this should be about 1 second
  }
  private void drawDebugEG_ADSR()
  {
    //Set the attack and release based on the mouse position
    modules[3].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_ATTACK).setCurrentPosition((float)mouseX / (float)width);
    modules[3].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_RELEASE).setCurrentPosition((float)mouseY / (float)height);
    //Use the square brackets to set the power knob, acting more like a switch flip
    if(key == '[')
    {
      modules[0].getKnob(Power_CONSTANTS.KNOB_POWER).setCurrentPosition((float)440 / (float)modules[0].getKnob(Power_CONSTANTS.KNOB_POWER).getMaximumValue());
      System.out.println("Turn on the power!");
    }
    else if(key == ']')
    {
      modules[0].getKnob(Power_CONSTANTS.KNOB_POWER).setCurrentPosition(0.0);
      System.out.println("Turn off the power!");
    }
    draw_update();
  }
  
  private void setupDebugKeyboard()
  {
    root = new Keyboard();
    modules = new SynthModule[31]; //Yes, it is a lot because we need one envelope, multiple, and oscillator per key
    patches = new PatchCable[40]; //Because each key's setup needs 4 patches, phew!
    modules[0] = root;
    for(int i = Keyboard_CONSTANTS.PATCHOUT_KEY0; i < Keyboard_CONSTANTS.TOTAL_PATCHOUT; i++)
    {
      //Instantiate the trio of modules that go with a single key
      modules[1 + (3 * i)] = new Multiples1to8();
      modules[2 + (3 * i)] = new EnvelopeGenerator();
      modules[3 + (3 * i)] = new VCO();
      //Simple patch to make an enveloped square wave play for the key
      patches[4 * i] = new PatchCable(modules[0], i, modules[1 + (3 * i)], Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL);
      patches[1 + (4 * i)] = new PatchCable(modules[1 + (3 * i)], Multiples1to8_CONSTANTS.PATCHOUT_COPY0, modules[2 + (3 * i)], EnvelopeGenerator_CONSTANTS.PATCHIN_GATE);
      patches[2 + (4 * i)] = new PatchCable(modules[1 + (3 * i)], Multiples1to8_CONSTANTS.PATCHOUT_COPY1, modules[3 + (3 * i)], VCO_CONSTANTS.PATCHIN_FREQ);
      patches[3 + (4 * i)] = new PatchCable(modules[3 + (3 * i)], VCO_CONSTANTS.PATCHOUT_SQUARE, modules[2 + (3 * i)], EnvelopeGenerator_CONSTANTS.PATCHIN_WAVE);
      
      //Patch cable still cannot connect to speaker since it is not a module... perhaps worth making it one?
      modules[2 + (3 * i)].getPatchOut(EnvelopeGenerator_CONSTANTS.PATCHOUT_WAVE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
      
      //Force the unmodified knobs to have fixed values for testing purposes (ADSR has too many on its own)
      modules[3 + (3 * i)].getKnob(VCO_CONSTANTS.KNOB_FREQ).setCurrentPosition(0.0); //Only Keyboard sets the frequency
      modules[3 + (3 * i)].getKnob(VCO_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0);
      modules[2 + (3 * i)].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_STARTAMP).setCurrentPosition(0.0);
      modules[2 + (3 * i)].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_ENDAMP).setCurrentPosition(0.0);
      modules[2 + (3 * i)].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_MAXAMP).setCurrentPosition(1.0);
      modules[2 + (3 * i)].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_SUSTAIN).setCurrentPosition(0.5);
      modules[2 + (3 * i)].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_DECAY).setCurrentPosition(0.333333); //Since [0,3], this should be about 1 second
      modules[2 + (3 * i)].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_ATTACK).setCurrentPosition(0.16667); //Since [0,3], this should be about 0.5 seconds
      modules[2 + (3 * i)].getKnob(EnvelopeGenerator_CONSTANTS.KNOB_RELEASE).setCurrentPosition(0.666667); //Since [0,3], this should be about 2 seconds
    }
    
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE).patch(allInstruments_toOut);
  }
  private void drawDebugKeyboard()
  {
    //To avoid needing to integrate the test with the keyPress and keyRelease listeners,
    //  simply assume the lowercase turns a note on and uppercase turns it off (use the
    //  lowercase character for the sake of binding)
    if(Character.isLowerCase(key))
    {
      int assignedIndex = ((Keyboard)modules[0]).set_key(key, Frequency.ofMidiNote(60.0 + Character.getNumericValue(key)).asHz());
      if(assignedIndex >= 0)
      {
        System.out.println("Playing key " + assignedIndex + " bound to " + key + " (midi #" + Character.getNumericValue(key) + " => " + Frequency.ofMidiNote(60.0 + Character.getNumericValue(key)).asHz() + " Hz)");
      }
    }
    else if(Character.isUpperCase(key))
    {
      boolean unassignedIndex = ((Keyboard)modules[0]).unset_key(Character.toLowerCase(key));
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
    modules = new SynthModule[3];
    modules[0] = root;
    modules[1] = new VCA();
    modules[2] = new NoiseGenerator();
    patches = new PatchCable[2];
    patches[0] = new PatchCable(modules[2], NoiseGenerator_CONSTANTS.PATCHOUT_PINK, modules[0], VCF_CONSTANTS.PATCHIN_WAVE);
    patches[1] = new PatchCable(modules[0], VCF_CONSTANTS.PATCHOUT_WAVE, modules[1], VCA_CONSTANTS.PATCHIN_WAVE);
    //Patch cable still cannot connect to speaker since it is not a module... perhaps worth making it one?
    modules[1].getPatchOut(VCA_CONSTANTS.PATCHOUT_WAVE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE).patch(allInstruments_toOut);
    
    //Force the non-modulated knobs to have fixed values for testing purposes
    root.getKnob(VCF_CONSTANTS.KNOB_RES).setCurrentPosition(0.0); //No resonance
    modules[1].getKnob(VCA_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0); //Set the volume all the way up
    modules[2].getKnob(NoiseGenerator_CONSTANTS.KNOB_AMP).setCurrentPosition(1.0); //Set the volume all the way up
  }
  private void drawDebugVCF()
  {
    root.getKnob(VCF_CONSTANTS.KNOB_FREQ).setCurrentPosition((float)mouseY / (float)height);
    root.getKnob(VCF_CONSTANTS.KNOB_PASS).setCurrentPosition((float)mouseX / (float)width);
    draw_update();
  }
  
  /*--For debugging of modulesList (new format setup, with additional fuctions that use
      these data structures, setup and draw functions that specifically test them--*/
  //Recreates the EG (envelope generator) debug test above, but now with polyphonic support
  private void setupDebugList()
  {
    try
    {
      addSynthModule(new Power()); //Pseudo-keyboard, will flip like a switch instead of knob
      addSynthModule(new VCO());
      addSynthModule(new Multiples1to8()); //Will copy the power to use for frequency and gate
      addSynthModule(new EnvelopeGenerator());
    }
    catch(Exception e)
    {
      System.out.println("ERROR: " + e + "\n\tWhen defining modules in setupDebugList");
    }
    addPatchCable(new PatchCable(modulesList.get(0), Power_CONSTANTS.PATCHOUT_POWER, modulesList.get(2), Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL));
    addPatchCable(new PatchCable(modulesList.get(2), Multiples1to8_CONSTANTS.PATCHOUT_COPY0, modulesList.get(1), VCO_CONSTANTS.PATCHIN_FREQ));
    addPatchCable(new PatchCable(modulesList.get(2), Multiples1to8_CONSTANTS.PATCHOUT_COPY1, modulesList.get(3), EnvelopeGenerator_CONSTANTS.PATCHIN_GATE));
    addPatchCable(new PatchCable(modulesList.get(1), VCO_CONSTANTS.PATCHOUT_SQUARE, modulesList.get(3), EnvelopeGenerator_CONSTANTS.PATCHIN_WAVE));
    
    //Patch cable still cannot connect to speaker since it is not a module... perhaps worth making it one?
    modulesList.get(3).getPatchOut(EnvelopeGenerator_CONSTANTS.PATCHOUT_WAVE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE).patch(allInstruments_toOut);
    
    //Force the unmodified knobs to have fixed values for testing purposes (ADSR has too many on its own)
    println("Setting knobs results: "
      + "\n\t" + setKnob(1, VCO_CONSTANTS.KNOB_FREQ, 0.0) //; //Only Power sets the frequency
      + "\n\t" + setKnob(1, VCO_CONSTANTS.KNOB_AMP, 1.0) //;
      + "\n\t" + setKnob(3, EnvelopeGenerator_CONSTANTS.KNOB_STARTAMP, 0.0) //;
      + "\n\t" + setKnob(3, EnvelopeGenerator_CONSTANTS.KNOB_ENDAMP, 0.0) //;
      + "\n\t" + setKnob(3, EnvelopeGenerator_CONSTANTS.KNOB_MAXAMP, 1.0) //;
      + "\n\t" + setKnob(3, EnvelopeGenerator_CONSTANTS.KNOB_SUSTAIN, 0.5) //;
      + "\n\t" + setKnob(3, EnvelopeGenerator_CONSTANTS.KNOB_DECAY, 0.333333)); //Since [0,3], this should be about 1 second
  }
  private void drawDebugList()
  {
    //Set the attack and release based on the mouse position
    setKnob(3, EnvelopeGenerator_CONSTANTS.KNOB_ATTACK, (float)mouseX / (float)width);
    setKnob(3, EnvelopeGenerator_CONSTANTS.KNOB_RELEASE, (float)mouseY / (float)height);
    //Use the square brackets to set the power knob, acting more like a switch flip
    if(key == '[')
    {
      setKnob(0, Power_CONSTANTS.KNOB_POWER, (float)440 / (float)modulesList.get(0).getKnob(Power_CONSTANTS.KNOB_POWER).getMaximumValue());
      System.out.println("Turn on the power!");
    }
    else if(key == ']')
    {
      setKnob(0, Power_CONSTANTS.KNOB_POWER, 0.0);
      System.out.println("Turn off the power!");
    }
    draw_update();
  }
  
  /*--For debugging of polyphonic setup--*/
  //Recreates the Keyboard debug test above, but now with polyphonic support via the 
  //  keyboard object (not one we insert into the instrument)
  public void setupDebugPolyphonic()
  {
    try
    {
      addSynthModule(new Multiples1to8());
      addSynthModule(new EnvelopeGenerator());
      addSynthModule(new VCO());
    }
    catch(Exception e)
    {
      System.out.println("ERROR: " + e + "\n\tWhen defining modules in setupDebugPolyphonic");
    }
    
    //Simple patch to make an enveloped square wave play for the key
    addPatchCable(new PatchCable(keyboard, Keyboard_CONSTANTS.PATCHOUT_KEY0, modulesList.get(0), Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL));
    addPatchCable(new PatchCable(modulesList.get(0), Multiples1to8_CONSTANTS.PATCHOUT_COPY0, modulesList.get(1), EnvelopeGenerator_CONSTANTS.PATCHIN_GATE));
    addPatchCable(new PatchCable(modulesList.get(0), Multiples1to8_CONSTANTS.PATCHOUT_COPY1, modulesList.get(2), VCO_CONSTANTS.PATCHIN_FREQ));
    addPatchCable(new PatchCable(modulesList.get(2), VCO_CONSTANTS.PATCHOUT_SQUARE, modulesList.get(1), EnvelopeGenerator_CONSTANTS.PATCHIN_WAVE));
      
    //Patch cable still cannot connect to speaker since it is not a module... perhaps worth making it one?
    println("Now connecting all " + polyphonicCompClones.get(modulesList.get(1)).length + " clones of Envelope Generator to the audio output");
    for(SynthModule eg : polyphonicCompClones.get(modulesList.get(1)))
    {
      eg.getPatchOut(EnvelopeGenerator_CONSTANTS.PATCHOUT_WAVE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    }
      
    //Force the unmodified knobs to have fixed values for testing purposes (ADSR has too many on its own)
    setKnob(2, VCO_CONSTANTS.KNOB_FREQ, 0.0); //Only Keyboard sets the frequency
    setKnob(2, VCO_CONSTANTS.KNOB_AMP, 1.0);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_STARTAMP, 0.0);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_ENDAMP, 0.0);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_MAXAMP, 1.0);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_SUSTAIN, 0.5);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_DECAY, 0.333333); //Since [0,3], this should be about 1 second
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_ATTACK, 0.16667); //Since [0,3], this should be about 0.5 seconds
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_RELEASE, 0.666667); //Since [0,3], this should be about 2 seconds
    
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE).patch(allInstruments_toOut);
  }
  public void drawDebugPolyphonic()
  {
    //To avoid needing to integrate the test with the keyPress and keyRelease listeners,
    //  simply assume the lowercase turns a note on and uppercase turns it off (use the
    //  lowercase character for the sake of binding)
    if(Character.isLowerCase(key))
    {
      int assignedIndex = keyboard.set_key(key, Frequency.ofMidiNote(60.0 + Character.getNumericValue(key)).asHz());
      if(assignedIndex >= 0)
      {
        System.out.println("Playing key " + assignedIndex + " bound to " + key + " (midi #" + Character.getNumericValue(key) + " => " + Frequency.ofMidiNote(60.0 + Character.getNumericValue(key)).asHz() + " Hz)");
      }
    }
    else if(Character.isUpperCase(key))
    {
      boolean unassignedIndex = keyboard.unset_key(Character.toLowerCase(key));
      if(unassignedIndex)
      {
        System.out.println("Stopping key bound to " + key + " (midi #" + Character.getNumericValue(key) + " => " + Frequency.ofMidiNote(60.0 + Character.getNumericValue(key)).asHz() + " Hz)");
      }
    }
    
    draw_update(); //Lesson learned from this debug---need to let draw_update call the clones as well!
  }
  
  //Recreates the Polyphonic (which recreated the Keyboard) debug test above, but now
  //  with polyphonic support via the keyboard object and a mixer
  //NOTE: To test the mixing part, also include an ongoing wave tone (so keyboard adds another sound to it)
  public void setupDebugMixer8to1()
  {
    try
    {
      addSynthModule(new Multiples1to8());
      addSynthModule(new EnvelopeGenerator());
      addSynthModule(new VCO());
      addSynthModule(new Mixer8to1());
    }
    catch(Exception e)
    {
      System.out.println("ERROR: " + e + "\n\tWhen defining modules in setupDebugMixer8to1");
    }
    
    //Simple patch to make an enveloped square wave play for the key
    addPatchCable(new PatchCable(keyboard, Keyboard_CONSTANTS.PATCHOUT_KEY0, modulesList.get(0), Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL));
    addPatchCable(new PatchCable(modulesList.get(0), Multiples1to8_CONSTANTS.PATCHOUT_COPY0, modulesList.get(1), EnvelopeGenerator_CONSTANTS.PATCHIN_GATE));
    addPatchCable(new PatchCable(modulesList.get(0), Multiples1to8_CONSTANTS.PATCHOUT_COPY1, modulesList.get(2), VCO_CONSTANTS.PATCHIN_FREQ));
    addPatchCable(new PatchCable(modulesList.get(2), VCO_CONSTANTS.PATCHOUT_SQUARE, modulesList.get(1), EnvelopeGenerator_CONSTANTS.PATCHIN_WAVE));
    addPatchCable(new PatchCable(modulesList.get(1), EnvelopeGenerator_CONSTANTS.PATCHOUT_WAVE, modulesList.get(3), Mixer8to1_CONSTANTS.PATCHIN_ORIGINAL0));
    //Also patch an ongoing tone through the mixer to test it
    addPatchCable(new PatchCable(modulesList.get(2), VCO_CONSTANTS.PATCHOUT_TRIANGLE, modulesList.get(3), Mixer8to1_CONSTANTS.PATCHIN_ORIGINAL1));
      
    //Patch cable still cannot connect to speaker since it is not a module... perhaps worth making it one?
    //NOTE: If this works, then will make a special mixer module for the instrument!
    println("Now connecting all " + polyphonicCompClones.get(modulesList.get(1)).length + " clones of Envelope Generator to the audio output");
    for(SynthModule mx : polyphonicCompClones.get(modulesList.get(3)))
    {
      mx.getPatchOut(Mixer8to1_CONSTANTS.PATCHOUT_MERGE).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    }
      
    //Force the unmodified knobs to have fixed values for testing purposes (ADSR has too many on its own)
    setKnob(2, VCO_CONSTANTS.KNOB_FREQ, 0.0); //Only Keyboard sets the frequency
    setKnob(2, VCO_CONSTANTS.KNOB_AMP, 1.0);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_STARTAMP, 0.0);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_ENDAMP, 0.0);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_MAXAMP, 1.0);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_SUSTAIN, 0.5);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_DECAY, 0.333333); //Since [0,3], this should be about 1 second
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_ATTACK, 0.16667); //Since [0,3], this should be about 0.5 seconds
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_RELEASE, 0.666667); //Since [0,3], this should be about 2 seconds
    
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE).patch(allInstruments_toOut);
  }
  public void drawDebugMixer8to1()
  {
    //To avoid needing to integrate the test with the keyPress and keyRelease listeners,
    //  simply assume the lowercase turns a note on and uppercase turns it off (use the
    //  lowercase character for the sake of binding)
    if(Character.isLowerCase(key))
    {
      int assignedIndex = keyboard.set_key(key, Frequency.ofMidiNote(60.0 + Character.getNumericValue(key)).asHz());
      if(assignedIndex >= 0)
      {
        System.out.println("Playing key " + assignedIndex + " bound to " + key + " (midi #" + Character.getNumericValue(key) + " => " + Frequency.ofMidiNote(60.0 + Character.getNumericValue(key)).asHz() + " Hz)");
      }
    }
    else if(Character.isUpperCase(key))
    {
      boolean unassignedIndex = keyboard.unset_key(Character.toLowerCase(key));
      if(unassignedIndex)
      {
        System.out.println("Stopping key bound to " + key + " (midi #" + Character.getNumericValue(key) + " => " + Frequency.ofMidiNote(60.0 + Character.getNumericValue(key)).asHz() + " Hz)");
      }
    }
    
    //Try out the mixer's volume knobs with the mouse
    setKnob(3, Mixer8to1_CONSTANTS.KNOB_VOL0, (float)mouseX / (float)width);
    setKnob(3, Mixer8to1_CONSTANTS.KNOB_VOL1, (float)mouseY / (float)height);
    
    draw_update(); //Lesson learned from this debug---need to let draw_update call the clones as well!
  }
  
  //Recreates the Polyphonic (which recreated the Keyboard) debug test above, but now
  //  with polyphonic support via the keyboard object and a mixer
  //NOTE: To test the mixing part, also include an ongoing wave tone (so keyboard adds another sound to it)
  public void setupDebugMixer4to2()
  {
    try
    {
      addSynthModule(new Multiples1to8());
      addSynthModule(new EnvelopeGenerator());
      addSynthModule(new VCO());
      addSynthModule(new Mixer4to2());
    }
    catch(Exception e)
    {
      System.out.println("ERROR: " + e + "\n\tWhen defining modules in setupDebugMixer8to1");
    }
    
    //Simple patch to make an enveloped square wave play for the key
    addPatchCable(new PatchCable(keyboard, Keyboard_CONSTANTS.PATCHOUT_KEY0, modulesList.get(0), Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL));
    addPatchCable(new PatchCable(modulesList.get(0), Multiples1to8_CONSTANTS.PATCHOUT_COPY0, modulesList.get(1), EnvelopeGenerator_CONSTANTS.PATCHIN_GATE));
    addPatchCable(new PatchCable(modulesList.get(0), Multiples1to8_CONSTANTS.PATCHOUT_COPY1, modulesList.get(2), VCO_CONSTANTS.PATCHIN_FREQ));
    addPatchCable(new PatchCable(modulesList.get(2), VCO_CONSTANTS.PATCHOUT_SQUARE, modulesList.get(1), EnvelopeGenerator_CONSTANTS.PATCHIN_WAVE));
    addPatchCable(new PatchCable(modulesList.get(1), EnvelopeGenerator_CONSTANTS.PATCHOUT_WAVE, modulesList.get(3), Mixer4to2_CONSTANTS.PATCHIN_ORIGINAL0));
    //Also patch an ongoing tone through the mixer to test it
    addPatchCable(new PatchCable(modulesList.get(2), VCO_CONSTANTS.PATCHOUT_TRIANGLE, modulesList.get(3), Mixer4to2_CONSTANTS.PATCHIN_ORIGINAL7));
      
    //Patch cable still cannot connect to speaker since it is not a module... perhaps worth making it one?
    //NOTE: If this works, then will make a special mixer module for the instrument!
    println("Now connecting all " + polyphonicCompClones.get(modulesList.get(1)).length + " clones of Envelope Generator to the audio output");
    for(SynthModule mx : polyphonicCompClones.get(modulesList.get(3)))
    {
      mx.getPatchOut(Mixer4to2_CONSTANTS.PATCHOUT_MERGE0).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
      mx.getPatchOut(Mixer4to2_CONSTANTS.PATCHOUT_MERGE1).patch(toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE));
    }
      
    //Force the unmodified knobs to have fixed values for testing purposes (ADSR has too many on its own)
    setKnob(2, VCO_CONSTANTS.KNOB_FREQ, 0.0); //Only Keyboard sets the frequency
    setKnob(2, VCO_CONSTANTS.KNOB_AMP, 1.0);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_STARTAMP, 0.0);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_ENDAMP, 0.0);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_MAXAMP, 1.0);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_SUSTAIN, 0.5);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_DECAY, 0.333333); //Since [0,3], this should be about 1 second
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_ATTACK, 0.16667); //Since [0,3], this should be about 0.5 seconds
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_RELEASE, 0.666667); //Since [0,3], this should be about 2 seconds
    
    //Not using the instrument notes, so have to patch to the speaker ourselves for constant sound
    toAudioOutput.getPatchOut(MixerInstrument_CONSTANTS.PATCHOUT_MERGE).patch(allInstruments_toOut);
  }
  public void drawDebugMixer4to2()
  {
    //To avoid needing to integrate the test with the keyPress and keyRelease listeners,
    //  simply assume the lowercase turns a note on and uppercase turns it off (use the
    //  lowercase character for the sake of binding)
    if(Character.isLowerCase(key))
    {
      int assignedIndex = keyboard.set_key(key, Frequency.ofMidiNote(60.0 + Character.getNumericValue(key)).asHz());
      if(assignedIndex >= 0)
      {
        System.out.println("Playing key " + assignedIndex + " bound to " + key + " (midi #" + Character.getNumericValue(key) + " => " + Frequency.ofMidiNote(60.0 + Character.getNumericValue(key)).asHz() + " Hz)");
      }
    }
    else if(Character.isUpperCase(key))
    {
      boolean unassignedIndex = keyboard.unset_key(Character.toLowerCase(key));
      if(unassignedIndex)
      {
        System.out.println("Stopping key bound to " + key + " (midi #" + Character.getNumericValue(key) + " => " + Frequency.ofMidiNote(60.0 + Character.getNumericValue(key)).asHz() + " Hz)");
      }
    }
    
    //Try out the mixer's volume knobs with the mouse
    setKnob(3, Mixer8to1_CONSTANTS.KNOB_VOL0, (float)mouseX / (float)width);
    setKnob(3, Mixer8to1_CONSTANTS.KNOB_VOL7, (float)mouseY / (float)height);
    
    draw_update(); //Lesson learned from this debug---need to let draw_update call the clones as well!
  }
  
  //Recreates the Mixer1to8 (which recreated the Polyphonic ) debug test above, but now
  //  with polyphonic support via the keyboard object and a mixer for the overall instrument
  //NOTE: To test the mixing part, also include an ongoing wave tone (so keyboard adds another sound to it)
  public void setupDebugMixerInstrument()
  {
    try
    {
      addSynthModule(new Multiples1to8());
      addSynthModule(new EnvelopeGenerator());
      addSynthModule(new VCO());
    }
    catch(Exception e)
    {
      System.out.println("ERROR: " + e + "\n\tWhen defining modules in setupDebugMixer8to1");
    }
    
    //Simple patch to make an enveloped square wave play for the key
    addPatchCable(new PatchCable(keyboard, Keyboard_CONSTANTS.PATCHOUT_KEY0, modulesList.get(0), Multiples1to8_CONSTANTS.PATCHIN_ORIGINAL));
    addPatchCable(new PatchCable(modulesList.get(0), Multiples1to8_CONSTANTS.PATCHOUT_COPY0, modulesList.get(1), EnvelopeGenerator_CONSTANTS.PATCHIN_GATE));
    addPatchCable(new PatchCable(modulesList.get(0), Multiples1to8_CONSTANTS.PATCHOUT_COPY1, modulesList.get(2), VCO_CONSTANTS.PATCHIN_FREQ));
    addPatchCable(new PatchCable(modulesList.get(2), VCO_CONSTANTS.PATCHOUT_SQUARE, modulesList.get(1), EnvelopeGenerator_CONSTANTS.PATCHIN_WAVE));
    //Setup the patches to now use the instrument's mixer
    addPatchCable(new PatchCable(modulesList.get(1), EnvelopeGenerator_CONSTANTS.PATCHOUT_WAVE, toAudioOutput, MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL0));
    //Also patch an ongoing tone through the mixer to test it
    addPatchCable(new PatchCable(modulesList.get(2), VCO_CONSTANTS.PATCHOUT_TRIANGLE, toAudioOutput, MixerInstrument_CONSTANTS.PATCHIN_ORIGINAL1));
      
    //Force the unmodified knobs to have fixed values for testing purposes (ADSR has too many on its own)
    setKnob(2, VCO_CONSTANTS.KNOB_FREQ, 0.0); //Only Keyboard sets the frequency
    setKnob(2, VCO_CONSTANTS.KNOB_AMP, 1.0);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_STARTAMP, 0.0);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_ENDAMP, 0.0);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_MAXAMP, 1.0);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_SUSTAIN, 0.5);
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_DECAY, 0.333333); //Since [0,3], this should be about 1 second
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_ATTACK, 0.16667); //Since [0,3], this should be about 0.5 seconds
    setKnob(1, EnvelopeGenerator_CONSTANTS.KNOB_RELEASE, 0.666667); //Since [0,3], this should be about 2 seconds
  }
  public void drawDebugMixerInstrument()
  {
    //To avoid needing to integrate the test with the keyPress and keyRelease listeners,
    //  simply assume the lowercase turns a note on and uppercase turns it off (use the
    //  lowercase character for the sake of binding)
    if(Character.isLowerCase(key))
    {
      int assignedIndex = keyboard.set_key(key, Frequency.ofMidiNote(60.0 + Character.getNumericValue(key)).asHz());
      if(assignedIndex >= 0)
      {
        System.out.println("Playing key " + assignedIndex + " bound to " + key + " (midi #" + Character.getNumericValue(key) + " => " + Frequency.ofMidiNote(60.0 + Character.getNumericValue(key)).asHz() + " Hz)");
      }
    }
    else if(Character.isUpperCase(key))
    {
      boolean unassignedIndex = keyboard.unset_key(Character.toLowerCase(key));
      if(unassignedIndex)
      {
        System.out.println("Stopping key bound to " + key + " (midi #" + Character.getNumericValue(key) + " => " + Frequency.ofMidiNote(60.0 + Character.getNumericValue(key)).asHz() + " Hz)");
      }
    }
    
    //Try out the mixer's volume knobs with the mouse
    setKnob(CustomInstrument_CONSTANTS.MIXERINSTRUMENT_INDEX, MixerInstrument_CONSTANTS.KNOB_VOL0, (float)mouseX / (float)width);
    setKnob(CustomInstrument_CONSTANTS.MIXERINSTRUMENT_INDEX, MixerInstrument_CONSTANTS.KNOB_VOL1, (float)mouseY / (float)height);
    
    draw_update(); //Lesson learned from this debug---need to let draw_update call the clones as well!
  }
  
  //Simply prints to what a mouse click corresponds on the screen, testing for the GUI
  public void drawDebugReverseFocus()
  {
    //Check if a left mouse click occurred, and print information about the click if so
    if(mousePressed && (mouseButton == LEFT))
    {
      print("Mouse clicked at (" + mouseX + ", " + mouseY + "): ");
      SynthModule focus = getSynthModuleAt(mouseX, mouseY);
      if(focus != null)
      {
        println("synth module in the click = " + focus);
        //Need to figure out the coordinates for focus's placement
        int compIndex = findSynthModuleIndex(focus);
        int topLeftX = getModuleTopLeftX(compIndex); //(compIndex == CustomInstrument_CONSTANTS.KEYBOARD_INDEX) ? (Render_CONSTANTS.APP_WIDTH - Render_CONSTANTS.LOWER_BORDER_WIDTH) : (compIndex == CustomInstrument_CONSTANTS.MIXERINSTRUMENT_INDEX) ? (Render_CONSTANTS.APP_WIDTH - Render_CONSTANTS.RIGHT_BORDER_WIDTH) : (Render_CONSTANTS.LEFT_BORDER_WIDTH + (Render_CONSTANTS.MODULE_WIDTH * (compIndex % Render_CONSTANTS.TILE_HORIZ_COUNT)));
        int topLeftY = getModuleTopLeftY(compIndex); //(compIndex == CustomInstrument_CONSTANTS.KEYBOARD_INDEX) ? (Render_CONSTANTS.APP_HEIGHT - Render_CONSTANTS.LOWER_BORDER_HEIGHT) : (compIndex == CustomInstrument_CONSTANTS.MIXERINSTRUMENT_INDEX) ? (Render_CONSTANTS.UPPER_BORDER_HEIGHT) : (Render_CONSTANTS.UPPER_BORDER_HEIGHT + (Render_CONSTANTS.MODULE_HEIGHT * (compIndex / Render_CONSTANTS.TILE_HORIZ_COUNT)));
        int[] focusDetails = focus.getElementAt(mouseX - topLeftX, mouseY - topLeftY);
        print("\tSpecifically clicked on element: ");
        if(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHMODULE_ELEMENT_NONE)
        {
          print("none ");
        }
        else if(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHMODULE_ELEMENT_KNOB)
        {
          print("knob ");
        }
        else if(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHMODULE_ELEMENT_PATCHIN)
        {
          print("in-patch ");
        }
        else if(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHMODULE_ELEMENT_PATCHOUT)
        {
          print("out-patch ");
        }
        else
        {
          print("uh-oh... some junk data snuck in that cannot be interpreted ");
        }
        println("at index " + focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX]);
      }
      else
      {
        println("no synth module in the click = " + focus); //focus should be null here
      }
    }
  }
}
