#include <stdio.h>
#include "pico/stdlib.h"

extern void test_print();
extern void test_panic();
extern void test_file();

int main()
{
    stdio_init_all();

    busy_wait_ms(4000);

    printf("Hello World from C!\n");
	test_print();

    busy_wait_ms(2000);
    test_file();

    busy_wait_ms(2000);
    test_panic();

    printf("Check panic?\n");

    while (true) {}
}