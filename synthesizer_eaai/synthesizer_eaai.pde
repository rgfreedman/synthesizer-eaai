/*synthesizer_eaai.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 November 26

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

//Constant used to toggle debug modes
public final boolean DEBUG_SYSTEM = true; //For general procedural stuff, like control flow

void setup()
{
  //size(Render_CONSTANTS.APP_WIDTH, Render_CONSTANTS.APP_HEIGHT, P2D);
  size(1000, 1000, P2D);
  
  //Initialize the Minim and AudioOutput objects
  minim = new Minim( this );
  out = minim.getLineOut();
  allInstruments_toOut = new Summer();
  
  //Initialize the list of instruments, which begins empty (until instruments are added)
  instruments = new ArrayList();
  
  //The global Summer is always patched to the audio output for our setup
  //Instead of patching directly with the output, patch with the global Summer instead!
  allInstruments_toOut.patch(out);
  
  //Due to closing with the global Summer's patch still active, we force the unpatch before quitting the application
  //Thank you to https://forum.processing.org/one/topic/run-code-on-exit.html ,
  //  where the solution for how to activate code when exiting the application was found
  prepareExitHandler();
  
  //For easy access to a testbed, preload a special custom instrument when debugging
  if(DEBUG_SYSTEM)
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
  if(DEBUG_SYSTEM)
  {
    drawDebugInstrument();
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
}

//Used to perform draw-level (looped) interactions with the preloaded test instrument
private void drawDebugInstrument()
{
  debugCustomInstrument.drawDebugPatch();
}
