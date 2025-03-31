# Blow Boat

## Overview

This project was developed to illustrate the mechanic of combining two sine waves. It uses a CPU computations to calculate the height of the wave at multiple coordinates, as well as the GPU to render the visuals by impmplementing VERTEX and FRAGMENT shaders. 

A simple game of tug of war. The demo is configued to allow two users to enter their desired wave configuration. Once the wave configuration is locked in the users can use a sensor to aid in getting the boat to the opposite side.

![[https://github.com/mjrevel/blowboat/blob/main/images/blowboat1.png?raw=true]]

Resources and Inspiration:

[Nvidia GPU Gems - Effective Water Simulation Physical Models](https://developer.nvidia.com/gpugems/gpugems/part-i-natural-effects/chapter-1-effective-water-simulation-physical-models)

[Acerola - How Games Fake Water](https://www.youtube.com/watch?v=PH9q0HNBjT4)

[Crigz Vs Game Dev - How to make things float in Godot 4](https://www.youtube.com/watch?v=_R2KDcAp1YQ)

## How To Play

You can play with or without the sensors hooked up.

### With Sensors

Depending on your machines configuration you may need to modify the serial port being monitored.

To modify the port navigate to the file ocean.gd and modify the port and baud rate.

```
serial.open("/dev/ttyACM0", 115200)
```

### Without Sensors

Open the project in Godot and click the "play" button
