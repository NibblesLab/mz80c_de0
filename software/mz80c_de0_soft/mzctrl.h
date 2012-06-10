/*
 * MZ-80C on FPGA (Altera DE0 version)
 * MZ control routines header
 *
 * (c) Nibbles Lab. 2012
 *
 */

#ifndef MZCTRL_H_
#define MZCTRL_H_

typedef struct {
	unsigned int status;
} z80_t;

void button_int_regist(void);
void MZ_release(void);
void MZ_Brequest(void);
void MZ_Brelease(void);
void MZ_disp(unsigned int, unsigned int, unsigned char);
void MZ_msg(unsigned int, unsigned int, char *);
void MZ_msgx(unsigned int, unsigned int, char *, unsigned int);
void crev(unsigned int, unsigned int, unsigned int, unsigned int);
int pulseout(unsigned char, int);
int z11000(void);
int z20(void);
int o20(void);
int sumout(unsigned int);

#endif /* MZCTRL_H_ */
