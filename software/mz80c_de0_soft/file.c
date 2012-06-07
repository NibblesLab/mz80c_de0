/*
 * MZ-80C on FPGA (Altera DE0 version)
 * File Access routines
 *
 * (c) Nibbles Lab. 2012
 *
 */

#include "system.h"
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
extern char fname[13];

/*
 * Read File (bulk)
 */
FRESULT file_bulk_read(unsigned char *buf, UINT size)
{
	FIL fobj;
	FRESULT res;
	UINT r;

	// File Read
	res=f_open(&fobj, (TCHAR*)fname, FA_OPEN_EXISTING | FA_READ);
	if(res!=FR_OK) return(res);
	res=f_read(&fobj, buf, size, &r);
	return(f_close(&fobj));
}

/*
 * Force put memory from MZT file
 */
void direct_load(void)
{
	FRESULT res;
	UINT i,size,dtadr;
	unsigned char buf[65536];

	// File Read
	res=file_bulk_read(buf, 65536);

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
	FRESULT res;
	alt_flash_fd *fd;
	ROMS_t romdata;
	int i;
	unsigned char *buf;
	char *name;

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
	res=file_bulk_read(buf, 4096);
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

