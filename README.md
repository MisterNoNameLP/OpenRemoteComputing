# OpenRemoteComputing
ORC is a library to execute scripts on remote computers.

The idea is to setup one or multiple remote computers (like drones) with this BIOS and never touch the EEPROM ever again.

# Features
### Execute scripts 
With ORC you are be able to execute scripts with any size. 
You can execute files as well as strings.

### Libary loading
With ORC you are be able to load libraries for later use. 
This way you can easly execute complex programms on your remote computers.

### Debugging
With ORC you have a print function avaiable on the remote computers per default.
The prints can be printet on screen and are accesibe as log at the ORC client.

ORC has multiple layers of debugging logs.
Giving you detailed information about whats going on (see [orcExample.lua](https://github.com/MisterNoNameLP/OpenRemoteComputing/blob/main/src/client/orcExample.lua)).

# Usage
### BIOS 
Flash the bios_minified.lua to an eeprom. 

### Client
At the moment there is only the [orcExample.lua](https://github.com/MisterNoNameLP/OpenRemoteComputing/blob/main/src/client/orcExample.lua) to see how it works.

If there is intresst I am willing to help or make a more detailed documentaion.  
Please open an issue if so.

# Approach
The approach is do have 2 execution layers at the remote computers.

The first layer is a simple network BIOS waiting for control streams.
If you connect to a remote computer the BIOS loads a loader script shipped by ORC.

The load script then handles user requests, library loading as well as some more debugging.

This way you can update ORC without having to modify the BIOS/EEPROM again. Since all advanced things are happening in the loader.

# Requirements
### Hardware
Remote computers as well as the client needs to have network cards installed.

### Software
For ORC you need to have [minitel](https://github.com/ShadowKatStudios/OC-Minitel) installed on your client PC.  
Please check the minitel page to see how to install it on your OS.

https://github.com/ShadowKatStudios/OC-Minitel

# Third party
ORC utilizes the [microtel](https://github.com/ShadowKatStudios/OC-Minitel) by ShadowKatStudios.


