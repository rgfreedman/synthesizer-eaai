/*PatchCable.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 November 27

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
  
  //No Default constructor - Supply the patch information and then the patch sets itself up
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
    
    //Set the variables
    patchInSynComp = inSC;
    patchInIndex = inIndex;
    
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
    
    //Set the variables
    patchOutSynComp = outSC;
    patchOutIndex = outIndex;
    
    //Next, patch the current UGen setup if the in patch already exists
    //NOTE: Output of "from" component patches input of "to" component
    if((patchOutSynComp != null) && (patchOutIndex >= 0) && (patchInSynComp != null) && (patchInIndex >= 0))
    {
      patchOutSynComp.getPatchOut(patchOutIndex).patch(patchInSynComp.getPatchIn(patchInIndex));
    }
  }
}
