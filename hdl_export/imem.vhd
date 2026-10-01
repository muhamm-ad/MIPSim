--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : imem.vhd
-- Description: This file defines a generic instruction memory component named 'imem'.
-- It allows for a configurable address size with a fixed 32-bit instruction width.
--
-- The program is loaded at elaboration time from the text file INIT_FILE:
--   * one 32-bit instruction per line, as exactly 8 hexadecimal digits
--     (e.g. "20020005"), stored at consecutive word addresses starting at 0;
--   * anything after the 8 digits is ignored; blank lines and lines whose first
--     non-blank character is '#', '/' or '-' are comments;
--   * unused locations are zero (sll $0,$0,0 = nop).
-- With the default INIT_FILE = "" a small built-in demo program is used.
-- The file path is relative to the directory the simulator is started from.
-- Programs are produced from MIPS assembly by tools/asm.py.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.TEXTIO.ALL;

-- Entity declaration of imem (instruction memory)
ENTITY imem IS
    GENERIC (
        ADDR_SIZE : INTEGER := 6; -- Generic parameter for address size, default is 6 bits
        INIT_FILE : STRING := "" -- Program file (hex words), "" = built-in demo program
    );
    PORT (
        a : IN STD_LOGIC_VECTOR(ADDR_SIZE - 1 DOWNTO 0); -- Word address input (size determined by ADDR_SIZE)
        rd : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) -- 32-bit output for instruction data
    );
END imem;

-- Architecture definition of imem
ARCHITECTURE behave OF imem IS
    -- Calculate the number of memory locations based on address size
    CONSTANT MEM_SIZE : INTEGER := 2 ** ADDR_SIZE;
    TYPE ramtype IS ARRAY(0 TO MEM_SIZE - 1) OF STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- Build the memory contents: from INIT_FILE, or the built-in demo program
    IMPURE FUNCTION load_program RETURN ramtype IS
        FILE f : TEXT;
        VARIABLE status : FILE_OPEN_STATUS;
        VARIABLE l : LINE;
        VARIABLE word : STD_LOGIC_VECTOR(31 DOWNTO 0);
        VARIABLE good : BOOLEAN;
        VARIABLE m : ramtype := (OTHERS => (OTHERS => '0')); -- Memory initialization with all zeros
        VARIABLE idx : NATURAL := 0;
        VARIABLE lineno : NATURAL := 0;
        VARIABLE first : CHARACTER;
        VARIABLE comment : BOOLEAN;
    BEGIN
        IF INIT_FILE'length = 0 THEN
            -- Example initialization
            m(0) := X"20020005"; --     addi $v0, $0, 5	    # $v0(2) = 5
            m(1) := X"2003000c"; --     addi $v1, $0, 12	    # $v1(3) = 12
            m(2) := X"2067fff7"; --     addi $a3, $v1,-9 	    # $a3(7) = $v1(3) - 9 = 3
            m(3) := X"00e22025"; --     or   $a0, $a3, $v0	# $a0(4) = $a3(7) or $v0(2) = 3 or 5 = 7
            m(4) := X"00642824"; --     and  $a1, $v1, $a0	# $a1(5) = $v1(3) and $a0(4)= 12 and 7 = 4
            m(5) := X"00a42820"; --     add  $a1, $a1, $a0	# $a1(5) = $a1(5) + $a0(4) = 4 + 7 = 11
            RETURN m;
        END IF;

        file_open(status, f, INIT_FILE, read_mode);
        ASSERT status = open_ok
        REPORT "imem: cannot open program file '" & INIT_FILE & "'" SEVERITY failure;

        WHILE NOT endfile(f) LOOP
            readline(f, l);
            lineno := lineno + 1;

            -- Blank line or comment?
            comment := TRUE;
            FOR k IN l'RANGE LOOP
                first := l(k);
                IF first /= ' ' AND first /= HT THEN
                    comment := (first = '#' OR first = '/' OR first = '-');
                    EXIT;
                END IF;
            END LOOP;

            IF NOT comment THEN
                hread(l, word, good);
                ASSERT good
                REPORT "imem: " & INIT_FILE & ":" & INTEGER'image(lineno) & ": expected 8 hex digits"
                    SEVERITY failure;
                ASSERT idx < MEM_SIZE
                REPORT "imem: program '" & INIT_FILE & "' does not fit in " & INTEGER'image(MEM_SIZE)
                    & " words (ADDR_SIZE = " & INTEGER'image(ADDR_SIZE) & ")" SEVERITY failure;
                m(idx) := word;
                idx := idx + 1;
            END IF;
        END LOOP;
        file_close(f);
        RETURN m;
    END FUNCTION;

    CONSTANT mem : ramtype := load_program;
BEGIN
    -- Read memory operation: Sets the output 'rd' to the value at memory location 'a'
    rd <= mem(TO_INTEGER(unsigned(a))) WHEN NOT is_x(a) ELSE
        (OTHERS => '0'); -- Convert address 'a' to integer for memory indexing
END behave;
