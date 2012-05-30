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
void MZ_msg(unsigned int, unsigned int, unsigned char *);
void crev(unsigned int, unsigned int, unsigned int, unsigned int);

#endif /* MZCTRL_H_ */
