#!/usr/bin/env python3
"""Write the &pvland namelist block from module pvland_nml (module_pvland.f90).

Each parameter gets its default value and its one-line description, taken
from the declarations of the module. Values can be overridden:
    make_pvland_nml.py module_pvland.f90 [name=value ...] > block.txt
"""
import re
import sys

src = open(sys.argv[1], encoding='latin-1').read()
mod = src[src.index('MODULE pvland_nml'):src.index('END MODULE pvland_nml')]
over = dict(a.split('=', 1) for a in sys.argv[2:])

out = [' &pvland']
for line in mod.splitlines():
    m = re.match(r'\s*!\s*----\s*(.*?)\s*----', line)
    if m:
        out.append('')
        out.append(f'   ! --- {m.group(1)} ---')
        continue
    m = re.match(r'\s*(INTEGER|REAL)\s*::\s*(\w+)\s*=\s*([^!]+?)\s*!\s*(.*)$', line)
    if m:
        name, val, desc = m.group(2), m.group(3), m.group(4)
        val = over.get(name, val)
        out.append(f'   {name:<20s} = {val + ",":<10s} ! {desc}')
out.append(' /')
print('\n'.join(out))
