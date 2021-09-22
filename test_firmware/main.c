int _start()
{
	while (1) {
		*((int *)0x10000000) = 0xffffffff;
	}
}
