--------------------------------------------------------------------------------
-- Testbench : complete system (top = mips core + imem + dmem), data driven.
--
-- Runs the program PROGRAM (hex file produced by tools/asm.py) until it halts,
-- then checks the final data memory against the EXPECT file.
--
--   * Halt detection: the PC does not change across a clock edge (the program
--     ended with `halt`, i.e. `j <itself>`). Failing to halt within MAX_CYCLES is
--     an error.
--   * Data memory model: every store seen on the core's memory interface
--     (memwrite / dataadr / writedata) is recorded at the rising clock edge, just
--     before it is committed by the real dmem. A store outside the data memory is
--     an error.
--   * EXPECT file: lines "<byte address> <value>" in hex (8 digits each); '#'
--     starts a comment. Every expected word must have been written and hold the
--     expected value. With the default EXPECT = "" only the halt is checked.
--
-- Run one program:  ghdl -r tb_mips -gPROGRAM=programs/gcd.hex -gEXPECT=programs/gcd.expect
-- (see `make sim PROG=programs/gcd` and `make test`).
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.TEXTIO.ALL;
USE STD.ENV.ALL;

ENTITY tb_mips IS
    GENERIC (
        PROGRAM : STRING := "programs/smoke.hex";
        EXPECT : STRING := ""; -- expectation file, "" = only check that the program halts
        IMEM_ADDR_SIZE : INTEGER := 8; -- 256 instructions
        DMEM_SIZE : INTEGER := 64; -- words
        MAX_CYCLES : INTEGER := 20000;
        VERBOSE : BOOLEAN := FALSE -- print every store
    );
END tb_mips;

ARCHITECTURE sim OF tb_mips IS
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL reset : STD_LOGIC := '1';
    SIGNAL pc, writedata, dataadr : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL memwrite : STD_LOGIC;
BEGIN
    clk <= NOT clk AFTER 5 ns; -- rising edges at 5, 15, 25 ... ns

    dut : ENTITY work.top
        GENERIC MAP(IMEM_ADDR_SIZE => IMEM_ADDR_SIZE, DMEM_SIZE => DMEM_SIZE, PROGRAM => PROGRAM)
        PORT MAP(clk => clk, reset => reset, pc => pc, writedata => writedata, dataadr => dataadr, memwrite => memwrite);

    PROCESS
        TYPE word_array IS ARRAY(0 TO DMEM_SIZE - 1) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
        TYPE flag_array IS ARRAY(0 TO DMEM_SIZE - 1) OF BOOLEAN;
        VARIABLE model : word_array := (OTHERS => (OTHERS => '0'));
        VARIABLE written : flag_array := (OTHERS => FALSE);
        VARIABLE prev_pc : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => 'U');
        VARIABLE cycles : NATURAL := 0;
        VARIABLE stores : NATURAL := 0;
        VARIABLE checks : NATURAL := 0;
        VARIABLE halted : BOOLEAN := FALSE;
        VARIABLE idx : NATURAL;

        FILE ef : TEXT;
        VARIABLE estatus : FILE_OPEN_STATUS;
        VARIABLE l : LINE;
        VARIABLE addr, value : STD_LOGIC_VECTOR(31 DOWNTO 0);
        VARIABLE good_a, good_v, comment : BOOLEAN;
        VARIABLE c : CHARACTER;
        VARIABLE lineno : NATURAL := 0;
    BEGIN
        -- Release reset before the first rising edge so instruction 0 executes normally
        reset <= '1';
        WAIT FOR 2 ns;
        reset <= '0';

        -- Run until halt ---------------------------------------------------------
        WHILE NOT halted AND cycles < MAX_CYCLES LOOP
            WAIT UNTIL rising_edge(clk); -- signals still hold their pre-edge values here
            cycles := cycles + 1;
            IF pc = prev_pc THEN
                halted := TRUE;
            ELSE
                prev_pc := pc;
                IF memwrite = '1' THEN
                    ASSERT NOT is_x(dataadr) AND NOT is_x(writedata)
                    REPORT PROGRAM & ": store with undefined address/data at pc=" & to_hstring(pc)
                        SEVERITY error;
                    idx := TO_INTEGER(unsigned(dataadr(31 DOWNTO 2)));
                    ASSERT idx < DMEM_SIZE
                    REPORT PROGRAM & ": store outside data memory, address " & to_hstring(dataadr)
                        & " at pc=" & to_hstring(pc) SEVERITY error;
                    model(idx) := writedata;
                    written(idx) := TRUE;
                    stores := stores + 1;
                    IF VERBOSE THEN
                        REPORT "store MEM[" & to_hstring(dataadr) & "] = " & to_hstring(writedata)
                            & " (" & INTEGER'image(TO_INTEGER(signed(writedata))) & ") at pc=" & to_hstring(pc);
                    END IF;
                END IF;
            END IF;
        END LOOP;
        ASSERT halted
        REPORT PROGRAM & ": did not halt within " & INTEGER'image(MAX_CYCLES) & " cycles (last pc=" & to_hstring(pc) & ")"
            SEVERITY error;

        -- Check expectations -------------------------------------------------------
        IF EXPECT'length > 0 THEN
            file_open(estatus, ef, EXPECT, read_mode);
            ASSERT estatus = open_ok REPORT "cannot open expectation file '" & EXPECT & "'" SEVERITY failure;
            WHILE NOT endfile(ef) LOOP
                readline(ef, l);
                lineno := lineno + 1;
                comment := TRUE;
                FOR k IN l'RANGE LOOP
                    c := l(k);
                    IF c /= ' ' AND c /= HT THEN
                        comment := (c = '#');
                        EXIT;
                    END IF;
                END LOOP;
                IF NOT comment THEN
                    hread(l, addr, good_a);
                    hread(l, value, good_v);
                    ASSERT good_a AND good_v
                    REPORT EXPECT & ":" & INTEGER'image(lineno) & ": expected '<addr> <value>' (8 hex digits each)"
                        SEVERITY failure;
                    idx := TO_INTEGER(unsigned(addr(31 DOWNTO 2)));
                    ASSERT idx < DMEM_SIZE
                    REPORT EXPECT & ":" & INTEGER'image(lineno) & ": address " & to_hstring(addr) & " is outside the data memory"
                        SEVERITY failure;
                    ASSERT written(idx)
                    REPORT PROGRAM & ": MEM[" & to_hstring(addr) & "] was never written (expected " & to_hstring(value) & ")"
                        SEVERITY error;
                    ASSERT model(idx) = value
                    REPORT PROGRAM & ": MEM[" & to_hstring(addr) & "] expected " & to_hstring(value)
                        & " (" & INTEGER'image(TO_INTEGER(signed(value))) & ") got " & to_hstring(model(idx))
                        & " (" & INTEGER'image(TO_INTEGER(signed(model(idx)))) & ")" SEVERITY error;
                    checks := checks + 1;
                END IF;
            END LOOP;
            file_close(ef);
        END IF;

        REPORT "tb_mips[" & PROGRAM & "]: PASS (" & INTEGER'image(cycles) & " cycles, "
            & INTEGER'image(stores) & " stores, " & INTEGER'image(checks) & " expectations)";
        finish;
    END PROCESS;
END sim;
