/*SynthModule.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2022 January 17

Class for a module within a synthesized instrument.  This is a superclass with the
most basic features in all components (UI elements, knobs, patch and gate in/out, etc.).
Be sure to extend this for each Module you want available!
*/

public abstract class SynthModule
{
  //Array of possible patch inputs (number available will depend on module specs)
  protected UGen[] patchIn;
  //Array of possible patch outputs (number available will depend on module specs)
  protected UGen[] patchOut;
  
  //Array of knobs (number available and what they do depend on module specs)
  protected Knob[] knobs;
  
  //Array of patch cables, which should mirror the patch inputs and outputs above
  protected PatchCable[] patchInCable;
  protected PatchCable[] patchOutCable;
  
  //Array of labels describing the patches and knobs (for GUI display)
  protected String[] patchInLabel;
  protected String[] patchOutLabel;
  protected String[] knobsLabel;
  
  //Name of the module (for GUI display)
  protected String moduleName;
  //Unique name for the module (to disambiguate identical modules in GUI)
  protected String uniqueName;
  
  //Default Constructor - just make all arrays non-null, assuming one input/output
  public SynthModule()
  {
    patchIn = new UGen[1];
    patchInCable = new PatchCable[1];
    patchInLabel = new String[1];
    patchOut = new UGen[1];
    patchOutCable = new PatchCable[1];
    patchOutLabel = new String[1];
    knobs = new Knob[1];
    knobsLabel = new String[1];
    
    moduleName = "";
    uniqueName = "";
  }
  
  //Typical Constructor - set up all the arrays with the number of patches and gates
  public SynthModule(int numPI, int numPO, int numKnobs)
  {
    //When no items for an array, leave it null
    patchIn = (numPI > 0) ? new UGen[numPI] : null;
    patchInCable = (numPI > 0) ? new PatchCable[numPI] : null;
    patchInLabel = (numPI > 0) ? new String[numPI] : null;
    patchOut = (numPO > 0) ? new UGen[numPO] : null;
    patchOutCable = (numPO > 0) ? new PatchCable[numPO] : null;
    patchOutLabel = (numPO > 0) ? new String[numPO] : null;
    knobs = (numKnobs > 0) ? new Knob[numKnobs] : null;
    knobsLabel = (numKnobs > 0) ? new String[numKnobs] : null;
    
    moduleName = "";
    uniqueName = "";
  }
  
  //Accessors for the UGens based on indexing for each array
  public UGen getPatchIn(int index)
  {
    //No UGen if no patch inputs OR invalid index
    if((patchIn == null) || (index < 0) || (index >= patchIn.length))
    {
      return null;
    }
    return patchIn[index];
  }
  
  public UGen getPatchOut(int index)
  {
    //No UGen if no patch inputs OR invalid index
    if((patchOut == null) || (index < 0) || (index >= patchOut.length))
    {
      return null;
    }
    return patchOut[index];
  }
  
  //Accessors for the knobs
  public Knob getKnob(int index)
  {
    //No UGen if no patch inputs OR invalid index
    if((knobs == null) || (index < 0) || (index >= knobs.length))
    {
      return null;
    }
    return knobs[index];
  }
  
  //Accessors for the patch cables
  public PatchCable getCableIn(int index)
  {
    //No PatchCable if no patch inputs OR invalid index
    if((patchInCable == null) || (index < 0) || (index >= patchInCable.length))
    {
      return null;
    }
    return patchInCable[index];
  }
  public PatchCable getCableOut(int index)
  {
    //No PatchCable if no patch outputs OR invalid index
    if((patchOutCable == null) || (index < 0) || (index >= patchOutCable.length))
    {
      return null;
    }
    return patchOutCable[index];
  }
  
  //Accessors for the names
  public String getModuleName() {return moduleName;}
  public String getUniqueName() {return uniqueName;}
  
  //Accessors for the total number of patches, knobs, and cables
  public int getTotalPatchIn()
  {
    return (patchIn == null) ? 0 : patchIn.length;
  }
  public int getTotalPatchOut()
  {
    return (patchOut == null) ? 0 : patchOut.length;
  }
  public int getTotalKnob()
  {
    return (knobs == null) ? 0 : knobs.length;
  }
  
  //Mutator for the unique name only (module name should not be changed outside its constructor setting)
  public void setUniqueName(String n) {uniqueName = n;}
  
