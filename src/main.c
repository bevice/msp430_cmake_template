#include <msp430.h>
#include <stdint.h>

static void __attribute__((naked, section(".crt_0042"), used))
disable_watchdog (void)
{
    WDTCTL = WDTPW | WDTHOLD;
}


int main(void) {
    // WDTCTL = WDTPW | WDTHOLD;	// Stop watchdog timer // See function above
    P1DIR |= BIT0 | BIT6;           // set P1.0 and P1.6 as output

    P1OUT |= BIT0;                              // start with P1.0 on
    P1OUT &= ~BIT6;                             // and P1.6 off

    while(1) {
        for (uint16_t i = 0; i < 0x6000; i++);  // Waste of time


        P1OUT ^= BIT0 | BIT6;                   // Invert P1.0 and P1.6


    }

    return 0;
}
