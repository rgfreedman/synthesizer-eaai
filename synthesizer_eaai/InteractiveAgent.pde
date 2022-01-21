/*InteractiveAgent.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2022 January 20

Facilitate finding commands for interactions with the interface by placing the commands
in this separate file.  Because Processing combines all files together in a project when
compiling, this is effectively the same as appending the code to the end of synthesizer_eaai.pde.

Also includes some code for an interactive intelligent agent to use, receiving information
about what happens in the interface and computing commands to perform in the interface.
*/

//User IDs will be assigned via socket support to know who took which actions, and
//  direct interactions with the GUI will be a single user ID
public int GUI_USER = -1; //Intentionally out of an array's bounds

/*---Methods for an interactive intelligent agent to use---*/
//These will eventually have socket support to send/receive information to programs written 
//  in other languages.  To use directly in Processing, simply fill in the methods with
//  things the agent should do.

//When the program starts, prepare any setup for things the agent will need before starting
void setup_agent()
{
  /*Useful commands the agent can use include:
  commandStartNote(int instrumentIndex, int midiValue, char binding, int userID) //binding can be any character, but need to remember it to later stop the note
  commandStartNote(int instrumentIndex, float frequency, char binding, int userID) //same as above, but can specify a frequency that might not correspond to a specific MIDI index
  commandStopNote(int instrumentIndex, int midiValue, char binding, int userID) //binding can be any character, but need to match the one that started the corresponding note
  commandStopNote(int instrumentIndex, float frequency, char binding, int userID) //same as above, but can specify a frequency that might not correspond to a specific MIDI index
  commandAdjustKnob(int instrumentIndex, int moduleIndex, int knobIndex, float position, int userID)
  commandAddPatch(int instrumentIndex, int moduleOutIndex, int patchOutIndex, int moduleInIndex, int patchInIndex, int userID)
  commandMovePatchOut(int instrumentIndex, int moduleFromOutIndex, int patchFromOutIndex, int moduleToOutIndex, int patchToOutIndex, int userID)
  commandMovePatchIn(int instrumentIndex, int moduleFromInIndex, int patchFromInIndex, int moduleToInIndex, int patchToInIndex, int userID)
  commandRemovePatchOut(int instrumentIndex, int moduleIndex, int patchOutIndex, int userID) //Like commandRemovePatchIn, but only need the output patch details
  commandRemovePatchIn(int instrumentIndex, int moduleIndex, int patchInIndex, int userID) //Like commandRemovePatchOut, but only need the input patch details
  commandAddModule(int instrumentIndex, int moduleID, int userID)
  commandRemoveModule(int instrumentIndex, int moduleIndex, int userID)
  */
}

//As the program continues, process whatever the agent will need to do/consider each frame
void draw_agent()
{
  /*Useful commands the agent can use include:
  commandStartNote(int instrumentIndex, int midiValue, char binding, int userID) //binding can be any character, but need to remember it to later stop the note
  commandStartNote(int instrumentIndex, float frequency, char binding, int userID) //same as above, but can specify a frequency that might not correspond to a specific MIDI index
  commandStopNote(int instrumentIndex, int midiValue, char binding, int userID) //binding can be any character, but need to match the one that started the corresponding note
  commandStopNote(int instrumentIndex, float frequency, char binding, int userID) //same as above, but can specify a frequency that might not correspond to a specific MIDI index
  commandAdjustKnob(int instrumentIndex, int moduleIndex, int knobIndex, float position, int userID)
  commandAddPatch(int instrumentIndex, int moduleOutIndex, int patchOutIndex, int moduleInIndex, int patchInIndex, int userID)
  commandMovePatchOut(int instrumentIndex, int moduleFromOutIndex, int patchFromOutIndex, int moduleToOutIndex, int patchToOutIndex, int userID)
  commandMovePatchIn(int instrumentIndex, int moduleFromInIndex, int patchFromInIndex, int moduleToInIndex, int patchToInIndex, int userID)
  commandRemovePatchOut(int instrumentIndex, int moduleIndex, int patchOutIndex, int userID) //Like commandRemovePatchIn, but only need the output patch details
  commandRemovePatchIn(int instrumentIndex, int moduleIndex, int patchInIndex, int userID) //Like commandRemovePatchOut, but only need the input patch details
  commandAddModule(int instrumentIndex, int moduleID, int userID)
  commandRemoveModule(int instrumentIndex, int moduleIndex, int userID)
  */
}

//Things the interactive intelligent agent should do when a note starts playing
void reportStartNote(int instrumentIndex, float frequency, int userID)
{
  //This means a human started to play the note
  if(userID == GUI_USER)
  {
  }
}

