/*Keyboard.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2022 January 20

Class for a keyboard module within a synthesized instrument.
This module sends frequency information for a pressed key that can act as dynamic
input to an oscillator, envelope, etc.  Includes polyphonic support for up to 10 pressed
keys "at once" (need to press or release one key per frame, cannot be simultaneous).
*/

//For the data structures, need some imported classes
import java.util.Queue;
import java.util.HashMap;

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the VCO class below
public static class Keyboard_CONSTANTS
{
  //Nothing to patch in, much like power (surprise, this module is effectively 
  //  10 power-like knobs under the hood)
  public static final int TOTAL_PATCHIN = 0;
  
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
  //NOTE: Due to computational resources, can reduce polyphony support by lowering TOTAL_PATCHOUT regardless of the indeces available above
  public static final int TOTAL_PATCHOUT = PATCHOUT_KEY2 + 1;//PATCHOUT_KEY9 + 1;
  
  //Indeces for more output patches - these are the gates noting when a polyphonic key is pressed
  public static final int PATCHOUT_GATE0 = TOTAL_PATCHOUT; //The gate patches continue after the key patches
  public static final int PATCHOUT_GATE1 = PATCHOUT_GATE0 + 1;
  public static final int PATCHOUT_GATE2 = PATCHOUT_GATE1 + 1;
  public static final int PATCHOUT_GATE3 = PATCHOUT_GATE2 + 1;
  public static final int PATCHOUT_GATE4 = PATCHOUT_GATE3 + 1;
  public static final int PATCHOUT_GATE5 = PATCHOUT_GATE4 + 1;
  public static final int PATCHOUT_GATE6 = PATCHOUT_GATE5 + 1;
  public static final int PATCHOUT_GATE7 = PATCHOUT_GATE6 + 1;
  public static final int PATCHOUT_GATE8 = PATCHOUT_GATE7 + 1;
  public static final int PATCHOUT_GATE9 = PATCHOUT_GATE8 + 1;
  //NOTE: No total because each PATCHOUT_KEY# matches a PATCHOUT_GATE# and is thus restricted to TOTAL_PATCHOUT
  
  //For key type when binding annotations
  public static final boolean NATURAL_KEY = true;
  public static final boolean HALFTONE_KEY = !NATURAL_KEY;
}

public class Keyboard extends SynthModule
{
  //Internal UGen Objects that compose the module's "circuit"
  //Each output will be a single, constant frequency whose value changes with key presses
  private Constant[] keys;
  //Paired with each key's frequency constant is a gate constant, which is 1 when a key is pressed and 0 when a key is not pressed
  private Constant[] gates;
  
  //Internal data structures used to manage the keys in use for polyphonic sound
  //Queue that tracks remaining available indeces
  private Queue<Integer> availableKeys;
  //HashMap from a keybinding to the key index that is playing the key value
  private HashMap<Character, Integer> keyBindings;
  
  //In case key annotations are used when rendering (depends on GUI, but can include keyboard bindings, note names, etc.)
  private String[] annotations_natural;
  private String[] annotations_halftone;
  
  //In case key highlighting is used when rendering (depends on GUI, but can include keyboard pressing, etc.)
  private boolean[] highlight_natural;
  private boolean[] highlight_halftone;
  
  //Default Constructor - set up all the patches and knobs
  public Keyboard()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    //NOTE: Double the number of output patches to handle both keys and gates
    super(Keyboard_CONSTANTS.TOTAL_PATCHIN, Keyboard_CONSTANTS.TOTAL_PATCHOUT * 2, Keyboard_CONSTANTS.TOTAL_KNOB);

    //Set up the internals of the module with the UGen elements from Minim
    keys = new Constant[Keyboard_CONSTANTS.TOTAL_PATCHOUT];
    gates = new Constant[Keyboard_CONSTANTS.TOTAL_PATCHOUT];
    for(int i = Keyboard_CONSTANTS.PATCHOUT_KEY0; i < Keyboard_CONSTANTS.TOTAL_PATCHOUT; i++)
    {
      keys[i] = new Constant(0.0);
      gates[i] = new Constant(0.0);
    }
    
