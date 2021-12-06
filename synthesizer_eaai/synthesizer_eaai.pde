/*synthesizer_eaai.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 December 5

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

//Constant used to toggle debug modes
//NOTE: "Dead code" warnings below when checking for multiple debug flags are expected because of lazy Boolean evaluation
public final boolean DEBUG_SYSTEM = true; //For general procedural stuff, like control flow
public final boolean DEBUG_INTERFACE_KNOB = false; //For testing interfacing (defined below) with the knob
public final boolean DEBUG_INTERFACE_PATCH = false; //For testing interfacing (defined below) with the patches
public final boolean DEBUG_INTERFACE = false || DEBUG_INTERFACE_KNOB || DEBUG_INTERFACE_PATCH; //For testing interfacing features (GUI, set values via I/O-related function calls)

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
  if((currentInstrument >= 0) && (currentInstrument < instruments.size()))
  {
    instruments.get(currentInstrument).render();
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
