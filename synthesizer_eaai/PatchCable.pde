/*PatchCable.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 August 06

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
  
  //This is the "from" direction of the edge
  //Information about the output patch (patchOut), which is the component and output index
  protected SynthComponent patchOutSynComp;
  protected int patchOutIndex = -1;
  
  //No Default constructor - Supply the patch information and then the patch sets itself up
  public PatchCable(SynthComponent outSC, int outIndex, SynthComponent inSC, int inIndex)
  {
    //Set the variables
    patchInSynComp = inSC;
    patchInIndex = inIndex;
    patchOutSynComp = outSC;
    patchOutIndex = outIndex;
    
    //Perform the patch between the components - if incorrect indeces, null UGens should
    //  trigger NullPointerException (for the patchOut, at least)
    //NOTE: Output of "from" component patches input of "to" component
    patchOutSynComp.getPatchOut(patchOutIndex).patch(patchInSynComp.getPatchIn(patchInIndex));
    
    //Assign the cable to the respective components for bookkeeping purposes
    //  If the indeces are wrong and NullPointerException did not throw, then there
    //  will certainly be an IndexOutOfBoundsException for either patchIn or patchOut
    patchInSynComp.setCableIn(patchInIndex, this);
    patchOutSynComp.setCableOut(patchOutIndex, this);
  }
  
  //Accessors for the components and indeces
  public SynthComponent getPatchInComponent() {return patchInSynComp;}
  public int getPatchInIndex() {return patchInIndex;}
  public SynthComponent getPatchOutComponent() {return patchOutSynComp;}
  public int getPatchOutIndex() {return patchOutIndex;}
  //Simplified accessor for getting the actual UGen based on the component and index
  public UGen getPatchIn() {return patchInSynComp.getPatchIn(patchInIndex);}
  public UGen getPatchOut() {return patchOutSynComp.getPatchOut(patchOutIndex);}
}
