/*synthesizer_eaai.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2022 January 21

A synthesizer application that generates custom audio based on setup of various modules.
Made possible using the Minim library (API at http://code.compartmental.net/minim/index_ugens.html)

---------------------------------------------------------------------
Copyright 2022 Richard (Rick) G. Freedman

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
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
private int mouseTargetModuleIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of SynthModule currently selected with the mouse
private int mouseTargetKnobIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of focused SynthModule's currently selected knob with the mouse
private int mouseTargetPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of in patch cable currently selected with the mouse
private int mouseTargetPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of out patch cable currently selected with the mouse
private int mousePrevModuleIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of patch cable of focus's previous module to which it was plugged in
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
public final char[] INSTRUMENT_HOTKEYS = {'`', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', '[', ']', '\\'};

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
  
  //Initialize all the MIDI information for the keyboard
  setupMIDIarrays();
  
  //Now there is enough information to bind the keys to the keyboard, if a keyboard exists
  //Place the hands a little away from the center (rather than at extreme ends) of the keyboard
  left_hand_curIndex = (Render_CONSTANTS.KEYBOARD_KEYS_TOTAL / 2) - KEYS_PER_HAND;//0; //This is a natural key, starting at E4
  right_hand_curIndex = (Render_CONSTANTS.KEYBOARD_KEYS_TOTAL / 2) + KEYS_PER_HAND - 2;//Render_CONSTANTS.KEYBOARD_KEYS_TOTAL - KEYS_PER_HAND; //This is a natural key, starting at E6
  //NOTE: realignment is now done in setCurrentInstrument, called from setupBlankInstruments
  //realignKeyboard(LEFT_HAND, left_hand_curIndex);
  //realignKeyboard(RIGHT_HAND, right_hand_curIndex);
  
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
  
  guiKeyBindings = new HashMap();
  
  //Before entering the draw loop and such, let the agent perform any necessary setup
  setup_agent();
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
  
  //Let the agent perform any necessary change(s) through its own commands
  draw_agent();
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
     || (instruments.get(currentInstrument).getSynthModule(CustomInstrument_CONSTANTS.KEYBOARD_INDEX) == null))
  {
    return false;
  }
  
  if(DEBUG_INTERFACE_KEYBOARD)
  {
    println("Aligning keyboard with " + (hand ? "right":"left") + " hand at newIndex " + newIndex + " which is a " + (midiNatural[newIndex] ? "natural":"halftone") + " key");
  }
  
  //Grab the keyboard for the upcoming calls to change annotations
  Keyboard k = (Keyboard)instruments.get(currentInstrument).getSynthModule(CustomInstrument_CONSTANTS.KEYBOARD_INDEX);
  
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
      //Some awkward cases where there are more natural keys than expected... simply skip annotations and key bindings
      if(nextNaturalIndex < naturalKeys.length)
      {
        k.set_annotation(midiNatural[i], midiKeyIndex[i], "" + naturalKeys[nextNaturalIndex]);
      }
      nextNaturalIndex++;
    }
    else if(midiNatural[i] == Keyboard_CONSTANTS.HALFTONE_KEY)
    {
      //Some awkward cases where there are more halftone keys than expected... simply skip annotations and key bindings
      if(nextHalftoneIndex < halftoneKeys.length)
      {
        k.set_annotation(midiNatural[i], midiKeyIndex[i], "" + halftoneKeys[nextHalftoneIndex]);
      }
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

//Resets the keyboard annotations, removing all labels from all keys
public void resetKeyboardAnnotations()
{
  //Make sure the newIndex value is valid (within bounds for at least one key on the hand)
  if((currentInstrument < 0) || (currentInstrument >= instruments.size()) || (instruments.get(currentInstrument) == null)
     || (instruments.get(currentInstrument).getSynthModule(CustomInstrument_CONSTANTS.KEYBOARD_INDEX) == null))
  {
    return;
  }
  
  if(DEBUG_INTERFACE_KEYBOARD)
  {
    println("Removing all labels on keyboard");
  }
  
  //Grab the keyboard for the upcoming calls to change annotations
  Keyboard k = (Keyboard)instruments.get(currentInstrument).getSynthModule(CustomInstrument_CONSTANTS.KEYBOARD_INDEX);
  
  //Simply iterate over all the keys and set them to be blank
  for(int i = 0; i < midiNatural.length; i++)
  {
    k.set_annotation(midiNatural[i], midiKeyIndex[i], "");
  }
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
    
    //Before swapping out the instrument, clear the annotations on the current keyboard (might change before coming back)
    resetKeyboardAnnotations();
    
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
          //NOTE: Setting to an ArrayList of the set to avoid the ConcurrentModificationException
          for(Character c : new ArrayList<Character>(guiKeyBindings.keySet()))
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
    
    //After swapping out the instrument, realign the keyboard to match the current settings
    realignKeyboard(LEFT_HAND, left_hand_curIndex);
    realignKeyboard(RIGHT_HAND, right_hand_curIndex);
    
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
    //Identify the module of focus for the current instrument
    SynthModule focus = instruments.get(currentInstrument).getSynthModuleAt(mouseX, mouseY);
    if(DEBUG_INTERFACE_MOUSE)
    {
      print("\tLeft mouse pressed on module " + focus + "...\n");
    }
    //If there is a target module in the focus, then determine whether a knob or patch was selected
    if(focus != null)
    {
      int topLeftX = instruments.get(currentInstrument).getModuleTopLeftX(focus);
      int topLeftY = instruments.get(currentInstrument).getModuleTopLeftY(focus);
      int[] focusDetails = focus.getElementAt(mouseX - topLeftX, mouseY - topLeftY);
      
      //If any element was found, then we will need the instrument and module indeces
      if(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] != Render_CONSTANTS.SYNTHMODULE_ELEMENT_NONE)
      {
        mouseTargetInstrumentIndex = currentInstrument;
        mouseTargetModuleIndex = instruments.get(currentInstrument).findSynthModuleIndex(focus);
      }
      
      //When the focus element is a ModuleChooser object, then special case to add a module
      if(focus instanceof ModuleChooser)
      {
        //Compute the Module ID, which should correlate with the patch indeces
        int moduleID = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
        if(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHMODULE_ELEMENT_PATCHIN)
        {
          moduleID = focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX];
        }
        else if(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHMODULE_ELEMENT_PATCHOUT)
        {
          moduleID = ModuleChooser_CONSTANTS.TOTAL_PATCHIN + focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX];
        }
        //If the ID exists, then add the corresponding module
        if(moduleID > CustomInstrument_CONSTANTS.NO_SUCH_INDEX)
        {
          commandAddModule(mouseTargetInstrumentIndex, moduleID, GUI_USER);
        }
        //We will not need the mouseTarget indeces after creating the module
        mouseTargetInstrumentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
        mouseTargetModuleIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
      }
      //When the press is on a knob, identify the position of the cursor over the knob's
      //  width to set the value---also store the information for any dragging until mouse release
      else if(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHMODULE_ELEMENT_KNOB)
      {
        mouseTargetKnobIndex = focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX];
        if(DEBUG_INTERFACE_MOUSE)
        {
          print("\t\tKnob " + mouseTargetKnobIndex + " was under the click\n");
        }
        Knob k = instruments.get(mouseTargetInstrumentIndex).getSynthModule(mouseTargetModuleIndex).getKnob(mouseTargetKnobIndex);
        commandAdjustKnob(mouseTargetInstrumentIndex, mouseTargetModuleIndex, mouseTargetKnobIndex, (float)(mouseX - k.getTopLeftX()) / (float)k.getWidth(), GUI_USER);
      }
      //When the press is on an input patch, either create or readjust the patch cable---
      //  also store the information until mouse release to complete the patch
      else if(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHMODULE_ELEMENT_PATCHIN)
      {
        if(DEBUG_INTERFACE_MOUSE)
        {
          print("\t\tInput patch's cable " + focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX] + " was under the click\n");
        }
        //Null means no cable has been inserted yet to move => create a new patch cable and plug it in
        if(focus.getCableIn(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX]) == null)
        {
          //In case the move fails, note the lack of a previous connection so that it may be deleted
          mousePrevModuleIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          mousePrevPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          mousePrevPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          //The current focus in patch will serve as a reference to find the patch for adding in later
          mouseTargetPatchInIndex = focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX];
          mouseTargetPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          //The patch cable is included now for the GUI to visualize
          instruments.get(currentInstrument).addPatchCable(new PatchCable(null, CustomInstrument_CONSTANTS.NO_SUCH_INDEX, focus, mouseTargetPatchInIndex));
        }
        //Otherwise, move the pre-existing patch cable (for the move, it is now plugged into null)
        else
        {
          //In case the move fails, store the current patch assignment to be safe
          mousePrevModuleIndex = mouseTargetModuleIndex;
          mousePrevPatchInIndex = focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX];
          mousePrevPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          //The other end of the patch cable associated with this focus will be needed as a reference to find the patch later
          //  Conceptually, this is like adding a new patch cable where the out patch was selected first
          mouseTargetPatchOutIndex = focus.getCableIn(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX]).getPatchOutIndex();
          mouseTargetModuleIndex = instruments.get(currentInstrument).findSynthModuleIndex(focus.getCableIn(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX]).getPatchOutModule());
          mouseTargetPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          //Unplug the selected patch cable for now so that it follows the mouse in the GUI
          instruments.get(currentInstrument).unsetPatchIn(mousePrevModuleIndex, mousePrevPatchInIndex);
        }
      }
      //When the press is on an output patch, either create or readjust the patch cable---
      //  also store the information until mouse release to complete the patch
      else if(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHMODULE_ELEMENT_PATCHOUT)
      {
        if(DEBUG_INTERFACE_MOUSE)
        {
          print("\t\tOutput patch's cable " + focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX] + " was under the click\n");
        }
        //Null means no cable has been inserted yet to move => create a new patch cable and plug it in
        if(focus.getCableOut(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX]) == null)
        {
          //In case the move fails, note the lack of a previous connection so that it may be deleted
          mousePrevModuleIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          mousePrevPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          mousePrevPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          //The current focus in patch will serve as a reference to find the patch for adding in later
          mouseTargetPatchOutIndex = focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX];
          mouseTargetPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          //The patch cable is included now for the GUI to visualize
          instruments.get(currentInstrument).addPatchCable(new PatchCable(focus, mouseTargetPatchOutIndex, null, CustomInstrument_CONSTANTS.NO_SUCH_INDEX));
        }
        //Otherwise, move the pre-existing patch cable (for the move, it is now plugged into null)
        else
        {
          //In case the move fails, store the current patch assignment to be safe
          mousePrevModuleIndex = mouseTargetModuleIndex;
          mousePrevPatchOutIndex = focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX];
          mousePrevPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          //The other end of the patch cable associated with this focus will be needed as a reference to find the patch later
          //  Conceptually, this is like adding a new patch cable where the in patch was selected first
          mouseTargetPatchInIndex = focus.getCableOut(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX]).getPatchInIndex();
          mouseTargetModuleIndex = instruments.get(currentInstrument).findSynthModuleIndex(focus.getCableOut(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX]).getPatchInModule());
          mouseTargetPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
          //Unplug the selected patch cable for now so that it follows the mouse in the GUI
          instruments.get(currentInstrument).unsetPatchOut(mousePrevModuleIndex, mousePrevPatchOutIndex);
        }
      }
      else
      {
        if(DEBUG_INTERFACE_MOUSE)
        {
          print("\t\tNo element in the module was under the click\n");
        }
      }
    }
    //When no module is in the focus, then some extra functionality might exist in the
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
      Knob k = instruments.get(mouseTargetInstrumentIndex).getSynthModule(mouseTargetModuleIndex).getKnob(mouseTargetKnobIndex);
      commandAdjustKnob(mouseTargetInstrumentIndex, mouseTargetModuleIndex, mouseTargetKnobIndex, (float)(mouseX - k.getTopLeftX()) / (float)k.getWidth(), GUI_USER);
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
      //Identify the module of focus for the current instrument
      SynthModule focus = instruments.get(currentInstrument).getSynthModuleAt(mouseX, mouseY);
      if(DEBUG_INTERFACE_MOUSE)
      {
        print("\tLeft mouse released on module " + focus + "...\n");
      }
      
      int[] focusDetails = null;
      //If there is a target module in the focus, then determine whether a knob or patch was selected
      if(focus != null)
      {
        int topLeftX = instruments.get(currentInstrument).getModuleTopLeftX(focus);
        int topLeftY = instruments.get(currentInstrument).getModuleTopLeftY(focus);
        focusDetails = focus.getElementAt(mouseX - topLeftX, mouseY - topLeftY);
      }
      
      //The patch will complete based on the direction (in or out)---need the opposite direction on the mouse release
      if(mouseTargetPatchOutIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX)
      {
        //Although this will sound silly, the changes so far are for visualization in the GUI;
        //  those changes have to be redone in the actual newPatch or movePatchX calls => undo the changes first
        //NOTE: If the patch completion fails, then this undo would happen anyways without the remaining steps to redo the changes
        
        //Get the patch cable from the patch out index, which will be needed
        PatchCable pc = instruments.get(currentInstrument).getSynthModule(mouseTargetModuleIndex).getCableOut(mouseTargetPatchOutIndex);
        
        //Use the previous target information to undo the partially-changed patch
        if((mousePrevPatchInIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX) && (mousePrevModuleIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX))
        {
          instruments.get(currentInstrument).setPatchIn(mousePrevModuleIndex, mousePrevPatchInIndex, pc);
        }
        //This means removing it if no previous patch information
        else
        {
          instruments.get(currentInstrument).unsetPatchOut(mouseTargetModuleIndex, mouseTargetPatchOutIndex);
          instruments.get(currentInstrument).removePatchCable(pc);
        }
        
        //Mouse release needs to match the known patch-out with an unused patch-in; revert when not the case 
        if((focusDetails == null) || (focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] != Render_CONSTANTS.SYNTHMODULE_ELEMENT_PATCHIN) || ((focus != null) && (focus.getCableIn(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX]) != null)))
        {
          if(DEBUG_INTERFACE_MOUSE)
          {
            if(focusDetails == null)
            {
              print("\t\tCannot complete patch from patch out " + mouseTargetPatchOutIndex + " of " + instruments.get(currentInstrument).getSynthModule(mouseTargetModuleIndex) + " because no focus information was found\n");
            }
            else if(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] != Render_CONSTANTS.SYNTHMODULE_ELEMENT_PATCHIN)
            {
              print("\t\tCannot complete patch from patch out " + mouseTargetPatchOutIndex + " of " + instruments.get(currentInstrument).getSynthModule(mouseTargetModuleIndex) + " because mouse released on something that is not a patch in\n");
            }
            else if((focus != null) && (focus.getCableIn(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX]) != null))
            {
              print("\t\tCannot complete patch from patch out " + mouseTargetPatchOutIndex + " of " + instruments.get(currentInstrument).getSynthModule(mouseTargetModuleIndex) + " because mouse released on a patch in that is already in use\n");
            }
          }
          //Nothing else to do here because the undone process was already performed above this conditional statement
        }
        else
        {
          if(DEBUG_INTERFACE_MOUSE)
          {
            print("\t\tCompleting patch from patch out " + mouseTargetPatchOutIndex + " of " + instruments.get(currentInstrument).getSynthModule(mouseTargetModuleIndex) + " to patch in " + focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX] + " of " + focus + "\n");
          }
          //If there is previous target information, then the action is moving the selected patch
          if((mousePrevPatchInIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX) && (mousePrevModuleIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX))
          {
            commandMovePatchIn(mouseTargetInstrumentIndex, mousePrevModuleIndex, mousePrevPatchInIndex, instruments.get(currentInstrument).findSynthModuleIndex(focus), focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX], GUI_USER);
          }
          //If there is no previous target information, then the action is adding a new patch cable from the press to release foci
          else
          {
            commandAddPatch(mouseTargetInstrumentIndex, mouseTargetModuleIndex, mouseTargetPatchOutIndex, instruments.get(currentInstrument).findSynthModuleIndex(focus), focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX], GUI_USER);
          }
        }
      }
      else if(mouseTargetPatchInIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX)
      {
        //Although this will sound silly, the changes so far are for visualization in the GUI;
        //  those changes have to be redone in the actual newPatch or movePatchX calls => undo the changes first
        
        //Get the patch cable from the patch out index, which will be needed
        PatchCable pc = instruments.get(currentInstrument).getSynthModule(mouseTargetModuleIndex).getCableIn(mouseTargetPatchInIndex);
        
        //NOTE: If the patch completion fails, then this undo would happen anyways without the remaining steps to redo the changes
        //Use the previous target information to undo the partially-changed patch
        if((mousePrevPatchOutIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX) && (mousePrevModuleIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX))
        {
          instruments.get(currentInstrument).setPatchOut(mousePrevModuleIndex, mousePrevPatchOutIndex, pc);
        }
        //This means removing it if no previous patch information
        else
        {
          instruments.get(currentInstrument).unsetPatchIn(mouseTargetModuleIndex, mouseTargetPatchInIndex);
          instruments.get(currentInstrument).removePatchCable(pc);
        }
          
        //Mouse release needs to match the known patch-in with an unused patch-out; revert when not the case
        if((focusDetails == null) || (focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] != Render_CONSTANTS.SYNTHMODULE_ELEMENT_PATCHOUT) || ((focus != null) && (focus.getCableOut(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX]) != null)))
        {
          if(DEBUG_INTERFACE_MOUSE)
          {
            if(focusDetails == null)
            {
              print("\t\tCannot complete patch from patch in " + mouseTargetPatchInIndex + " of " + instruments.get(currentInstrument).getSynthModule(mouseTargetModuleIndex) + " because no focus information was found\n");
            }
            else if(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] != Render_CONSTANTS.SYNTHMODULE_ELEMENT_PATCHOUT)
            {
              print("\t\tCannot complete patch from patch in " + mouseTargetPatchInIndex + " of " + instruments.get(currentInstrument).getSynthModule(mouseTargetModuleIndex) + " because mouse released on something that is not a patch out\n");
            }
            else if((focus != null) && (focus.getCableOut(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX]) != null))
            {
              print("\t\tCannot complete patch from patch in " + mouseTargetPatchInIndex + " of " + instruments.get(currentInstrument).getSynthModule(mouseTargetModuleIndex) + " because mouse released on a patch out that is already in use\n");
            }
          }
          //Nothing else to do here because the undone process was already performed above this conditional statement
        }
        else
        {
          if(DEBUG_INTERFACE_MOUSE)
          {
            print("\t\tCompleting patch from patch in " + mouseTargetPatchInIndex + " of " + instruments.get(currentInstrument).getSynthModule(mouseTargetModuleIndex) + " to patch out " + focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX] + " of " + focus + "\n");
          }
          //If there is previous target information, then the action is moving the selected patch
          if((mousePrevPatchOutIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX) && (mousePrevModuleIndex > CustomInstrument_CONSTANTS.NO_SUCH_INDEX))
          {
            commandMovePatchOut(mouseTargetInstrumentIndex, mousePrevModuleIndex, mousePrevPatchOutIndex, instruments.get(currentInstrument).findSynthModuleIndex(focus), focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX], GUI_USER);
          }
          //If there is no previous target information, then the action is adding a new patch cable from the press to release foci
          else
          {
            commandAddPatch(mouseTargetInstrumentIndex, instruments.get(currentInstrument).findSynthModuleIndex(focus), focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX], mouseTargetModuleIndex, mouseTargetPatchInIndex, GUI_USER);
          }
        }
      }
    }
    //Simply set the target patches (all of them) to null to stop manipulating the patches
    mouseTargetPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
    mouseTargetPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
    mousePrevPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
    mousePrevPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
    mousePrevModuleIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
    
    //Lastly, remove the focus on the instrument and module as well
    mouseTargetInstrumentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
    mouseTargetModuleIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
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
    //Identify the module of focus for the current instrument
    SynthModule focus = instruments.get(currentInstrument).getSynthModuleAt(mouseX, mouseY);
    if(DEBUG_INTERFACE_MOUSE)
    {
      print("\tRight mouse pressed on module " + focus + "...\n");
    }
    //If there is a target module in the focus, then determine whether a knob or patch was selected
    if(focus != null)
    {
      int topLeftX = instruments.get(currentInstrument).getModuleTopLeftX(focus);
      int topLeftY = instruments.get(currentInstrument).getModuleTopLeftY(focus);
      int[] focusDetails = focus.getElementAt(mouseX - topLeftX, mouseY - topLeftY);
      
      //If any element was found, then we will need the instrument and module indeces
      if(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] != Render_CONSTANTS.SYNTHMODULE_ELEMENT_NONE)
      {
        mouseTargetInstrumentIndex = currentInstrument;
        mouseTargetModuleIndex = instruments.get(currentInstrument).findSynthModuleIndex(focus);
      }
      
      //When the reove button is identified, then remove the associated module from the instrument
      if(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHMODULE_ELEMENT_REMOVE)
      {
        commandRemoveModule(mouseTargetInstrumentIndex, mouseTargetModuleIndex, GUI_USER);
      }
      //When a patch is identified with an existing cable, then remove it from the instrument
      else if(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHMODULE_ELEMENT_PATCHIN)
      {
        if(DEBUG_INTERFACE_MOUSE)
        {
          print("\t\tInput patch's cable " + focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX] + " was under the click\n");
        }
        //Null means no cable has been inserted yet => nothing to remove
        if(focus.getCableIn(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX]) == null)
        {
        }
        //Otherwise, remove the patch cable
        else
        {
          commandRemovePatchIn(mouseTargetInstrumentIndex, mouseTargetModuleIndex, focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX], GUI_USER);
        }
      }
      else if(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHMODULE_ELEMENT_PATCHOUT)
      {
        if(DEBUG_INTERFACE_MOUSE)
        {
          print("\t\tOutput patch's cable " + focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX] + " was under the click\n");
        }
        //Null means no cable has been inserted yet => nothing to remove
        if(focus.getCableOut(focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX]) == null)
        {
        }
        //Otherwise, remove the patch cable
        else
        {
          commandRemovePatchOut(mouseTargetInstrumentIndex, mouseTargetModuleIndex, focusDetails[Render_CONSTANTS.SYNTHMODULE_FOCUS_INDEX], GUI_USER);
        }
      }
      //Since the removal of modules and patches is a one-and-done operation, release the focus indeces
      mouseTargetInstrumentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
      mouseTargetModuleIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
    }
    //When no module is in the focus, then some extra functionality might exist in the
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
    //Highlight the specified key as well
    ((Keyboard)instruments.get(currentInstrument).getSynthModule(CustomInstrument_CONSTANTS.KEYBOARD_INDEX)).set_highlight(midiNatural[midiIndex], midiKeyIndex[midiIndex], true);
    //Send the command to play the specified note
    commandStartNote(currentInstrument, midiNum[midiIndex], lowerCaseKey, GUI_USER);
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
      commandStopNote(currentInstrument, midiNum[guiKeyBindings.get(lowerCaseKey)], lowerCaseKey, GUI_USER);
    }
    //If no binding anymore, then at least try to stop the key in case something is playing...
    //  use a fake frequency value since the binding is to the character value only
    else
    {
      commandStopNote(currentInstrument, 0.0, lowerCaseKey, GUI_USER);
    }
    //Undo the highlighting of the corresponding key on the keyboard
    ((Keyboard)instruments.get(currentInstrument).getSynthModule(CustomInstrument_CONSTANTS.KEYBOARD_INDEX)).set_highlight(midiNatural[midiIndex], midiKeyIndex[midiIndex], false);
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
  
  //If the key is assigned to change the current instrument, then set the index appropriately (and check that index works first---done in the setCurrentInstrument method)
  for(int i = 0; i < INSTRUMENT_HOTKEYS.length; i++)
  {
    if(key == INSTRUMENT_HOTKEYS[i])
    {
      setCurrentInstrument(i);
      break;
    }
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
