#include <stdio.h>
#include "pico/stdlib.h"

#include "FreeRTOS.h"
#include "task.h"

#ifndef RUN_FREERTOS_ON_CORE
#define RUN_FREERTOS_ON_CORE 
#endif

#define MAIN_TASK_PRIORITY ( tskIDLE_PRIORITY + 1UL )
#define MAIN_TASK_STACK_SIZE ( configMINIMAL_STACK_SIZE * 4UL )

void test_print(void);
void test_panic(void);
void test_file(const char*);
void test_http_server(void);

int mount(void);

void main_task(__unused void *params)
{
    printf("Hello World from C!\n");
	test_print();

    printf("Doing the mount...");
    if (!mount())
    {
        printf("success!\n");

        printf("Testing File IO\n");
        test_file("/TEST_FILE");
    }
    else
        printf("fail!\n");

#if PICO_CYW43_SUPPORTED
    if (cyw43_arch_init()) {
        printf("failed to initialise\n");
        return;
    }

    cyw43_arch_enable_sta_mode();
    printf("Connecting to Wi-Fi...\n");
    if (cyw43_arch_wifi_connect_timeout_ms(WIFI_SSID, WIFI_PASSWORD, CYW43_AUTH_WPA2_AES_PSK, 30000)) {
        printf("failed to connect.\n");
    } else {
        printf("Connected.\n");
        test_http_server();
    }
#endif

    busy_wait_ms(1000);
    test_panic();

    printf("Check panic?\n");

    while (true) {}
}

void vLaunch( void) {
    TaskHandle_t task;
    xTaskCreate(main_task, "TestMainThread", MAIN_TASK_STACK_SIZE, NULL, MAIN_TASK_PRIORITY, &task);

#if NO_SYS && configUSE_CORE_AFFINITY && configNUMBER_OF_CORES > 1
    // we must bind the main task to one core (well at least while the init is called)
    // (note we only do this in NO_SYS mode, because cyw43_arch_freertos
    // takes care of it otherwise)
    vTaskCoreAffinitySet(task, 1);
#endif

    /* Start the tasks and timer running. */
    vTaskStartScheduler();
}

int main( void )
{
    stdio_init_all();
    busy_wait_ms(4000);

    /* Configure the hardware ready to run the demo. */
    const char *rtos_name;
#if ( configNUMBER_OF_CORES > 1 )
    rtos_name = "FreeRTOS SMP";
#else
    rtos_name = "FreeRTOS";
#endif

#if ( configNUMBER_OF_CORES == 2 )
    printf("Starting %s on both cores\n", rtos_name);
    vLaunch();
#elif ( RUN_FREERTOS_ON_CORE == 1 )
    printf("Starting %s on core 1\n", rtos_name);
    multicore_launch_core1(vLaunch);
    while (true);
#else
    printf("Starting %s on core 0\n", rtos_name);
    vLaunch();
#endif
    return 0;
}
