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
	char *lpAppName,        /* �Z�N�V������ */
	char *lpKeyName,        /* �L�[�� */
	char *lpReturnedString,  /* ��񂪊i�[�����o�b�t�@ */
	const char *lpFileName        /* .ini �t�@�C���̖��O */
)
{
	WORD p;
	FIL fobj;
	FRESULT res;

	/* .ini�t�@�C���I�[�v�� */
	res=f_open(&fobj, lpFileName, FA_OPEN_EXISTING | FA_READ);
	/* .ini�t�@�C��������Ȃ� */
	if(res==FR_OK){
		/* �Z�N�V�����s���� */
		do{
			/* 1�s�ǂ�ŁAEOF��������break */
			if(f_gets(lpReturnedString, 512, &fobj)==NULL) break;
			/* �Z�N�V������\�킷'['�Ȃ� */
			if(lpReturnedString[0]=='['){
				/* '['�̎��̕��� */
				p=1;
				/* �Z�N�V�������̏I����\�킷']'���A�s�̏I��肩�A�w�肵���Z�N�V�������̏I���܂� */
				while(lpReturnedString[p]!=']' && lpReturnedString[p]!='\0' && lpAppName[p-1]!='\0'){
					/* bit5���}�X�N���邱�Ƃő啶�������������̕�������r���A�������break */
					if((lpReturnedString[p]&0xdf)!=(lpAppName[p-1]&0xdf)) break;
					/* �܂���v���Ă�̂Ŏ��̕����� */
					p++;
				}
				/* ���̃��[�v�̒E�o�������Z�N�V���������S��v�Ȃ� */
				if(lpAppName[p-1]=='\0'){
					/* �L�[�s���� */
					do{
						/* 1�s�ǂ�ŁAEOF��������break */
						if(f_gets(lpReturnedString, 512, &fobj)==NULL) break;
						/* �ǂ񂾍s���Z�N�V�����Ȃ�A�V�����Z�N�V�����ɓ���̂�break */
						if(lpReturnedString[0]=='[') break;
						/* �ǂ񂾍s���R�����g�Ȃ�A���̍s���΂� */
						/*if(lpReturnedString[0]==';') continue;*/
						/* �s�̐擪 */
						p=0;
						/* �L�[���̏I���ƂȂ�'='���X�y�[�X���A�s�̏I��肩�A�^�u���A�w�肵���L�[���̏I���܂� */
						while(lpReturnedString[p]!='=' && lpReturnedString[p]!=' ' && lpReturnedString[p]!=0x09 && lpReturnedString[p]!='\0' && lpKeyName[p]!='\0'){
							/* bit5���}�X�N���邱�Ƃő啶�������������̕�������r���A�������break */
							if((lpReturnedString[p]&0xdf)!=(lpKeyName[p]&0xdf)) break;
							/* �܂���v���Ă�̂Ŏ��̕����� */
							p++;
						}
						/* ���̃��[�v�̒E�o�������L�[�����S��v�Ȃ� */
						if(lpKeyName[p]=='\0'){
							/* �X�y�[�X��^�u�A'='�̓X�L�b�v���Ă��� */
							while(lpReturnedString[p]=='=' || lpReturnedString[p]==' ' || lpReturnedString[p]==0x09) p++;
							/* .ini �t�@�C���N���[�Y */
							res=f_close(&fobj);
							/* ������̏ꏊ��Ԃ� */
							return p;
						}
					/* �܂�EOF�łȂ���ΌJ��Ԃ� */
					}while(fobj.fptr!=fobj.fsize);	/* while(!feof(&fobj1)); */
				}
			}
		/* �܂�EOF�łȂ���ΌJ��Ԃ� */
		}while(fobj.fptr!=fobj.fsize);	/* while(!feof(&fobj1)); */
	}
	/* .ini�t�@�C���N���[�Y */
	res=f_close(&fobj);
	/* .ini�t�@�C�����Ȃ����Z�N�V�����܂��̓L�[��������Ȃ� */
	return 0;
}


void GetPrivateProfileString(
	char *lpAppName,        /* �Z�N�V������ */
	char *lpKeyName,        /* �L�[�� */
	char *lpDefault,        /* ����̕����� */
	char *lpReturnedString,  /* ��񂪊i�[�����o�b�t�@ */
	const char *lpFileName        /* .ini �t�@�C���̖��O */
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
	char *lpAppName,  /* �Z�N�V������ */
	char *lpKeyName,  /* �L�[�� */
	DWORD nDefault,       /* �L�[����������Ȃ������ꍇ�ɕԂ��ׂ��l */
	const char *lpFileName  /* .ini �t�@�C���̖��O */
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
