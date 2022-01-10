/*synthesizer_eaai.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2022 January 09

A synthesizer application that generates custom audio based on setup of various components.
Made possible using the Minim library (API at http://code.compartmental.net/minim/index_ugens.html)
*/

import ddf.minim.*;
import ddf.minim.ugens.*;

import java.util.ArrayList;
import java.util.HashMap;

//Create global variables that will need to be accessed in multiple methods
private Minim minim; //Makes the Minum magic happen!
private AudioOutput out; //Generates audio output (speaker, file, etc.)
//The Summer combines soundwaves from multiple patches, such as multiple instruments. 
//  We use this global Summer to let the output play all instruments at the same time
private Summer allInstruments_toOut;

//The available instruments (independent synthesizer setups), maintained in a list
private ArrayList<CustomInstrument> instruments;
private int currentInstrument = -1;

//Some variables to share target/focus information over time/between frames (like a short-term memory)
private int mouseTargetInstrumentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of instrument with currently selected things via the mouse
private int mouseTargetComponentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of SynthComponent currently selected with the mouse
private int mouseTargetKnobIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of focused SynthComponent's currently selected knob with the mouse
private int mouseTargetPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of in patch cable currently selected with the mouse
private int mouseTargetPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of out patch cable currently selected with the mouse
private int mousePrevComponentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of patch cable of focus's previous component to which it was plugged in
private int mousePrevPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of in patch cable of focus's previous patch entry to which it was plugged in
private int mousePrevPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of out patch cable of focus's previous patch entry to which it was plugged in

//Constant used to toggle debug modes
//NOTE: "Dead code" warnings below when checking for multiple debug flags are expected because of lazy Boolean evaluation
public final boolean DEBUG_SYSTEM = false; //For general procedural stuff, like control flow
public final boolean DEBUG_INTERFACE_KNOB = false; //For testing interfacing (defined below) with the knob
public final boolean DEBUG_INTERFACE_PATCH = false; //For testing interfacing (defined below) with the patches
public final boolean DEBUG_INTERFACE_MOUSE = false; //For testing interfacing (definted below) with the computer mouse
public final boolean DEBUG_INTERFACE_KEYBOARD = false; //For testing interfacing (defined below) with the computer keyboard
public final boolean DEBUG_INTERFACE = false || DEBUG_INTERFACE_KNOB || DEBUG_INTERFACE_PATCH || DEBUG_INTERFACE_MOUSE || DEBUG_INTERFACE_KEYBOARD; //For testing interfacing features (GUI, set values via I/O-related function calls)

//Information about the MIDI numbers mapping to various piano keyboard keys and frequency information
private int[] midiNum;
private float[] midiFreq;
private boolean[] midiNatural;
private int[] midiKeyIndex; //Will mix with natural and halftone

//Also need information about hands for key bindings with GUI
public final int KEYS_PER_OCTAVE = 12;
public final int KEYS_PER_HAND = KEYS_PER_OCTAVE + 1; //Allows whole octave (sorry, no ninths or tenths with the limited keys avaiable...)
public final char[] HALFTONE_KEYS_LEFT = {'q', 'w', 'e', 'r', 't'}; //Assign left hand's halftone keys in this order... assumes a QWERTY keyboard (sorry!)
public final char[] NATURAL_KEYS_LEFT = {'a', 'z', 's', 'x', 'd', 'c', 'f', 'v'}; //Assign left hand's natural keys in this order... assumes a QWERTY keyboard (sorry!)
public final char[] HALFTONE_KEYS_RIGHT = {'y', 'u', 'i', 'o', 'p'}; //Assign right hand's halftone keys in this order... assumes a QWERTY keyboard (sorry!)
public final char[] NATURAL_KEYS_RIGHT = {'j', 'm', 'k', ',', 'l', '.', ';', '/'}; //Assign right hand's natural keys in this order... assumes a QWERTY keyboard (sorry!)
public final boolean LEFT_HAND = true;
public final boolean RIGHT_HAND = !LEFT_HAND;
private int left_hand_curIndex = 0; //Starts at left pinky
private int right_hand_curIndex = 0; //Starts at right thumb

//The GUI should keep track of notes being played
private HashMap<Character, Integer> guiKeyBindings;

//For the GUI to render all available instruments at once (easier than adding/removing through GUI commands)
public int MAX_INSTRUMENTS = 2; //16;

void setup()
{
  //NOTE: Must provide magic numbers to size(...), not static constants
  //      Make sure the APP_... constant values match the size(...) arguments to render properly
  //size(Render_CONSTANTS.APP_WIDTH, Render_CONSTANTS.APP_HEIGHT, P2D);
  size(1000, 800, P2D);
  
  //Initialize the Minim and AudioOutput objects
  minim = new Minim( this );
  out = minim.getLineOut();
  allInstruments_toOut = new Summer();
  
  //Initialize the list of instruments, which begins empty (until instruments are added)
  instruments = new ArrayList();
  currentInstrument = -1;
  
  //The global Summer is always patched to the audio output for our setup
  //Instead of patching directly with the output, patch with the global Summer instead!
  allInstruments_toOut.patch(out);
  
  //Due to closing with the global Summer's patch still active, we force the unpatch before quitting the application
  //Thank you to https://forum.processing.org/one/topic/run-code-on-exit.html ,
  //  where the solution for how to activate code when exiting the application was found
  prepareExitHandler();
  
  //For easy access to a testbed, preload a special custom instrument when debugging
  if(DEBUG_SYSTEM || DEBUG_INTERFACE)
  {
    setupDebugInstrument();
  }
  //When no instrument debugging, then need a fresh, empty instrument to get started
  else
  {
    setupBlankInstruments(MAX_INSTRUMENTS);
  }
  
  //Initialize all the MIDI information for the keyboard
  setupMIDIarrays();
  
  guiKeyBindings = new HashMap();
  
  //Now there is enough information to bind the keys to the keyboard, if a keyboard exists
  left_hand_curIndex = 0;
  right_hand_curIndex = Render_CONSTANTS.KEYBOARD_KEYS_TOTAL - KEYS_PER_HAND; //This is a natural key, and will have one key off the keyboard bounds
  realignKeyboard(LEFT_HAND, left_hand_curIndex);
  realignKeyboard(RIGHT_HAND, right_hand_curIndex);
}

void draw()
{
  //Reset the drawn image with a cleared background to a default color
  clear();
  background(200, 200, 200);
  
  //For easy access to a testbed, do things with a special custom instrument when debugging
  if(DEBUG_SYSTEM || DEBUG_INTERFACE)
  {
    drawDebugInstrument();
  }
  
  //Before rendering the current instrument, make sure all instruments have a chance to update their state
  for(int i = 0; i < instruments.size(); i++)
  {
    if(instruments.get(currentInstrument) != null)
    {
      instruments.get(i).draw_update();
    }
  }
  //Draw on screen the instrument that is currently selected
  if((currentInstrument >= 0) && (currentInstrument < instruments.size()) && (instruments.get(currentInstrument) != null))
  {
    instruments.get(currentInstrument).render();
  }
}

//Used to setup a blank custom instrument with no preloaded features
private void setupBlankInstruments(int numInstruments)
{
  //Make sure at least one instrument gets created
  if(numInstruments <= 0) {numInstruments = 1;}
  
  for(int i = 0; i < numInstruments; i++)
  {
    instruments.add(new CustomInstrument());
  }
  setCurrentInstrument(0); //Set the first instrument on screen to be the current one
}

