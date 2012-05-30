/*
 * MZ-80C on FPGA (Altera DE0 version)
 * Main module
 *
 * (c) Nibbles Lab. 2012
 *
 */

#include "system.h"
#include <stdio.h>
#include "unistd.h"
#include "altera_avalon_pio_regs.h"
#include "sys/alt_irq.h"
#include "diskio.h"
#include "mz80c_de0_main.h"
#include "mzctrl.h"
#include "key.h"
#include "menu.h"
#include "file.h"
#include "ff.h"

extern volatile z80_t z80_status;

// FatFs Globals
FATFS fs;
DIR dirs;
FILINFO finfo;
unsigned char fname[13];

int main()
{
	//unsigned int x,y;
	int k;

	// Interrupt regist
	button_int_regist();
	key_int_regist();

	f_mount(0,&fs);

	// Start MZ
	MZ_release();

	/* Event loop never exits. */
	while (1){
		// Wait MENU Button
		while(z80_status.status==0);

		// Z80-Bus request
		MZ_Brequest();
		do {
			k=menu(0,0,0);	// Root menu
			switch(k){
			case 3:
				direct_load();
			default:
				break;
			}
			break;
		}while(1);
		z80_status.status=0;

		// Z80-Bus release
		MZ_Brelease();
	}

	return 0;
}
