#!/usr/bin/env python3
import sys

if len(sys.argv) != 3:
    print("Usage: " + sys.argv[0] + " <input blif file> <output blif file>")

clock_inv_list = {}

def process_line(line):
    global clock_inv_list
    parts = line.split()
    for i in range(len(parts)):
        parts[i] = parts[i].strip()
    if parts[0] != ".latch":
        return line
    parts = parts[1:]

    subckt = "FDRE_ZINI"
    in_wire = parts[0]
    out_wire = parts[1]
    clock =  "unconn"
    if len(parts) >= 4 and parts[3] != "NIL":
        clock = parts[3]

    invert_line = ""
    if parts[2] == "fe":
        if clock == "unconn":
            print("Found falling edge latch with global latch")
            print("Dont know how to handle")
            exit(1)
        if clock in clock_inv_list:
            clock = clock_inv_list[clock]
        else:
            new_clock = clock + "^^^^latch_map.py$clock_invert"
            clock_inv_list[clock] = new_clock
            invert_line = ".names {} {}\n0 1\n\n".format(clock, new_clock)
            clock = new_clock
    elif parts[2] != "re":
        print("Found {} latch".format(parts[2]))
        print("Can only handle rising edge or falling edge latches")
        exit(1)

    if len(parts) >= 5:
        init = int(parts[4])
        if init == 1:
            print("Dont support non zero initialisation")
            exit(1)

    subckt_line = ".subckt {} D={} C={} CE=vcc R=gnd Q={}\n".format(subckt, in_wire, clock, out_wire)
    return invert_line + subckt_line



with open(sys.argv[1], "r") as in_blif:
    with open(sys.argv[2], "w") as out_blif:
        cur_line = ""
        for line in in_blif:
            if len(line.strip()) == 0 or line.lstrip()[0] == '#':
                continue
            cur_line += line
            if cur_line[-2] == '\\':
                cur_line = cur_line[:-2]
                continue
            if ".latch" in cur_line:
                cur_line = process_line(cur_line)
            out_blif.write(cur_line)
            cur_line = ""
