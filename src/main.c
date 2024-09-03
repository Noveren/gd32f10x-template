
#include "gd32f10x.h"

void main() {
    rcu_periph_clock_enable(RCU_GPIOC);
    gpio_init(GPIOC, GPIO_MODE_OUT_PP, GPIO_OSPEED_50MHZ, GPIO_PIN_13);
    // gpio_bit_set(GPIOC, GPIO_PIN_13);
    gpio_bit_reset(GPIOC, GPIO_PIN_13);
    for (;;) {

    }
}