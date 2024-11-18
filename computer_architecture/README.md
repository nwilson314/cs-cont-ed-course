# Computer Architecture Course
This holds the lab work for the [CS 15-213 course](https://learncs.me/cmu/15213) from Carnegie Mellon University.

## Notes
### Lab 1
The `dlc` compiler, which is supposed to check the lab for explicitly following the lab's coding guidelines, is a 32-bit Unix executable. However, my machine is 64-bit MacOS and the `dlc` binary does not work. Since I am self learning and have no incentive to cheat, I will not attempt to figure out how to get `dlc` to work on my machine (through some sort of virtualization).

This issue also extends to the `btest` program, which is expected to be compiled to a 32-bit binary as well. Instead, I have compiled it to a 64-bit binary and have proceeded forward with the lab. I can envision this breaking the lab, and will update when/if that happens and what the outcome will be. --> I basically implemented a 32-bit mask for the btest program to test against and capture the spriit of the lab.