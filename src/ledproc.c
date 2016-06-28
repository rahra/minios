
int toggle_led(void);
unsigned long get_uptime(void);


void wait(unsigned int t)
{
   unsigned long end;

   end = get_uptime() + t;
   while (get_uptime() < end);
}



void led_proc(void)
{
   for (;;)
   {
      toggle_led();
      wait(1);
   }
}


