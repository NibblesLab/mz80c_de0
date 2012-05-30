/*
 * MZ-80C on FPGA (Altera DE0 version)
 * MENU Select routines header
 *
 * (c) Nibbles Lab. 2012
 *
 */

#ifndef MENU_H_
#define MENU_H_

typedef struct {
	unsigned char *item;
	unsigned int *next;
	unsigned int items;
} menu_t;

void frame(unsigned int, unsigned int, unsigned int);
void disp_menu(unsigned int, unsigned int);
int select_menu(unsigned int, unsigned int);
int menu(unsigned int, unsigned int, unsigned int);

#endif /* MENU_H_ */