//Things the interactive intelligent agent should do when a note stops playing
void reportStopNote(int instrumentIndex, float frequency, int userID)
{
  //This means a human stopped playing the note
  if(userID == GUI_USER)
  {
  }
}

//Things the interactive intelligent agent should do when a knob is adjusted
//NOTE: position is the amount the knob is turned, not its actual value
void reportAdjustKnob(int instrumentIndex, int moduleIndex, int knobIndex, float position, int userID)
{
  //This means a human turned the GUI knob
  if(userID == GUI_USER)
  {
  }
}

//Things the interactive intelligent agent should do when a new patch is added
void reportAddPatch(int instrumentIndex, int moduleOutIndex, int patchOutIndex, int moduleInIndex, int patchInIndex, int userID)
{
  //This means a human inserted the new patch in the GUI
  if(userID == GUI_USER)
  {
  }
}

//Things the interactive intelligent agent should do when an output patch is moved
void reportMovePatchOut(int instrumentIndex, int moduleFromOutIndex, int patchFromOutIndex, int moduleToOutIndex, int patchToOutIndex, int userID)
{
  //This means a human removed and re-inserted the output part of a patch in the GUI
  if(userID == GUI_USER)
  {
  }
}

//Things the interactive intelligent agent should do when an input patch is moved
void reportMovePatchIn(int instrumentIndex, int moduleFromInIndex, int patchFromInIndex, int moduleToInIndex, int patchToInIndex, int userID)
{
  //This means a human removed and re-inserted the input part of a patch in the GUI
  if(userID == GUI_USER)
  {
  }
}

//Things the interactive intelligent agent should do when a patch is removed
void reportRemovePatch(int instrumentIndex, int moduleOutIndex, int patchOutIndex, int moduleInIndex, int patchInIndex, int userID)
{
  //This means a human removed the patch in the GUI
  if(userID == GUI_USER)
  {
  }
}

//Things the interactive intelligent agent should do when a module is added
//NOTE: The possible values of moduleID are defined in the CustomInstrument_CONSTANTS class
void reportAddModule(int instrumentIndex, int moduleID, int userID)
{
  //This means a human added the module in the GUI
  if(userID == GUI_USER)
  {
  }
}

//Things the interactive intelligent agent should do when a module is removed
//NOTE: moduleIndex is the index in the instrument's layout of modules, not the moduleID like in reportAddModule
void reportRemoveModule(int instrumentIndex, int moduleIndex, int userID)
{
  //This means a human removed the module in the GUI
  if(userID == GUI_USER)
  {
  }
}

/*---Methods for operating the interface elements with the mouse and/or keyboard---*/

//Set a knob's position
void commandAdjustKnob(int instrumentIndex, int moduleIndex, int knobIndex, float position, int userID)
{
  //Make sure the indeces all exist and are not null before beginning
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleIndex).getKnob(knobIndex) == null))
  {
    return;
  }
  
  Knob k = instruments.get(instrumentIndex).getSynthModule(moduleIndex).getKnob(knobIndex);
  float kMinPos = k.getMinimumPosition();
  float kMaxPos = k.getMaximumPosition();
  //If too small, then set the position to min
  if(position < kMinPos)
  {
    instruments.get(instrumentIndex).setKnob(moduleIndex, knobIndex, kMinPos);
  }
  //If too large, then set the position to max
  else if(position > kMaxPos)
  {
    instruments.get(instrumentIndex).setKnob(moduleIndex, knobIndex, kMaxPos);
  }
  //When in the middle, use position
  else
  {
    instruments.get(instrumentIndex).setKnob(moduleIndex, knobIndex, position);
  }
  
  //Report the performed action for interactive intelligent agents to process
  reportAdjustKnob(instrumentIndex, moduleIndex, knobIndex, position, userID);
}

//Create a new patch and plug it into the instrument
void commandAddPatch(int instrumentIndex, int moduleOutIndex, int patchOutIndex, int moduleInIndex, int patchInIndex, int userID)
{
  //Make sure the indeces all exist and are not null before beginning
  //NOTE: The getPatchX is the UGen (should not be null), and getCableX is the PatchCable (should be null) 
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleOutIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleOutIndex).getPatchOut(patchOutIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleOutIndex).getCableOut(patchOutIndex) != null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleInIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleInIndex).getPatchIn(patchInIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleInIndex).getCableIn(patchInIndex) != null))
  {
    return;
  }
  
  //Simply add the specified patch cable, generating a new object to pass in
  instruments.get(instrumentIndex).addPatchCable(new PatchCable(instruments.get(instrumentIndex).getSynthModule(moduleOutIndex), patchOutIndex, instruments.get(instrumentIndex).getSynthModule(moduleInIndex), patchInIndex));
  
  //Report the performed action for interactive intelligent agents to process
  reportAddPatch(instrumentIndex, moduleOutIndex, patchOutIndex, moduleInIndex, patchInIndex, userID);
}

