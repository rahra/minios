/*! \file ledproc.c
 * This file contains the function led_proc() which continuously toggles the
 * led on the Arduino board. The function is started as separate process by
 * main().
 * The function wait() waits a given number of time slices.
 * @author Bernhard R. Fischer, 4096R/8E24F29D bf@abenteuerland.at
 */

int toggle_led(void);            // defined in led.S
void init_ledport(void);         // defined in led.S
unsigned long get_uptime(void);  // defined in timer.S
void sys_sleep(void);            // defined in process.S


/* Waits the defined number t of time slices until it returns.
 * @param t Number of time slices to wait.
 */
void wait(unsigned int t)
{
   unsigned long end;

   end = get_uptime() + t;
   while (get_uptime() < end)
      sys_sleep();
}


/* This function continuously toggles the led. The function does never return.
 */
void led_proc(void)
{
   init_ledport();
   for (;;)
   {
      toggle_led();
      wait(5);
   }
}

