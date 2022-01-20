/*Knob.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2022 January 20

Class for a knob found on a module within a synthesized instrument.  Simply has a 
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
  //The rendering information that is not built-in to Render_CONSTANTS class
  private int topLeftX = Render_CONSTANTS.INVALID_VALUE;
  private int topLeftY = Render_CONSTANTS.INVALID_VALUE;
  
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
  //Accessor that gets the current value of the knob as a number, needed in at least ADSR envelope
  //Yes, the position part currently simplifies to currentPosition, but using the 
  //  generalized version just-in-case it changes later
  public float getCurrentValue_float() {return minimumValue + ((maximumValue - minimumValue) * ((currentPosition - MINIMUM_POSITION) / (MAXIMUM_POSITION - MINIMUM_POSITION)));}
  
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
  
  //Renders the knob, including the sliding cursor
  //NOTE: Renders locally (within the slider's rectangle); need global coordinates for offset
  public void render(int xOffset, int yOffset)
  {
    //Store the offsets as the top-left coordinate position for the knob
    topLeftX = xOffset;
    topLeftY = yOffset;
    
    //The slider itself is a white rectangle
    stroke(255, 255, 255);
    fill(255, 255, 255);
    rect(xOffset, yOffset, Render_CONSTANTS.KNOB_WIDTH, Render_CONSTANTS.KNOB_HEIGHT);
    
    //The cursor is a red rectangle of different dimensions relative to the slider
    //NOTE: The position is for the top-left corner, but the position info assumes center
    stroke(255, 0, 0);
    fill(255, 0, 0);
    rect(xOffset + (int)(currentPosition * Render_CONSTANTS.KNOB_WIDTH) - (Render_CONSTANTS.KNOB_CURSOR_WIDTH / 2), yOffset - ((Render_CONSTANTS.KNOB_CURSOR_HEIGHT - Render_CONSTANTS.KNOB_HEIGHT) / 2), Render_CONSTANTS.KNOB_CURSOR_WIDTH, Render_CONSTANTS.KNOB_CURSOR_HEIGHT);
    
    //Lastly, print the interval of values for reference (at the ends of the slider)
    fill(0, 0, 0);
    textAlign(LEFT, CENTER);
    text("" + minimumValue, xOffset, yOffset + (Render_CONSTANTS.KNOB_HEIGHT / 2));
    textAlign(RIGHT, CENTER);
    text("" + maximumValue, xOffset + Render_CONSTANTS.KNOB_WIDTH, yOffset + (Render_CONSTANTS.KNOB_HEIGHT / 2));
    
    //Return the text alignment to its traditional setting
    textAlign(CENTER, CENTER);
  }
  
  //Reverse engineering of the rendering process to identify if this knob has the focus
  //  (it is at some pixel location)
  //NOTE: The inputs x and y are relative to the top-left corner of this Knob
  public boolean contains_point(int x, int y)
  {
    //Simply check if the rectangle for the slider or the rectangle for the cursor contains the point
    if(Render_CONSTANTS.rect_contains_point(0, 0, Render_CONSTANTS.KNOB_WIDTH, Render_CONSTANTS.KNOB_HEIGHT, x, y) ||
       Render_CONSTANTS.rect_contains_point((int)(currentPosition * Render_CONSTANTS.KNOB_WIDTH) - (Render_CONSTANTS.KNOB_CURSOR_WIDTH / 2), -1 * ((Render_CONSTANTS.KNOB_CURSOR_HEIGHT - Render_CONSTANTS.KNOB_HEIGHT) / 2), Render_CONSTANTS.KNOB_CURSOR_WIDTH, Render_CONSTANTS.KNOB_CURSOR_HEIGHT, x, y))
    {
      return true;
    }
    else
    {
      return false;
    }
  }
  
  //Also need to know the rectangle (without the slider) information for position calculations
  //Knob's rectangle's top-left coordinate's X-value
  public int getTopLeftX()
  {
    return topLeftX;
  }
  //Knob's rectangle's top-left coordinate's Y-value
  public int getTopLeftY()
  {
    return topLeftY;
  }
  //Knob's rectangle's width
  public int getWidth()
  {
    return Render_CONSTANTS.KNOB_WIDTH;
  }
  //Knob's rectangle's height
  public int getHeight()
  {
    return Render_CONSTANTS.KNOB_HEIGHT;
  }
}
