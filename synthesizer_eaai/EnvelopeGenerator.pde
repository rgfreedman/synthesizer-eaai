/*EnvelopeGenerator.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2022 January 20

Class for an envelope generator (EG) module within a synthesized instrument.
This module modifies the amplitude of an input wave with a more complex pattern that
is bound to a note structure (such as a keypress).
To begin the envelope's application, the gate should receive a non-0 input.
To end the envelope's application, the gate should receive a 0 input.

This envelope uses attack-decay-sustain-release (ADSR), and Minim kindly has two extra
parameters for the start and stop values so that the envelope can be fully shaped:
Amplitude values are START_AMPLITUDE, MAX_AMPLITUDE, SUSTAIN, and END_AMPLITUDE
Time durations that interpolate the above amplitudes are ATTACK, DECAY, and RELEASE
- When start note, go from START_AMPLITUDE to MAX_AMPLITUDE in ATTACK seconds and then
                      from MAX_AMPLITUDE to SUSTAIN in DECAY seconds
- When stopping note, go from SUSTAIN to END_AMPLITUDE in RELEASE seconds
- After ATTACK + DELAY seconds, if the note is not stopped, the envelope maintains the
  SUSTAIN amplitude indefinitely (until the note is stopped)
*/

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the VCO class below
public static class EnvelopeGenerator_CONSTANTS
{
  //Indeces for input patches - this is the waveform
  public static final int PATCHIN_WAVE = 0;
  public static final int PATCHIN_GATE = PATCHIN_WAVE + 1;
  public static final int TOTAL_PATCHIN = PATCHIN_GATE + 1;
  
  //Indeces for knobs - one per value to include in the generated envelope
  public static final int KNOB_STARTAMP = 0;
  public static final int KNOB_MAXAMP = KNOB_STARTAMP + 1;
  public static final int KNOB_SUSTAIN = KNOB_MAXAMP + 1;
  public static final int KNOB_ENDAMP = KNOB_SUSTAIN + 1;
  public static final int KNOB_ATTACK = KNOB_ENDAMP + 1;
  public static final int KNOB_DECAY = KNOB_ATTACK + 1;
  public static final int KNOB_RELEASE = KNOB_DECAY + 1;
  public static final int TOTAL_KNOB = KNOB_RELEASE + 1;
  
  //Indeces for output patches - this is the modified waveform
  public static final int PATCHOUT_WAVE = 0;
  public static final int TOTAL_PATCHOUT = PATCHOUT_WAVE + 1;
  
  //Special threshold parameter for the gate since 0 might be too precise to check
  public static final float THRESHOLD_GATE_PLAYNOTE = 0.001;
}

public class EnvelopeGenerator extends SynthModule
{
  //Internal UGen Objects that compose the module's "circuit"
  //ADSR generates the envelope that will modify the input waveform when a note plays
  private ADSR envelope;
  //This Sink is simply reading the values patched into it, which will determine when
  //  a note starts (non-0 value) and ends (0 value)
  private Summer gate;
  private Sink ground; //Minim ignores the gate unless its output goes somewhere
  
  //Bookkeeping variable for whether a note is currently playing
  private boolean note_playing = false;
  //Stores the most recent gate sample, which is used to detect note playing
  float[] recent_gate;
  
  //Default Constructor - set up all the patches and knobs
  public EnvelopeGenerator()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(EnvelopeGenerator_CONSTANTS.TOTAL_PATCHIN, EnvelopeGenerator_CONSTANTS.TOTAL_PATCHOUT, EnvelopeGenerator_CONSTANTS.TOTAL_KNOB);

    //Now fill in the knobs
    //The amplitude value knobs are bound to [0,1]
    knobs[EnvelopeGenerator_CONSTANTS.KNOB_STARTAMP] = new Knob(0.0, 1.0);
    knobs[EnvelopeGenerator_CONSTANTS.KNOB_MAXAMP] = new Knob(0.0, 1.0);
    knobs[EnvelopeGenerator_CONSTANTS.KNOB_SUSTAIN] = new Knob(0.0, 1.0);
    knobs[EnvelopeGenerator_CONSTANTS.KNOB_ENDAMP] = new Knob(0.0, 1.0);
    //The time duration knobs are bound to [0,3] since it is unlikely to have longer notes
    knobs[EnvelopeGenerator_CONSTANTS.KNOB_ATTACK] = new Knob(0.0, 3.0);
    knobs[EnvelopeGenerator_CONSTANTS.KNOB_DECAY] = new Knob(0.0, 3.0);
    knobs[EnvelopeGenerator_CONSTANTS.KNOB_RELEASE] = new Knob(0.0, 3.0);
    
    //Labels for the knobs in the GUI
    knobsLabel[EnvelopeGenerator_CONSTANTS.KNOB_STARTAMP] = "AMP START";
    knobsLabel[EnvelopeGenerator_CONSTANTS.KNOB_MAXAMP] = "AMP MAX";
    knobsLabel[EnvelopeGenerator_CONSTANTS.KNOB_SUSTAIN] = "SUSTAIN";
    knobsLabel[EnvelopeGenerator_CONSTANTS.KNOB_ENDAMP] = "AMP END";
    knobsLabel[EnvelopeGenerator_CONSTANTS.KNOB_ATTACK] = "ATTACK";
    knobsLabel[EnvelopeGenerator_CONSTANTS.KNOB_DECAY] = "DECAY";
    knobsLabel[EnvelopeGenerator_CONSTANTS.KNOB_RELEASE] = "RELEASE";

