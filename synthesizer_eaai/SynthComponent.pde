/*SynthComponent.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 November 27

Class for a component within a synthesized instrument.  This is a superclass with the
most basic features in all components (UI elements, knobs, patch and gate in/out, etc.).
Be sure to extend this for each component you want available!
*/

public abstract class SynthComponent
{
  //Array of possible patch inputs (number available will depend on component specs)
  protected UGen[] patchIn;
  //Array of possible patch outputs (number available will depend on component specs)
  protected UGen[] patchOut;
  
  //Array of knobs (number available and what they do depend on component specs)
  protected Knob[] knobs;
  
  //Array of patch cables, which should mirror the patch inputs and outputs above
  protected PatchCable[] patchInCable;
  protected PatchCable[] patchOutCable;
  
  //Array of labels describing the patches and knobs (for GUI display)
  protected String[] patchInLabel;
  protected String[] patchOutLabel;
  protected String[] knobsLabel;
  
  //Name of the component (for GUI display)
  protected String componentName;
  //Unique name for the component (to disambiguate identical components in GUI)
  protected String uniqueName;
  
  //Default Constructor - just make all arrays non-null, assuming one input/output
  public SynthComponent()
  {
    patchIn = new UGen[1];
    patchInCable = new PatchCable[1];
    patchInLabel = new String[1];
    patchOut = new UGen[1];
    patchOutCable = new PatchCable[1];
    patchOutLabel = new String[1];
    knobs = new Knob[1];
    knobsLabel = new String[1];
    
    componentName = "";
    uniqueName = "";
  }
  
  //Typical Constructor - set up all the arrays with the number of patches and gates
  public SynthComponent(int numPI, int numPO, int numKnobs)
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
    
    componentName = "";
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
  public String getComponentName() {return componentName;}
  public String getUniqueName() {return uniqueName;}
  
  //Mutator for the unique name only (component name should not be changed outside its constructor setting)
  public void setUniqueName(String n) {uniqueName = n;}
  
  //Assign patch cables with this mutator method
  //NOTE: This simply overwrites the pointer to the previous patch cable, which should
  //      lead to garbage collection if BOTH the in and out patching components replace it
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
  
  //Implement in each component to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public abstract void draw_update();
  
  //Renders the component, accounting for spacing of patch holes, knobs, and the labels
  //NOTE: Renders locally (within the component's rectangle); need global coordinates for offset
  public void render(int xOffset, int yOffset)
  {
    //As the lowest layer of the GUI image for the component,
    //  render the component's box as a rectangle
    stroke(0, 0, 0); //Black stroke
    fill(128, 128, 128); //light-grey fill
    rect(xOffset, yOffset, Render_CONSTANTS.COMPONENT_WIDTH, Render_CONSTANTS.COMPONENT_HEIGHT);
    
    //All text should be centered about the specified (x,y) coordinates per text() call
    textAlign(CENTER, CENTER);
    //Like font, set the size of all text on this component (measured in pixels)
    //For simplicity, make the same size as a knob (since portrayed as a slider)
    textSize(Render_CONSTANTS.KNOB_HEIGHT);
    
    //Next, render the component name in the top-center of the component
    if(componentName != null)
    {
      fill(0, 0, 0); //Black text
      text(componentName + ((uniqueName.equals("")) ? "":(" (" + uniqueName + ")")), xOffset + (Render_CONSTANTS.COMPONENT_WIDTH / 2), yOffset + Render_CONSTANTS.KNOB_HEIGHT);
    }
    
    //Now render the patches, laying them out along the component
    //  Each patch is a uniformly-sized circle, set to be solid black (like a hole)
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
          text(patchInLabel[i], xOffset + (Render_CONSTANTS.COMPONENT_WIDTH / 8), yOffset + Render_CONSTANTS.PATCH_RADIUS + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)));
        }
        //First two values are center, width and height are equal for circle
        ellipse(xOffset + (Render_CONSTANTS.COMPONENT_WIDTH / 8), yOffset + (3 * Render_CONSTANTS.PATCH_RADIUS) + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)), Render_CONSTANTS.PATCH_DIAMETER, Render_CONSTANTS.PATCH_DIAMETER);
        
        //Also send the center values to the patch cable, if one exists that is plugged into this patch
        if((patchInCable != null) && (patchInCable[i] != null))
        {
          patchInCable[i].setRenderIn(xOffset + (Render_CONSTANTS.COMPONENT_WIDTH / 8), yOffset + (3 * Render_CONSTANTS.PATCH_RADIUS) + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)));
        }
      }
    }
    
    for(int i = 0; i < ((patchOut != null) ? patchOut.length : 0); i++)
    {
      //Render a patch hole if a patch is defined in this entry
      //  This is to avoid putting a cable into nothing, or can align holes to pretty-print component
      if(patchOut[i] != null)
      {
        //If provided, include label for the patch
        if((patchOutLabel != null) && (patchOutLabel[i] != null))
        {
          text(patchOutLabel[i], xOffset + ((Render_CONSTANTS.COMPONENT_WIDTH * 7) / 8), yOffset + Render_CONSTANTS.PATCH_RADIUS + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)));
        }
        //First two values are center, width and height are equal for circle
        ellipse(xOffset + ((Render_CONSTANTS.COMPONENT_WIDTH * 7) / 8), yOffset + (3 * Render_CONSTANTS.PATCH_RADIUS) + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)), Render_CONSTANTS.PATCH_DIAMETER, Render_CONSTANTS.PATCH_DIAMETER);
        
        //Also send the center values to the patch cable, if one exists that is plugged into this patch
        if((patchOutCable != null) && (patchOutCable[i] != null))
        {
          patchOutCable[i].setRenderOut(xOffset + ((Render_CONSTANTS.COMPONENT_WIDTH * 7) / 8), yOffset + (3 * Render_CONSTANTS.PATCH_RADIUS) + ((i + 1) * 2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)));
        }
      }
    }
    
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
          text(knobsLabel[i], xOffset + (Render_CONSTANTS.COMPONENT_WIDTH / 2), yOffset + (Render_CONSTANTS.KNOB_HEIGHT / 2) + ((i + 1) * 2 * (Render_CONSTANTS.KNOB_HEIGHT + Render_CONSTANTS.VERT_SPACE)));
        }
        //Unlike the ellipse, these are the top-left corner of the rectangle
        knobs[i].render(xOffset + (Render_CONSTANTS.COMPONENT_WIDTH / 2) - (Render_CONSTANTS.KNOB_WIDTH / 2), yOffset + Render_CONSTANTS.KNOB_HEIGHT + ((i + 1) * 2 * (Render_CONSTANTS.KNOB_HEIGHT + Render_CONSTANTS.VERT_SPACE)));
      }
    }
  }
}
