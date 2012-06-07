/*
 * MZ-80C on FPGA (Altera DE0 version)
 * MENU Select routines
 *
 * (c) Nibbles Lab. 2012
 *
 */

#include "system.h"
#include "alt_types.h"
#include <stdio.h>
#include "malloc.h"
#include "string.h"
#include "altera_avalon_pio_regs.h"
#include "mz80c_de0_main.h"
#include "menu.h"
#include "mzctrl.h"
#include "key.h"
#include "ff.h"

extern volatile z80_t z80_status;

// Menu members
static char main_menu_item[]="    VIEW    \0 SET MEDIA >\0 REL MEDIA >\0 DIR. LOAD >\0 SET ROMS  >\0 REL ROMS  >";
static unsigned int main_menu_next[6]={0,1,2,99,3,4};

static char rel_media_item[]="    TAPE    \0    FDD 1   \0    FDD 2   ";
static unsigned int rel_media_next[6]={0,0,0,0,0,0};

static char set_media_item[]="    TAPE   >\0    FDD 1  >\0    FDD 2  >";
static unsigned int set_media_next[6]={99,99,99,0,0,0};

static char set_rom_item[]="    MON    >\0  MON(80A) >\0  EX.ROM   >\0  FD ROM   >\0FD ROM(80A)>\0  CG ROM   >\0CG ROM(80A)>\0  KEYMAP   >\0KEYMAP(80A)>";
static unsigned int set_rom_next[9]={99,99,99,99,99,99,99,99,99};

static char rel_rom_item[]="    MON     \0  MON(80A)  \0  EX.ROM    \0  FD ROM    \0FD ROM(80A) \0  CG ROM    \0CG ROM(80A) \0  KEYMAP    \0KEYMAP(80A) ";
static unsigned int rel_rom_next[9]={0,0,0,0,0,0,0,0,0};

menu_t menus[5]={{main_menu_item,main_menu_next,6},
				 {set_media_item,set_media_next,3},
				 {rel_media_item,rel_media_next,3},
				 {set_rom_item,set_rom_next,9      },
				 {rel_rom_item,rel_rom_next,9      }};

extern FATFS fs;
extern DIR dirs;
extern FILINFO finfo;
extern char fname[13];

/*
 * Display Frame by Item numbers
 */
