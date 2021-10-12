int _start()
{
	*((int *)0x10000000) = 0xffffffff;

	for (int i = 0; i < 5; i++) {
	}

	while (1) {
	}
}
