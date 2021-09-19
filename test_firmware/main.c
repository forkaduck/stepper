int _start()
{
	for (int i = 0; i < 4; i++) {
		*((int *)0x10000000) = !(*((int *)0x10000000));
	}

	while (1) {
	}
}
