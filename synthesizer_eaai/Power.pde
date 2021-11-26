/*Power.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 August 06

Class for a voltage output component (power, like a battery) within a synthesized instrument.
This component simply outputs a value, being a glorified knob that one can patch to
other component inputs.
*/

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the VCO class below
public static class Power_CONSTANTS
{
  //No inputs
  public static final int TOTAL_PATCHIN = 0;
  
  //Index for the knob
  public static final int KNOB_POWER = 0;
  public static final int TOTAL_KNOB = KNOB_POWER + 1;
  
  //Index for the output patch - passes along the knob value
  public static final int PATCHOUT_POWER = 0;
  public static final int TOTAL_PATCHOUT = PATCHOUT_POWER + 1;
}

public class Power extends SynthComponent
{
  //Default Constructor - set up the knob and pipe its oscillator to the output patch
  public Power()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(Power_CONSTANTS.TOTAL_PATCHIN, Power_CONSTANTS.TOTAL_PATCHOUT, Power_CONSTANTS.TOTAL_KNOB);

    //Now fill in the knob
    knobs[Power_CONSTANTS.KNOB_POWER] = new Knob(0, 6000); //Audible frequencies... 22000 hurts the ears... piano goes to about 4200... let's cap it off just a bit above that
    
    //Label for the knob in the GUI
    knobsLabel[Power_CONSTANTS.KNOB_POWER] = "FREQ";
    
    //The patchable output is simply the knob's value, noting how much voltage (frequency) to send
    patchOut[Power_CONSTANTS.PATCHOUT_POWER] = knobs[Power_CONSTANTS.KNOB_POWER].getCurrentValue();
    
    //Label for the patch in the GUI
    patchOutLabel[Power_CONSTANTS.PATCHOUT_POWER] = "FREQ OUT";
    componentName = "Power";
  }
  
  //Implement in each component to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public void draw_update()
  {
    //Nothing here yet, knob updates are now done in Knob class (as they should)
  }
}