//Used to run the MIDI-related arrays setup (to avoid setup itself being too messy)
//CITE: Based on https://newt.phys.unsw.edu.au/jw/notes.html 's figure https://newt.phys.unsw.edu.au/jw/graphics/notes.GIF
private void setupMIDIarrays()
{
  midiNum = new int[Render_CONSTANTS.KEYBOARD_KEYS_TOTAL];
  //MIDI starts at number 21 for A0, up to 108 (C8) when mapped to physical keyboard
  for(int i = 0; i < midiNum.length; i++)
  {
    midiNum[i] = i + 21; //This makes 0~87 become 21~108 as desired
  }
  
  midiFreq = new float[Render_CONSTANTS.KEYBOARD_KEYS_TOTAL];
  //Frequency of A0 is 27.5 Hz, and each half-step note is 2^(1/12) times the previous
  midiFreq[0] = 27.5;
  for(int i = 1; i < midiFreq.length; i++)
  {
    midiFreq[i] = midiFreq[i - 1] * pow(2, 1.0 / 12.0);
  }
  
  midiNatural = new boolean[Render_CONSTANTS.KEYBOARD_KEYS_TOTAL];
  //Need to fill in whether a key is natural or halftone, which has a pattern per octave
  //NOTE: The pattern is based off the Keyboard class's render function
  java.util.Arrays.fill(midiNatural, Keyboard_CONSTANTS.NATURAL_KEY);
  int halftoneOffset = midiNatural.length - 2; //Right-most key is natural, not halftone, which starts offset pattern at -2 rather than -1 (to avoid out-of-bounds error)
  for(int i = 0; i < (Render_CONSTANTS.KEYBOARD_HALFTONE_TOTAL / Render_CONSTANTS.KEYBOARD_HALFTONE_OCTAVE); i++) //Per complete octave
  {
    halftoneOffset--; //No halftone key (enharmonic B = Cb), so just skips B
    for(int j = 0; j < 3; j++) //3 halftone keys in a row
    {
      midiNatural[halftoneOffset] = Keyboard_CONSTANTS.HALFTONE_KEY;
      halftoneOffset -= 2; //Alternates natural-halftone for Bb/A#, A, Ab/G#, G, Gb/F#, F, Fb/E
    }
    halftoneOffset--; //No halftone key (enharmonic E = Fb), so just skips E
    for(int j = 0; j < 2; j++) //2 halftone keys in a row
    {
      midiNatural[halftoneOffset] = Keyboard_CONSTANTS.HALFTONE_KEY;
      halftoneOffset -= 2; //Alternates natural-halftone for Eb/D#, D, Db/C#, C, Cb/B
    }
  }
  //Just one halftone key leftover...
  halftoneOffset--; //No halftone key (enharmonic B = Cb), so just skips B
  midiNatural[halftoneOffset] = Keyboard_CONSTANTS.HALFTONE_KEY;
  
  midiKeyIndex = new int[Render_CONSTANTS.KEYBOARD_KEYS_TOTAL];
  //Because the natural and halftone keys are operated separately in Keyboard class, need to map the global piano key index to these separate indeces
  int nextNatural = 0;
  int nextHalftone = 0;
  for(int i = 0; i < midiKeyIndex.length; i++)
  {
    if(midiNatural[i] == Keyboard_CONSTANTS.NATURAL_KEY)
    {
      midiKeyIndex[i] = nextNatural;
      nextNatural++;
    }
    else //if(midiNatural[i] == Keyboard_CONSTANTS.HALFTONE_KEY)
    {
      midiKeyIndex[i] = nextHalftone;
      nextHalftone++;
    }
  }
}

//Aligns a hand with the keyboard bindings, assuming the bindings and instrument both exist
//Returns a boolean for whether the assignment was successful (a.k.a. newIndex is in bounds and current instrument exists)
public boolean realignKeyboard(boolean hand, int newIndex)
{
  //Make sure the newIndex value is valid (within bounds for at least one key on the hand)
  if(((newIndex + KEYS_PER_HAND) < 0) || (newIndex >= Render_CONSTANTS.KEYBOARD_KEYS_TOTAL)
     || (currentInstrument < 0) || (currentInstrument >= instruments.size()) || (instruments.get(currentInstrument) == null)
     || (instruments.get(currentInstrument).getSynthComponent(CustomInstrument_CONSTANTS.KEYBOARD_INDEX) == null))
  {
    return false;
  }
  
  if(DEBUG_INTERFACE_KEYBOARD)
  {
    println("Aligning keyboard with " + (hand ? "right":"left") + " hand at newIndex " + newIndex + " which is a " + (midiNatural[newIndex] ? "natural":"halftone") + " key");
  }
  
  //Grab the keyboard for the upcoming calls to change annotations
  Keyboard k = (Keyboard)instruments.get(currentInstrument).getSynthComponent(CustomInstrument_CONSTANTS.KEYBOARD_INDEX);
  
  //First get the original index to ensure that the old key annotations are cleared
  int prevIndex = (hand == LEFT_HAND) ? left_hand_curIndex : right_hand_curIndex;
  
  for(int i = prevIndex; i < (prevIndex + KEYS_PER_HAND); i++)
  {
    if((i < 0) || (i >= midiNatural.length)) {continue;} //Skip if out-of-bounds
    k.set_annotation(midiNatural[i], midiKeyIndex[i], "");
  }
  
  //Now setup the new annotation and assigned keys based on the given hand
  char[] naturalKeys;
  char[] halftoneKeys;
  
  if(hand == LEFT_HAND)
  {
    left_hand_curIndex = newIndex;
    naturalKeys = NATURAL_KEYS_LEFT;
    halftoneKeys = HALFTONE_KEYS_LEFT;
  }
  else if(hand == RIGHT_HAND)
  {
    right_hand_curIndex = newIndex;
    naturalKeys = NATURAL_KEYS_RIGHT;
    halftoneKeys = HALFTONE_KEYS_RIGHT;
  }
  //This should be dead code, but never hurts to be safe
  else
  {
    return false;
  }
  
  //Assign the updated labels as annotations to the keyboard
  int nextNaturalIndex = 0;
  int nextHalftoneIndex = 0;
  
  for(int i = newIndex; i < (newIndex + KEYS_PER_HAND); i++)
  {
    if((i < 0) || (i >= midiNatural.length)) {continue;} //Skip if out-of-bounds
    if(midiNatural[i] == Keyboard_CONSTANTS.NATURAL_KEY)
    {
      k.set_annotation(midiNatural[i], midiKeyIndex[i], "" + naturalKeys[nextNaturalIndex]);
      nextNaturalIndex++;
    }
    else if(midiNatural[i] == Keyboard_CONSTANTS.HALFTONE_KEY)
    {
      k.set_annotation(midiNatural[i], midiKeyIndex[i], "" + halftoneKeys[nextHalftoneIndex]);
      nextHalftoneIndex++;
    }
    //This should be dead code, but never hurts to be safe
    else
    {
      return false;
    }
  }
  
  //By this point, the change was successful
  return true;
}