  //Assign patch cables with this mutator method
  //NOTE: This simply overwrites the pointer to the previous patch cable, which should
  //      lead to garbage collection if BOTH the in and out patching modules replace it
  //      (This means pc should be null if the cable is simply removed!)
  public void setCableIn(int index, PatchCable pc)
  {
    //No PatchCable if no patch inputs OR invalid index
    if((patchInCable == null) || (index < 0) || (index >= patchInCable.length))
    {
      return;
    }
    patchInCable[index] = pc;
  }
  public void setCableOut(int index, PatchCable pc)
  {
    //No PatchCable if no patch outputs OR invalid index
    if((patchOutCable == null) || (index < 0) || (index >= patchOutCable.length))
    {
      return;
    }
    patchOutCable[index] = pc;
  }
  
  //Implement in each module to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public abstract void draw_update();
  
  //Renders the module, accounting for spacing of patch holes, knobs, and the labels
  //NOTE: Renders locally (within the module's rectangle); need global coordinates for offset
  public void render(int xOffset, int yOffset)
  {
    //As the lowest layer of the GUI image for the module,
    //  render the module's box as a rectangle
    stroke(0, 0, 0); //Black stroke
    fill(128, 128, 128); //light-grey fill
    strokeWeight(Render_CONSTANTS.DEFAULT_STROKE_WEIGHT);
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
      //Render a patch hole if a patch is defined in this entry
      //  This is to avoid putting a cable into nothing, or can align holes to pretty-print module
      if(patchIn[i] != null)
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
    }
    
    for(int i = 0; i < ((patchOut != null) ? patchOut.length : 0); i++)
    {
      //Render a patch hole if a patch is defined in this entry
      //  This is to avoid putting a cable into nothing, or can align holes to pretty-print module
      if(patchOut[i] != null)
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
    }
    
    //Now render the knobs, laying them out along the module
    //  Each knob is a rectangle to resemble a slider, including a "cursor" for the position
    for(int i = 0; i < ((knobs != null) ? knobs.length : 0); i++)
    {
      //Render a knob if a patch is defined in this entry
      //  This is to avoid sliding on nothing, or can align knobs to pretty-print module
      if(knobs[i] != null)
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
    
    //Lastly, render the remove button as a simple, red, labeled rectangle at the bottom of the module
    fill(128, 0, 0); //red color
    stroke(0, 0, 0); //black stroke
    rect(xOffset + (Render_CONSTANTS.MODULE_WIDTH - Render_CONSTANTS.REMOVEBUTTON_WIDTH), yOffset + (Render_CONSTANTS.MODULE_HEIGHT - Render_CONSTANTS.REMOVEBUTTON_HEIGHT), Render_CONSTANTS.REMOVEBUTTON_WIDTH, Render_CONSTANTS.REMOVEBUTTON_HEIGHT);
    fill(255, 255, 255); //white to print label on button
    text("Remove (Right Click Here)", xOffset + (Render_CONSTANTS.MODULE_WIDTH - Render_CONSTANTS.REMOVEBUTTON_WIDTH), yOffset + (Render_CONSTANTS.MODULE_HEIGHT - Render_CONSTANTS.REMOVEBUTTON_HEIGHT), Render_CONSTANTS.REMOVEBUTTON_WIDTH, Render_CONSTANTS.REMOVEBUTTON_HEIGHT);
  }
  
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
    
    //Before checking modules, determine whether the remove button was clicked
    //  This is a simple rectangle bounds check
    if(Render_CONSTANTS.rect_contains_point(Render_CONSTANTS.MODULE_WIDTH - Render_CONSTANTS.REMOVEBUTTON_WIDTH, Render_CONSTANTS.MODULE_HEIGHT - Render_CONSTANTS.REMOVEBUTTON_HEIGHT, Render_CONSTANTS.REMOVEBUTTON_WIDTH, Render_CONSTANTS.REMOVEBUTTON_HEIGHT, x, y))
    {
      toReturn[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] = Render_CONSTANTS.SYNTHMODULE_ELEMENT_REMOVE;
      //Remove button has no index to set
      return toReturn;
    }
    
    //First, consider the point being aligned with some in patch
    if(patchIn != null)
    {
      for(int i = 0; i < patchIn.length; i++)
      {
        //The patch is just a circle
        if((patchIn[i] != null) && Render_CONSTANTS.circ_contains_point(Render_CONSTANTS.MODULE_WIDTH / 8, (3 * Render_CONSTANTS.PATCH_RADIUS) + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)), Render_CONSTANTS.PATCH_RADIUS, x, y))
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
        if((patchOut[i] != null) && Render_CONSTANTS.circ_contains_point((Render_CONSTANTS.MODULE_WIDTH * 7) / 8, (3 * Render_CONSTANTS.PATCH_RADIUS) + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)), Render_CONSTANTS.PATCH_RADIUS, x, y))
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
