/*
 * MZ-80C on FPGA (Altera DE0 version)
 * Main module header
 *
 * (c) Nibbles Lab. 2012
 *
 */

#ifndef MZ80C_DE0_MAIN_H_
#define MZ80C_DE0_MAIN_H_

typedef struct {
	unsigned char mon80c[4096];
	char mon80c_name[13];
	unsigned char mon80a[4096];
	char mon80a_name[13];
	unsigned char ex[2048];
	char ex_name[13];
	unsigned char fd80c[4096];
	char fd80c_name[13];
	unsigned char fd80a[4096];
	char fd80a_name[13];
	unsigned char char80c[2048];
	char char80c_name[13];
	unsigned char char80a[2048];
	char char80a_name[13];
	unsigned char key80c[256];
	char key80c_name[13];
	unsigned char key80a[256];
	char key80a_name[13];
} ROMS_t;

#define version "0.1"

#endif /* MZ80C_DE0_MAIN_H_ */
