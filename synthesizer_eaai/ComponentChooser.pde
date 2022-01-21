/*ModuleChooser.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2022 January 20

Class for a pseudo-module within a synthesized instrument.
This module simply lists the available modules for selection, which is mostly 
intended as a menu to add a new SynthModule object to an instrument.
*/

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the ModuleChooser class below
public static class ModuleChooser_CONSTANTS
{
  //Indeces for "input patches" - this is the left-half of the modules list
  public static final int PATCHIN_ENVGEN = 0;
  public static final int PATCHIN_LFO = PATCHIN_ENVGEN + 1;
  public static final int PATCHIN_MIX1_8 = PATCHIN_LFO + 1;
  public static final int PATCHIN_MIX4_2 = PATCHIN_MIX1_8 + 1;
  public static final int PATCHIN_MULT1_8 = PATCHIN_MIX4_2 + 1;
  public static final int PATCHIN_MULT2_4 = PATCHIN_MULT1_8 + 1;
  public static final int PATCHIN_NOISEGEN = PATCHIN_MULT2_4 + 1;
  public static final int PATCHIN_POWER = PATCHIN_NOISEGEN + 1;
  public static final int TOTAL_PATCHIN = PATCHIN_POWER + 1;
  
  //No knobs (using patches to pretend to be buttons, knobs cannot do that as intuitively)
  public static final int TOTAL_KNOB = 0;
  
  //Indeces for "output patches" - this is the right-half of the modules list
  public static final int PATCHOUT_VCA = 0;
  public static final int PATCHOUT_VCF = PATCHOUT_VCA + 1;
  public static final int PATCHOUT_VCO = PATCHOUT_VCF + 1;
  public static final int TOTAL_PATCHOUT = PATCHOUT_VCO + 1;
}

public class ModuleChooser extends SynthModule
{
  //No internal UGen Objects since this module has no "circuit" underneath
  
  //Default Constructor - set up all the patches and knobs
  public ModuleChooser()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(ModuleChooser_CONSTANTS.TOTAL_PATCHIN, ModuleChooser_CONSTANTS.TOTAL_PATCHOUT, ModuleChooser_CONSTANTS.TOTAL_KNOB);

    //No internals to set up, and the UGen elements from Minim should always yield null as a result
    