//Checks if the character (forced to lower-case) is assigned to play a note on the instrument's keyboard
//NOTE: Instead of returning a boolean, returns the index of the MIDI note associated with the key's current binding (-1 when none)
int playsNote(char c)
{
  //Set the character to lower case since no extra bindings to keys when shift is used to play a note
  c = Character.toLowerCase(c);
  
  //Need to consider all assigned keys; also keep track of the index for when a binding is found
  int checkIndex = right_hand_curIndex;
  while((checkIndex >= 0) && (checkIndex < midiNatural.length) && (midiNatural[checkIndex] == Keyboard_CONSTANTS.HALFTONE_KEY))
  {
    checkIndex++;
  }
  for(int i = 0; i < NATURAL_KEYS_RIGHT.length; i++)
  {
    //Found a match for the character
    if(c == NATURAL_KEYS_RIGHT[i])
    {
      return checkIndex;
    }
    //Advance checkIndex to the next relevant key corresponding to the searched array
    do
    {
      checkIndex++;
    }
    while((checkIndex >= 0) && (checkIndex < midiNatural.length) && (midiNatural[checkIndex] == Keyboard_CONSTANTS.HALFTONE_KEY));
  }
  
  checkIndex = left_hand_curIndex;
  while((checkIndex >= 0) && (checkIndex < midiNatural.length) && (midiNatural[checkIndex] == Keyboard_CONSTANTS.HALFTONE_KEY))
  {
    checkIndex++;
  }
  for(int i = 0; i < NATURAL_KEYS_LEFT.length; i++)
  {
    //Found a match for the character
    if(c == NATURAL_KEYS_LEFT[i])
    {
      return checkIndex;
    }
    //Advance checkIndex to the next relevant key corresponding to the searched array
    do
    {
      checkIndex++;
    }
    while((checkIndex >= 0) && (checkIndex < midiNatural.length) && (midiNatural[checkIndex] == Keyboard_CONSTANTS.HALFTONE_KEY));
  }
  
  checkIndex = right_hand_curIndex;
  while((checkIndex >= 0) && (checkIndex < midiNatural.length) && (midiNatural[checkIndex] == Keyboard_CONSTANTS.NATURAL_KEY))
  {
    checkIndex++;
  }
  for(int i = 0; i < HALFTONE_KEYS_RIGHT.length; i++)
  {
    //Found a match for the character
    if(c == HALFTONE_KEYS_RIGHT[i])
    {
      return checkIndex;
    }
    //Advance checkIndex to the next relevant key corresponding to the searched array
    do
    {
      checkIndex++;
    }
    while((checkIndex >= 0) && (checkIndex < midiNatural.length) && (midiNatural[checkIndex] == Keyboard_CONSTANTS.NATURAL_KEY));
  }
  
  checkIndex = left_hand_curIndex;
  while((checkIndex >= 0) && (checkIndex < midiNatural.length) && (midiNatural[checkIndex] == Keyboard_CONSTANTS.NATURAL_KEY))
  {
    checkIndex++;
  }
  for(int i = 0; i < HALFTONE_KEYS_LEFT.length; i++)
  {
    //Found a match for the character
    if(c == HALFTONE_KEYS_LEFT[i])
    {
      return checkIndex;
    }
    //Advance checkIndex to the next relevant key corresponding to the searched array
    do
    {
      checkIndex++;
    }
    while((checkIndex >= 0) && (checkIndex < midiNatural.length) && (midiNatural[checkIndex] == Keyboard_CONSTANTS.NATURAL_KEY));
  }
  
  //By this point, no matches were found; the key should not be assigned to a note
  return CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
}

//Sets the currentInstrument value to another index, switching out the GUI-displayed instrument
boolean setCurrentInstrument(int index)
{
  //Confirm the index is valid for an instrument first
  if((instruments.size() > index) && (index >= 0))
  {
    if(DEBUG_INTERFACE_KEYBOARD)
    {
      println("Changing current instrument from " + currentInstrument + " to " + index + ": success");
    }
    //Before swapping out the instrument, make sure anything with a pressed key or mouse is resolved (release them)
    if(index != currentInstrument)
    {
      //Stops any current dragging, patch placement, knob changing, etc.
      mouseReleased();
      //Need to handle for each pressed key on the keyboard to release it
      if(guiKeyBindings != null)
      {
        try
        {
          for(Character c : guiKeyBindings.keySet())
          {
            key = c;
            keyReleased();
          }
        }
        //This was encountered while stress-testing; need to hold a lot of keys and change the instrument at the same time... 
        //  hopefully no one tries to do this for real
        catch(java.util.ConcurrentModificationException e)
        {
          println(e + ": Please release music-playing keys before changing instruments");
        }
      }
    }
    currentInstrument = index;
    return true;
  }
  else
  {
    if(DEBUG_INTERFACE_KEYBOARD)
    {
      println("Changing current instrument from " + currentInstrument + " to " + index + ": failed");
    }
    return false;
  }
}

/*---Functions for GUI interfacing (computer mouse and keyboard)---*/

//When the user presses a mouse button, determine whether it relates to some action on the screen
void mousePressed()
{
  if(DEBUG_INTERFACE_MOUSE)
  {
    print("Mouse Pressed:\n");
  }
  
  //Alter processing the mouse press if there is no instrument with which to interact,
  //  such as loading an instrument (for now, just abort since no extra functionality)
  if((currentInstrument < 0) || (currentInstrument >= instruments.size()) || (instruments.get(currentInstrument) == null))
  {
    if(DEBUG_INTERFACE_MOUSE)
    {
      print("\tNo instrument identified...\n");
    }
    return;
  }
  
  //Left click will add a patch, move a patch, or manipulate a knob
  if(mouseButton == LEFT)
  {
    //Identify the component of focus for the current instrument
    SynthComponent focus = instruments.get(currentInstrument).getSynthComponentAt(mouseX, mouseY);
    if(DEBUG_INTERFACE_MOUSE)
    {
      print("\tLeft mouse pressed on component " + focus + "...\n");
    }
    //If there is a target component in the focus, then determine whether a knob or patch was selected
    if(focus != null)
    {
      int topLeftX = instruments.get(currentInstrument).getComponentTopLeftX(focus);
      int topLeftY = instruments.get(currentInstrument).getComponentTopLeftY(focus);
      int[] focusDetails = focus.getElementAt(mouseX - topLeftX, mouseY - topLeftY);
      
      //If any element was found, then we will need the instrument and component indeces
      if(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] != Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_NONE)
      {
        mouseTargetInstrumentIndex = currentInstrument;
        mouseTargetComponentIndex = instruments.get(currentInstrument).findSynthComponentIndex(focus);
      }
      
      //When the focus element is a ComponentChooser object, then special case to add a component
      if(focus instanceof ComponentChooser)
      {
        //Compute the Component ID, which should correlate with the patch indeces
        int componentID = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
        if(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_PATCHIN)
        {
          componentID = focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX];
        }
        else if(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_PATCHOUT)
        {
          componentID = ComponentChooser_CONSTANTS.TOTAL_PATCHIN + focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX];
        }
        //If the ID exists, then add the corresponding component
        if(componentID > CustomInstrument_CONSTANTS.NO_SUCH_INDEX)
        {
          mouseAddComponent(mouseTargetInstrumentIndex, componentID);
        }
        //We will not need the mouseTarget indeces after creating the component
        mouseTargetInstrumentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
        mouseTargetComponentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
      }
      //When the press is on a knob, identify the position of the cursor over the knob's
      //  width to set the value---also store the information for any dragging until mouse release
      else if(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_KNOB)
      {
        mouseTargetKnobIndex = focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX];
        if(DEBUG_INTERFACE_MOUSE)
        {
          print("\t\tKnob " + mouseTargetKnobIndex + " was under the click\n");
        }
        mouseAdjustKnob(mouseTargetInstrumentIndex, mouseTargetComponentIndex, mouseTargetKnobIndex);
      }
      //When the press is on an input patch, either create or readjust the patch cable---
      //  also store the information until mouse release to complete the patch
      else if(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_PATCHIN)
      {
        if(DEBUG_INTERFACE_MOUSE)
        {
          print("\t\tInput patch's cable " + focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX] + " was under the click\n");
        }
        //Null means no cable has been inserted yet to move => create a new patch cable and plug it in
        if(focus.getCableIn(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]) == null)
        {
          //In case the move fails, note the lack of a previous connection so that it may be deleted
          mousePrevComponentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          mousePrevPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          mousePrevPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          //The current focus in patch will serve as a reference to find the patch for adding in later
          mouseTargetPatchInIndex = focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX];
          mouseTargetPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          //The patch cable is included now for the GUI to visualize
          instruments.get(currentInstrument).addPatchCable(new PatchCable(null, CustomInstrument_CONSTANTS.NO_SUCH_INDEX, focus, mouseTargetPatchInIndex));
        }
        //Otherwise, move the pre-existing patch cable (for the move, it is now plugged into null)
        else
        {
          //In case the move fails, store the current patch assignment to be safe
          mousePrevComponentIndex = mouseTargetComponentIndex;
          mousePrevPatchInIndex = focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX];
          mousePrevPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          //The other end of the patch cable associated with this focus will be needed as a reference to find the patch later
          //  Conceptually, this is like adding a new patch cable where the out patch was selected first
          mouseTargetPatchOutIndex = focus.getCableIn(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]).getPatchOutIndex();
          mouseTargetComponentIndex = instruments.get(currentInstrument).findSynthComponentIndex(focus.getCableIn(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]).getPatchOutComponent());
          mouseTargetPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          //Unplug the selected patch cable for now so that it follows the mouse in the GUI
          instruments.get(currentInstrument).unsetPatchIn(mousePrevComponentIndex, mousePrevPatchInIndex);
        }
      }
      //When the press is on an output patch, either create or readjust the patch cable---
      //  also store the information until mouse release to complete the patch
      else if(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_PATCHOUT)
      {
        if(DEBUG_INTERFACE_MOUSE)
        {
          print("\t\tOutput patch's cable " + focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX] + " was under the click\n");
        }
        //Null means no cable has been inserted yet to move => create a new patch cable and plug it in
        if(focus.getCableOut(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]) == null)
        {
          //In case the move fails, note the lack of a previous connection so that it may be deleted
          mousePrevComponentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          mousePrevPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          mousePrevPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          //The current focus in patch will serve as a reference to find the patch for adding in later
          mouseTargetPatchOutIndex = focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX];
          mouseTargetPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          //The patch cable is included now for the GUI to visualize
          instruments.get(currentInstrument).addPatchCable(new PatchCable(focus, mouseTargetPatchOutIndex, null, CustomInstrument_CONSTANTS.NO_SUCH_INDEX));
        }
        //Otherwise, move the pre-existing patch cable (for the move, it is now plugged into null)
        else
        {
          //In case the move fails, store the current patch assignment to be safe
          mousePrevComponentIndex = mouseTargetComponentIndex;
          mousePrevPatchOutIndex = focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX];
          mousePrevPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          //The other end of the patch cable associated with this focus will be needed as a reference to find the patch later
          //  Conceptually, this is like adding a new patch cable where the in patch was selected first
          mouseTargetPatchInIndex = focus.getCableOut(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]).getPatchInIndex();
          mouseTargetComponentIndex = instruments.get(currentInstrument).findSynthComponentIndex(focus.getCableOut(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]).getPatchInComponent());
          mouseTargetPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          //Unplug the selected patch cable for now so that it follows the mouse in the GUI
          instruments.get(currentInstrument).unsetPatchOut(mousePrevComponentIndex, mousePrevPatchOutIndex);
        }
      }
      else
      {
        if(DEBUG_INTERFACE_MOUSE)
        {
          print("\t\tNo element in the component was under the click\n");
        }
      }
    }
    //When no component is in the focus, then some extra functionality might exist in the
    //  future, but nothing for now
    else
    {
    }
  }
  //Right click will delete a patch, but only when clicked (press and release) 
}

