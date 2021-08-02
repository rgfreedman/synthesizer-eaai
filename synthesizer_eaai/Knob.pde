/*Knob.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 August 01

Class for a knob found on a component within a synthesized instrument.  Simply has a 
current position, min/max interval, and ways to compute the value via interpolation 
given a position and the interval.
*/

public class Knob
{
  //The values that a knob can represent
  private float minimumValue = 0.0;
  private float maximumValue = 1.0;
  private float currentValue = 0.0;
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
    setCurrentPosition(0.0);
  }
  
  //Accessor methods
  public float getMinimumValue() {return minimumValue;}
  public float getMaximumValue() {return maximumValue;}
  public float getCurrentValue() {return currentValue;}
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
    
    //Before leaving, also change the value to return (more efficient to compute upon 
    //  change than during each accessor call)
    //Yes, the position part currently simplifies to currentPosition, but using the 
    //  generalized version just-in-case it changes later
    currentValue = minimumValue + ((maximumValue - minimumValue) * ((currentPosition - MINIMUM_POSITION) / (MAXIMUM_POSITION - MINIMUM_POSITION)));
    
    return currentPosition;
  }
}
