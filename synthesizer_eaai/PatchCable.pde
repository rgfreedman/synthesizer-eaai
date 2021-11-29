/*PatchCable.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 November 28

Class for a patch cable the joins components within a synthesized instrument.
This component simply contains the information about the input and output patch,
joining them during its construction.  Think of the cable like a directed edge in a 
graph where the synthesizer components are nodes.
*/

public class PatchCable
{
  //This is the "to" direction of the edge
  //Information about the input patch (patchIn), which is the component and input index
  protected SynthComponent patchInSynComp;
  protected int patchInIndex = -1;
  
  //For rendering in the GUI, need to keep track of the x,y of the patch (for cable insertion)
  //NOTE: Use negative value when unknown (will render off-screen) 
  protected int patchIn_renderX = -1;
  protected int patchIn_renderY = -1;
  
  //This is the "from" direction of the edge
  //Information about the output patch (patchOut), which is the component and output index
  protected SynthComponent patchOutSynComp;
  protected int patchOutIndex = -1;
  
  //For rendering in the GUI, need to keep track of the x,y of the patch (for cable insertion)
  //NOTE: Use negative value when unknown (will render off-screen) 
  protected int patchOut_renderX = -1;
  protected int patchOut_renderY = -1;
  
  //Default constructor - defaults to have nothing set (use setPatchIn and setPatchOut later)
  public PatchCable()
  {
    this.setPatchIn(null, -1);
    this.setPatchOut(null, -1);
  }
  
  //Typical constructor - Supply the patch information and then the patch sets itself up
  public PatchCable(SynthComponent outSC, int outIndex, SynthComponent inSC, int inIndex)
  {
    //Simply use the mutator methods to set up these patches without worrying about errors
    this.setPatchIn(inSC, inIndex);
    this.setPatchOut(outSC, outIndex);
  }
  
  //Accessors for the components and indeces
  public SynthComponent getPatchInComponent() {return patchInSynComp;}
  public int getPatchInIndex() {return patchInIndex;}
  public SynthComponent getPatchOutComponent() {return patchOutSynComp;}
  public int getPatchOutIndex() {return patchOutIndex;}
  //Simplified accessor for getting the actual UGen based on the component and index
  public UGen getPatchIn() {return patchInSynComp.getPatchIn(patchInIndex);}
  public UGen getPatchOut() {return patchOutSynComp.getPatchOut(patchOutIndex);}
  
  //Mutators for the components and indeces (in case patch cable is changed => unplugged and inserted elsewhere)
  public void setPatchIn(SynthComponent inSC, int inIndex)
  {
    //First, unpatch the current UGen setup if it already exists
    //NOTE: Output of "from" component patches input of "to" component
    if((patchOutSynComp != null) && (patchOutIndex >= 0) && (patchInSynComp != null) && (patchInIndex >= 0))
    {
      patchOutSynComp.getPatchOut(patchOutIndex).unpatch(patchInSynComp.getPatchIn(patchInIndex));
    }
    if((patchInSynComp != null) && (patchInIndex >= 0))
    {
      patchInSynComp.setCableIn(patchInIndex, null);
    }
    
    //Set the variables
    patchInSynComp = inSC;
    patchInIndex = inIndex;
    //Also store the cable pointer in the synth component
    if(patchInSynComp != null)
    {
      patchInSynComp.setCableIn(patchInIndex, this);
    }
    
    //This means the rendering position for the new in patch is unknown
    patchIn_renderX = -1;
    patchIn_renderY = -1;
    
    //Next, patch the current UGen setup if the out patch already exists
    //NOTE: Output of "from" component patches input of "to" component
    if((patchOutSynComp != null) && (patchOutIndex >= 0) && (patchInSynComp != null) && (patchInIndex >= 0))
    {
      patchOutSynComp.getPatchOut(patchOutIndex).patch(patchInSynComp.getPatchIn(patchInIndex));
    }
  }
  public void setPatchOut(SynthComponent outSC, int outIndex)
  {
    //First, unpatch the current UGen setup if it already exists
    //NOTE: Output of "from" component patches input of "to" component
    if((patchOutSynComp != null) && (patchOutIndex >= 0) && (patchInSynComp != null) && (patchInIndex >= 0))
    {
      patchOutSynComp.getPatchOut(patchOutIndex).unpatch(patchInSynComp.getPatchIn(patchInIndex));
    }
    if((patchOutSynComp != null) && (patchOutIndex >= 0))
    {
      patchOutSynComp.setCableOut(patchOutIndex, null);
    }
    
    //Set the variables
    patchOutSynComp = outSC;
    patchOutIndex = outIndex;
    //Also store the cable pointer in the synth component
    if(patchOutSynComp != null)
    {
      patchOutSynComp.setCableOut(patchOutIndex, this);
    }
    
    //This means the rendering position for the new out patch is unknown
    patchOut_renderX = -1;
    patchOut_renderY = -1;
    
    //Next, patch the current UGen setup if the in patch already exists
    //NOTE: Output of "from" component patches input of "to" component
    if((patchOutSynComp != null) && (patchOutIndex >= 0) && (patchInSynComp != null) && (patchInIndex >= 0))
    {
      patchOutSynComp.getPatchOut(patchOutIndex).patch(patchInSynComp.getPatchIn(patchInIndex));
    }
  }
  
  //Mutators for setting the global rendering positions
  //  NOTE: Intended for use with SynthComponent's render(...) call only, but no "friend" functions in Processing
  public void setRenderOut(int x, int y)
  {
    patchOut_renderX = x;
    patchOut_renderY = y;
  }
  public void setRenderIn(int x, int y)
  {
    patchIn_renderX = x;
    patchIn_renderY = y;
  }
  
  //Renders the patch cable, based on information provided from Synth Components
  //NOTE: Renders globally due to passed-in information, use mouse if coordinates are -1
  public void render()
  {
    //Now render the patche insertions
    //  Each patch is a uniformly-sized circle, set to be cyan color (for contrast)
    fill(0, 255, 255);
    stroke(0, 255, 255);
    
    //Patch cable's plug into the out patch
    //In case the mouse coordinate is needed somewhere, use a temp coordinate variable pair
    int drawCenterOutX = (patchOut_renderX >= 0) ? patchOut_renderX : mouseX;
    int drawCenterOutY = (patchOut_renderY >= 0) ? patchOut_renderY : mouseY;
    ellipse(drawCenterOutX, drawCenterOutY, Render_CONSTANTS.PATCH_PLUG_DIAMETER, Render_CONSTANTS.PATCH_PLUG_DIAMETER);
    
    //Patch cable's plug into the in patch
    //In case the mouse coordinate is needed somewhere, use a temp coordinate variable pair
    int drawCenterInX = (patchIn_renderX >= 0) ? patchIn_renderX : mouseX;
    int drawCenterInY = (patchIn_renderY >= 0) ? patchIn_renderY : mouseY;
    ellipse(drawCenterInX, drawCenterInY, Render_CONSTANTS.PATCH_PLUG_DIAMETER, Render_CONSTANTS.PATCH_PLUG_DIAMETER);
    
    //Patch cable connecting the two plugs
    strokeWeight(Render_CONSTANTS.PATCH_CORD_WIDTH);
    line(drawCenterOutX, drawCenterOutY, drawCenterInX, drawCenterInY);
    
    //Revert the stroke weight for rendering everything else
    strokeWeight(Render_CONSTANTS.DEFAULT_STROKE_WEIGHT);
  }
}
