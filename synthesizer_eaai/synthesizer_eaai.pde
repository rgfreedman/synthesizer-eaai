/*synthesizer_eaai.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2022 January 01

A synthesizer application that generates custom audio based on setup of various components.
Made possible using the Minim library (API at http://code.compartmental.net/minim/index_ugens.html)
*/

import ddf.minim.*;
import ddf.minim.ugens.*;

import java.util.ArrayList;

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
int mouseTargetInstrumentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of instrument with currently selected things via the mouse
int mouseTargetComponentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of SynthComponent currently selected with the mouse
int mouseTargetKnobIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of focused SynthComponent's currently selected knob with the mouse
int mouseTargetPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of in patch cable currently selected with the mouse
int mouseTargetPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of out patch cable currently selected with the mouse
int mousePrevComponentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of patch cable of focus's previous component to which it was plugged in
int mousePrevPatchInIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of in patch cable of focus's previous patch entry to which it was plugged in
int mousePrevPatchOutIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX; //Index of out patch cable of focus's previous patch entry to which it was plugged in

//Constant used to toggle debug modes
//NOTE: "Dead code" warnings below when checking for multiple debug flags are expected because of lazy Boolean evaluation
public final boolean DEBUG_SYSTEM = false; //For general procedural stuff, like control flow
public final boolean DEBUG_INTERFACE_KNOB = false; //For testing interfacing (defined below) with the knob
public final boolean DEBUG_INTERFACE_PATCH = false; //For testing interfacing (defined below) with the patches
public final boolean DEBUG_INTERFACE_MOUSE = false; //For testing interfacing (definted below) with the mouse
public final boolean DEBUG_INTERFACE = false || DEBUG_INTERFACE_KNOB || DEBUG_INTERFACE_PATCH || DEBUG_INTERFACE_MOUSE; //For testing interfacing features (GUI, set values via I/O-related function calls)

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
    setupBlankInstrument();
  }
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
private void setupBlankInstrument()
{
  instruments.add(new CustomInstrument());
  currentInstrument = 0; //Set the instrument on screen to be the current one
}

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
    //  future to add a component, but nothing for now
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
      
      //When a patch is identified with an existing cable, then remove it from the instrument
      if(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_PATCHIN)
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
      //Since the removal of patches is a one-and-done operation, release the focus indeces
      mouseTargetInstrumentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
      mouseTargetComponentIndex = CustomInstrument_CONSTANTS.NO_SUCH_INDEX;
    }
    //When no component is in the focus, then some extra functionality might exist in the
    //  future to delete a component, but nothing for now
    else
    {
    }
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
