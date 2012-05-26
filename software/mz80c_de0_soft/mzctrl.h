/*
 * mzctrl.h
 *
 *  Created on: 2012/05/07
 *      Author: ohishi
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
