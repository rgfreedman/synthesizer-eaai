/*synthesizer_eaai.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 December 30

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
final int NO_INDEX = -1; //Constant when there is not focus target
int mouseTargetInstrumentIndex = NO_INDEX; //Index of instrument with currently selected things via the mouse
int mouseTargetComponentIndex = NO_INDEX; //Index of SynthComponent currently selected with the mouse
int mouseTargetKnobIndex = NO_INDEX; //Index of focused SynthComponent's currently selected knob with the mouse
int mouseTargetPatchCableIndex = NO_INDEX; //Patch cable currently selected with the mouse

//Constant used to toggle debug modes
//NOTE: "Dead code" warnings below when checking for multiple debug flags are expected because of lazy Boolean evaluation
public final boolean DEBUG_SYSTEM = true; //For general procedural stuff, like control flow
public final boolean DEBUG_INTERFACE_KNOB = false; //For testing interfacing (defined below) with the knob
public final boolean DEBUG_INTERFACE_PATCH = false; //For testing interfacing (defined below) with the patches
public final boolean DEBUG_INTERFACE_MOUSE = true; //For testing interfacing (definted below) with the mouse
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
  
  //Draw on screen the instrument that is currently selected
  if((currentInstrument >= 0) && (currentInstrument < instruments.size()) && (instruments.get(currentInstrument) != null))
  {
    instruments.get(currentInstrument).render();
  }
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
      print("\tLeft mouse clicked on component " + focus + "...\n");
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
      
      //When the press is on a knob, identify the position of the cursor over the knob's
      //  width to set the value---also store the information for any dragging until mouse release
      if(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_KNOB)
      {
        mouseTargetKnobIndex = focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX];
        if(DEBUG_INTERFACE_MOUSE)
        {
          print("\t\tKnob " + mouseTargetKnobIndex + " was under the click\n");
        }
        mouseAdjustKnob(mouseTargetInstrumentIndex, mouseTargetComponentIndex, mouseTargetKnobIndex);
      }
      else if(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_PATCHIN)
      {
        //mouseTargetPatchCable = focus.getCableIn(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]);
        if(DEBUG_INTERFACE_MOUSE)
        {
          print("\t\tInput patch's cable " + mouseTargetPatchCableIndex + " was under the click\n");
        }
        //Null means no cable has been inserted yet to move => create a new patch cable and plug it in
      }
      else if(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_ELEMENT] == Render_CONSTANTS.SYNTHCOMPONENT_ELEMENT_PATCHOUT)
      {
        //mouseTargetPatchCable = focus.getCableOut(focusDetails[Render_CONSTANTS.SYNTHCOMPONENT_FOCUS_INDEX]);
        if(DEBUG_INTERFACE_MOUSE)
        {
          print("\t\tOutput patch's cable " + mouseTargetPatchCableIndex + " was under the click\n");
        }
        //Null means no cable has been inserted yet to move => create a new patch cable and plug it in
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
    if(mouseTargetKnobIndex > NO_INDEX)
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
  //Left click will complete a patch placement or stop manipulating a knob
  if(mouseButton == LEFT)
  {
    //Simply set the target knob to null to stop manipulating that knob
    mouseTargetKnobIndex = NO_INDEX;
    
    //If there is a selected patch cable, then finish inserting the cable first (if applicable)
    mouseTargetPatchCableIndex = NO_INDEX;
    
    //Lastly, remove the focus on the instrument and component as well
    mouseTargetInstrumentIndex = NO_INDEX;
    mouseTargetComponentIndex = NO_INDEX;
  }
}

//When the user clicks a mouse button (press and release), determine whether it relates to some action on the screen
void mouseClicked()
{
  //Alter processing the mouse press if there is no instrument with which to interact,
  //  such as loading an instrument (for now, just abort since no extra functionality)
  if((currentInstrument < 0) || (currentInstrument >= instruments.size()) || (instruments.get(currentInstrument) == null))
  {
    return;
  }
  
  if(mouseButton == RIGHT)
  {
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