//When the user drags a pressed mouse button, continue some pressed action on the screen
void mouseDragged()
{
  if(DEBUG_INTERFACE_MOUSE)
  {
    print("Mouse Dragged:\n");
  }
  
  //Alter processing the mouse press if there is no instrument with which to interact,
  //  such as loading an instrument (for now, just abort since no extra functionality)
  if((currentInstrument < 0) || (currentInstrument >= instruments.size()) || (instruments.get(currentInstrument) == null))
  {
    if(DEBUG_INTERFACE_MOUSE)
    {
      print("\tNo instrument identified...\n");
    }
    return;
  }
  
  //Left click will manipulate a knob, but patches remain unchanged (they follow the mouse when not plugged in by default)
  if(mouseButton == LEFT)
  {
    //Continue to adjust the knob at the new mouse position
    if(mouseTargetKnobIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX)
    {
      if(DEBUG_INTERFACE_MOUSE)
      {
        print("\tLeft mouse is dragging knob " + mouseTargetKnobIndex + "...\n");
      }
      mouseAdjustKnob(mouseTargetInstrumentIndex, mouseTargetComponentIndex, mouseTargetKnobIndex);
    }
  }
}

//When the user releases a pressed mouse button, stop some pressed action on the screen
void mouseReleased()
{
  if(DEBUG_INTERFACE_MOUSE)
  {
    print("Mouse Released:\n");
  }
  
  //Alter processing the mouse press if there is no instrument with which to interact,
  //  such as loading an instrument (for now, just abort since no extra functionality)
  if((currentInstrument < 0) || (currentInstrument >= instruments.size()) || (instruments.get(currentInstrument) == null))
  {
    if(DEBUG_INTERFACE_MOUSE)
    {
      print("\tNo instrument identified...\n");
    }
    return;
  }
  
  //Left click will complete a patch placement or stop manipulating a knob
  if(mouseButton == LEFT)
  {
    //Simply set the target knob to null to stop manipulating that knob
    mouseTargetKnobIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
    
    //If there is a selected patch cable, then finish inserting the cable first (if applicable)
    if((mouseTargetPatchInIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX) || (mouseTargetPatchOutIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX))
    {
      //Identify the component of focus for the current instrument
      SynthComponent focus = instruments.get(currentInstrument).getSynthComponentAt(mouseX, mouseY);
      if(DEBUG_INTERFACE_MOUSE)
      {
        print("\tLeft mouse released on component " + focus + "...\n");
      }
      
      int[] focusDetails = null;
      //If there is a target component in the focus, then determine whether a knob or patch was selected
      if(focus != null)
      {
        int topLeftX = instruments.get(currentInstrument).getComponentTopLeftX(focus);
        int topLeftY = instruments.get(currentInstrument).getComponentTopLeftY(focus);
        focusDetails = focus.getElementAt(mouseX - topLeftX, mouseY - topLeftY);
      }
      
      //The patch will complete based on the direction (in or out)---need the opposite direction on the mouse release
      if(mouseTargetPatchOutIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX)
      {
        //Although this will sound silly, the changes so far are for visualization in the GUI;
        //  those changes have to be redone in the actual newPatch or movePatchX calls => undo the changes first
        //NOTE: If the patch completion fails, then this undo would happen anyways without the remaining steps to redo the changes
        
        //Get the patch cable from the patch out index, which will be needed
        PatchCable pc = instruments.get(currentInstrument).getSynthComponent(mouseTargetComponentIndex).getCableOut(mouseTargetPatchOutIndex);
        
        //Use the previous target information to undo the partially-changed patch
        if((mousePrevPatchInIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX) && (mousePrevComponentIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX))
        {
          instruments.get(currentInstrument).setPatchIn(mousePrevComponentIndex, mousePrevPatchInIndex, pc);
        }
        //This means removing it if no previous patch information
        else
        {
          instruments.get(currentInstrument).unsetPatchOut(mouseTargetComponentIndex, mouseTargetPatchOutIndex);
          instruments.get(currentInstrument).removePatchCable(pc);
        }
        
        //Mouse release needs to match the known patch-out with an unused patch-in; revert when not the case 
        if((focusDetails == null) || (focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] != Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_PATCHIN) || ((focus != null) && (focus.getCableIn(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]) != null)))
        {
          if(DEBUG_INTERFACE_MOUSE)
          {
            if(focusDetails == null)
            {
              print("\t\tCannot complete patch from patch out " + mouseTargetPatchOutIndex + " of " + instruments.get(currentInstrument).getSynthComponent(mouseTargetComponentIndex) + " because no focus information was found\n");
            }
            else if(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] != Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_PATCHIN)
            {
              print("\t\tCannot complete patch from patch out " + mouseTargetPatchOutIndex + " of " + instruments.get(currentInstrument).getSynthComponent(mouseTargetComponentIndex) + " because mouse released on something that is not a patch in\n");
            }
            else if((focus != null) && (focus.getCableIn(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]) != null))
            {
              print("\t\tCannot complete patch from patch out " + mouseTargetPatchOutIndex + " of " + instruments.get(currentInstrument).getSynthComponent(mouseTargetComponentIndex) + " because mouse released on a patch in that is already in use\n");
            }
          }
          //Nothing else to do here because the undone process was already performed above this conditional statement
        }
        else
        {
          if(DEBUG_INTERFACE_MOUSE)
          {
            print("\t\tCompleting patch from patch out " + mouseTargetPatchOutIndex + " of " + instruments.get(currentInstrument).getSynthComponent(mouseTargetComponentIndex) + " to patch in " + focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX] + " of " + focus + "\n");
          }
          //If there is previous target information, then the action is moving the selected patch
          if((mousePrevPatchInIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX) && (mousePrevComponentIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX))
          {
            mouseMovePatchIn(mouseTargetInstrumentIndex, mousePrevComponentIndex, mousePrevPatchInIndex, instruments.get(currentInstrument).findSynthComponentIndex(focus), focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]);
          }
          //If there is no previous target information, then the action is adding a new patch cable from the press to release foci
          else
          {
            mouseNewPatch(mouseTargetInstrumentIndex, mouseTargetComponentIndex, mouseTargetPatchOutIndex, instruments.get(currentInstrument).findSynthComponentIndex(focus), focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]);
          }
        }
      }
      else if(mouseTargetPatchInIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX)
      {
        //Although this will sound silly, the changes so far are for visualization in the GUI;
        //  those changes have to be redone in the actual newPatch or movePatchX calls => undo the changes first
        
        //Get the patch cable from the patch out index, which will be needed
        PatchCable pc = instruments.get(currentInstrument).getSynthComponent(mouseTargetComponentIndex).getCableIn(mouseTargetPatchInIndex);
        
        //NOTE: If the patch completion fails, then this undo would happen anyways without the remaining steps to redo the changes
        //Use the previous target information to undo the partially-changed patch
        if((mousePrevPatchOutIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX) && (mousePrevComponentIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX))
        {
          instruments.get(currentInstrument).setPatchOut(mousePrevComponentIndex, mousePrevPatchOutIndex, pc);
        }
        //This means removing it if no previous patch information
        else
        {
          instruments.get(currentInstrument).unsetPatchIn(mouseTargetComponentIndex, mouseTargetPatchInIndex);
          instruments.get(currentInstrument).removePatchCable(pc);
        }
          
        //Mouse release needs to match the known patch-in with an unused patch-out; revert when not the case
        if((focusDetails == null) || (focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] != Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_PATCHOUT) || ((focus != null) && (focus.getCableOut(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]) != null)))
        {
          if(DEBUG_INTERFACE_MOUSE)
          {
            if(focusDetails == null)
            {
              print("\t\tCannot complete patch from patch in " + mouseTargetPatchInIndex + " of " + instruments.get(currentInstrument).getSynthComponent(mouseTargetComponentIndex) + " because no focus information was found\n");
            }
            else if(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] != Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_PATCHOUT)
            {
              print("\t\tCannot complete patch from patch in " + mouseTargetPatchInIndex + " of " + instruments.get(currentInstrument).getSynthComponent(mouseTargetComponentIndex) + " because mouse released on something that is not a patch out\n");
            }
            else if((focus != null) && (focus.getCableOut(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]) != null))
            {
              print("\t\tCannot complete patch from patch in " + mouseTargetPatchInIndex + " of " + instruments.get(currentInstrument).getSynthComponent(mouseTargetComponentIndex) + " because mouse released on a patch out that is already in use\n");
            }
          }
          //Nothing else to do here because the undone process was already performed above this conditional statement
        }
        else
        {
          if(DEBUG_INTERFACE_MOUSE)
          {
            print("\t\tCompleting patch from patch in " + mouseTargetPatchInIndex + " of " + instruments.get(currentInstrument).getSynthComponent(mouseTargetComponentIndex) + " to patch out " + focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX] + " of " + focus + "\n");
          }
          //If there is previous target information, then the action is moving the selected patch
          if((mousePrevPatchOutIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX) && (mousePrevComponentIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX))
          {
            mouseMovePatchOut(mouseTargetInstrumentIndex, mousePrevComponentIndex, mousePrevPatchOutIndex, instruments.get(currentInstrument).findSynthComponentIndex(focus), focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]);
          }
          //If there is no previous target information, then the action is adding a new patch cable from the press to release foci
          else
          {
            mouseNewPatch(mouseTargetInstrumentIndex, instruments.get(currentInstrument).findSynthComponentIndex(focus), focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX], mouseTargetComponentIndex, mouseTargetPatchInIndex);
          }
        }
      }
    }
    //Simply set the target patches (all of them) to null to stop manipulating the patches
    mouseTargetPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
    mouseTargetPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
    mousePrevPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
    mousePrevPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
    mousePrevComponentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
    
    //Lastly, remove the focus on the instrument and component as well
    mouseTargetInstrumentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
    mouseTargetComponentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
  }
}

