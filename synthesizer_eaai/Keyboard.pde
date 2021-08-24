/*Keyboard.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 August 24

Class for a keyboard component within a synthesized instrument.
This component sends frequency information for a pressed key that can act as dynamic
input to an oscillator, envelope, etc.  Includes polyphonic support for up to 10 pressed
keys "at once" (need to press or release one key per frame, cannot be simultaneous).
*/

//For the data structures, need some imported classes
import java.util.Stack;
import java.util.HashMap;

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the VCO class below
public static class Keyboard_CONSTANTS
{
  //Nothing to patch in, much like power (surprise, this component is effectively 
  //  10 power-like knobs under the hood)
  public static final int TOTAL_PATCHIN = 0;
  
  //No gates
  public static final int TOTAL_GATE = 0;
  
  //No knobs that are public-facing (keyboard controls them with key presses)
  public static final int TOTAL_KNOB = 0;
  
  //Indeces for output patches - these are the frequencies per pressed polyphonic key
  public static final int PATCHOUT_KEY0 = 0;
  public static final int PATCHOUT_KEY1 = PATCHOUT_KEY0 + 1;
  public static final int PATCHOUT_KEY2 = PATCHOUT_KEY1 + 1;
  public static final int PATCHOUT_KEY3 = PATCHOUT_KEY2 + 1;
  public static final int PATCHOUT_KEY4 = PATCHOUT_KEY3 + 1;
  public static final int PATCHOUT_KEY5 = PATCHOUT_KEY4 + 1;
  public static final int PATCHOUT_KEY6 = PATCHOUT_KEY5 + 1;
  public static final int PATCHOUT_KEY7 = PATCHOUT_KEY6 + 1;
  public static final int PATCHOUT_KEY8 = PATCHOUT_KEY7 + 1;
  public static final int PATCHOUT_KEY9 = PATCHOUT_KEY8 + 1;
  public static final int TOTAL_PATCHOUT = PATCHOUT_KEY9 + 1;
}

public class Keyboard extends SynthComponent
{
  //Internal UGen Objects that compose the component's "circuit"
  //Each output will be a single, constant frequency whose value changes with key presses
  private Constant[] keys;
  
  //Internal data structures used to manage the keys in use for polyphonic sound
  //Stack that tracks remaining available indeces
  Stack<Integer> availableKeys;
  //HashMap from a keybinding to the key index that is playing the key value
  HashMap<Character, Integer> keyBindings;
  
  //Default Constructor - set up all the patches and knobs
  public Keyboard()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(Keyboard_CONSTANTS.TOTAL_PATCHIN, Keyboard_CONSTANTS.TOTAL_PATCHOUT, Keyboard_CONSTANTS.TOTAL_GATE, Keyboard_CONSTANTS.TOTAL_KNOB);

    //Set up the internals of the component with the UGen elements from Minim
    keys = new Constant[Keyboard_CONSTANTS.TOTAL_PATCHOUT];
    for(int i = Keyboard_CONSTANTS.PATCHOUT_KEY0; i < Keyboard_CONSTANTS.TOTAL_PATCHOUT; i++)
    {
      keys[i] = new Constant(0.0);
    }
    
    //With the UGens all setup, fill in the external-facing ones for input/output
    for(int i = Keyboard_CONSTANTS.PATCHOUT_KEY0; i < Keyboard_CONSTANTS.TOTAL_PATCHOUT; i++)
    {
      patchOut[i] = keys[i];
    }
    
    //No patchwork for the internal components because each constant is independent of the others
    
    //Setup the internal data structures for key management/polyphony
    availableKeys = new Stack();
    keyBindings = new HashMap();
    //At the beginning, all keys are available
    for(int i = Keyboard_CONSTANTS.PATCHOUT_KEY0; i < Keyboard_CONSTANTS.TOTAL_PATCHOUT; i++)
    {
      availableKeys.push(i);
    }
  }
  
  //Implement in each component to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public void draw_update()
  {
    //Nothing here yet, knob updates are now done in Knob class (as they should)
  }
  
  //Sets a key to send a frequency value (if one of the keys is currently unused
  //  and the specified frequency is not already in use)
  //Returns whether an available key was found (that index), -1 if none
  public int set_key(char bind, float freq)
  {
    //Instantly fail if no key is available or the bind value is in use already
    if(availableKeys.isEmpty() || (keyBindings.containsKey(bind) && (keyBindings.get(bind) != null)))
    {
      return -1;
    }
    
    //Set the next key that is available
    int nextKeyIndex = availableKeys.pop();
    //Assign the Constant to the specified frequency
    keys[nextKeyIndex].setConstant(freq);
    //Set up the binding for the selected index
    keyBindings.put(bind, nextKeyIndex);
    
    //Return the index to confirm the assignment
    return nextKeyIndex;
  }
  
  //Sets a key to 0 frequency value (if one of the keys was playing the specified value)
  //Returns whether the key was found and successfully turned off (as a boolean)
  public boolean unset_key(char bind)
  {
    //Instantly fail if the binding is not in use already
    if(!keyBindings.containsKey(bind) || (keyBindings.get(bind) == null))
    {
      return false;
    }
    
    //Retrieve the key with the specified binding
    int boundKeyIndex = keyBindings.get(bind);
    //Return the Constant to the 0.0 frequency for "off" setting
    keys[boundKeyIndex].setConstant(0.0);
    //Undo the binding (set to mapped value to null) and make key available again
    keyBindings.put(bind, null);
    availableKeys.push(boundKeyIndex);
    
    //Return true to confirm the undone assignment
    return true;
  }
}
