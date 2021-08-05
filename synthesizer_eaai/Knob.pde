/*Knob.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 August 05

Class for a knob found on a component within a synthesized instrument.  Simply has a 
current position, min/max interval, and ways to compute the value via interpolation 
given a position and the interval.
*/

public class Knob
{
  //The values that a knob can represent
  private float minimumValue = 0.0;
  private float maximumValue = 1.0;
  //The actual value will be the offset of an oscillator to pass along for frequency modulation
  private Oscil currentValue;
  //The position along [0,1] that the knob is currently turned
  protected float currentPosition = 0.0;
  private final float MINIMUM_POSITION = 0.0;
  private final float MAXIMUM_POSITION = 1.0;
  
  //Default constructor - assign dummy values [0,1] with position at minimum value
  public Knob()
  {
    minimumValue = 0.0;
    maximumValue = 1.0;
    setCurrentPosition(MINIMUM_POSITION);
    //Current value is a 0-amplitude oscillator whose offset is the interpolated current position
    currentValue = new Oscil(0.0, 0.0, Waves.SINE);
    currentValue.offset.setLastValue(minimumValue); //Minimum position => minimum value
  }
  
  //Typical constructor - assign interval values [0,1] with position at minimum value
  /*Parameters:
      (double) minVal = minimum value that the knob can represent
      (double) maxVal = maximum value that the knob can represent
  */
  public Knob(float minVal, float maxVal)
  {
    minimumValue = minVal;
    maximumValue = maxVal;
    setCurrentPosition(MINIMUM_POSITION);
    //Current value is a 0-amplitude oscillator whose offset is the interpolated current position
    currentValue = new Oscil(0.0, 0.0, Waves.SINE);
    currentValue.offset.setLastValue(minimumValue); //Minimum position => minimum value
  }
  
  //Accessor methods
  public float getMinimumValue() {return minimumValue;}
  public float getMaximumValue() {return maximumValue;}
  public Oscil getCurrentValue() {return currentValue;}
  public float getCurrentPosition() {return currentPosition;}
  public float getMinimumPosition() {return MINIMUM_POSITION;}
  public float getMaximumPosition() {return MAXIMUM_POSITION;}
  
  //Mutator methods - only the current position can actually change
  public float setCurrentPosition(float newPos)
  {
    //Make sure the proposed position is within the specified interval, else set to
    //  the closest of the lower/upper bounds
    if(newPos < MINIMUM_POSITION)
    {
      currentPosition = MINIMUM_POSITION;
    }
    else if(newPos > MAXIMUM_POSITION)
    {
      currentPosition = MAXIMUM_POSITION;
    }
    else
    {
      currentPosition = newPos;
    }
    
    //Before leaving, also change the value (more efficient to compute upon 
    //  change than during each accessor call)
    //Yes, the position part currently simplifies to currentPosition, but using the 
    //  generalized version just-in-case it changes later
    if(currentValue != null) //Setup timing might not have the oscillator initialized yet... wait until it exists
    {
      currentValue.offset.setLastValue(minimumValue + ((maximumValue - minimumValue) * ((currentPosition - MINIMUM_POSITION) / (MAXIMUM_POSITION - MINIMUM_POSITION))));
    }
    
    return currentPosition;
  }
}