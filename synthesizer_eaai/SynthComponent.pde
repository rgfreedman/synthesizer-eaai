/*SynthComponent.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 August 01

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
}