//Take an existing patch and replug its output patch elsewhere in the instrument
void commandMovePatchOut(int instrumentIndex, int moduleFromOutIndex, int patchFromOutIndex, int moduleToOutIndex, int patchToOutIndex, int userID)
{
  //Make sure the indeces all exist and are not null before beginning
  //NOTE: The getPatchOut is the UGen (should not be null), and getCableOut is the PatchCable (should be null in To, not null in From) 
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleFromOutIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleFromOutIndex).getPatchOut(patchFromOutIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleFromOutIndex).getCableOut(patchFromOutIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleToOutIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleToOutIndex).getPatchOut(patchToOutIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleToOutIndex).getCableOut(patchToOutIndex) != null))
  {
    return;
  }
  
  //Simply set the specified output patch cable, using the cable specified in From
  instruments.get(instrumentIndex).setPatchOut(moduleToOutIndex, patchToOutIndex, instruments.get(instrumentIndex).getSynthModule(moduleFromOutIndex).getCableOut(patchFromOutIndex));
  
  //Report the performed action for interactive intelligent agents to process
  reportMovePatchOut(instrumentIndex, moduleFromOutIndex, patchFromOutIndex, moduleToOutIndex, patchToOutIndex, userID);
}

//Take an existing patch and replug its input patch elsewhere in the instrument
void commandMovePatchIn(int instrumentIndex, int moduleFromInIndex, int patchFromInIndex, int moduleToInIndex, int patchToInIndex, int userID)
{
  //Make sure the indeces all exist and are not null before beginning
  //NOTE: The getPatchIn is the UGen (should not be null), and getCableIn is the PatchCable (should be null in To, not null in From) 
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleFromInIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleFromInIndex).getPatchIn(patchFromInIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleFromInIndex).getCableIn(patchFromInIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleToInIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleToInIndex).getPatchIn(patchToInIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleToInIndex).getCableIn(patchToInIndex) != null))
  {
    return;
  }
  
  //Simply set the specified output patch cable, using the cable specified in From
  instruments.get(instrumentIndex).setPatchIn(moduleToInIndex, patchToInIndex, instruments.get(instrumentIndex).getSynthModule(moduleFromInIndex).getCableIn(patchFromInIndex));
  
  //Report the performed action for interactive intelligent agents to process
  reportMovePatchIn(instrumentIndex, moduleFromInIndex, patchFromInIndex, moduleToInIndex, patchToInIndex, userID);
}

//Take an existing patch and remove it from the instrument
void commandRemovePatchOut(int instrumentIndex, int moduleIndex, int patchOutIndex, int userID)
{
  //Make sure the indeces all exist and are not null before beginning
  //NOTE: The getPatchOut is the UGen (should not be null), and getCableOut is the PatchCable (should not be null) 
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleIndex).getPatchOut(patchOutIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleIndex).getCableOut(patchOutIndex) == null))
  {
    return;
  }
  
  //Before removing the patch cable forever, get a pointer to it to report its details
  PatchCable toRemove = instruments.get(instrumentIndex).getSynthModule(moduleIndex).getCableOut(patchOutIndex);
  
  //Simply remove the patch cable with specified output
  instruments.get(instrumentIndex).removePatchCable(toRemove);
  
  //Report the performed action for interactive intelligent agents to process
  reportRemovePatch(instrumentIndex, moduleIndex, patchOutIndex, instruments.get(instrumentIndex).findSynthModuleIndex(toRemove.getPatchInModule()), toRemove.getPatchInIndex(), userID);
}

//Take an existing patch and remove it from the instrument
void commandRemovePatchIn(int instrumentIndex, int moduleIndex, int patchInIndex, int userID)
{
  //Make sure the indeces all exist and are not null before beginning
  //NOTE: The getPatchIn is the UGen (should not be null), and getCableIn is the PatchCable (should not be null) 
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleIndex).getPatchIn(patchInIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleIndex).getCableIn(patchInIndex) == null))
  {
    return;
  }
  
  //Before removing the patch cable forever, get a pointer to it to report its details
  PatchCable toRemove = instruments.get(instrumentIndex).getSynthModule(moduleIndex).getCableIn(patchInIndex);
  
  //Simply remove the patch cable with specified input
  instruments.get(instrumentIndex).removePatchCable(toRemove);
  
  //Report the performed action for interactive intelligent agents to process
  reportRemovePatch(instrumentIndex, instruments.get(instrumentIndex).findSynthModuleIndex(toRemove.getPatchOutModule()), toRemove.getPatchOutIndex(), moduleIndex, patchInIndex, userID);
}

