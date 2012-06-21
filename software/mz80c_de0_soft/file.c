/*
 * MZ-80C on FPGA (Altera DE0 version)
 * File Access routines
 *
 * (c) Nibbles Lab. 2012
 *
 */

#include "system.h"
#include "io.h"
#include "alt_types.h"
#include <stdio.h>
#include <string.h>
#include "altera_avalon_pio_regs.h"
#include "sys/alt_flash.h"
#include "mz80c_de0_main.h"
#include "mzctrl.h"
#include "integer.h"
#include "ff.h"

extern FATFS fs;
extern DIR dirs;
extern FILINFO finfo;
extern char fname[13],tname[13];
extern DWORD ql_pt;

/*
 * Read File (bulk)
 */
UINT file_bulk_read(unsigned char *buf, UINT size)
{
	FIL fobj;
	FRESULT res;
	UINT r;

	// File Read
	res=f_open(&fobj, (TCHAR*)fname, FA_OPEN_EXISTING | FA_READ);
	if(res!=FR_OK) return(0);
	res=f_read(&fobj, buf, size, &r);
	return(r);
}

/*
 * Force put memory from MZT file
 */
void direct_load(void)
{
	UINT i,r,size,dtadr;
	unsigned char buf[65536];

	// File Read
	r=file_bulk_read(buf, 65536);

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

/*
 * ROM data setting
 */
void set_rom(int select){
	alt_flash_fd *fd;
	ROMS_t romdata;
	int i;
	unsigned char *buf;
	char *name;
	UINT r;

	for(i=0;i<sizeof(ROMS_t);i++)
		((char *)&romdata)[i]=((char *)(CFI_FLASH_0_BASE+0x100000))[i];

	switch(select){
	case 40:
		buf=romdata.mon80c;
		name=romdata.mon80c_name;
		break;
	case 41:
		buf=romdata.mon80a;
		name=romdata.mon80a_name;
		break;
	case 42:
		buf=romdata.ex;
		name=romdata.ex_name;
		break;
	case 43:
		buf=romdata.fd80c;
		name=romdata.fd80c_name;
		break;
	case 44:
		buf=romdata.fd80a;
		name=romdata.fd80a_name;
		break;
	case 45:
		buf=romdata.char80c;
		name=romdata.char80c_name;
		break;
	case 46:
		buf=romdata.char80a;
		name=romdata.char80a_name;
		break;
	case 47:
		buf=romdata.key80c;
		name=romdata.key80c_name;
		break;
	case 48:
		buf=romdata.key80a;
		name=romdata.key80a_name;
		break;
	default:
		break;
	}

	// File Read
	r=file_bulk_read(buf, 4096);
	strcpy(name, fname);

	fd=alt_flash_open_dev(CFI_FLASH_0_NAME);
	if(fd)
		alt_write_flash(fd, 0x100000, (char *)&romdata, sizeof(ROMS_t));
	alt_flash_close_dev(fd);
}

void clear_rom(int select){
	alt_flash_fd *fd;
	ROMS_t romdata;
	int i;
	unsigned char *buf;
	char *name;
	size_t size;

	for(i=0;i<sizeof(ROMS_t);i++)
		((char *)&romdata)[i]=((char *)(CFI_FLASH_0_BASE+0x100000))[i];

	switch(select){
	case 50:
		buf=romdata.mon80c;
		name=romdata.mon80c_name;
		size=sizeof(romdata.mon80c);
		break;
	case 51:
		buf=romdata.mon80a;
		name=romdata.mon80a_name;
		size=sizeof(romdata.mon80a);
		break;
	case 52:
		buf=romdata.ex;
		name=romdata.ex_name;
		size=sizeof(romdata.ex);
		break;
	case 53:
		buf=romdata.fd80c;
		name=romdata.fd80c_name;
		size=sizeof(romdata.fd80c);
		break;
	case 54:
		buf=romdata.fd80a;
		name=romdata.fd80a_name;
		size=sizeof(romdata.fd80a);
		break;
	case 55:
		buf=romdata.char80c;
		name=romdata.char80c_name;
		size=sizeof(romdata.char80c);
		break;
	case 56:
		buf=romdata.char80a;
		name=romdata.char80a_name;
		size=sizeof(romdata.char80a);
		break;
	case 57:
		buf=romdata.key80c;
		name=romdata.key80c_name;
		size=sizeof(romdata.key80c);
		break;
	case 58:
		buf=romdata.key80a;
		name=romdata.key80a_name;
		size=sizeof(romdata.key80a);
		break;
	default:
		break;
	}

	// File Read
	memset(buf, 0xff, size);
	memset(name, 0xff, 13);

	fd=alt_flash_open_dev(CFI_FLASH_0_NAME);
	if(fd)
		alt_write_flash(fd, 0x100000, (char *)&romdata, sizeof(ROMS_t));
	alt_flash_close_dev(fd);
}

WORD FindSectionAndKey(
	char *lpAppName,        /* セクション名 */
	char *lpKeyName,        /* キー名 */
	char *lpReturnedString,  /* 情報が格納されるバッファ */
	const char *lpFileName        /* .ini ファイルの名前 */
)
{
	WORD p;
	FIL fobj;
	FRESULT res;

	/* .iniファイルオープン */
	res=f_open(&fobj, lpFileName, FA_OPEN_EXISTING | FA_READ);
	/* .iniファイルがあるなら */
	if(res==FR_OK){
		/* セクション行検索 */
		do{
			/* 1行読んで、EOFだったらbreak */
			if(f_gets(lpReturnedString, 512, &fobj)==NULL) break;
			/* セクションを表わす'['なら */
			if(lpReturnedString[0]=='['){
				/* '['の次の文字 */
				p=1;
				/* セクション名の終わりを表わす']'か、行の終わりか、指定したセクション名の終わりまで */
				while(lpReturnedString[p]!=']' && lpReturnedString[p]!='\0' && lpAppName[p-1]!='\0'){
					/* bit5をマスクすることで大文字化した両方の文字列を比較し、違ったらbreak */
					if((lpReturnedString[p]&0xdf)!=(lpAppName[p-1]&0xdf)) break;
					/* まだ一致してるので次の文字へ */
					p++;
				}
				/* 今のループの脱出原因がセクション名完全一致なら */
				if(lpAppName[p-1]=='\0'){
					/* キー行検索 */
					do{
						/* 1行読んで、EOFだったらbreak */
						if(f_gets(lpReturnedString, 512, &fobj)==NULL) break;
						/* 読んだ行がセクションなら、新しいセクションに入るのでbreak */
						if(lpReturnedString[0]=='[') break;
						/* 読んだ行がコメントなら、その行を飛ばす */
						/*if(lpReturnedString[0]==';') continue;*/
						/* 行の先頭 */
						p=0;
						/* キー名の終わりとなる'='かスペースか、行の終わりか、タブか、指定したキー名の終わりまで */
						while(lpReturnedString[p]!='=' && lpReturnedString[p]!=' ' && lpReturnedString[p]!=0x09 && lpReturnedString[p]!='\0' && lpKeyName[p]!='\0'){
							/* bit5をマスクすることで大文字化した両方の文字列を比較し、違ったらbreak */
							if((lpReturnedString[p]&0xdf)!=(lpKeyName[p]&0xdf)) break;
							/* まだ一致してるので次の文字へ */
							p++;
						}
						/* 今のループの脱出原因がキー名完全一致なら */
						if(lpKeyName[p]=='\0'){
							/* スペースやタブ、'='はスキップしておく */
							while(lpReturnedString[p]=='=' || lpReturnedString[p]==' ' || lpReturnedString[p]==0x09) p++;
							/* .ini ファイルクローズ */
							res=f_close(&fobj);
							/* 文字列の場所を返す */
							return p;
						}
					/* まだEOFでなければ繰り返し */
					}while(fobj.fptr!=fobj.fsize);	/* while(!feof(&fobj1)); */
				}
			}
		/* まだEOFでなければ繰り返し */
		}while(fobj.fptr!=fobj.fsize);	/* while(!feof(&fobj1)); */
	}
	/* .iniファイルクローズ */
	res=f_close(&fobj);
	/* .iniファイルがないかセクションまたはキーが見つからない */
	return 0;
}


void GetPrivateProfileString(
	char *lpAppName,        /* セクション名 */
	char *lpKeyName,        /* キー名 */
	char *lpDefault,        /* 既定の文字列 */
	char *lpReturnedString,  /* 情報が格納されるバッファ */
	const char *lpFileName        /* .ini ファイルの名前 */
)
{
	WORD p,q;

	p=FindSectionAndKey(lpAppName, lpKeyName, lpReturnedString, lpFileName);
	if(p==0){
		do{
			lpReturnedString[p]=lpDefault[p];
		}while(lpDefault[p++]!='\0');
	} else {
		q=p;
		do{
			lpReturnedString[p-q]=lpReturnedString[p];
		}while(lpReturnedString[p++]!='\0');
	}
}


DWORD GetPrivateProfileInt(
	char *lpAppName,  /* セクション名 */
	char *lpKeyName,  /* キー名 */
	DWORD nDefault,       /* キー名が見つからなかった場合に返すべき値 */
	const char *lpFileName  /* .ini ファイルの名前 */
)
{
	WORD c,p,q;
	char buffer[64];

	p=FindSectionAndKey(lpAppName, lpKeyName, buffer, lpFileName);
	if(p==0){
		return nDefault;
	} else {
		q=0;
		while(buffer[p]!='\0'){
			c=buffer[p];
			if(c<'0' || c>'9') break;
			q=c-0x30+q*10;
			p++;
		}
		return q;
	}
}

void put_tape_formatting_pulse(void)
{
	int tpos,sum,size,p,q,step;
	DWORD fsize;
	unsigned char tdata[128],c;
	UINT r;
	FIL fobj;
	FRESULT res;

	IOWR_ALTERA_AVALON_PIO_IRQ_MASK(INT_BUTTON_BASE,0);	// Disable IRQ

	if(tname[0]!='\0'){
		res=f_open(&fobj, tname, FA_OPEN_EXISTING | FA_READ);
		if(res==FR_OK){
			fsize=fobj.fsize;
			IOWR_ALTERA_AVALON_PIO_DATA(NUM_BASE, fsize);
			while(1){
				res=f_read(&fobj, tdata, 128, &r);
				if(r==0) break;
				if(z11000()<0) break;
				if(z11000()<0) break;
				if(o20()<0) break;
				if(o20()<0) break;
				if(z20()<0) break;
				if(z20()<0) break;
				if(pulseout(0x80,1)<0) break;
				tpos=0;
				sum=0;
				for(p=0;p<128;p++){
					q=pulseout(0x80,1);
					if(q<0) break;
					c=tdata[tpos++];
					q=pulseout(c,8);
					if(q<0) break;
					sum+=q;
					fsize--;
					IOWR_ALTERA_AVALON_PIO_DATA(NUM_BASE, fsize);
				}
				if(q<0) break;
				if(sumout(sum)<0) break;
				if(z11000()<0) break;
				if(o20()<0) break;
				if(z20()<0) break;
				if(pulseout(0x80,1)<0) break;
				sum=0;
				size=(tdata[19]<<8)+tdata[18];
				while(1){
					if(size<128) step=size; else step=128;
					res=f_read(&fobj, tdata, step, &r);
					tpos=0;
					for(p=0;p<r;p++){
						q=pulseout(0x80,1);
						if(q<0) break;
						c=tdata[tpos++];
						q=pulseout(c,8);
						if(q<0) break;
						sum+=q;
						fsize--;
						IOWR_ALTERA_AVALON_PIO_DATA(NUM_BASE, fsize);
					}
					if(q<0) break;
					if(size>128) size-=128; else break;
				}
				if(q<0) break;
				if(sumout(sum)<0) break;
			}
			if(f_eof(&fobj)){
				tname[0]='\0';	// Release Tape Data
				IOWR(CMT_0_BASE, 1, 0);
			}
		}
		res=f_close(&fobj);
	}else{
		while((IORD(CMT_0_BASE, 0)&0x80)!=0);	// Wait for Stop
	}

	IOWR_ALTERA_AVALON_PIO_IRQ_MASK(INT_BUTTON_BASE,0xf);	// Enable IRQ

}

/*
 * Quick Load MZT file
 */
void quick_load(void)
{
	DWORD tadr,size;
	UINT i,r;
	FIL fobj;
	FRESULT res;
	unsigned char *buf;

	tadr=(IORD(CMT_0_BASE, 1)&0xffff)*2;
	size=IORD(CMT_0_BASE, 2)&0xffff;
	buf=malloc(size);

	res=f_open(&fobj, tname, FA_OPEN_EXISTING | FA_READ);
	res=f_lseek(&fobj, ql_pt);
	res=f_read(&fobj, buf, size, &r);
	IOWR_ALTERA_AVALON_PIO_DATA(PAGE_BASE,0);	// Set Page
	for(i=0;i<size;i++){
		((volatile unsigned char*)(INTERNAL_SRAM2_0_BASE+tadr))[i*2]=buf[i];
	}

	if(f_eof(&fobj)){
		tname[0]='\0';	// Release Tape Data
		IOWR(CMT_0_BASE, 1, 0);
	}

	res=f_close(&fobj);
	ql_pt+=size;
	free(buf);
}
