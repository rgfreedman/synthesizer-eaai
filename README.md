# synthesizer-eaai
Modular Synthesizer Application for the 2023 EAAI Mentored Undergraduate Research Challenge

For more information about the challenge, please visit https://www.yetanotherfreedman.com/resources/challenge_haaisam.html

If you use this software in any form; including but not limited to research, music generation/recording, performance, and producing a software derivation; please provide credit to Richard (Rick) G. Freedman and the 2023 EAAI Mentored Undergraduate Research Challenge.  Even if you do not use this software as a participant in the challenge, spreading the word about the challenge would be appreciated to ensure that undergraduate students around the world have an opportunity to participate if they would be interested and did not happen to know about it.

## Setup

This program is written in the [Processing](https://processing.org/) programming language and uses the [Minim](http://code.compartmental.net/tools/minim/) library without any modifications.  Running and editing Processing programs are typically done in the IDE that comes with their application.  The recommended setup to open, modify, and run this software are:
1. Download a stable release of Processing for your operating system: https://processing.org/download .
2. Install Processing on your computer after the download completes.
3. Open the Processing application.
4. Depending on the version of Processing you chose (there is a stable release for 2, 3, and 4), follow the respective directions at http://code.compartmental.net/tools/minim/ to get Minim as an available Processing library.
5. Download or clone this repository on your computer.
6. In the Processing application, got to `File` and click `Open...`.  A window for choosing a file should appear.
7. Navigate the window until you find your copy of the repository.  Within it, select the file named `synthesizer_eaai.pde` within the `synthesizer_eaai` directory.
8. This selection will open the entire project, which includes all `.pde` files in the directory.  Each file will be its own tab in the application.  If there are too many tabs (`synthesizer_eaai.pde` has a lot of `.pde` files), then the downdrop at the far-right of the tabs will list all the files available for selection.
9. If you wish to modify any of the code, then scroll through the tabs to find the file you want to modify.  Simply type your code and then save your work with the traditional `File` and `Save`---saving saves the *entire project*, which is all the `.pde` files in the directory.
10. If you want to run the program, then go to `Sketch` and click `Run`.  As a shortcut, there is also a `Run` button in the application that looks like a traditional "Play" button.
11. When you are done running the program, go to `Sketch` and click `Stop`.  As a shortcut, there is also a `Stop` button in the application that looks like a traditional "Stop" button.

**NOTE**: Editing the code in this project is independent of editing the code in Minim, and care must be taken if anyone wishes to make changes to both.  This software only imports Minim as a library and uses its classes, methods, and API without any modification.  Because Minim is licensed under the [GNU LESSER GENERAL PUBLIC LICENSE](https://www.gnu.org/licenses/lgpl-3.0-standalone.html), this distinction matters because it grants this software an exception from having to use a GNU GPL-based license.  The `synthesizer_eaai` project is under the [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0), which would be an incompatability conflict without this exception.

## Running the Modular Synthesizer

Once the program is running, a graphical user interface (GUI) will appear.  A human user may interact directly with this interface using the mouse and keyboard.  The control scheme include:
* Left clicking the mouse on a dark circle has one of two uses:
  * If the dark circle is part of the `Add Module` module, then the instrument will add a new module corresponding to the label above the selected circle.  The new module will appear in place of the `Add Module` module, shifting it over one module.
  * If the dark circle is part of any other module, then the instrument will attempt to create a patch (wire connecting inputs and outputs between various modules).  To complete the patch successfully, hold down the left mouse and drag the cursor to another dark circle.  Releasing the left mouse over this other dark circle will insert the patch if it is valid---one end must be an input (the left side of a module) while the other end must be an output (the right side of a odule).  The `Keyboard` module at the bottom of the screen is a special case because all of its dark circles, despite being on the left, are outputs.  The patch was successful if there is now a cyan line connecting the two dark circles and the circles contain a cyan fill.
* Left clicking the mouse on a cyan circle that fills a dark circle will allow the selected patch to be moved.  Similar to creating a new patch, hold down the left mouse and drag the cursor to another dark circle.  Releasing the left mouse over this dark circle will change the placement of the cyan circle and move the line connecting modules.  Like before, one end of each patch must be an input while the other must be an output.
* Right clicking the mouse on various things will remove them from the instrument:
  * Right clicking on either of the cyan circles at the endpoints of a patch will delete that patch.
  * Right clicking on the maroon rectangle at the bottom of a module will delete that module.  All patches with at least one end plugged into the deleted module will also be deleted.
* Left clicking the mouse on a red rectangle that crosses over a light rectangle enables manipulating a slider.  The red rectangle shows the current position along the light rectangle, and the value of that slider is proportional to the distance between the two ends.  Sliders print their lowest and greatest values on their extremes, and this can help to interpret how to evaluate the slider's position.
* The top row of the computer keyboard can switch between instruments (sets of modules) if the software supports that many instruments.  Due to computational limits, there might be fewer than the 16 possible instruments (the repository cuts it down to 2 since a ten-year-old laptop was struggling with 3 or more instruments).  The first instrument is `~`, the second is `1`, the third is `2`, and so forth up to `=` as the thirteenth; then fourteenth is `[`, fifteenth is `]`, and sixteenth is `\`.  If that instrument does not exist, then nothing will happen.
* The `Keyboard` module presents some computer keys on the virtual music keyboard, and pressing any of these computer keys will press its corresponding virtual music key.
  * Each set of computer keys is allocated for one of the hands.  The left hand has `q, w, e, r, t, a, s, d, f, z, x, c, v` while the right hand has `y, u, i, o, p, j, k, l, ;, m, ,, ., /`.
  * To scroll the left hand to the left on the virtual music keyboard, press the `g` computer key; `G` will scroll the left hand by 6 keys instead of 1.  To scroll the left hand to the right on the virtual music keyboard, press the `b` computer key; `B` will scroll the left hand by 6 keys instead of 1.
  * To scroll the right hand to the left on the virtual music keyboard, press the `h` computer key; `H` will scroll the left hand by 6 keys instead of 1.  To scroll the left hand to the right on the virtual music keyboard, press the `n` computer key; `N` will scroll the left hand by 6 keys instead of 1.

## Programming the Modular Synthesizer

To control the instruments with a computer, methods are included in the file `InteractiveAgent.pde`.

The `setup_agent()` and `draw_agent()` methods run during the Processing program's `setup()` and `draw()` method calls.  `setup_agent()` is useful for creating any data structures and pre-loading information that will useful during program execution.  `draw_agent()` will be called every frame during program execution, which makes it ideal for making decisions about what to do and send commands to the modular synthesizer.

There are a variety of `report...` methods that run whenever the respective interaction with the interface occurs.  For the interactive intelligent agent, these are particularly useful when they specify that the human did the interaction with the GUI.  If the agent does not care about some of the specified human interactions, then the methods can be left blank as they currently are now.

A planned upcoming update to this project will include socket support to run interactive intelligent agent programs in other languages.  The `setup_agent()`, `draw_agent()`, and all `report...` methods will contain code in the update to broadcast and receive information over sockets.  So this file will still be useful even if one does not intend to program their agent in the Processing programming language.

## Troubleshooting

* Pressing keys on the computer keyboard does not produce any sounds.
  1. The default instrument has no modules with any connecting patches.  Be sure to create some patches that connect the `Keyboard` module to the `Mixer (Speaker)` module.
  2. Patching the `Keyboard` module directly to the `Mixer (Speaker)` module will not produce any sound because the `Keyboard` outputs control voltage (CV) rather than a sound wave.  CV does not oscillate, but the oscillation property of a sound wave is necessary to hear anything.  A component that produces oscillating sound waves is the `Voltage-Controlled Oscillator` (VCO).
  3. If the patches are all connected correctly with an oscillator along the path, then check that volume and amplitudes are *not* set to 0.  Most of the sliders start at 0, but no volume or amplitude silences the output.
* Things are sounding very crunchy, and not in a good way.
  1. Unlike a real modular synthesizer that runs on electrical wires and physics, this virtual modular synthesizer runs on a CPU computing numbers.  If there are too many modules or the patch is complex enough, then the computer will struggle to keep up with the framerate and the sound will degrade or fail.  Unfortunately, please try a simpler instrument design.
  2. If the simpler instrument design does not fix the problem, then your computer might not be able to handle playing multiple keys on the keyboard at once (each key duplicates most the instrument, eating up more CPU cycles) or multiple instruments at once.  The variables to change in the code to reduce these numbers are `Keyboard_CONSTANTS.TOTAL_PATCHOUT` in `Keyboard.pde` and `MAX_INSTRUMENTS` in `synthesizer_eaai.pde`, respectively.  Do not worry, the code works with those changed variables alone and will not need additional changes to run.  Remember to stop the program and start running it again to update the variable values.
  3. When all else fails, try stopping the program and starting it again.

## Planned Upcoming Updates

Features will not be removed, but some additional ones are planned to be added for undergraduate students to have some additional options during the 2023 EAAI Mentored Undergraduate Research Challenge.  In case it helps students prepare, the expected updates will include:
* Saving and loading instrument designs (currently, one needs to add all modules, place all patches, and drag all knobs every time the software runs)
* Socket support to enable communications with programs written in other languages

There are also plenty of additional parts of the Minim library that are not yet accessible via this software's GUI.  Some include being able to record the generated audio to a file, other modules like samplers and vocoders, and sound wave analysis methods.  These may be incrementally added over time, but are not guaranteed.  If you are participating in the challenge and are on a registered team, then you may contact Rick Freedman with requests for specific features that would be useful for your research project.  If they are feasible, then those feature requests will be given priority for future updates.
