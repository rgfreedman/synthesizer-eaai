/*Power.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2022 January 20

Class for a voltage output module (power, like a battery) within a synthesized instrument.
This module simply outputs a value, being a glorified knob that one can patch to
other module inputs.
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

public class Power extends SynthModule
{
  //Internal UGen Objects that compose the module's "circuit"
  //Output for frequency is assumed to be in Hertz, but need in volts
  private Multiplier toVolts;
  
  //Default Constructor - set up the knob and pipe its oscillator to the output patch
  public Power()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(Power_CONSTANTS.TOTAL_PATCHIN, Power_CONSTANTS.TOTAL_PATCHOUT, Power_CONSTANTS.TOTAL_KNOB);

    //Now fill in the knob
    knobs[Power_CONSTANTS.KNOB_POWER] = new Knob(0, Audio_CONSTANTS.MAX_FREQ); //Audible frequencies... 22000 hurts the ears... piano goes to about 4200... let's cap it off just a bit above that
    
    //Label for the knob in the GUI
    knobsLabel[Power_CONSTANTS.KNOB_POWER] = "FREQ";
    
    //Patch the knob's UGen into toVolts for proper output conversion
    toVolts = new Multiplier(Audio_CONSTANTS.MAX_FREQ / Audio_CONSTANTS.MAX_VOLT);
    knobs[Power_CONSTANTS.KNOB_POWER].getCurrentValue().patch(toVolts);
    
    //The patchable output is simply the knob's value, noting how much voltage (frequency) to send
    patchOut[Power_CONSTANTS.PATCHOUT_POWER] = toVolts;
    
    //Label for the patch in the GUI
    patchOutLabel[Power_CONSTANTS.PATCHOUT_POWER] = "CV OUT";
    moduleName = "Power";
  }
  
  //Implement in each module to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public void draw_update()
  {
    //Nothing here yet, knob updates are now done in Knob class (as they should)
  }
}
