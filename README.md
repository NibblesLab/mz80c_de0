MZ-80C on FPGA
=============

What is this?
-------------------
This is a implementation Sharp MZ-80 series to FPGA.

Requirements
--------------------
* Altera(Terasic) DE0 board
* Quartus II (I use 11.0 sp1)
* SD, SDHC or MMC card

How to reproduction project
----------------------------------------
1. Download [zip](https://github.com/NibblesLab/mz80c_de0/archive/master.zip) file.
* Create folder to build project in your PC.
* Put these files in zip to folder.
    * logic/
    * internal\_sram\_hw.tcl
    * internal\_sram2\_hw.tcl
    * internal\_sram8\_hw.tcl
    * mz80c.cdf
    * mz80c.pin
    * mz80c.qsf
    * mz80c.sdc
    * mz80c\_de0.qpf
    * mz80c\_de0\_sopc.sopc
* Start Quartus II.
* Open project. File->Open Project...->mz80c_de0.qpf
* Start SOPC Builder. Tools->SOPC Builder
* Push Ganerate button in SOPC Builder.
* When generate successfully, exit SOPC Builder.
* Start Compilation at Quartus II.
* Program to DE0 board with mz80c.pof.
* Start NiosII EDS. Tools->Nios II Software Build Tools for Eclipse
* When does PC ask workspace, push OK as it is.
* Create new application and BSP. File->New->Nios II Application and BSP from Template
* Set parameters and push Finish button.
    * SOPC Information File name:->mz80c\_de0\_sopc.sopcinfo
    * CPU name:->cpu\_0
    * Project name:->mz80c\_de0\_soft
    * Project template->Hello World
* Put these files in zip(software/mz80c\_de0\_soft/*) to software/mz80c\_de0\_soft folder.
    * diskio.c
    * diskio.h
    * ff.c
    * ff.h
    * ffconf.h
    * file.c
    * file.h
    * integer.h
    * key.c
    * key.h
    * menu.c
    * menu.h
    * mz80c\_de0\_main.c
    * mz80c\_de0\_main.h
    * mzctrl.c
    * mzctrl.h
* Delete hello\_world.c.
* At Project Explorer, expand mz80c\_de0\_soft, then right-click and select Refresh(F5).
* Build project. Project->Build All
* Program to DE0 board with mz80c\_de0\_soft.elf.
* Put the files in CARD folder to SD/MMC card.
* Set card to slot, SW5 is ON(upper), then push power-switch off-on.

Special thanks to ...
-----------------------------
* Z80 core ''T80'' from OpenCores by Wllnar, Daniel and MikeJ
* ''Looks like font'' from [MZ700WIN](http://retropc.net/mz-memories/) by marukun
* [MZ-NEW MONITOR](http://retropc.net/mz-memories/mz700/kyodaku.html) by Takeharu Takada and Kenji Machida from Musasino Mycom Club
* [FatFs module](http://elm-chan.org/fsw/ff/00index_j.html) by ChaN
* [Japan Andriod Group Kobe](http://sites.google.com/site/androidjpkobe/)