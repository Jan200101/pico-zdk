#include <stdio.h>
#include "pico/stdlib.h"

extern void test_print();

int main()
{
    stdio_init_all();

    busy_wait_ms(2000);

    printf("Hello World from C!\n");
	test_print();
    while (true) {}
}