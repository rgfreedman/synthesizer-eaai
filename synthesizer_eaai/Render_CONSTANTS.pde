/*Render_CONSTANTS.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2021 November 27

Class for constants that affect rendering components on the screen; edit the assigned
values to alter how things display on the screen.
*/

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the VCO class below
public static class Render_CONSTANTS
{
  //Define the screen width and height here
  //NOTE: Processing requires magic numbers directly, not even static final variables work
  //      This means that changing these numbers will NOT resize the application;
  //      must change here and in the size(...) command
  public static final int APP_WIDTH = 1000;
  public static final int APP_HEIGHT = 800;
  
  //Border about the components (to allow menu, keyboard display, output, and other
  //  details that are per instrument or application, not a component itself)
  //NOTE: Defined as a proportion of the screen size
  public static final int UPPER_BORDER_WIDTH = APP_WIDTH;
  public static final int UPPER_BORDER_HEIGHT = APP_HEIGHT / 32;
  
  public static final int LOWER_BORDER_WIDTH = APP_WIDTH;
  public static final int LOWER_BORDER_HEIGHT = (APP_HEIGHT * 3) / 16;
  
  public static final int LEFT_BORDER_WIDTH = APP_WIDTH / 8;
  public static final int LEFT_BORDER_HEIGHT = APP_HEIGHT;
  
  public static final int RIGHT_BORDER_WIDTH = APP_WIDTH / 8;
  public static final int RIGHT_BORDER_HEIGHT = APP_HEIGHT;
  
  //For tiling components within an instrument: limits total components unless scrolling
  //  is added as a later feature
  public static final int TILE_HORIZ_COUNT = 5;
  public static final int TILE_VERT_COUNT = 2;
  
  //An assumed limit to the number of in-patches, knobs, or out-patches in a single component
  public static final int MAX_IN_PATCH = 9;
  public static final int MAX_OUT_PATCH = MAX_IN_PATCH;
  public static final int MAX_KNOB = 9;
  
  //Uses static information above to do precomputations of component size information
  //NOTE: Do not edit these equations unless designing a new layout scheme
  public static final int COMPONENT_WIDTH = (APP_WIDTH - LEFT_BORDER_WIDTH - RIGHT_BORDER_WIDTH) / TILE_HORIZ_COUNT;
  public static final int COMPONENT_HEIGHT = (APP_HEIGHT - UPPER_BORDER_HEIGHT - LOWER_BORDER_HEIGHT) / TILE_VERT_COUNT;
  
  //Sizes of the patches (circles) and knobs (rectangles, portray as a slider)
  //NOTE: Double number of max patches/knobs to account for their labels
  public static final int PATCH_DIAMETER = min(COMPONENT_HEIGHT / (2 * (MAX_IN_PATCH + 1)), COMPONENT_WIDTH / 4);
  public static final int PATCH_RADIUS = PATCH_DIAMETER / 2;
  public static final int KNOB_WIDTH = (COMPONENT_WIDTH * 2) / 5;
  public static final int KNOB_HEIGHT = min(COMPONENT_HEIGHT / (2 * (MAX_KNOB + 1)), COMPONENT_WIDTH / 4);
  
  //Size of patch cable parts (filling of hole and cord thickness)
  public static final int PATCH_PLUG_DIAMETER = max((PATCH_DIAMETER * 7) / 8, 5);
  public static final int PATCH_PLUG_RADIUS = PATCH_PLUG_DIAMETER / 2;
  public static final int PATCH_CORD_WIDTH = min(PATCH_PLUG_RADIUS / 2, 5);
  
  //Checked Processing Reference Manual => default stroke weight is 4 (need to undo setting PATCH_CORD_WIDTH)
  //  Citation: https://processing.org/reference/strokeWeight_.html
  public static final int DEFAULT_STROKE_WEIGHT = 4;
  
  //Size of cursor for the slider-representation of a knob
  //NOTE: Ensure a minimum width since it could become 0
  public static final int KNOB_CURSOR_WIDTH = max(KNOB_WIDTH / 10, 5);
  public static final int KNOB_CURSOR_HEIGHT = max((KNOB_HEIGHT * 6) / 5, KNOB_HEIGHT + 10);
  
  //Some vertical spacing between patches/knobs in the same column
  public static final int VERT_SPACE = min(KNOB_HEIGHT, PATCH_DIAMETER) / 10;
  
  //Keyboard key sizes (NATURAL is a white-colored key, HALFTONE is a black-colored key)
  public static final int KEYBOARD_NATURAL_TOTAL = 52;
  public static final int KEYBOARD_HALFTONE_TOTAL = 36;
  public static final int KEYBOARD_KEYS_TOTAL = KEYBOARD_NATURAL_TOTAL + KEYBOARD_HALFTONE_TOTAL;
  public static final int KEYBOARD_NATURAL_OCTAVE = 7;
  public static final int KEYBOARD_HALFTONE_OCTAVE = 5;
  public static final int KEYBOARD_NATURAL_WIDTH = (LOWER_BORDER_WIDTH - LEFT_BORDER_WIDTH - RIGHT_BORDER_WIDTH) / KEYBOARD_NATURAL_TOTAL;
  public static final int KEYBOARD_NATURAL_HEIGHT = (LOWER_BORDER_HEIGHT * 5) / 8;
  public static final int KEYBOARD_HALFTONE_WIDTH = (KEYBOARD_NATURAL_WIDTH * 2) / 3;
  public static final int KEYBOARD_HALFTONE_HEIGHT = KEYBOARD_NATURAL_HEIGHT / 2;
  public static final int KEYBOARD_HALFTONE_HORIZ_OFFSET = KEYBOARD_NATURAL_WIDTH / 3;
  public static final int KEYBOARD_HALFTONE_VERT_OFFSET = 0;
}
