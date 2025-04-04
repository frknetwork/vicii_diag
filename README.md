# Overview
This visual test in text mode tests the VICII's ability to access
memory in certain ways. In particular, it tests accessing 16k memory blocks
other than the default. Issues with memory access will result in predictable
display artifacts that (hopefully) will give clues to the underlying problems.

# Background
My C64 recently had a weird issue where diagnostics passed, and a lot of
stuff seemed to work fine, but some games were giving me garbled graphics.

It was acting like a memory issue, but, from the CPU's point of view,
memory was fine. Along the way, I learned that the VICII accesses
memory VERY differently from the CPU. Specifically:
* It can only see 16kb at a time and relies on signals from one of the CIA chips to select different banks.
* Banks 0 and 2 ALWAYS see the character ROM at location $1000 (tho where it actually reads character data is configurable)
* Banks 1 and 3 NEVER see the character ROM at all and can only access character data from RAM.
* It can't access kernel or BASIC ROMs or access IO addresses. It ONLY sees RAM and character ROM.

I guessed that something was failing when some games tried to point the
VICII at diffent 16k banks. I'd wanted to learn 6502 assembly anyway, so I
decided to hack together a "quick" test to exercise the paging.

It ended up taking a LOT longer to write the test than to actually figure
out the problem on my machine. :-) (The problem was a bad socket on U14).

Please forgive the ugliness of my code. It's been a decade or two since I've
written assembly and never for the 6502 and Kick Assembler. I should really
make more consistent use of constants, and use scoping and macros to make
stuff easier to read. It would also be better to populate memory pages at
run time rather than abusing the loader the way I am. Oh well. :-)

# How to use this test
Start with a mostly working machine. You should be able to get to the
"ready" screen and be able to load and run a program.

Load the program. Your screen will immediately fill with text because
the program loaded data into screen RAM, but the program isn't running
yet.
<todo insert screen shot here>

Arrow to a blank line and type "RUN". Then tap space. The screen should
change to a similar page, but it should say "BANK1" at the top and
the bottom of the page should be filled with 1s.

Keep tapping space. It should flip between banks 0 thru 3 and then back
to 0.
Now tap F1. The font should toggle between the standard C64 font with PETSCII
characters and a mixed upper/lower case font.

If you see anything weird, you have a fault.

# How to interpret results
There are infinite ways things can fail, and I can't predict them all, but here
are a few things that seem likely.

### What happens:
Hitting space doesn't flip through all (or any) of the banks.
### What's up:
Try hitting F1 to flip fonts just to make sure the program is running.
Bank selection may be broken. Take a look at the components related to that. On
my machine that's signals VA14 and VA15 which start on pins 2 and 3 of U2.
Don't assume the CIA is to blame (tho it might be). It could be a bad
component elsewhere, a bad trace, a short, lots of things.

### What happens:
One particular bank is garbled.
### What's up:
Something is failing when the VICII accesses that range. Bad RAM, maybe?

### What happens:
Character set is incomplete or screwed up. Characters repeat or have
lines through them.
### What's up:
Look for stuck bits. Repeated characters could be a problem in the
VICII reading from a certain data bit in RAM or an address line on
character ROM. Lines are probably stuck data bits. Character ROM
might also be toast.

### What happens:
The character set is wrong on pages 0 and 2 but right on 1 and 3 (or the
opposite).
### What's up:
The VICII might be able to access RAM but not the character ROM (or the
opposite). Take a look at the chip select line on that character ROM. If
this happens, I suspect the PLA.


[The Pictorial C64 Fault Guide](https://www.pictorial64.com/) is also a great
resource for diagnosing visual errors!

# FAQ
Q: Why don't you just display "BAD" or something and show clear instructions
on a failure?\
A: That would only work if the CPU could see the problem. This test is
for problems the CPU can't see that cause the VICII to misbehave. There
are a few things I could do to make some things clearer. Hopefully
in future revisions.

Q: I have a suggestion. What should I do?\
A: Drop me a line in email. If you're willing to write code to add
something you want, awesome, but talk to me first. I want to make
sure we're aligned. I also have a lot of other projects going on
all the time, and I'm easily distracted. :-) No promises on what
I'll get done.

Q: What about other graphics modes? Other VICII capabilities.\
A: I'd love for this to be the first in a series of similar tests.
We'll see if I get time.

Q: I want to use your code to train my AI. Can I?\
A: No.

Q: I want to fork your code to do something else. Can I?\
A: Sure. So long as you comply with the license, INCLUDING
the restriction on no use in AI, and ensure that 
