/*
 * file.c
 *
 *  Created on: 2012/05/17
 *      Author: ohishi
 */
#include "system.h"
#include "alt_types.h"
#include <stdio.h>
#include "string.h"
#include "altera_avalon_pio_regs.h"
#include "mz80c_de0_main.h"
#include "mzctrl.h"
#include "ff.h"

extern FATFS fs;
extern DIR dirs;
extern FILINFO finfo;
extern unsigned char fname[13];

void direct_load(void)
{
	FIL fobj;
	FRESULT res;
	UINT i,r,size,dtadr;
	unsigned char buf[65536];

	// File Read
	res=f_open(&fobj, (TCHAR*)fname, FA_OPEN_EXISTING | FA_READ);
	res=f_read(&fobj, buf, 65536, &r);
	res=f_close(&fobj);

	IOWR_ALTERA_AVALON_PIO_DATA(PAGE_BASE,0);	// Set Page
	for(i=0;i<128;i++){	// Information
		((volatile unsigned char*)(INTERNAL_SRAM2_0_BASE+0x10f0*2))[i*2]=buf[i];
	}
	size=(buf[0x13]<<8)+buf[0x12];
	dtadr=((buf[0x15]<<8)+buf[0x14])*2;
	for(i=0;i<size;i++){	// Body
		((volatile unsigned char*)(INTERNAL_SRAM2_0_BASE+dtadr))[i*2]=buf[128+i];
	}
}
