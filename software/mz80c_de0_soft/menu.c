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
#include "unistd.h"
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
static char main_menu_item[]="    VIEW    \0 SET MEDIA >\0 REL MEDIA >\0 DIR. LOAD >\0 SET ROMS  >\0 REL ROMS  >\0CARD CHANGE ";
static unsigned int main_menu_next[7]={0,1,2,99,3,4,0};

static char rel_media_item[]="    TAPE    \0    FDD 1   \0    FDD 2   ";
static unsigned int rel_media_next[6]={0,0,0,0,0,0};

static char set_media_item[]="    TAPE   >\0    FDD 1  >\0    FDD 2  >";
static unsigned int set_media_next[6]={99,99,99,0,0,0};

static char set_rom_item[]="    MON    >\0  MON(80A) >\0  USER ROM >\0  FD ROM   >\0FD ROM(80A)>\0  CG ROM   >\0CG ROM(80A)>\0  KEYMAP   >\0KEYMAP(80A)>";
static unsigned int set_rom_next[9]={99,99,99,99,99,99,99,99,99};

static char rel_rom_item[]="    MON     \0  MON(80A)  \0  USER ROM  \0  FD ROM    \0FD ROM(80A) \0  CG ROM    \0CG ROM(80A) \0  KEYMAP    \0KEYMAP(80A) ";
static unsigned int rel_rom_next[9]={0,0,0,0,0,0,0,0,0};

menu_t menus[5]={{main_menu_item,main_menu_next,7},
				 {set_media_item,set_media_next,3},
				 {rel_media_item,rel_media_next,3},
				 {set_rom_item,set_rom_next,9      },
				 {rel_rom_item,rel_rom_next,9      }};

extern FATFS fs;
extern DIR dirs;
extern FILINFO finfo;
extern char fname[13],tname[13];	//,dname1[13],dname2[13];

/*
 * Display Frame by Item numbers
 */
