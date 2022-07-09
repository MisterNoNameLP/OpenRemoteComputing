# OpenRemoteComputing
ORC is a simple and light weight library to execute scripts on remote computers like drones.

The idea is to setup one or multiple remote computers with this BIOS and never touch the EEPROM ever again.

This is made to get a smooth workflow for developing drone scripts, but can be used for any other PC as well.

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

# Instalation
Flash the [bios_minified.lua](https://raw.githubusercontent.com/MisterNoNameLP/OpenRemoteComputing/main/src/bios/bios_minified.lua) to an eeprom and craft it to your remote computers.

Install [minitel](https://github.com/ShadowKatStudios/OC-Minitel) on the devide you want to use ORC on.

# Usage
At the moment there is only the [orcExample.lua](https://github.com/MisterNoNameLP/OpenRemoteComputing/blob/main/src/client/orcExample.lua) to see how it works.

If there is intresst I am willing to help or make a more detailed documentaion.  
Please open an issue if so.

# Requirements
### Hardware
Remote computers as well as the client needs to have network cards installed.

### Software
For ORC you need to have [minitel](https://github.com/ShadowKatStudios/OC-Minitel) installed on your client PC.  
Please check the minitel page to see how to install it on your OS.

https://github.com/ShadowKatStudios/OC-Minitel

# Approach
The approach is do have 2 execution layers at the remote computers.

The first layer is a simple network BIOS waiting for control streams.
If you connect to a remote computer the BIOS loads a loader script shipped by ORC.

The loader script then handles user requests, library loading as well as some more debugging.

This way you can update ORC without having to modify the BIOS/EEPROM again. Since all advanced things are happening in the loader.

# BIOS
There are 3 variants of the BIOS. The dev version, the export version and the minified one.

The minified version is ready to use and can be flashed to a eeprom to work with the default configuration of ORC.

The export version is a unminified version. It can be used to set custom configurations, but it needs to get [minified](https://goonlinetools.com/lua-minifier/) to fit on a eeprom.  

The dev version includes all debugging features, like printing BIOS debug messages to a screen. 
This is helpful to debug the BIOS, but is to big to fit on a EEPROM, even in a minified version.
To get it fitting you need to remove everything inbetween the `--REMOVE_START` and the `--REMOVE_END` comments and [minifi](https://goonlinetools.com/lua-minifier/) it afterwards.

Minifier: https://goonlinetools.com/lua-minifier/

# Third party
ORC utilizes the [microtel](https://github.com/ShadowKatStudios/OC-Minitel) by ShadowKatStudios to handle the network communication.


