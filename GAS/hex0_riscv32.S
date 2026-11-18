## Copyright (C) 2021 Ekaitz Zarraga
## Copyright (C) 2021 Andrius Štikonas
## Copyright (C) 2022 Gabriel Wicki
## This file is part of stage0.
##
## stage0 is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## stage0 is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with stage0.  If not, see <http://www.gnu.org/licenses/>.
# Compile this thing with -nostdlib


# Register use:
# s2: input fd
# s3: output fd
# s4: pending high nibble or -1

# Uses top of the stack as i/o buffer

.text
.global _start
_start:
    lw a1, 8(sp)          # Input file name

    # Open input file and store FD in s2
    li a7, 56             # sys_openat
    li a0, -100           # AT_FDCWD
    li a2, 0              # read only
    ecall
    mv s2, a0             # Save fd in s2 for later

    # Open output file and store the FD in s3
    li a0, -100           # AT_FDCWD
    lw a1, 12(sp)         # Output file (argument 3)
    li a2, 00001101
    # O_TRUNC   00001000
    # O_CREAT   00000100
    # O_WRONLY  00000001
    # OCTAL!
    li a3, 00700          # Set read, write, execute permission on user
    # S_IRWXU  00700
    # OCTAL!
    ecall
    mv s3, a0             # Save fd in s3 for later

    mv a1, sp
    li a2, 1
pair:
    li s4, -1
normal:
    jal t2, read
    li t0, 35
    beq a0, t0, comment
    li t0, 59
    bne a0, t0, decode
comment:
    jal t2, read
    li t0, 10
    beq a0, t0, normal
    li t0, 13
    bne a0, t0, comment
    j normal
decode:
    addi t0, a0, -48
    sltiu t1, t0, 10
    bnez t1, digit
    ori t0, a0, 32
    addi t0, t0, -97
    sltiu t1, t0, 6
    beqz t1, normal
    addi t0, t0, 10
digit:
    bltz s4, first
    or t0, t0, s4
    sb t0, 0(sp)
    mv a0, s3
    li a7, 64
    ecall
    j pair
first:
    slli s4, t0, 4
    j normal
read:
    mv a0, s2
    li a7, 63
    ecall
    beqz a0, exit
    lb a0, 0(sp)
    jr t2
exit:
    li a7, 93
    ecall
