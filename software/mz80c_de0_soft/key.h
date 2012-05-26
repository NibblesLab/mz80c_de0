/*
 * key.h
 *
 *  Created on: 2012/05/11
 *      Author: ohishi
 */

#ifndef KEY_H_
#define KEY_H_

typedef struct {
	unsigned char kcode[32];
	unsigned int wptr;
	unsigned int rptr;
	unsigned int flagf0;
	unsigned int flage0;
	unsigned int Lshift;
	unsigned int Rshift;
} keyb_t;

void key_int_regist(void);
unsigned char get_key(void);

#endif /* KEY_H_ */
