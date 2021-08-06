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
  //Array of possible gate inputs (number available will depend on component specs)
  protected UGen[] gateIn;
  
  //Array of knobs (number available and what they do depend on component specs)
  protected Knob[] knobs;
  
  //Array of patch cables, which should mirror the patch inputs and outputs above
  protected PatchCable[] patchInCable;
  protected PatchCable[] patchOutCable;
  
  //Default Constructor - just make all arrays non-null, assuming one input/output
  public SynthComponent()
  {
    patchIn = new UGen[1];
    patchInCable = new PatchCable[1];
    patchOut = new UGen[1];
    patchOutCable = new PatchCable[1];
    gateIn = new UGen[1];
    knobs = new Knob[1];
  }
  
  //Typical Constructor - set up all the arrays with the number of patches and gates
  public SynthComponent(int numPI, int numPO, int numGI, int numKnobs)
  {
    //When no items for an array, leave it null
    patchIn = (numPI > 0) ? new UGen[numPI] : null;
    patchInCable = (numPI > 0) ? new PatchCable[numPI] : null;
    patchOut = (numPO > 0) ? new UGen[numPO] : null;
    patchOutCable = (numPO > 0) ? new PatchCable[numPO] : null;
    gateIn = (numGI > 0) ? new UGen[numGI] : null;
    knobs = (numKnobs > 0) ? new Knob[numKnobs] : null;
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
  
  public UGen getGateIn(int index)
  {
    //No UGen if no patch inputs OR invalid index
    if((gateIn == null) || (index < 0) || (index >= gateIn.length))
    {
      return null;
    }
    return gateIn[index];
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
  
  //Assign patch cables with this mutator method
  //NOTE: This simply overwrites the pointer to the previous patch cable, which should
  //      lead to garbage collection if BOTH the in and out patching components replace it
  //      (This means pc should be null if the cable is simply removed!)
  public void setCableIn(int index, PatchCable pc)
  {
    patchInCable[index] = pc;
  }
  public void setCableOut(int index, PatchCable pc)
  {
    patchOutCable[index] = pc;
  }
  
  //Implement in each component to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public abstract void draw_update();
}