//When the user clicks a mouse button (press and release), determine whether it relates to some action on the screen
void mouseClicked()
{
  if(DEBUG_INTERFACE_MOUSE)
  {
    print("Mouse Clicked:\n");
  }
  
  //Alter processing the mouse press if there is no instrument with which to interact,
  //  such as loading an instrument (for now, just abort since no extra functionality)
  if((currentInstrument < 0) || (currentInstrument >= instruments.size()) || (instruments.get(currentInstrument) == null))
  {
    if(DEBUG_INTERFACE_MOUSE)
    {
      print("\tNo instrument identified...\n");
    }
    return;
  }
  
  //Right click will delete something if removable
  if(mouseButton == RIGHT)
  {
    //Identify the component of focus for the current instrument
    SynthComponent focus = instruments.get(currentInstrument).getSynthComponentAt(mouseX, mouseY);
    if(DEBUG_INTERFACE_MOUSE)
    {
      print("\tRight mouse pressed on component " + focus + "...\n");
    }
    //If there is a target component in the focus, then determine whether a knob or patch was selected
    if(focus != null)
    {
      int topLeftX = instruments.get(currentInstrument).getComponentTopLeftX(focus);
      int topLeftY = instruments.get(currentInstrument).getComponentTopLeftY(focus);
      int[] focusDetails = focus.getElementAt(mouseX - topLeftX, mouseY - topLeftY);
      
      //If any element was found, then we will need the instrument and component indeces
      if(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] != Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_NONE)
      {
        mouseTargetInstrumentIndex = currentInstrument;
        mouseTargetComponentIndex = instruments.get(currentInstrument).findSynthComponentIndex(focus);
      }
      
      //When the reove button is identified, then remove the associated component from the instrument
      if(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_REMOVE)
      {
        mouseRemoveComponent(mouseTargetInstrumentIndex, mouseTargetComponentIndex);
      }
      //When a patch is identified with an existing cable, then remove it from the instrument
      else if(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_PATCHIN)
      {
        if(DEBUG_INTERFACE_MOUSE)
        {
          print("\t\tInput patch's cable " + focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX] + " was under the click\n");
        }
        //Null means no cable has been inserted yet => nothing to remove
        if(focus.getCableIn(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]) == null)
        {
        }
        //Otherwise, remove the patch cable
        else
        {
          mouseRemovePatchIn(mouseTargetInstrumentIndex, mouseTargetComponentIndex, focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]);
        }
      }
      else if(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_PATCHOUT)
      {
        if(DEBUG_INTERFACE_MOUSE)
        {
          print("\t\tOutput patch's cable " + focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX] + " was under the click\n");
        }
        //Null means no cable has been inserted yet => nothing to remove
        if(focus.getCableOut(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]) == null)
        {
        }
        //Otherwise, remove the patch cable
        else
        {
          mouseRemovePatchOut(mouseTargetInstrumentIndex, mouseTargetComponentIndex, focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]);
        }
      }
      //Since the removal of components and patches is a one-and-done operation, release the focus indeces
      mouseTargetInstrumentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
      mouseTargetComponentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
    }
    //When no component is in the focus, then some extra functionality might exist in the
    //  future, but nothing for now
    else
    {
    }
  }
}

