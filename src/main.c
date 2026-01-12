#include <stdio.h>
#include "pico/stdlib.h"

void test_print();
void test_panic();
void test_file();

int mount(void);

int main()
{
    stdio_init_all();
    busy_wait_ms(4000);

    printf("Hello World from C!\n");
	test_print();

    printf("Doing the mount...");
    if (!mount())
    {
        printf("success!\n");

        printf("Testing File IO\n");
        test_file();
    }
    else
        printf("fail!\n");


    busy_wait_ms(1000);
    test_panic();

    printf("Check panic?\n");

    while (true) {}
}