    //Labels for the patches in the GUI
    moduleName = "Add Module";
    patchInLabel[ModuleChooser_CONSTANTS.PATCHIN_ENVGEN] = "EG";
    patchInLabel[ModuleChooser_CONSTANTS.PATCHIN_LFO] = "LFO";
    patchInLabel[ModuleChooser_CONSTANTS.PATCHIN_MIX1_8] = "MIX 8->1";
    patchInLabel[ModuleChooser_CONSTANTS.PATCHIN_MIX4_2] = "MIX 4->2";
    patchInLabel[ModuleChooser_CONSTANTS.PATCHIN_MULT1_8] = "MLT 1->8";
    patchInLabel[ModuleChooser_CONSTANTS.PATCHIN_MULT2_4] = "MLT 2->4";
    patchInLabel[ModuleChooser_CONSTANTS.PATCHIN_NOISEGEN] = "NG";
    patchInLabel[ModuleChooser_CONSTANTS.PATCHIN_POWER] = "POWER";
    //Not all fit on the Patch In side; continue on Patch Out side
    patchOutLabel[ModuleChooser_CONSTANTS.PATCHOUT_VCA] = "VCA";
    patchOutLabel[ModuleChooser_CONSTANTS.PATCHOUT_VCF] = "VCF";
    patchOutLabel[ModuleChooser_CONSTANTS.PATCHOUT_VCO] = "VCO";
  }
  
  //Implement in each module to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public void draw_update()
  {
    //Nothing here yet, knob updates are now done in Knob class (as they should)
  }
  
  //NOTE: This overrides SynthModule's render simply by allowing a null patch/knob to be drawn and ignoring the remove button...
  //Renders the module, accounting for spacing of patch holes, knobs, and the labels
  //NOTE: Renders locally (within the module's rectangle); need global coordinates for offset
  public void render(int xOffset, int yOffset)
  {
    //As the lowest layer of the GUI image for the module,
    //  render the module's box as a rectangle
    stroke(0, 0, 0); //Black stroke
    strokeWeight(Render_CONSTANTS.DEFAULT_STROKE_WEIGHT);
    fill(128, 128, 128); //light-grey fill
    rect(xOffset, yOffset, Render_CONSTANTS.MODULE_WIDTH, Render_CONSTANTS.MODULE_HEIGHT);
    
    //All text should be centered about the specified (x,y) coordinates per text() call
    textAlign(CENTER, CENTER);
    //Like font, set the size of all text on this module (measured in pixels)
    //For simplicity, make the same size as a knob (since portrayed as a slider)
    textSize(Render_CONSTANTS.KNOB_HEIGHT);
    
    //Next, render the module name in the top-center of the module
    if(moduleName != null)
    {
      fill(0, 0, 0); //Black text
      text(moduleName + ((uniqueName.equals("")) ? "":(" (" + uniqueName + ")")), xOffset + (Render_CONSTANTS.MODULE_WIDTH / 2), yOffset + Render_CONSTANTS.KNOB_HEIGHT);
    }
    
    //Now render the patches, laying them out along the module
    //  Each patch is a uniformly-sized circle, set to be solid black (like a hole)
    fill(0, 0, 0);
    stroke(0, 0, 0);
    
    //For simplicity, make the labels half the size of a knob (since portrayed as a slider)
    textSize(Render_CONSTANTS.KNOB_HEIGHT / 2);
    
    for(int i = 0; i < ((patchIn != null) ? patchIn.length : 0); i++)
    {
      //If provided, include label for the patch
      if((patchInLabel != null) && (patchInLabel[i] != null))
      {
        text(patchInLabel[i], xOffset + (Render_CONSTANTS.MODULE_WIDTH / 8), yOffset + Render_CONSTANTS.PATCH_RADIUS + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)));
      }
      //First two values are center, width and height are equal for circle
      ellipse(xOffset + (Render_CONSTANTS.MODULE_WIDTH / 8), yOffset + (3 * Render_CONSTANTS.PATCH_RADIUS) + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)), Render_CONSTANTS.PATCH_DIAMETER, Render_CONSTANTS.PATCH_DIAMETER);
        
      //Also send the center values to the patch cable, if one exists that is plugged into this patch
      if((patchInCable != null) && (patchInCable[i] != null))
      {
        patchInCable[i].setRenderIn(xOffset + (Render_CONSTANTS.MODULE_WIDTH / 8), yOffset + (3 * Render_CONSTANTS.PATCH_RADIUS) + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)));
      }
    }
    
    for(int i = 0; i < ((patchOut != null) ? patchOut.length : 0); i++)
    {
      //If provided, include label for the patch
      if((patchOutLabel != null) && (patchOutLabel[i] != null))
      {
        text(patchOutLabel[i], xOffset + ((Render_CONSTANTS.MODULE_WIDTH * 7) / 8), yOffset + Render_CONSTANTS.PATCH_RADIUS + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)));
      }
      //First two values are center, width and height are equal for circle
      ellipse(xOffset + ((Render_CONSTANTS.MODULE_WIDTH * 7) / 8), yOffset + (3 * Render_CONSTANTS.PATCH_RADIUS) + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)), Render_CONSTANTS.PATCH_DIAMETER, Render_CONSTANTS.PATCH_DIAMETER);
        
      //Also send the center values to the patch cable, if one exists that is plugged into this patch
      if((patchOutCable != null) && (patchOutCable[i] != null))
      {
        patchOutCable[i].setRenderOut(xOffset + ((Render_CONSTANTS.MODULE_WIDTH * 7) / 8), yOffset + (3 * Render_CONSTANTS.PATCH_RADIUS) + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)));
      }
    }
    
    //Now render the knobs, laying them out along the module
    //  Each knob is a rectangle to resemble a slider, including a "cursor" for the position
    for(int i = 0; i < ((knobs != null) ? knobs.length : 0); i++)
    {
      //If provided, include label for the patch
      if((knobsLabel != null) && (knobsLabel[i] != null))
      {
        //Reset colors to black since knob cursor is red, but label should be black
        fill(0, 0, 0);
        stroke(0, 0, 0);
        text(knobsLabel[i], xOffset + (Render_CONSTANTS.MODULE_WIDTH / 2), yOffset + (Render_CONSTANTS.KNOB_HEIGHT / 2) + ((i + 1) * 2 * (Render_CONSTANTS.KNOB_HEIGHT + Render_CONSTANTS.VERT_SPACE)));
      }
      //Unlike the ellipse, these are the top-left corner of the rectangle
      knobs[i].render(xOffset + (Render_CONSTANTS.MODULE_WIDTH / 2) - (Render_CONSTANTS.KNOB_WIDTH / 2), yOffset + Render_CONSTANTS.KNOB_HEIGHT + ((i + 1) * 2 * (Render_CONSTANTS.KNOB_HEIGHT + Render_CONSTANTS.VERT_SPACE)));
    }
  }
  
  //NOTE: This overrides SynthModule's getElementAt simply by allowing a null patch/knob to be drawn and ignoring the remove button...
  //Reverse engineering of the rendering process to identify the focus
  //  (what element [patch hole or knob] is at some pixel location)
  //Output format is a length-2 integer array: [element_type, index]
  //NOTE: The output format will have some helpful magic numbers defined in Render_CONSTANTS
  //NOTE: The inputs x and y are relative to the top-left corner of this SynthModule
  public int[] getElementAt(int x, int y)
  {
    //Setup the output array first, fill in just before returning (set to default, the "null")
    int[] toReturn = new int[Render_CONSTANTS.SYNTHMODULE_TOTAL_FOCUS];
    toReturn[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] = Render_CONSTANTS.SYNTHMODULE_ELEMENT_NONE;
    toReturn[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX] = Render_CONSTANTS.INVALID_VALUE;
    
    //Before starting, return nothing relevant if outside the bounds of the module
    if((x < 0) || (x >= Render_CONSTANTS.MODULE_WIDTH) || (y < 0) || (y >= Render_CONSTANTS.MODULE_HEIGHT))
    {
      return toReturn;
    }
    
    //First, consider the point being aligned with some in patch
    if(patchIn != null)
    {
      for(int i = 0; i < patchIn.length; i++)
      {
        //The patch is just a circle
        if(Render_CONSTANTS.circ_contains_point(Render_CONSTANTS.MODULE_WIDTH / 8, (3 * Render_CONSTANTS.PATCH_RADIUS) + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)), Render_CONSTANTS.PATCH_RADIUS, x, y))
        {
          toReturn[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] = Render_CONSTANTS.SYNTHMODULE_ELEMENT_PATCHIN;
          toReturn[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX] = i;
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
        if((knobs[i] != null) && knobs[i].contains_point(x - ((Render_CONSTANTS.MODULE_WIDTH / 2) - (Render_CONSTANTS.KNOB_WIDTH / 2)), y - (Render_CONSTANTS.KNOB_HEIGHT + ((i + 1) * 2 * (Render_CONSTANTS.KNOB_HEIGHT + Render_CONSTANTS.VERT_SPACE)))))
        {
          toReturn[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] = Render_CONSTANTS.SYNTHMODULE_ELEMENT_KNOB;
          toReturn[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX] = i;
          return toReturn;
        }
      }
    }
    //Third, consider the point being aligned with some out patch
    if(patchOut != null)
    {
      for(int i = 0; i < patchOut.length; i++)
      {
        //The patch is just a circle
        if(Render_CONSTANTS.circ_contains_point((Render_CONSTANTS.MODULE_WIDTH * 7) / 8, (3 * Render_CONSTANTS.PATCH_RADIUS) + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)), Render_CONSTANTS.PATCH_RADIUS, x, y))
        {
          toReturn[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] = Render_CONSTANTS.SYNTHMODULE_ELEMENT_PATCHOUT;
          toReturn[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX] = i;
          return toReturn;
        }
      }
    }
    
    //At this point, the point did not fit into any elements => return nothing
    return toReturn;
  }
}