//Adds a module to the instrument
void commandAddModule(int instrumentIndex, int moduleID, int userID)
{
  //Make sure the indeces all exist and are not null before beginning
  //NOTE: The getPatchIn is the UGen (should not be null), and getCableIn is the PatchCable (should not be null) 
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null))
  {
    return;
  }
  
  //Simply add the specified module
  instruments.get(instrumentIndex).addSynthModule(moduleID);
  
  //Report the performed action for interactive intelligent agents to process
  reportAddModule(instrumentIndex, moduleID, userID);
}

//Removes a module from the instrument
void commandRemoveModule(int instrumentIndex, int moduleIndex, int userID)
{
  //Make sure the indeces all exist and are not null before beginning
  //NOTE: The getPatchIn is the UGen (should not be null), and getCableIn is the PatchCable (should not be null) 
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (instruments.get(instrumentIndex).getSynthModule(moduleIndex) == null))
  {
    return;
  }
  
  //Simply remove the specified module
  instruments.get(instrumentIndex).removeSynthModule(moduleIndex);
  
  //Report the performed action for interactive intelligent agents to process
  reportRemoveModule(instrumentIndex, moduleIndex, userID);
}

//Starts playing a note from the instrument (can be a key or a frequency assigned to the binding)
void commandStartNote(int instrumentIndex, int midiValue, char binding, int userID)
{
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (midiValue < midiNum[0]) || (midiValue > midiNum[midiNum.length - 1]))
  {
    return;
  }
  commandStartNote(instrumentIndex, midiFreq[midiValue - midiNum[0]], binding, userID);
}
void commandStartNote(int instrumentIndex, float frequency, char binding, int userID)
{
  //Make sure the indeces all exist and are not null before beginning
  //NOTE: The getPatchIn is the UGen (should not be null), and getCableIn is the PatchCable (should not be null) 
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (frequency < Audio_CONSTANTS.MIN_FREQ) || (frequency > Audio_CONSTANTS.MAX_FREQ))
  {
    return;
  }
  
  //Simply start the note with the bound char value
  int assigned = ((Keyboard)instruments.get(instrumentIndex).getSynthModule(CustomInstrument_CONSTANTS.KEYBOARD_INDEX)).set_key(binding, frequency);
  if(DEBUG_INTERFACE_KEYBOARD)
  {
    println("Tried to play frequency " + frequency + " with key binding " + binding + " -> result: " + assigned);
  }
  
  //Report the performed action for interactive intelligent agents to process
  reportStartNote(instrumentIndex, frequency, userID);
}

//Stops playing a note from the instrument (can be a key or a frequency assigned to the binding)
void commandStopNote(int instrumentIndex, int midiValue, char binding, int userID)
{
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (midiValue < midiNum[0]) || (midiValue > midiNum[midiNum.length - 1]))
  {
    return;
  }
  commandStopNote(instrumentIndex, midiFreq[midiValue - midiNum[0]], binding, userID);
}
void commandStopNote(int instrumentIndex, float frequency, char binding, int userID)
{
  //Make sure the indeces all exist and are not null before beginning
  //NOTE: The getPatchIn is the UGen (should not be null), and getCableIn is the PatchCable (should not be null) 
  if((instrumentIndex < 0) || (instrumentIndex >= instruments.size()) || (instruments.get(instrumentIndex) == null)
     || (frequency < Audio_CONSTANTS.MIN_FREQ) || (frequency > Audio_CONSTANTS.MAX_FREQ))
  {
    return;
  }
  
  //Simply start the note with the bound char value
  boolean unassigned = ((Keyboard)instruments.get(instrumentIndex).getSynthModule(CustomInstrument_CONSTANTS.KEYBOARD_INDEX)).unset_key(binding);
  if(DEBUG_INTERFACE_KEYBOARD)
  {
    println("Tried to halt frequency " + frequency + " with key binding " + binding + " -> result: " + unassigned);
  }
  
  //Report the performed action for interactive intelligent agents to process
  reportStopNote(instrumentIndex, frequency, userID);
}
