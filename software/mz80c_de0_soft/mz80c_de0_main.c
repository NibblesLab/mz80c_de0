/*
 * MZ-80C on FPGA (Altera DE0 version)
 * Main module
 *
 * (c) Nibbles Lab. 2012
 *
 */

#include "system.h"
#include <stdio.h>
#include <string.h>
#include "unistd.h"
#include "integer.h"
#include "altera_avalon_pio_regs.h"
#include "sys/alt_irq.h"
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
char fname[13];

void ROM_read(char *buffer, char *data)
{
	FIL fobj;
	FRESULT res;
	UINT r;

	res=f_open(&fobj, buffer, FA_OPEN_EXISTING | FA_READ);
	if(res==FR_OK){
		res=f_read(&fobj, data, 4096, &r);
		res=f_close(&fobj);
	}
}

void System_Initialize(void)
{
	char SecName[8],buffer[512],data[4096];
	unsigned char *monrom,*fdrom,*cgrom,*keymap;
	UINT i;
	ROMS_t *romdata=(ROMS_t *)(CFI_FLASH_0_BASE+0x100000);

	// Interrupt regist
	button_int_regist();
	key_int_regist();

	f_mount(0,&fs);

	IOWR_ALTERA_AVALON_PIO_DATA(PAGE_BASE,0);	// Set Page
	// Extended ROM
	for(i=0;i<2048;i++){	// $E800-$EFFF
		((volatile unsigned char*)(INTERNAL_SRAM2_0_BASE+0xe800))[i*2]=romdata->ex[i];
	}
	switch(IORD_ALTERA_AVALON_PIO_DATA(PIO_0_BASE)&0x300){
	case 0x000:
	case 0x100:
	case 0x200:
		monrom=romdata->mon80c;
		fdrom=romdata->fd80c;
		cgrom=romdata->char80c;
		keymap=romdata->key80c;
		break;
	default:
		monrom=romdata->mon80a;
		fdrom=romdata->fd80a;
		cgrom=romdata->char80a;
		keymap=romdata->key80a;
		break;
	}
	// Monitor, FD I/F ROM
	for(i=0;i<4096;i++){	// $0000-$0FFF
		((volatile unsigned char*)(INTERNAL_SRAM2_0_BASE))[i*2]=monrom[i];
		((volatile unsigned char*)(INTERNAL_SRAM2_0_BASE+0xf000))[i*2]=fdrom[i];
	}
	// CG ROM
	for(i=0;i<2048;i++){	// (0xc800-0xcfff)
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xc800))[i]=cgrom[i];
	}
	// Key Map Data
	for(i=0;i<256;i++){	// (0xc000-0xc0ff)
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xc000))[i]=keymap[i];
	}

	if(IORD_ALTERA_AVALON_PIO_DATA(PIO_0_BASE)&0x20){
		// Select Section Name by MZ mode
		switch(IORD_ALTERA_AVALON_PIO_DATA(PIO_0_BASE)&0x300){
		case 0x000:
			strcpy(SecName, "MZ-80K");
			break;
		case 0x100:
			strcpy(SecName, "MZ-1200");
			break;
		case 0x200:
			strcpy(SecName, "MZ-80C");
			break;
		default:
			strcpy(SecName, "MZ-80A");
			break;
		}

		// Monitor
		GetPrivateProfileString(SecName, "MROM", "NULL", buffer, "system.ini");
		if(strcmp(buffer,"NULL")==0)
			GetPrivateProfileString("COMMON", "MROM", "NULL", buffer, "system.ini");
		if(strcmp(buffer,"NULL")!=0){
			ROM_read(buffer, data);
			for(i=0;i<4096;i++){	// $0000-$0FFF
				((volatile unsigned char*)(INTERNAL_SRAM2_0_BASE))[i*2]=data[i];
			}
		}
		// Extended ROM
		GetPrivateProfileString(SecName, "EXROM", "NULL", buffer, "system.ini");
		if(strcmp(buffer,"NULL")==0)
			GetPrivateProfileString("COMMON", "EXROM", "NULL", buffer, "system.ini");
		if(strcmp(buffer,"NULL")!=0){
			for(i=0;i<2048;i++) data[i]=0xff;
			ROM_read(buffer, data);
			for(i=0;i<2048;i++){	// $E800-$EFFF
				((volatile unsigned char*)(INTERNAL_SRAM2_0_BASE+0xe800))[i*2]=data[i];
			}
		}
		// FD I/F ROM
		GetPrivateProfileString(SecName, "FDROM", "NULL", buffer, "system.ini");
		if(strcmp(buffer,"NULL")==0)
			GetPrivateProfileString("COMMON", "FDROM", "NULL", buffer, "system.ini");
		if(strcmp(buffer,"NULL")!=0){
			for(i=0;i<4096;i++) data[i]=0xff;
			ROM_read(buffer, data);
			for(i=0;i<4096;i++){	// $F000-$FFFF
				((volatile unsigned char*)(INTERNAL_SRAM2_0_BASE+0xf000))[i*2]=data[i];
			}
		}
		// CG ROM
		GetPrivateProfileString(SecName, "CGROM", "NULL", buffer, "system.ini");
		if(strcmp(buffer,"NULL")==0)
			GetPrivateProfileString("COMMON", "CGROM", "NULL", buffer, "system.ini");
		if(strcmp(buffer,"NULL")!=0){
			ROM_read(buffer, data);
			for(i=0;i<2048;i++){	// (0xc800-0xcfff)
				((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xc800))[i]=data[i];
			}
		}
		// Key Map Data
		GetPrivateProfileString(SecName, "KEYMAP", "NULL", buffer, "system.ini");
		if(strcmp(buffer,"NULL")==0)
			GetPrivateProfileString("COMMON", "KEYMAP", "NULL", buffer, "system.ini");
		if(strcmp(buffer,"NULL")!=0){
			ROM_read(buffer, data);
			for(i=0;i<256;i++){	// (0xc000-0xc0ff)
				((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xc000))[i]=data[i];
			}
		}
	}
}

int main()
{
	//unsigned int x,y;
	int k;

	// Initialize Disk I/F and ROM
	System_Initialize();

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
			case 0:
				if(view_inventory()==999) continue;
				break;
			case 3:
				direct_load();
				break;
			case 40:
			case 41:
			case 42:
			case 43:
			case 44:
			case 45:
			case 46:
			case 47:
			case 48:
				set_rom(k);
				if(view_inventory()==999) continue;
				break;
			case 50:
			case 51:
			case 52:
			case 53:
			case 54:
			case 55:
			case 56:
			case 57:
			case 58:
				clear_rom(k);
				if(view_inventory()==999) continue;
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
