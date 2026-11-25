#!/usr/bin/env python3
"""Convert PV_LAND_final double-precision Fortran to the ARPS single precision.

REAL(8) / REAL(KIND=8) -> REAL, literals 1.5d-3 -> 1.5e-3, 2.0d0 -> 2.0,
REAL(x, 8) -> REAL(x), DGESV -> SGESV. Comments are left untouched.
Usage: to_single.py in.f90 out.f90
"""
import re
import sys


def conv_code(code):
    code = re.sub(r'(?i)REAL\s*\(\s*(KIND\s*=\s*)?8\s*\)', 'REAL', code)
    code = re.sub(r'(?i)\bREAL\s*\(([^,()]+),\s*8\s*\)', r'REAL(\1)', code)
    code = re.sub(r'(?i)(\d\.?\d*|\.\d+)[dD]0(?![0-9])', r'\1', code)
    code = re.sub(r'(?i)(\d\.?\d*|\.\d+)[dD]([-+]?\d+)', r'\1e\2', code)
    code = re.sub(r'\bDGESV\b', 'SGESV', code)
    code = re.sub(r'(?i)\bDBLE\(', 'REAL(', code)
    return code


def conv_line(line):
    # split code / comment, ignoring '!' inside quotes
    q = None
    for i, c in enumerate(line):
        if q:
            if c == q:
                q = None
        elif c in "'\"":
            q = c
        elif c == '!':
            return conv_code(line[:i]) + line[i:]
    return conv_code(line)


src = open(sys.argv[1], encoding='latin-1').read().splitlines(keepends=True)
open(sys.argv[2], 'w', encoding='latin-1').write(''.join(conv_line(l) for l in src))