//When the user presses a key, determine whether it relates to some action on the screen
void keyPressed()
{
  if(DEBUG_INTERFACE_KEYBOARD)
  {
    print("Key Pressed (" + key + "):\n");
  }
  
  //Alter processing the mouse press if there is no instrument with which to interact,
  //  such as loading an instrument (for now, just abort since no extra functionality)
  if((currentInstrument < 0) || (currentInstrument >= instruments.size()) || (instruments.get(currentInstrument) == null))
  {
    if(DEBUG_INTERFACE_KEYBOARD)
    {
      print("\tNo instrument identified...\n");
    }
    return;
  }
  
  //If the key is assigned to play a musical note (most lower/upper case and some punctuation), then start the assigned note
  int midiIndex = playsNote(key);
  if(DEBUG_INTERFACE_KEYBOARD)
  {
    print("\tKey " + key + " is bound to midiIndex " + midiIndex + "\n");
  }
  if((midiIndex >= 0) && (midiIndex < midiFreq.length))
  {
    char lowerCaseKey = Character.toLowerCase(key);
    //Bind this midi number to the key in case the keys change later
    guiKeyBindings.put(lowerCaseKey, midiIndex);
    commandStartNote(currentInstrument, midiNum[midiIndex], lowerCaseKey);
  }
}

//When the user releases a key, determine whether it relates to some action on the screen
void keyReleased()
{
  if(DEBUG_INTERFACE_KEYBOARD)
  {
    print("Key Released (" + key + "):\n");
  }
  
  //Alter processing the mouse press if there is no instrument with which to interact,
  //  such as loading an instrument (for now, just abort since no extra functionality)
  if((currentInstrument < 0) || (currentInstrument >= instruments.size()) || (instruments.get(currentInstrument) == null))
  {
    if(DEBUG_INTERFACE_KEYBOARD)
    {
      print("\tNo instrument identified...\n");
    }
    return;
  }
  
  //If the key is assigned to play a musical note (most lower/upper case and some punctuation), then start the assigned note
  int midiIndex = playsNote(key);
  if(DEBUG_INTERFACE_KEYBOARD)
  {
    print("\tKey " + key + " is bound to midiIndex " + midiIndex + "\n");
  }
  if((midiIndex >= 0) && (midiIndex < midiFreq.length))
  {
    char lowerCaseKey = Character.toLowerCase(key);
    //Make sure the binding still exists before stopping a false note
    if(guiKeyBindings.containsKey(key))
    {
      commandStopNote(currentInstrument, midiNum[guiKeyBindings.get(lowerCaseKey)], lowerCaseKey);
    }
    //If no binding anymore, then at least try to stop the key in case something is playing...
    //  use a fake frequency value since the binding is to the character value only
    else
    {
      commandStopNote(currentInstrument, 0.0, lowerCaseKey);
    }
    //Unbind this midi number from the key in case the keys change later
    guiKeyBindings.remove(lowerCaseKey);
  }
}

