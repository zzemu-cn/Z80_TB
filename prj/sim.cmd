@del z80sys.tb
iverilog -DSIMULATE=1 -DTV80=1 -DNEXTZ80=1 -c modules.f -o z80sys.tb
@rem iverilog -DSIMULATE=1 -DNEXTZ80=1 -c modules.f -o z80sys.tb
@rem iverilog -DSIMULATE=1 -DTV80=1 -c modules.f -o z80sys.tb

vvp z80sys.tb

gtkwave z80sys.dump