void frame(unsigned int level, unsigned int items, unsigned int select)
{
	unsigned int i;
	unsigned char c1,c2,c3,c4;

	for(i=1;i<=items;i++){
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[i*40+level*13]=0x79;
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[i*40+level*13+13]=0x79;
	}
	for(i=1;i<13;i++){
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[level*13+i]=0x78;
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[(items+1)*40+level*13+i]=0x78;
	}

	if(level){
		c1=0x4b; c2=0x4c; c3=0x6e; c4=0x6f;
	}else{
		c1=0x5c; c2=0x5d; c3=0x1d; c4=0x1c;
	}
	((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[level*13]=c1;
	((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[level*13+13]=c2;
	((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[(items+1)*40+level*13+13]=c3;
	((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[(items+1)*40+level*13]=c4;

	if(level){
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[(select+1)*40+level*13]=0x5e;
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[(select+1)*40+level*13-1]=0x78;
	}
}

/*
 * Display Items
 */
void disp_menu(unsigned int level, unsigned int n_menu)
{
	int i;

	for(i=0;i<menus[n_menu].items;i++){
		MZ_msg(level*13+1, 1+i, &(menus[n_menu].item)[i*13]);
	}
}

/*
 * Select Menu
 */
int select_menu(unsigned int level, unsigned int n_menu)
{
	unsigned int num=0;

	crev(level*13+1,num+1,level*13+12,num+1);
	while(1){
		if(z80_status.status==0) return(-1);
		switch(get_key()){
		case 0x0d:	// menu select
			crev(level*13+1,num+1,level*13+12,num+1);
			return(num);
			break;
		case 0x1b:	// escape menu
			z80_status.status=0;
			break;
		case 0x1d:	// menu back
			crev(level*13+1,num+1,level*13+12,num+1);
			return(999);
			break;
		case 0x1e:	// up
			if(num>0){
				crev(level*13+1,num,level*13+12,num+1);
				num--;
			}
			break;
		case 0x1f:	// down
			if(num<(menus[n_menu].items-1)){
				crev(level*13+1,num+1,level*13+12,num+2);
				num++;
			}
			break;
		default:
			break;
		}
	}
}

/*
 * Display File Names as Menu Items
 */
void disp_files(unsigned int level, unsigned char *items, unsigned int total)
{
	int i,j,k;
	char fname[13];

	fname[12]='\0';
	for(i=0;i<(total>23?23:total);i++){
		for(j=0,k=0;j<8;j++){
			if(items[i*13+k]!='.'){
				fname[j]=items[i*13+k];
				k++;
			}else{
				fname[j]=' ';
			}
		}
		for(j=8;j<12;j++){
			if(items[i*13+k]!='\0'){
				fname[j]=items[i*13+k];
				k++;
			}else{
				fname[j]=' ';
			}
		}
		MZ_msg(level*13+1, 1+i, fname);
	}
}

/*
 * File Select Menu
 */
int file_menu(unsigned int level, unsigned int select)
{
	FRESULT f;
	unsigned int total,offset,num,i;
	unsigned char *items;
	BYTE *attrib;

	f=f_opendir(&dirs, "\0");	// current directory
	switch(f){
		case FR_OK:
			total=0; offset=0; num=0;
			while((f_readdir(&dirs, &finfo) == FR_OK) && finfo.fname[0]){
				total++;
			}
			break;
		case FR_INT_ERR:
		case FR_NOT_READY:
		default:
			return(-1);
			break;
	}
	f_readdir(&dirs, (FILINFO *)NULL);	// rewind
	items=malloc(total*13);
	attrib=malloc(total*sizeof(BYTE));
	for(i=0;i<total;i++){
		f_readdir(&dirs, &finfo);
		memcpy(&items[i*13], finfo.fname, 13);
		attrib[i]=finfo.fattrib;
	}

	if(total>23){
		frame(level,23,select);
	}else{
		frame(level,total,select);
	}

	disp_files(level,&items[offset],total);

	crev(level*13+1,num+1,level*13+12,num+1);
	while(1){
		if(z80_status.status==0) return(-1);
		switch(get_key()){
		case 0x08:	// directory back
			crev(level*13+1,num+1,level*13+12,num+1);
			f_chdir("..");
			free(items); free(attrib);
			return(file_menu(level,select));
			break;
		case 0x0d:	// select
			crev(level*13+1,num+1,level*13+12,num+1);
			if(attrib[offset+num]&AM_DIR){
				f_chdir((TCHAR*)&items[(offset+num)*13]);
				free(items); free(attrib);
				return(file_menu(level,select));
			}else{
				memcpy(fname, &items[(offset+num)*13], 13);
				free(items); free(attrib);
				return(0);
			}
			break;
		case 0x1b:	// escape select
			z80_status.status=0;
			break;
		case 0x1d:	// back to menu
			crev(level*13+1,num+1,level*13+12,num+1);
			return(999);
			break;
		case 0x1e:	// up
			if(num>0){
				crev(level*13+1,num,level*13+12,num+1);
				num--;
			}else{
				if(offset>0){
					offset--;
					disp_files(level,&items[offset*13],total);
				}
			}
			break;
		case 0x1f:	// down
			if(total>23){
				if(num<22){
					crev(level*13+1,num+1,level*13+12,num+2);
					num++;
				}else{
					if((num+offset)<total){
						offset++;
						disp_files(level,&items[offset*13],total);
					}
				}
			}else{
				if(num<(total-1)){
					crev(level*13+1,num+1,level*13+12,num+2);
					num++;
				}
			}
			break;
		default:
			break;
		}
	}

}

/*
 * Root Menu
 */
int menu(unsigned int level, unsigned int n_menu, unsigned int select)
{
	int s,ss=0;

	while(1){
		frame(level,menus[n_menu].items,select);
		disp_menu(level,n_menu);
		s=select_menu(level,n_menu);
		switch(s){
		case -1:
		case 999:
			return(s);
			break;
		default:
			switch(menus[n_menu].next[s]){
			case 0:
				return(s);
				break;
			case 99:
				switch(file_menu(level+1, s)){
				case -1:
					return(-1);
					break;
				case 999:
					break;
				default:
					return(s);
					break;
				}
				break;
			default:
				ss=menu(level+1,menus[n_menu].next[s],s);
				if(ss==-1){
					return(ss);
				}else if(ss==999){
					break;
				}else{
					return(s*10+ss);
				}
			}
		}
	}
}

/*
 * View the Inventory of ROMs
 */
int view_inventory(void)
{
	unsigned int i,j;
	ROMS_t *romdata=(ROMS_t *)(CFI_FLASH_0_BASE+0x100000);
	char name[13];

	for(i=1;i<=24;i++){
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[i*40+13]=0x79;
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[i*40+39]=0x79;
	}
	for(i=14;i<=38;i++){
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[i]=0x78;
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[960+i]=0x78;
	}

	for(i=1;i<=23;i++){
		for(j=14;j<=38;j++){
			((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[i*40+j]=0;
		}
	}

	((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[13]=0x4b;
	((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[39]=0x4c;
	((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[999]=0x6e;
	((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[973]=0x6f;

	((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[53]=0x5e;
	((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[52]=0x78;

	name[12]='\0';
	MZ_msg(14, 1, "MZ-80C ON FPGA B.U.SYSTEM");
	MZ_msg(14, 2, " BY NIBBLESLAB VER."); MZ_msg(33, 2, version);
	MZ_msg(14, 5, "FOR MZ-80K/K2/K2E/C/1200;");
	MZ_msg(14, 7, "MONITOR ROM :");
		memcpy(name,romdata->mon80c_name,12);
		MZ_msg(27, 7, name);
	MZ_msg(14, 8, "FD ROM      :");
		memcpy(name,romdata->fd80c_name,12);
		MZ_msg(27, 8, name);
	MZ_msg(14, 9, "CG ROM      :");
		memcpy(name,romdata->char80c_name,12);
		MZ_msg(27, 9, name);
	MZ_msg(14, 10, "KEY MAP     :");
		memcpy(name,romdata->key80c_name,12);
		MZ_msg(27, 10, name);
	MZ_msg(14, 12, "FOR MZ-1200/80A;");
	MZ_msg(14, 14, "USER ROM    :");
		memcpy(name,romdata->ex_name,12);
		MZ_msg(27, 14, name);
	MZ_msg(14, 16, "FOR MZ-80A;");
	MZ_msg(14, 18, "MONITOR ROM :");
		memcpy(name,romdata->mon80a_name,12);
		MZ_msg(27, 18, name);
	MZ_msg(14, 19, "FD ROM      :");
		memcpy(name,romdata->fd80a_name,12);
		MZ_msg(27, 19, name);
	MZ_msg(14, 20, "CG ROM      :");
		memcpy(name,romdata->char80a_name,12);
		MZ_msg(27, 20, name);
	MZ_msg(14, 21, "KEY MAP     :");
		memcpy(name,romdata->key80a_name,12);
		MZ_msg(27, 21, name);

	while(1){
		if(z80_status.status==0) return(-1);
		switch(get_key()){
		case 0x1b:	// escape menu
			z80_status.status=0;
			break;
		case 0x1d:	// menu back
			return(999);
			break;
		default:
			break;
		}
	}
}
