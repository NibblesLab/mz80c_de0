/*
 * MZ-80C on FPGA (Altera DE0 version)
 * File Access routines header
 *
 * (c) Nibbles Lab. 2012
 *
 */

#ifndef FILE_H_
#define FILE_H_

void direct_load(void);
void set_rom(int);
void clear_rom(int);
void GetPrivateProfileString(char *, char *, char *, char *, const char *);
DWORD GetPrivateProfileInt(char *, char *, DWORD, const char *);

#endif /* FILE_H_ */