//When the user types (presses and releases) a key, determine whether it relates to some action on the screen
void keyTyped()
{
  if(DEBUG_INTERFACE_KEYBOARD)
  {
    print("Key Typed (" + key + "):\n");
  }
  
  //Alter processing the mouse press if there is no instrument with which to interact,
  //  such as loading an instrument (for now, just abort since no extra functionality)
  if((currentInstrument < 0) || (currentInstrument >= instruments.size()) || (instruments.get(currentInstrument) == null))
  {
    if(DEBUG_INTERFACE_KEYBOARD)
    {
      print("\tNo instrument identified...\n");
    }
    return;
  }
  
  //If the key is assigned to shift the hand (remaining lower/upper case), then realign the labels and key bindings as appropriate
  if(key == 'g') //Shift left hand left one natural key
  {
    if(DEBUG_INTERFACE_KEYBOARD)
    {
      print("\tg shifts left hand to the left one natural key...\n");
    }
    if((left_hand_curIndex > 0) && ((left_hand_curIndex - 1) < midiNatural.length) && (midiNatural[left_hand_curIndex - 1] == Keyboard_CONSTANTS.NATURAL_KEY))
    {
      realignKeyboard(LEFT_HAND, left_hand_curIndex - 1);
    }
    else if((left_hand_curIndex > 1) && ((left_hand_curIndex - 2) < midiNatural.length) && (midiNatural[left_hand_curIndex - 2] == Keyboard_CONSTANTS.NATURAL_KEY))
    {
      realignKeyboard(LEFT_HAND, left_hand_curIndex - 2);
    }
    //No need for an else case because this cannot shift left any further
    else
    {
      if(DEBUG_INTERFACE_KEYBOARD)
      {
        print("\t\tFailed with left_hand_curIndex " + left_hand_curIndex + "...\n");
      }
    }
  }
  else if(key == 'G') //Shift left hand left four natural keys
  {
    if(DEBUG_INTERFACE_KEYBOARD)
    {
      print("\tG shifts left hand to the left four natural keys...\n");
    }
    if((left_hand_curIndex > 5) && ((left_hand_curIndex - 6) < midiNatural.length) && (midiNatural[left_hand_curIndex - 6] == Keyboard_CONSTANTS.NATURAL_KEY))
    {
      realignKeyboard(LEFT_HAND, left_hand_curIndex - 6);
    }
    else if((left_hand_curIndex > 6) && ((left_hand_curIndex - 7) < midiNatural.length) && (midiNatural[left_hand_curIndex - 7] == Keyboard_CONSTANTS.NATURAL_KEY))
    {
      realignKeyboard(LEFT_HAND, left_hand_curIndex - 7);
    }
    //No need for an else case because this cannot shift left any further
    else
    {
      if(DEBUG_INTERFACE_KEYBOARD)
      {
        print("\t\tFailed with left_hand_curIndex " + left_hand_curIndex + "...\n");
      }
    }
  }
  else if(key == 'b') //Shift left hand right one natural key
  {
    if(DEBUG_INTERFACE_KEYBOARD)
    {
      print("\tb shifts left hand to the right one natural key...\n");
    }
    if(((left_hand_curIndex + KEYS_PER_HAND) <= (midiNatural.length - 1)) && ((left_hand_curIndex + 1) >= 0) && (midiNatural[left_hand_curIndex + 1] == Keyboard_CONSTANTS.NATURAL_KEY))
    {
      realignKeyboard(LEFT_HAND, left_hand_curIndex + 1);
    }
    else if(((left_hand_curIndex + KEYS_PER_HAND) <= (midiNatural.length - 2)) && ((left_hand_curIndex + 2) >= 0) && (midiNatural[left_hand_curIndex + 2] == Keyboard_CONSTANTS.NATURAL_KEY))
    {
      realignKeyboard(LEFT_HAND, left_hand_curIndex + 2);
    }
    //No need for an else case because this cannot shift right any further
    else
    {
      if(DEBUG_INTERFACE_KEYBOARD)
      {
        print("\t\tFailed with left_hand_curIndex " + left_hand_curIndex + "...\n");
      }
    }
  }
  else if(key == 'B') //Shift left hand right four natural keys
  {
    if(DEBUG_INTERFACE_KEYBOARD)
    {
      print("\tg shifts left hand to the right four natural keys...\n");
    }
    if(((left_hand_curIndex + KEYS_PER_HAND) < (midiNatural.length - 6)) && ((left_hand_curIndex + 6) >= 0) && (midiNatural[left_hand_curIndex + 6] == Keyboard_CONSTANTS.NATURAL_KEY))
    {
      realignKeyboard(LEFT_HAND, left_hand_curIndex + 6);
    }
    else if(((left_hand_curIndex + KEYS_PER_HAND) < (midiNatural.length - 7)) && ((left_hand_curIndex + 7) >= 0) && (midiNatural[left_hand_curIndex + 7] == Keyboard_CONSTANTS.NATURAL_KEY))
    {
      realignKeyboard(LEFT_HAND, left_hand_curIndex + 7);
    }
    //No need for an else case because this cannot shift right any further
    else
    {
      if(DEBUG_INTERFACE_KEYBOARD)
      {
        print("\t\tFailed with left_hand_curIndex " + left_hand_curIndex + "...\n");
      }
    }
  }
  else if(key == 'h') //Shift right hand left one natural key
  {
    if(DEBUG_INTERFACE_KEYBOARD)
    {
      print("\th shifts right hand to the left one natural key...\n");
    }
    if((right_hand_curIndex > 0) && ((right_hand_curIndex - 1) < midiNatural.length) && (midiNatural[right_hand_curIndex - 1] == Keyboard_CONSTANTS.NATURAL_KEY))
    {
      realignKeyboard(RIGHT_HAND, right_hand_curIndex - 1);
    }
    else if((right_hand_curIndex > 1) && ((right_hand_curIndex - 2) < midiNatural.length) && (midiNatural[right_hand_curIndex - 2] == Keyboard_CONSTANTS.NATURAL_KEY))
    {
      realignKeyboard(RIGHT_HAND, right_hand_curIndex - 2);
    }
    //No need for an else case because this cannot shift left any further
    else
    {
      if(DEBUG_INTERFACE_KEYBOARD)
      {
        print("\t\tFailed with right_hand_curIndex " + right_hand_curIndex + "...\n");
      }
    }
  }
  else if(key == 'H') //Shift right hand left four natural keys
  {
    if(DEBUG_INTERFACE_KEYBOARD)
    {
      print("\tH shifts right hand to the left four natural keys...\n");
    }
    if((right_hand_curIndex > 5) && ((right_hand_curIndex - 6) < midiNatural.length) && (midiNatural[right_hand_curIndex - 6] == Keyboard_CONSTANTS.NATURAL_KEY))
    {
      realignKeyboard(RIGHT_HAND, right_hand_curIndex - 6);
    }
    else if((right_hand_curIndex > 6) && ((right_hand_curIndex - 7) < midiNatural.length) && (midiNatural[right_hand_curIndex - 7] == Keyboard_CONSTANTS.NATURAL_KEY))
    {
      realignKeyboard(RIGHT_HAND, right_hand_curIndex - 7);
    }
    //No need for an else case because this cannot shift left any further
    else
    {
      if(DEBUG_INTERFACE_KEYBOARD)
      {
        print("\t\tFailed with right_hand_curIndex " + right_hand_curIndex + "...\n");
      }
    }
  }
  else if(key == 'n') //Shift right hand right one natural key
  {
    if(DEBUG_INTERFACE_KEYBOARD)
    {
      print("\tn shifts right hand to the right one natural key...\n");
    }
    if(((right_hand_curIndex + KEYS_PER_HAND) <= (midiNatural.length - 1)) && ((right_hand_curIndex + 1) >= 0) && (midiNatural[right_hand_curIndex + 1] == Keyboard_CONSTANTS.NATURAL_KEY))
    {
      realignKeyboard(RIGHT_HAND, right_hand_curIndex + 1);
    }
    else if(((right_hand_curIndex + KEYS_PER_HAND) <= (midiNatural.length - 2)) && ((right_hand_curIndex + 2) >= 0) && (midiNatural[right_hand_curIndex + 2] == Keyboard_CONSTANTS.NATURAL_KEY))
    {
      realignKeyboard(RIGHT_HAND, right_hand_curIndex + 2);
    }
    //No need for an else case because this cannot shift right any further
    else
    {
      if(DEBUG_INTERFACE_KEYBOARD)
      {
        print("\t\tFailed with right_hand_curIndex " + right_hand_curIndex + "...\n");
      }
    }
  }
  else if(key == 'N') //Shift right hand right four natural keys
  {
    if(DEBUG_INTERFACE_KEYBOARD)
    {
      print("\tN shifts right hand to the right four natural keys...\n");
    }
    if(((right_hand_curIndex + KEYS_PER_HAND) <= (midiNatural.length - 6)) && ((right_hand_curIndex + 6) >= 0) && (midiNatural[right_hand_curIndex + 6] == Keyboard_CONSTANTS.NATURAL_KEY))
    {
      realignKeyboard(RIGHT_HAND, right_hand_curIndex + 6);
    }
    else if(((right_hand_curIndex + KEYS_PER_HAND) <= (midiNatural.length - 7)) && ((right_hand_curIndex + 7) >= 0) && (midiNatural[right_hand_curIndex + 7] == Keyboard_CONSTANTS.NATURAL_KEY))
    {
      realignKeyboard(RIGHT_HAND, right_hand_curIndex + 7);
    }
    //No need for an else case because this cannot shift right any further
    else
    {
      if(DEBUG_INTERFACE_KEYBOARD)
      {
        print("\t\tFailed with right_hand_curIndex " + right_hand_curIndex + "...\n");
      }
    }
  }
  
  //If the key is assigned to change the current instrument, then set the index appropriately (and check that index works first)
  else if(key == '`')
  {
    setCurrentInstrument(0);
  }
  else if((key >= '1') && (key <= '9'))
  {
    //Want '1'->1, '2'->2, ..., '9'->9, and '0' is the first ASCII digit
    setCurrentInstrument(key - '0');
  }
  else if(key == '0')
  {
    //Yet the first ASCII digit is right-most on a QWERTY keyboard...
    setCurrentInstrument(10);
  }
  else if(key == '-')
  {
    setCurrentInstrument(11);
  }
  else if(key == '=')
  {
    setCurrentInstrument(12);
  }
  else if(key == '[')
  {
    setCurrentInstrument(13);
  }
  else if(key == ']')
  {
    setCurrentInstrument(14);
  }
  else if(key == '\\') //Escape character is escaped, not actually double-'\'
  {
    setCurrentInstrument(15);
  }
}

/*---Functions for operating the interface elements with the mouse and/or keyboard---*/

//Identify the mouse's horizontal position relative to the knob to set its position
void mouseAdjustKnob(int instrumentIndex, int componentIndex, int knobIndex)
{
  //Make sure the indeces all exist and are not null before beginning
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentIndex).getKnob(knobIndex) == null))
  {
    return;
  }
  
  Knob k = instruments.get(instrumentIndex).getSynthComponent(componentIndex).getKnob(knobIndex);
  int kTopLeftX = k.getTopLeftX();
  int kWidth = k.getWidth();
  //If too far to the left, then set the position to 0 (farthest left)
  if(mouseX < kTopLeftX)
  {
    instruments.get(instrumentIndex).setKnob(componentIndex, knobIndex, 0.0);
  }
  //If too far to the right, then set the position to 1 (farthest right)
  else if(mouseX > (kTopLeftX + kWidth))
  {
    instruments.get(instrumentIndex).setKnob(componentIndex, knobIndex, 1.0);
  }
  //When in the middle, interpolate position
  else
  {
    instruments.get(instrumentIndex).setKnob(componentIndex, knobIndex, (float)(mouseX - kTopLeftX) / (float)kWidth);
  }
}

//Create a new patch and plug it into the instrument
void mouseNewPatch(int instrumentIndex, int componentOutIndex, int patchOutIndex, int componentInIndex, int patchInIndex)
{
  //Make sure the indeces all exist and are not null before beginning
  //NOTE: The getPatchX is the UGen (should not be null), and getCableX is the PatchCable (should be null) 
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentOutIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentOutIndex).getPatchOut(patchOutIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentOutIndex).getCableOut(patchOutIndex) != null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentInIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentInIndex).getPatchIn(patchInIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentInIndex).getCableIn(patchInIndex) != null))
  {
    return;
  }
  
  //Simply add the specified patch cable, generating a new object to pass in
  instruments.get(instrumentIndex).addPatchCable(new PatchCable(instruments.get(instrumentIndex).getSynthComponent(componentOutIndex), patchOutIndex, instruments.get(instrumentIndex).getSynthComponent(componentInIndex), patchInIndex));
}

