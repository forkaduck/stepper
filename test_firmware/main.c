#define LEDS (*(short *)0x10000000)

int _start()
{
	while (1) {
		LEDS = ~LEDS;
	}
}
