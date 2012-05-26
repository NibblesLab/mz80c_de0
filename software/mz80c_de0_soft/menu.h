/*
 * menu.h
 *
 *  Created on: 2012/05/10
 *      Author: ohishi
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
