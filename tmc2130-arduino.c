// Test code ripped from a blog that initializes the

#include <TMC2130Stepper.h>
TMC2130Stepper X = TMC2130Stepper(2, 3, 4, 9); //Only param 4 (CS pin) matters
TMC2130Stepper Y = TMC2130Stepper(5, 6, 7, 10);

void setup()
{
	X.begin(); // Init
	X.rms_current(500); // Current in mA
	X.microsteps(16); // Behave like the original Pololu A4988 driver
	X.interpolate(1); // But generate intermediate steps
	X.shaft_dir(1); // Invert direction to mimic original driver
	X.diag0_stall(1); // diag0 will pull low on stall
	X.diag1_stall(1);
	X.diag1_active_high(1); // diag1 will pull high on stall
	X.coolstep_min_speed(
		25000); // avoid false stall detection at low speeds
	X.sg_stall_value(14); // figured out by trial and error

	Y.begin();
	Y.rms_current(1000);
	Y.microsteps(16);
	Y.interpolate(1);
	Y.shaft_dir(1);
	Y.diag0_stall(1);
	Y.diag1_stall(1);
	Y.diag1_active_high(1);
	Y.coolstep_min_speed(25000);
	Y.sg_stall_value(15);
}

void loop()
{
}
