/*ComponentChooser.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2022 January 01

Class for a pseudo-component within a synthesized instrument.
This component simply lists the available components for selection, which is mostly 
intended as a menu to add a new SynthComponent object to an instrument.
*/

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the ComponentChooser class below
public static class ComponentChooser_CONSTANTS
{
  //Indeces for "input patches" - this is the left-half of the components list
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
  
  //Indeces for "output patches" - this is the right-half of the components list
  public static final int PATCHOUT_VCA = 0;
  public static final int PATCHOUT_VCF = PATCHOUT_VCA + 1;
  public static final int PATCHOUT_VCO = PATCHOUT_VCF + 1;
  public static final int TOTAL_PATCHOUT = PATCHOUT_VCO + 1;
}

public class ComponentChooser extends SynthComponent
{
  //No internal UGen Objects since this component has no "circuit" underneath
  
  //Default Constructor - set up all the patches and knobs
  public ComponentChooser()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(ComponentChooser_CONSTANTS.TOTAL_PATCHIN, ComponentChooser_CONSTANTS.TOTAL_PATCHOUT, ComponentChooser_CONSTANTS.TOTAL_KNOB);

    //No internals to set up, and the UGen elements from Minim should always yield null as a result
    
    //Labels for the patches in the GUI
    componentName = "Add Component";
    patchInLabel[ComponentChooser_CONSTANTS.PATCHIN_ENVGEN] = "EG";
    patchInLabel[ComponentChooser_CONSTANTS.PATCHIN_LFO] = "LFO";
    patchInLabel[ComponentChooser_CONSTANTS.PATCHIN_MIX1_8] = "MIXER (8->1)";
    patchInLabel[ComponentChooser_CONSTANTS.PATCHIN_MIX4_2] = "MIXER (4->2)";
    patchInLabel[ComponentChooser_CONSTANTS.PATCHIN_MULT1_8] = "MULT (1->8)";
    patchInLabel[ComponentChooser_CONSTANTS.PATCHIN_MULT2_4] = "MULT (2->4)";
    patchInLabel[ComponentChooser_CONSTANTS.PATCHIN_NOISEGEN] = "NG";
    patchInLabel[ComponentChooser_CONSTANTS.PATCHIN_POWER] = "POWER";
    //Not all fit on the Patch In side; continue on Patch Out side
    patchOutLabel[ComponentChooser_CONSTANTS.PATCHOUT_VCA] = "VCA";
    patchOutLabel[ComponentChooser_CONSTANTS.PATCHOUT_VCF] = "VCF";
    patchOutLabel[ComponentChooser_CONSTANTS.PATCHOUT_VCO] = "VCO";
  }
  
  //Implement in each component to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public void draw_update()
  {
    //Nothing here yet, knob updates are now done in Knob class (as they should)
  }
  
  //Renders the component, accounting for spacing of patch holes, knobs, and the labels
  //NOTE: Renders locally (within the component's rectangle); need global coordinates for offset
  //NOTE: This overrides SynthComponent's render simply by allowing a null patch/knob to be drawn...
  public void render(int xOffset, int yOffset)
  {
    //As the lowest layer of the GUI image for the component,
    //  render the component's box as a rectangle
    stroke(0, 0, 0); //Black stroke
    strokeWeight(Render_CONSTANTS.DEFAULT_STROKE_WEIGHT);
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
    
    for(int i = 0; i < ((patchOut != null) ? patchOut.length : 0); i++)
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
    
    //Now render the knobs, laying them out along the component
    //  Each knob is a rectangle to resemble a slider, including a "cursor" for the position
    for(int i = 0; i < ((knobs != null) ? knobs.length : 0); i++)
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