    //Set up the internals of the module with the UGen elements from Minim
    envelope = new ADSR(); //Knobs will be synced in the draw step before gate has first chance to play a note
    gate = new Summer();
    ground = new Sink();
    
    //With the UGens all setup, fill in the external-facing ones for input/output
    patchIn[EnvelopeGenerator_CONSTANTS.PATCHIN_WAVE] = envelope;
    patchOut[EnvelopeGenerator_CONSTANTS.PATCHOUT_WAVE] = envelope;
    
    patchIn[EnvelopeGenerator_CONSTANTS.PATCHIN_GATE] = gate;
    
    //Labels for the patches in the GUI
    patchInLabel[EnvelopeGenerator_CONSTANTS.PATCHIN_WAVE] = "WAVE IN";
    patchInLabel[EnvelopeGenerator_CONSTANTS.PATCHIN_GATE] = "GATE";
    patchOutLabel[EnvelopeGenerator_CONSTANTS.PATCHOUT_WAVE] = "WAVE OUT";
    moduleName = "Envelope Generator";
    
    //Patch internal modules together (envelope and gate are disjoint, but gate needs ground)
    gate.patch(ground);
    
    //No note is playing yet, and need to instantiate source of samples
    note_playing = false;
    recent_gate = new float[1];
  }
  
  //Implement in each module to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public void draw_update()
  {
    //Check the gate value to determine whether a note is starting or stopping
    try
    {
      gate.tick(recent_gate);
    }
    //Somehow, the tick overflows once in a while and sends waaaay more than a few samples
    catch(java.lang.ArrayIndexOutOfBoundsException e)
    {
      println(e + ": Envelope Generator had a problem");
      //Set recent_gate to lenth 0 and skip the check below
      recent_gate = new float[0];
    }
    
    //Instead of looping over all the samples and starting/stopping many notes, just
    //  check the most recent sample
    //for(int sample_index = 0; sample_index < recent_gate.length; sample_index++)
    //{
    //WARNING: It is possible to get 0 samples, and then there is nothing to check!
    if(recent_gate.length > 0)
    {
      //NOTE: We use a threshold about 0 since samples might not be exact
      //      Because we are checking frequencies, this margin of error should be safer than checking amplitudes
      if(abs(recent_gate[recent_gate.length - 1]) < EnvelopeGenerator_CONSTANTS.THRESHOLD_GATE_PLAYNOTE)
      {
        //If the value is 0 (or close enough to 0), then stop a note if one is playing
        if(note_playing)
        {
          //If a patch is not present yet, then do not try to patch the UGens (null will cause errors)
          if((patchOutCable != null) && (patchOutCable[EnvelopeGenerator_CONSTANTS.PATCHOUT_WAVE] != null) && (patchOutCable[EnvelopeGenerator_CONSTANTS.PATCHOUT_WAVE].getPatchIn() != null))
          {
            envelope.unpatchAfterRelease(patchOutCable[EnvelopeGenerator_CONSTANTS.PATCHOUT_WAVE].getPatchIn());
          }
          envelope.noteOff();
          note_playing = false;
        }
      }
      else
      {
        //If the value is non-0 (or far enough from 0), then start a note if one is not playing
        if(!note_playing)
        {
          //Before starting the note, set the ADSR envelope to the current knob's settings
          envelope.setParameters(
            knobs[EnvelopeGenerator_CONSTANTS.KNOB_MAXAMP].getCurrentValue_float(),
            knobs[EnvelopeGenerator_CONSTANTS.KNOB_ATTACK].getCurrentValue_float(),
            knobs[EnvelopeGenerator_CONSTANTS.KNOB_DECAY].getCurrentValue_float(),
            knobs[EnvelopeGenerator_CONSTANTS.KNOB_SUSTAIN].getCurrentValue_float(),
            knobs[EnvelopeGenerator_CONSTANTS.KNOB_RELEASE].getCurrentValue_float(),
            knobs[EnvelopeGenerator_CONSTANTS.KNOB_STARTAMP].getCurrentValue_float(),
            knobs[EnvelopeGenerator_CONSTANTS.KNOB_ENDAMP].getCurrentValue_float()); //Closes envelope.setParameters
          envelope.noteOn();
          //If a patch is not present yet, then do not try to patch the UGens (null will cause errors)
          if((patchOutCable != null) && (patchOutCable[EnvelopeGenerator_CONSTANTS.PATCHOUT_WAVE] != null) && (patchOutCable[EnvelopeGenerator_CONSTANTS.PATCHOUT_WAVE].getPatchIn() != null))
          {
            envelope.patch(patchOutCable[EnvelopeGenerator_CONSTANTS.PATCHOUT_WAVE].getPatchIn());
          }
          note_playing = true;
        }
      }
    } //Closes if(recent_gate.length > 0)
    //} //Closes the commented-out for loop
  }
}
