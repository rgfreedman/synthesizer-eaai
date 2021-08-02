/*VCO.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 August 01

Class for a voltage-controlled oscillator (VCO) component within a synthesized instrument.
This component simply generates waves with specified properties.
*/

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the VCO class below
public static class VCO_CONSTANTS
{
  //Indeces for input patches - these are the oscillator parameters
  public static final int INPATCH_FREQ = 0;
  public static final int INPATCH_AMP = INPATCH_FREQ + 1;
  public static final int TOTAL_INPATCH = INPATCH_AMP + 1;
  
  //No gates
  public static final int TOTAL_GATE = 0;
  
  //Indeces for knobs - same as input patches in this case
  public static final int KNOB_FREQ = 0;
  public static final int KNOB_AMP = KNOB_FREQ + 1;
  public static final int TOTAL_KNOB = KNOB_AMP + 1;
  
  //Indeces for output patches - these are the waveforms
  public static final int OUTPATCH_SINE = 0;
  public static final int OUTPATCH_SQUARE = OUTPATCH_SINE + 1;
  public static final int OUTPATCH_TRIANGLE = OUTPATCH_SQUARE + 1;
  public static final int OUTPATCH_SAW = OUTPATCH_TRIANGLE + 1;
  public static final int OUTPATCH_PHASOR = OUTPATCH_SAW + 1;
  public static final int OUTPATCH_QUARTERPULSE = OUTPATCH_PHASOR + 1;
  public static final int TOTAL_OUTPATCH = OUTPATCH_QUARTERPULSE + 1;
}

public class VCO extends SynthComponent
{
  //Internal UGen Objects that compose the component's "circuit"
  //Summer combines the input patch and knob values when mapping to the same feature
  private Summer totalFrequency;
  private Summer totalAmplitude;
  
  //Oscillators for each knob value (no amplitude or frequency, will rely on the offset)
  private Oscil knob_freq;
  private Oscil knob_amp;
  
  //Oscillators for each wave output
  private Oscil out_sine;
  private Oscil out_square;
  private Oscil out_triangle;
  private Oscil out_saw;
  private Oscil out_phasor;
  private Oscil out_quarterpulse;
  
  //Default Constructor - set up all the patches and knobs
  public VCO()
  {
    //Processing doesn't like a class's own variables passed during construction because
    //  they are not initialized yet (cannot make static in Processing, either)...
    //  Luckily, we can make a static class with the static variables and use them!
    super(VCO_CONSTANTS.TOTAL_INPATCH, VCO_CONSTANTS.TOTAL_OUTPATCH, VCO_CONSTANTS.TOTAL_GATE, VCO_CONSTANTS.TOTAL_KNOB);

    //Now fill in the knobs
    knobs[VCO_CONSTANTS.KNOB_FREQ] = new Knob(0, 6000); //Audible frequencies... 22000 hurts the ears... piano goes to about 4200... let's cap it off just a bit above that
    knobs[VCO_CONSTANTS.KNOB_AMP] = new Knob(0.0, 1.0); //Amplitude is in [0,1]

    //Set up the internals of the component with the UGen elements from Minim
    totalFrequency = new Summer();
    totalAmplitude = new Summer();
    //NOTE: No frequency or amplitude for the output waveforms yet
    knob_freq = new Oscil(0.0, 0.0, Waves.SINE);
    knob_amp = new Oscil(0.0, 0.0, Waves.SINE);
    out_sine = new Oscil(0.0, 0.0, Waves.SINE);
    out_square = new Oscil(0.0, 0.0, Waves.SQUARE);
    out_triangle = new Oscil(0.0, 0.0, Waves.TRIANGLE);
    out_saw = new Oscil(0.0, 0.0, Waves.SAW);
    out_phasor = new Oscil(0.0, 0.0, Waves.PHASOR);
    out_quarterpulse = new Oscil(0.0, 0.0, Waves.QUARTERPULSE);
    
    //With the UGens all setup, fill in the external-facing ones for input/output
    patchIn[VCO_CONSTANTS.INPATCH_FREQ] = totalFrequency;
    patchIn[VCO_CONSTANTS.INPATCH_AMP] = totalAmplitude;
    patchOut[VCO_CONSTANTS.OUTPATCH_SINE] = out_sine;
    patchOut[VCO_CONSTANTS.OUTPATCH_SQUARE] = out_square;
    patchOut[VCO_CONSTANTS.OUTPATCH_TRIANGLE] = out_triangle;
    patchOut[VCO_CONSTANTS.OUTPATCH_SAW] = out_saw;
    patchOut[VCO_CONSTANTS.OUTPATCH_PHASOR] = out_phasor;
    patchOut[VCO_CONSTANTS.OUTPATCH_QUARTERPULSE] = out_quarterpulse;
    
    //Setup the patchwork for the internal components
    knob_freq.patch(totalFrequency);
    knob_amp.patch(totalAmplitude);
    totalFrequency.patch(out_sine.frequency);
    totalFrequency.patch(out_square.frequency);
    totalFrequency.patch(out_triangle.frequency);
    totalFrequency.patch(out_saw.frequency);
    totalFrequency.patch(out_phasor.frequency);
    totalFrequency.patch(out_quarterpulse.frequency);
    totalAmplitude.patch(out_sine.amplitude);
    totalAmplitude.patch(out_square.amplitude);
    totalAmplitude.patch(out_triangle.amplitude);
    totalAmplitude.patch(out_saw.amplitude);
    totalAmplitude.patch(out_phasor.amplitude);
    totalAmplitude.patch(out_quarterpulse.amplitude);
  }
  
  //Implement in each component to do any per-draw-iteration updates
  //  This will usually be setting values based on knobs, etc.
  public void draw_update()
  {
    knob_freq.offset.setLastValue(knobs[VCO_CONSTANTS.KNOB_FREQ].getCurrentValue());
    knob_amp.offset.setLastValue(knobs[VCO_CONSTANTS.KNOB_AMP].getCurrentValue());
  }
}
