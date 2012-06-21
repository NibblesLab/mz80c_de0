/*
 * MZ-80C on FPGA (Altera DE0 version)
 * File Access routines header
 *
 * (c) Nibbles Lab. 2012
 *
 */

#ifndef FILE_H_
#define FILE_H_

UINT file_bulk_read(unsigned char *, UINT);
void direct_load(void);
void set_rom(int);
void clear_rom(int);
void GetPrivateProfileString(char *, char *, char *, char *, const char *);
DWORD GetPrivateProfileInt(char *, char *, DWORD, const char *);
void put_tape_formatting_pulse(void);
void quick_load(void);

#endif /* FILE_H_ */