void frame(unsigned int level, unsigned int items, unsigned int select)
{
	unsigned int i,j;
	unsigned char c1,c2,c3,c4;

	if(level){
		c1=0x4b; c2=0x4c; c3=0x6e; c4=0x6f;
	}else{
		c1=0x5c; c2=0x5d; c3=0x1d; c4=0x1c;
	}

	((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[level*13]=c1;
	((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[40+level*13]=c4;
	((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[level*13+1]=c2;
	((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[40+level*13+1]=c3;
	for(i=1;i<13;i++){
		usleep(10000);
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[level*13+i]=0x78;
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[level*13+i+1]=c2;
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[40+level*13+i]=0x78;
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[40+level*13+i+1]=c3;
	}

	for(i=1;i<=items;i++){
		usleep(10000);
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[i*40+level*13]=0x79;
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[i*40+level*13+13]=0x79;
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[(i+1)*40+level*13]=c4;
		for(j=1;j<13;j++){
			((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[i*40+level*13+j]=0;
			((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[(i+1)*40+level*13+j]=0x78;
		}
		((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[(i+1)*40+level*13+13]=c3;
	}

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
		if((z80_status.status&0x01)==0) return(-1);
		switch(get_key()){
		case 0x0d:	// menu select
			crev(level*13+1,num+1,level*13+12,num+1);
			return(num);
			break;
		case 0x1b:	// escape menu
			z80_status.status&=0xfffffffe;
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
		MZ_msg(level*13+1, 1+i, "            ");
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
		if((z80_status.status&0x01)==0){
			free(items); free(attrib);
			return(-1);
		}
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
			z80_status.status&=0xfffffffe;
			break;
		case 0x1d:	// back to menu
			crev(level*13+1,num+1,level*13+12,num+1);
			free(items); free(attrib);
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

	((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[212]=0x57;
	((volatile unsigned char*)(INTERNAL_SRAM8_0_BASE+0xd000))[252]=0x57;

	MZ_msg(14, 1, "MZ-80C ON FPGA B.U.SYSTEM");
	MZ_msg(14, 2, " BY NIBBLESLAB VER."); MZ_msg(33, 2, version);
	MZ_msg(14, 4, "    TAPE    :"); MZ_msg(27, 4, tname);
	MZ_msg(14, 5, "    FDD 1   :"); //MZ_msg(27, 5, dname1);
	MZ_msg(14, 6, "    FDD 2   :"); //MZ_msg(27, 6, dname2);
	MZ_msg(14, 8, "FOR MZ-80K/K2/K2E/C/1200;");
	MZ_msg(14, 9, "MONITOR ROM :"); MZ_msgx(27, 9, romdata->mon80c_name, 12);
	MZ_msg(14, 10, "FD ROM      :"); MZ_msgx(27, 10, romdata->fd80c_name, 12);
	MZ_msg(14, 11, "CG ROM      :"); MZ_msgx(27, 11, romdata->char80c_name, 12);
	MZ_msg(14, 12, "KEY MAP     :"); MZ_msgx(27, 12, romdata->key80c_name, 12);
	MZ_msg(14, 14, "FOR MZ-1200/80A;");
	MZ_msg(14, 15, "USER ROM    :"); MZ_msgx(27, 15, romdata->ex_name, 12);
	MZ_msg(14, 17, "FOR MZ-80A;");
	MZ_msg(14, 18, "MONITOR ROM :"); MZ_msgx(27, 18, romdata->mon80a_name, 12);
	MZ_msg(14, 19, "FD ROM      :"); MZ_msgx(27, 19, romdata->fd80a_name, 12);
	MZ_msg(14, 20, "CG ROM      :"); MZ_msgx(27, 20, romdata->char80a_name, 12);
	MZ_msg(14, 21, "KEY MAP     :"); MZ_msgx(27, 21, romdata->key80a_name, 12);

	while(1){
		if((z80_status.status&0x01)==0) return(-1);
		switch(get_key()){
		case 0x1b:	// escape menu
			z80_status.status&=0xfffffffe;
			break;
		case 0x1d:	// menu back
			return(999);
			break;
		default:
			break;
		}
	}
}

/*
 * 1 Line Input
 */
int getl(int x, int y, int len, char *text)
{
	char buf[len+1],k;
	int i,x0,y0,pos=0,max=0;

	for(i=0;i<len-1;i++)
		buf[i]=' ';
	buf[len]='\0';
	x0=x; y0=y;

	while(1){
		crev(x,y,x,y);
		do k=get_key(); while(k==0);
		crev(x,y,x,y);
		if(k>0x1f){
			MZ_disp(x,y,k);
			buf[pos]=k;
			if(pos<len-1){
				if(x==39){
					if(y!=24){
						y++; x=0;
						pos++;
					}
				}else{
					x++;
					pos++;
				}
				if(pos>max) max=pos;
			}else{
				max=len;
			}
		}

		switch(k){
		case 0x08:	// back space
			if(pos!=0){
				if(x==0){
					if(y!=0){
						y--; x=39;
						pos--;
					}
				}else{
					x--;
					pos--;
				}
				for(i=pos;i<len;i++)
					buf[i]=buf[i+1];
				MZ_msgx(x0,y0,buf,len);
				if(max>0) max--;
			}
			break;
		case 0x0d:	// finish
			for(i=0;i<max;i++)
				*(text+i)=buf[i];
			*(text+max+1)='\0';
			return(max);
			break;
		case 0x1b:	// escape menu
			return(-1);
			break;
		case 0x1c:	// right
			if(pos<len-1){
				if(x==39){
					if(y!=24){
						y++; x=0;
						pos++;
					}
				}else{
					x++;
					pos++;
				}
			}
			break;
		case 0x1d:	// left
			if(pos!=0){
				if(x==0){
					if(y!=0){
						y--; x=39;
						pos--;
					}
				}else{
					x--;
					pos--;
				}
			}
			break;
		default:
			break;
		}
	}
}

/*
 * File Name Entry
 */
int input_file_name(void)
{
	char buf[13];
	int res;

	MZ_msg(0,0,"PLEASE ENTER FILE NAME");
	res=getl(0,1,8,buf);
	if(res>0){
		buf[res]='.'; buf[res+1]='M'; buf[res+2]='Z'; buf[res+3]='T'; buf[res+4]='\0';
		strcpy(tname, buf);
	}
	return(res);
}
