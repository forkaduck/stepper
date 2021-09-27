typedef unsigned char uint8_t;
typedef unsigned short int uint16_t;
typedef unsigned int uint32_t;

#define LEDS (*(volatile uint32_t *)0x10000000)

void wait(uint32_t);

int _start()
{
	LEDS = 0x0000000a;
	while (1) {
		wait(6000000);
		LEDS = ~(LEDS & 0xf);
	}
}

void wait(uint32_t cycles)
{
	for (uint32_t i = 0; i < cycles; i++) {
		asm("nop");
	}
}
