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
  
  //Default Constructor - just make all arrays non-null, assuming one input/output
  public SynthComponent()
  {
    patchIn = new UGen[1];
    patchOut = new UGen[1];
    gateIn = new UGen[1];
    knobs = new Knob[1];
  }
  
  //Typical Constructor - set up all the arrays with the number of patches and gates
  public SynthComponent(int numPI, int numPO, int numGI, int numKnobs)
  {
    //When no items for an array, leave it null
    patchIn = (numPI > 0) ? new UGen[numPI] : null;
    patchOut = (numPO > 0) ? new UGen[numPO] : null;
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
  
  //Implement in each component to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public abstract void draw_update();
}
