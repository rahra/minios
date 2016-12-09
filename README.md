# MiniOS

Arduino MiniOS is a tiny multi-tasking operating system for Arduino. It was
developed during a course focusing on assembler programming and operating
system internals.

This operating system currently serves demonstrational purpose and is not
thought to be a mature OS for productional use. Although it can and probably
will be enhanced and further developed.


## Description

The core components of MiniOS is a dispatcher (```context_switch()```) and a
thumb scheduler (```get_next_proc()```). Both are implemented in the file ```process.S```. The time slices for context switching are defined by the T0
timer interrupt, every ~16ms on a 16 MHz Arduino board. The code is found in ```timer.S```. This file additionally contains an uptime counter which is used
in the function ```wait()``` in ```ledproc.c``` which sleeps a specific number
of time slices. ```Process.S``` also contains the function to start new
processes (```start_proc()```). After system initialization a single task
(```main()```) is started by the OS (see below). All other processes have to be
started subsequently by ```main()``` or sub-processes by calling ```start_proc()```.

The file ```serial_io.S``` contains the code for complete interrupt driven
sending and receiving of data on the serial line. In this case it is used for a
tiny command line interface (which actually does not no any commands at the
current stage of development ;) ).

The system is initialized in ```init.S```. This is initializing the interrupts,
the timer and all registers and starts the first initial task which is ```main()``` in ```main.S```. ```Main()``` can then start further childs.

Currently two processes are running: ```main()``` which implements the command
line and serial communication and ```led_proc()``` which lets toggle the LED on
the Arduino board. The latter is implemented in C to show the interfernce
between C and Assembler on AVR by following the [calling conventions](http://www.atmel.com/webdoc/AVRLibcReferenceManual/FAQ_1faq_reg_usage.html) accordingly.


## Author

Arduino MiniOS is developed and maintained by Bernhard R. Fischer,
4096R/8E24F29D <bf@abenteuerland.at>.  You may also [follow me on Twitter](https://twitter.com/_Rahra_) or read my [tech and society blog](https://www.cypherpunk.at/).
You may also have a look at [my collection of Arduino materials](https://www.cypherpunk.at/download/Arduino/).

Feel free to contact me :)


## License

This code is completely free. Do what every you like with it and buy me a beer.