    //With the UGens all setup, fill in the external-facing ones for input/output
    for(int i = Keyboard_CONSTANTS.PATCHOUT_KEY0; i < Keyboard_CONSTANTS.TOTAL_PATCHOUT; i++)
    {
      patchOut[Keyboard_CONSTANTS.PATCHOUT_KEY0 + i] = keys[i];
      patchOut[Keyboard_CONSTANTS.PATCHOUT_GATE0 + i] = gates[i];
      //Label for the GUI
      patchOutLabel[Keyboard_CONSTANTS.PATCHOUT_KEY0 + i] = "FREQ OUT";
      patchOutLabel[Keyboard_CONSTANTS.PATCHOUT_GATE0 + i] = "GATE OUT";
    }
    moduleName = "Keyboard";
    
    //No patchwork for the internal modules because each constant is independent of the others
    
    //Setup the internal data structures for key management/polyphony
    availableKeys = new java.util.LinkedList();
    keyBindings = new HashMap();
    //At the beginning, all keys are available
    for(int i = Keyboard_CONSTANTS.PATCHOUT_KEY0; i < Keyboard_CONSTANTS.TOTAL_PATCHOUT; i++)
    {
      availableKeys.add(i);
    }
    
    //Setup the annotations to all be empty strings for now
    annotations_natural = new String[Render_CONSTANTS.KEYBOARD_NATURAL_TOTAL];
    annotations_halftone = new String[Render_CONSTANTS.KEYBOARD_HALFTONE_TOTAL];
    highlight_natural = new boolean[Render_CONSTANTS.KEYBOARD_NATURAL_TOTAL];
    highlight_halftone = new boolean[Render_CONSTANTS.KEYBOARD_HALFTONE_TOTAL];
  }
  
  //Implement in each module to do any per-draw-iteration updates
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
    int nextKeyIndex = availableKeys.poll(); //poll instead of remove to get null if the queue is empty (though the check above should avoid that case)
    //Assign the keys Constant to the specified frequency
    keys[nextKeyIndex].setConstant(freq);
    //Note the gate Constant is now "active"
    gates[nextKeyIndex].setConstant(1.0);
    //Set up the binding for the selected index
    keyBindings.put(bind, nextKeyIndex);
    
    //Return the index to confirm the assignment
    return nextKeyIndex;
  }
  
  //Sets a gate to 0 value (if one of the keys was playing the specified value)
  //NOTE: The key frequency is not changed so that an envelope generator can complete its release after the key is pressed (else it releases on a 0-frequency waveform...)
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
    //Return the gates Constant to the 0.0 frequency for "off" setting
    //NOTE: The key frequency is not changed so that an envelope generator can complete its release after the key is pressed (else it releases on a 0-frequency waveform...)
    gates[boundKeyIndex].setConstant(0.0);
    //Undo the binding (set to mapped value to null) and make key available again
    keyBindings.put(bind, null);
    availableKeys.add(boundKeyIndex);
    
    //Return true to confirm the undone assignment
    return true;
  }
  
  //Assigns an annotation to render with some key
  //The boolean natural is true when index is for a natural note, false when index is for a halftone
  //The return value is false when the index does not exist to complete the annotation
  public boolean set_annotation(boolean natural, int index, String annotation)
  {
    //Easy case: index is negative to guarantee out-of-bounds
    if(index < 0)
    {
      return false;
    }
    //A natural key uses the corresponding annotation array
    else if((natural == Keyboard_CONSTANTS.NATURAL_KEY) && (index < annotations_natural.length))
    {
      annotations_natural[index] = annotation;
      return true;
    }
    //A halftone key uses the corresponding annotation array
    else if((natural == Keyboard_CONSTANTS.HALFTONE_KEY) && (index < annotations_halftone.length))
    {
      annotations_halftone[index] = annotation;
      return true;
    }
    //At this point, index was out-of-bounds from being too large
    else
    {
      return false;
    }
  }
  
  //Toggles highlighting to render with some key
  //The boolean natural is true when index is for a natural note, false when index is for a halftone
  //The return value is false when the index does not exist to complete the annotation
  public boolean set_highlight(boolean natural, int index, boolean highlight)
  {
    //Easy case: index is negative to guarantee out-of-bounds
    if(index < 0)
    {
      return false;
    }
    //A natural key uses the corresponding annotation array
    else if((natural == Keyboard_CONSTANTS.NATURAL_KEY) && (index < highlight_natural.length))
    {
      highlight_natural[index] = highlight;
      return true;
    }
    //A halftone key uses the corresponding annotation array
    else if((natural == Keyboard_CONSTANTS.HALFTONE_KEY) && (index < highlight_halftone.length))
    {
      highlight_halftone[index] = highlight;
      return true;
    }
    //At this point, index was out-of-bounds from being too large
    else
    {
      return false;
    }
  }
  
  //Override the render command for SynthModule superclass because the keyboard is
  //  very different in design (show subset of patches and knobs, mostly keys) and 
  //  should be part of all instruments (rather than as a possible module)
  public void render(int xOffset, int yOffset)
  {
    //As the lowest layer of the GUI image for the module,
    //  render the module's box as a rectangle (rather than a module, fills lower border)
    stroke(0, 0, 0); //Black stroke
    strokeWeight(Render_CONSTANTS.DEFAULT_STROKE_WEIGHT);
    fill(128, 128, 128); //light-grey fill
    rect(xOffset, yOffset, Render_CONSTANTS.LOWER_BORDER_WIDTH, Render_CONSTANTS.LOWER_BORDER_HEIGHT);
    
    //All text should be centered about the specified (x,y) coordinates per text() call
    textAlign(CENTER, CENTER);
    //Like font, set the size of all text on this module (measured in pixels)
    //For simplicity, make the same size as a knob (since portrayed as a slider)
    textSize(Render_CONSTANTS.KNOB_HEIGHT);
    
    //Next, render the module name in the top-center of the module
    if(moduleName != null)
    {
      fill(0, 0, 0); //Black text
      text(moduleName, xOffset + (Render_CONSTANTS.LOWER_BORDER_WIDTH / 2), yOffset + Render_CONSTANTS.KNOB_HEIGHT);
    }
    
    //Despite all the output patches, these are to allow instrument polyphony (simultaneous
    //  notes at once) => only allow one of these patches (the first) to be used in the GUI
    //Each patch is a uniformly-sized circle, set to be solid black (like a hole)
    fill(0, 0, 0);
    stroke(0, 0, 0);
    
    //For simplicity, make the labels half the size of a knob (since portrayed as a slider)
    textSize(Render_CONSTANTS.KNOB_HEIGHT / 2);
    
    //Render a patch hole if a patch is defined in this entry
    //  This is to avoid putting a cable into nothing, or can align holes to pretty-print module
    if((patchOut != null) && (patchOut[Keyboard_CONSTANTS.PATCHOUT_KEY0] != null))
    {
      //If provided, include label for the patch
      if((patchOutLabel != null) && (patchOutLabel[Keyboard_CONSTANTS.PATCHOUT_KEY0] != null))
      {
        text(patchOutLabel[Keyboard_CONSTANTS.PATCHOUT_KEY0], xOffset + (Render_CONSTANTS.LEFT_BORDER_WIDTH / 2), yOffset + Render_CONSTANTS.KNOB_HEIGHT + Render_CONSTANTS.PATCH_RADIUS);
      }
      //First two values are center, width and height are equal for circle
      ellipse(xOffset + (Render_CONSTANTS.LEFT_BORDER_WIDTH / 2), yOffset + Render_CONSTANTS.KNOB_HEIGHT + (3 * Render_CONSTANTS.PATCH_RADIUS), Render_CONSTANTS.PATCH_DIAMETER, Render_CONSTANTS.PATCH_DIAMETER);
      
      //Also send the center values to the patch cable, if one exists that is plugged into this patch
      if((patchOutCable != null) && (patchOutCable[Keyboard_CONSTANTS.PATCHOUT_KEY0] != null))
      {
        patchOutCable[Keyboard_CONSTANTS.PATCHOUT_KEY0].setRenderOut(xOffset + (Render_CONSTANTS.LEFT_BORDER_WIDTH / 2), yOffset + Render_CONSTANTS.KNOB_HEIGHT + (3 * Render_CONSTANTS.PATCH_RADIUS));
      }
    }
    if((patchOut != null) && (patchOut[Keyboard_CONSTANTS.PATCHOUT_GATE0] != null))
    {
      //If provided, include label for the patch
      if((patchOutLabel != null) && (patchOutLabel[Keyboard_CONSTANTS.PATCHOUT_GATE0] != null))
      {
        text(patchOutLabel[Keyboard_CONSTANTS.PATCHOUT_GATE0], xOffset + (Render_CONSTANTS.LEFT_BORDER_WIDTH / 2), yOffset + Render_CONSTANTS.KNOB_HEIGHT + Render_CONSTANTS.PATCH_RADIUS + (2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)));
      }
      //First two values are center, width and height are equal for circle
      ellipse(xOffset + (Render_CONSTANTS.LEFT_BORDER_WIDTH / 2), yOffset + Render_CONSTANTS.KNOB_HEIGHT + (3 * Render_CONSTANTS.PATCH_RADIUS) + (2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)), Render_CONSTANTS.PATCH_DIAMETER, Render_CONSTANTS.PATCH_DIAMETER);
      
      //Also send the center values to the patch cable, if one exists that is plugged into this patch
      if((patchOutCable != null) && (patchOutCable[Keyboard_CONSTANTS.PATCHOUT_GATE0] != null))
      {
        patchOutCable[Keyboard_CONSTANTS.PATCHOUT_GATE0].setRenderOut(xOffset + (Render_CONSTANTS.LEFT_BORDER_WIDTH / 2), yOffset + Render_CONSTANTS.KNOB_HEIGHT + (3 * Render_CONSTANTS.PATCH_RADIUS) + (2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)));
      }
    }
    
    //Now render the keys on the keyboard, natural are tiled first with halftones on top
    stroke(0, 0, 0); //Black stroke
    fill(255, 255, 255); //White fill
    for(int i = 0; i < Render_CONSTANTS.KEYBOARD_NATURAL_TOTAL; i++)
    {
      //Adjust the color display when the key is highlighted (turn to magenta key fill)
      if(highlight_natural[i])
      {
        fill(255, 0 , 255);
      }
      //Begin the natural keys in the lower border without intersection with the left
      //  border (used for the output patch), and center vertically
      rect(xOffset + Render_CONSTANTS.LEFT_BORDER_WIDTH + (i * Render_CONSTANTS.KEYBOARD_NATURAL_WIDTH), yOffset + Render_CONSTANTS.KNOB_HEIGHT + ((Render_CONSTANTS.LOWER_BORDER_HEIGHT - Render_CONSTANTS.KEYBOARD_NATURAL_HEIGHT - Render_CONSTANTS.KNOB_HEIGHT) / 2), Render_CONSTANTS.KEYBOARD_NATURAL_WIDTH, Render_CONSTANTS.KEYBOARD_NATURAL_HEIGHT);
      //Reset the color display when the key is highlighted (back to white key fill)
      if(highlight_natural[i])
      {
        fill(255, 255 , 255);
      }
      //If there is an annotation, then print it
      if((annotations_natural[i] != null) && (!annotations_natural[i].equals("")))
      {
        fill(0, 0, 0); //Black text on white key
        text(annotations_natural[i], xOffset + Render_CONSTANTS.LEFT_BORDER_WIDTH + (i * Render_CONSTANTS.KEYBOARD_NATURAL_WIDTH) + (Render_CONSTANTS.KEYBOARD_NATURAL_WIDTH / 2), yOffset + Render_CONSTANTS.KNOB_HEIGHT + ((Render_CONSTANTS.LOWER_BORDER_HEIGHT - Render_CONSTANTS.KEYBOARD_NATURAL_HEIGHT - Render_CONSTANTS.KNOB_HEIGHT) / 2) + ((2 * Render_CONSTANTS.KEYBOARD_NATURAL_HEIGHT) / 3));
        fill(255, 255, 255); //Back to white key's fill
      }
    }
    //NOTE: Halftones have fun spacing because of the 5 halftones vs. 7 naturals in one octave
    //      Easier to tile from right-to-left due to pattern being partially done in lowest octave
    stroke(0, 0, 0); //Black stroke
    fill(0, 0, 0); //Black fill
    int halftoneOffset = Render_CONSTANTS.KEYBOARD_NATURAL_TOTAL - 1; //Right-most key is natural, not halftone, which starts offset pattern
    int halftoneAnnotationIndex = annotations_halftone.length - 1;
    for(int i = 0; i < (Render_CONSTANTS.KEYBOARD_HALFTONE_TOTAL / Render_CONSTANTS.KEYBOARD_HALFTONE_OCTAVE); i++) //Per complete octave
    {
      halftoneOffset--; //No halftone key (enharmonic B# = C)
      for(int j = 0; j < 3; j++) //3 halftone keys in a row
      {
        //Adjust the color display when the key is highlighted (turn to blue key fill)
        if(highlight_halftone[halftoneAnnotationIndex])
        {
          fill(0, 0 , 255);
        }
        //Begin the halftone keys based on spacing horizontally (position with respect to
        //  natural keys and offset to one-third the width) and aligned on top
        rect(xOffset + Render_CONSTANTS.LEFT_BORDER_WIDTH + (halftoneOffset * Render_CONSTANTS.KEYBOARD_NATURAL_WIDTH) - Render_CONSTANTS.KEYBOARD_HALFTONE_HORIZ_OFFSET, yOffset + Render_CONSTANTS.KNOB_HEIGHT + ((Render_CONSTANTS.LOWER_BORDER_HEIGHT - Render_CONSTANTS.KEYBOARD_NATURAL_HEIGHT - Render_CONSTANTS.KNOB_HEIGHT) / 2) + Render_CONSTANTS.KEYBOARD_HALFTONE_VERT_OFFSET, Render_CONSTANTS.KEYBOARD_HALFTONE_WIDTH, Render_CONSTANTS.KEYBOARD_HALFTONE_HEIGHT);
        //Reset the color display when the key is highlighted (back to black key fill)
        if(highlight_halftone[halftoneAnnotationIndex])
        {
          fill(0, 0 , 0);
        }
        //If there is an annotation, then print it
        if((annotations_halftone[halftoneAnnotationIndex] != null) && (!annotations_halftone[halftoneAnnotationIndex].equals("")))
        {
          fill(255, 255, 255); //White text on black key
          text(annotations_halftone[halftoneAnnotationIndex], xOffset + Render_CONSTANTS.LEFT_BORDER_WIDTH + (halftoneOffset * Render_CONSTANTS.KEYBOARD_NATURAL_WIDTH) - Render_CONSTANTS.KEYBOARD_HALFTONE_HORIZ_OFFSET + (Render_CONSTANTS.KEYBOARD_HALFTONE_WIDTH / 2), yOffset + Render_CONSTANTS.KNOB_HEIGHT + ((Render_CONSTANTS.LOWER_BORDER_HEIGHT - Render_CONSTANTS.KEYBOARD_NATURAL_HEIGHT - Render_CONSTANTS.KNOB_HEIGHT) / 2) + Render_CONSTANTS.KEYBOARD_HALFTONE_VERT_OFFSET + ((1 * Render_CONSTANTS.KEYBOARD_HALFTONE_HEIGHT) / 2));
          fill(0, 0, 0); //Back to black key's fill
        }
        halftoneAnnotationIndex--;
        halftoneOffset--;
      }
      halftoneOffset--; //No halftone key (enharmonic E# = F)
      for(int j = 0; j < 2; j++) //2 halftone keys in a row
      {
        //Adjust the color display when the key is highlighted (turn to blue key fill)
        if(highlight_halftone[halftoneAnnotationIndex])
        {
          fill(0, 0 , 255);
        }
        //Begin the halftone keys based on spacing horizontally (position with respect to
        //  natural keys and offset to one-third the width) and aligned on top
        rect(xOffset + Render_CONSTANTS.LEFT_BORDER_WIDTH + (halftoneOffset * Render_CONSTANTS.KEYBOARD_NATURAL_WIDTH) - Render_CONSTANTS.KEYBOARD_HALFTONE_HORIZ_OFFSET, yOffset + Render_CONSTANTS.KNOB_HEIGHT + ((Render_CONSTANTS.LOWER_BORDER_HEIGHT - Render_CONSTANTS.KEYBOARD_NATURAL_HEIGHT - Render_CONSTANTS.KNOB_HEIGHT) / 2) + Render_CONSTANTS.KEYBOARD_HALFTONE_VERT_OFFSET, Render_CONSTANTS.KEYBOARD_HALFTONE_WIDTH, Render_CONSTANTS.KEYBOARD_HALFTONE_HEIGHT);
        //Reset the color display when the key is highlighted (back to black key fill)
        if(highlight_halftone[halftoneAnnotationIndex])
        {
          fill(0, 0 , 0);
        }
        //If there is an annotation, then print it
        if((annotations_halftone[halftoneAnnotationIndex] != null) && (!annotations_halftone[halftoneAnnotationIndex].equals("")))
        {
          fill(255, 255, 255); //White text on black key
          text(annotations_halftone[halftoneAnnotationIndex], xOffset + Render_CONSTANTS.LEFT_BORDER_WIDTH + (halftoneOffset * Render_CONSTANTS.KEYBOARD_NATURAL_WIDTH) - Render_CONSTANTS.KEYBOARD_HALFTONE_HORIZ_OFFSET + (Render_CONSTANTS.KEYBOARD_HALFTONE_WIDTH / 2), yOffset + Render_CONSTANTS.KNOB_HEIGHT + ((Render_CONSTANTS.LOWER_BORDER_HEIGHT - Render_CONSTANTS.KEYBOARD_NATURAL_HEIGHT - Render_CONSTANTS.KNOB_HEIGHT) / 2) + Render_CONSTANTS.KEYBOARD_HALFTONE_VERT_OFFSET + (Render_CONSTANTS.KEYBOARD_HALFTONE_HEIGHT / 2));
          fill(0, 0, 0); //Back to black key's fill
        }
        halftoneAnnotationIndex--;
        halftoneOffset--;
      }
    }
    //Just one halftone key leftover...
    halftoneOffset--; //No halftone key (enharmonic B# = C)
    //Adjust the color display when the key is highlighted (turn to blue key fill)
    if(highlight_halftone[halftoneAnnotationIndex])
    {
      fill(0, 0 , 255);
    }
    rect(xOffset + Render_CONSTANTS.LEFT_BORDER_WIDTH + (halftoneOffset * Render_CONSTANTS.KEYBOARD_NATURAL_WIDTH) - Render_CONSTANTS.KEYBOARD_HALFTONE_HORIZ_OFFSET, yOffset + Render_CONSTANTS.KNOB_HEIGHT + ((Render_CONSTANTS.LOWER_BORDER_HEIGHT - Render_CONSTANTS.KEYBOARD_NATURAL_HEIGHT - Render_CONSTANTS.KNOB_HEIGHT) / 2) + Render_CONSTANTS.KEYBOARD_HALFTONE_VERT_OFFSET, Render_CONSTANTS.KEYBOARD_HALFTONE_WIDTH, Render_CONSTANTS.KEYBOARD_HALFTONE_HEIGHT);
    //Reset the color display when the key is highlighted (back to black key fill)
    if(highlight_halftone[halftoneAnnotationIndex])
    {
      fill(0, 0 , 0);
    }
    //If there is an annotation, then print it
    if((annotations_halftone[halftoneAnnotationIndex] != null) && (!annotations_halftone[halftoneAnnotationIndex].equals("")))
    {
      fill(255, 255, 255); //White text on black key
      text(annotations_halftone[halftoneAnnotationIndex], xOffset + Render_CONSTANTS.LEFT_BORDER_WIDTH + (halftoneOffset * Render_CONSTANTS.KEYBOARD_NATURAL_WIDTH) - Render_CONSTANTS.KEYBOARD_HALFTONE_HORIZ_OFFSET + (Render_CONSTANTS.KEYBOARD_HALFTONE_WIDTH / 2), yOffset + Render_CONSTANTS.KNOB_HEIGHT + ((Render_CONSTANTS.LOWER_BORDER_HEIGHT - Render_CONSTANTS.KEYBOARD_NATURAL_HEIGHT - Render_CONSTANTS.KNOB_HEIGHT) / 2) + Render_CONSTANTS.KEYBOARD_HALFTONE_VERT_OFFSET + (Render_CONSTANTS.KEYBOARD_HALFTONE_HEIGHT / 2));
      fill(0, 0, 0); //Back to black key's fill
    }
    halftoneAnnotationIndex--;
  }
  
  //Override the getElementAt command for SynthModule superclass because the keyboard
  //  is very different in design (show subset of patches and knobs, mostly keys) and 
  //  should be part of all instruments (rather than as a possible module)
  //Output format is a length-2 integer array: [element_type, index]
  //NOTE: The output format will have some helpful magic numbers defined in Render_CONSTANTS
  //NOTE: The inputs x and y are relative to the top-left corner of this SynthModule
  public int[] getElementAt(int x, int y)
  {
    //Setup the output array first, fill in just before returning (set to default, the "null")
    int[] toReturn = new int[Render_CONSTANTS.SYNTHMODULE_TOTAL_FOCUS];
    toReturn[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] = Render_CONSTANTS.SYNTHMODULE_ELEMENT_NONE;
    toReturn[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX] = -1;
    
    //Only check for the provided first key/gate patch out; others are not displayed
    //The patch is just a circle
    if(Render_CONSTANTS.circ_contains_point(Render_CONSTANTS.LEFT_BORDER_WIDTH / 2, Render_CONSTANTS.KNOB_HEIGHT + (3 * Render_CONSTANTS.PATCH_RADIUS), Render_CONSTANTS.PATCH_RADIUS, x, y))
    {
      toReturn[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] = Render_CONSTANTS.SYNTHMODULE_ELEMENT_PATCHOUT;
      toReturn[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX] = Keyboard_CONSTANTS.PATCHOUT_KEY0;
      return toReturn;
    }
    else if(Render_CONSTANTS.circ_contains_point((Render_CONSTANTS.LEFT_BORDER_WIDTH / 2), Render_CONSTANTS.KNOB_HEIGHT + (3 * Render_CONSTANTS.PATCH_RADIUS) + (2 * (Render_CONSTANTS.PATCH_DIAMETER + Render_CONSTANTS.VERT_SPACE)), Render_CONSTANTS.PATCH_RADIUS, x, y))
    {
      toReturn[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] = Render_CONSTANTS.SYNTHMODULE_ELEMENT_PATCHOUT;
      toReturn[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX] = Keyboard_CONSTANTS.PATCHOUT_GATE0;
      return toReturn;
    }
    
    //At this point, the point did not fit into any elements => return nothing
    return toReturn;
  }
}
