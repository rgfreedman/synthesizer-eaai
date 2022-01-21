/*Audio_CONSTANTS.pde

Written by: Richard (Rick) G. Freedman
Last Updated: 2022 January 21

Class for constants that affect audio values; edit the assigned values to alter sound options.

---------------------------------------------------------------------
Copyright 2022 Richard (Rick) G. Freedman

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

//Processing only allows static content in a static class (rather than mixing)
//  This contains the static constants for the VCO class below
public static class Audio_CONSTANTS
{
  public static final float MIN_FREQ = 0.0; //Acts like "hear nothing"
  public static final float MAX_FREQ = 7040.0; //Audible frequencies... 22000 hurts the ears... piano goes to about 4200... let's cap it off just a bit above that at supposed note A8
  public static final float MAX_VOLT = 5.0; //Voltage value assigned to MAX_FREQ, which can vary (NOTE: Using Hertz/volt conversion, NOT volt/octave)
  public static final float MIN_VOLT = 0.0; //Voltage value assigned to MIN_FREQ, which can vary (NOTE: Using Hertz/volt conversion, NOT volt/octave)
}