//Take an existing patch and replug its output patch elsewhere in the instrument
void mouseMovePatchOut(int instrumentIndex, int componentFromOutIndex, int patchFromOutIndex, int componentToOutIndex, int patchToOutIndex)
{
  //Make sure the indeces all exist and are not null before beginning
  //NOTE: The getPatchOut is the UGen (should not be null), and getCableOut is the PatchCable (should be null in To, not null in From) 
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentFromOutIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentFromOutIndex).getPatchOut(patchFromOutIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentFromOutIndex).getCableOut(patchFromOutIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentToOutIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentToOutIndex).getPatchOut(patchToOutIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentToOutIndex).getCableOut(patchToOutIndex) != null))
  {
    return;
  }
  
  //Simply set the specified output patch cable, using the cable specified in From
  instruments.get(instrumentIndex).setPatchOut(componentToOutIndex, patchToOutIndex, instruments.get(instrumentIndex).getSynthComponent(componentFromOutIndex).getCableOut(patchFromOutIndex));
}

//Take an existing patch and replug its input patch elsewhere in the instrument
void mouseMovePatchIn(int instrumentIndex, int componentFromInIndex, int patchFromInIndex, int componentToInIndex, int patchToInIndex)
{
  //Make sure the indeces all exist and are not null before beginning
  //NOTE: The getPatchIn is the UGen (should not be null), and getCableIn is the PatchCable (should be null in To, not null in From) 
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentFromInIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentFromInIndex).getPatchIn(patchFromInIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentFromInIndex).getCableIn(patchFromInIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentToInIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentToInIndex).getPatchIn(patchToInIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentToInIndex).getCableIn(patchToInIndex) != null))
  {
    return;
  }
  
  //Simply set the specified output patch cable, using the cable specified in From
  instruments.get(instrumentIndex).setPatchIn(componentToInIndex, patchToInIndex, instruments.get(instrumentIndex).getSynthComponent(componentFromInIndex).getCableIn(patchFromInIndex));
}

//Take an existing patch and remove it from the instrument
void mouseRemovePatchOut(int instrumentIndex, int componentIndex, int patchOutIndex)
{
  //Make sure the indeces all exist and are not null before beginning
  //NOTE: The getPatchOut is the UGen (should not be null), and getCableOut is the PatchCable (should not be null) 
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentIndex).getPatchOut(patchOutIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentIndex).getCableOut(patchOutIndex) == null))
  {
    return;
  }
  
  //Simply remove the patch cable with specified output
  instruments.get(instrumentIndex).removePatchCable(instruments.get(instrumentIndex).getSynthComponent(componentIndex).getCableOut(patchOutIndex));
}

//Take an existing patch and remove it from the instrument
void mouseRemovePatchIn(int instrumentIndex, int componentIndex, int patchInIndex)
{
  //Make sure the indeces all exist and are not null before beginning
  //NOTE: The getPatchIn is the UGen (should not be null), and getCableIn is the PatchCable (should not be null) 
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentIndex).getPatchIn(patchInIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentIndex).getCableIn(patchInIndex) == null))
  {
    return;
  }
  
  //Simply remove the patch cable with specified input
  instruments.get(instrumentIndex).removePatchCable(instruments.get(instrumentIndex).getSynthComponent(componentIndex).getCableIn(patchInIndex));
}

//Adds a component to the instrument
void mouseAddComponent(int instrumentIndex, int componentID)
{
  //Make sure the indeces all exist and are not null before beginning
  //NOTE: The getPatchIn is the UGen (should not be null), and getCableIn is the PatchCable (should not be null) 
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null))
  {
    return;
  }
  
  //Simply add the specified component
  instruments.get(instrumentIndex).addSynthComponent(componentID);
}

//Removes a component from the instrument
void mouseRemoveComponent(int instrumentIndex, int componentIndex)
{
  //Make sure the indeces all exist and are not null before beginning
  //NOTE: The getPatchIn is the UGen (should not be null), and getCableIn is the PatchCable (should not be null) 
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (instruments.get(instrumentIndex).getSynthComponent(componentIndex) == null))
  {
    return;
  }
  
  //Simply remove the specified component
  instruments.get(instrumentIndex).removeSynthComponent(componentIndex);
}

//Starts playing a note from the instrument (can be a key or a frequency assigned to the binding)
void commandStartNote(int instrumentIndex, int midiValue, char binding)
{
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (midiValue < midiNum[0]) || (midiValue > midiNum[midiNum.length - 1]))
  {
    return;
  }
  commandStartNote(instrumentIndex, midiFreq[midiValue - midiNum[0]], binding);
}
void commandStartNote(int instrumentIndex, float frequency, char binding)
{
  //Make sure the indeces all exist and are not null before beginning
  //NOTE: The getPatchIn is the UGen (should not be null), and getCableIn is the PatchCable (should not be null) 
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (frequency < 0) || (frequency > 6000))
  {
    return;
  }
  
  //Simply start the note with the bound char value
  int assigned = ((Keyboard)instruments.get(instrumentIndex).getSynthComponent(CustomInstrument_CONSTANTS.KEYBOARD_INDEX)).set_key(binding, frequency);
  if(DEBUG_INTERFACE_KEYBOARD)
  {
    println("Tried to play frequency " + frequency + " with key binding " + binding + " -> result: " + assigned);
  }
}

//Stops playing a note from the instrument (can be a key or a frequency assigned to the binding)
void commandStopNote(int instrumentIndex, int midiValue, char binding)
{
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (midiValue < midiNum[0]) || (midiValue > midiNum[midiNum.length - 1]))
  {
    return;
  }
  commandStopNote(instrumentIndex, midiFreq[midiValue - midiNum[0]], binding);
}
void commandStopNote(int instrumentIndex, float frequency, char binding)
{
  //Make sure the indeces all exist and are not null before beginning
  //NOTE: The getPatchIn is the UGen (should not be null), and getCableIn is the PatchCable (should not be null) 
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (frequency < 0) || (frequency > 6000))
  {
    return;
  }
  
  //Simply start the note with the bound char value
  boolean unassigned = ((Keyboard)instruments.get(instrumentIndex).getSynthComponent(CustomInstrument_CONSTANTS.KEYBOARD_INDEX)).unset_key(binding);
  if(DEBUG_INTERFACE_KEYBOARD)
  {
    println("Tried to halt frequency " + frequency + " with key binding " + binding + " -> result: " + unassigned);
  }
}

//Due to closing with the global Summer's patch still active, we force the unpatch before quitting the application
//Thank you to https://forum.processing.org/one/topic/run-code-on-exit.html ,
//  where the solution for how to activate code when exiting the application was found
private void prepareExitHandler()
{
  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable()
  {
    public void run()
    {
      if(DEBUG_SYSTEM)
      {
        System.out.println("SHUTDOWN HOOK");
      }
      // application exit code here
      allInstruments_toOut.unpatch(out); //Perform the unpatch here
    }
  })); //Matches parentheses from addShutdownHook
}

/*----DEBUGGING TESTS AND DEBUGGER CONTENT BELOW-----*/

//The specialized instrument for debugging use
CustomInstrument debugCustomInstrument;

//Used to setup a custom instrument with preloaded features, intended to make debugging quick
private void setupDebugInstrument()
{
  debugCustomInstrument = new CustomInstrument();
  debugCustomInstrument.setupDebugPatch();
  instruments.add(debugCustomInstrument);
  currentInstrument = 0; //Force the instrument on screen to be the debug one
}

//Used to perform draw-level (looped) interactions with the preloaded test instrument
private void drawDebugInstrument()
{
  currentInstrument = 0; //Force the instrument on screen to be the debug one
  debugCustomInstrument.drawDebugPatch();
}
