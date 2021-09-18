int _start()
{
	*((int *)(0x10000000)) = 0xffffffff;
	while (1) {
	}
}
