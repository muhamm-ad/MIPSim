--------------------------------------------------------------------------------
-- Testbench : imem (built-in demo program and program loaded from a file)
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.ENV.ALL;

ENTITY tb_imem IS
END tb_imem;

ARCHITECTURE sim OF tb_imem IS
    SIGNAL a : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0');
    SIGNAL rd, rd_file : STD_LOGIC_VECTOR(31 DOWNTO 0);
BEGIN
    dut : ENTITY work.imem GENERIC MAP(ADDR_SIZE => 6) PORT MAP(a => a, rd => rd);
    dut_file : ENTITY work.imem
        GENERIC MAP(ADDR_SIZE => 6, INIT_FILE => "tb/fixtures/imem_test.hex")
        PORT MAP(a => a, rd => rd_file);

    PROCESS
        PROCEDURE expect(i : INTEGER; want : STD_LOGIC_VECTOR(31 DOWNTO 0)) IS
        BEGIN
            a <= STD_LOGIC_VECTOR(TO_UNSIGNED(i, 6));
            WAIT FOR 1 ns;
            ASSERT rd = want
            REPORT "imem[" & INTEGER'image(i) & "] expected " & to_hstring(want) & " got " & to_hstring(rd)
                SEVERITY error;
        END PROCEDURE;
    BEGIN
        expect(0, X"20020005"); -- addi $v0, $0, 5
        expect(1, X"2003000C"); -- addi $v1, $0, 12
        expect(2, X"2067FFF7"); -- addi $a3, $v1, -9
        expect(3, X"00E22025"); -- or   $a0, $a3, $v0
        expect(4, X"00642824"); -- and  $a1, $v1, $a0
        expect(5, X"00A42820"); -- add  $a1, $a1, $a0
        FOR i IN 6 TO 63 LOOP
            expect(i, X"00000000"); -- rest of the memory is zero (nop)
        END LOOP;

        -- Program loaded from a file (comments, blank lines, mixed case, trailing text ignored)
        a <= STD_LOGIC_VECTOR(TO_UNSIGNED(0, 6));
        WAIT FOR 1 ns;
        ASSERT rd_file = X"20020005" REPORT "file[0]: " & to_hstring(rd_file) SEVERITY error;
        a <= STD_LOGIC_VECTOR(TO_UNSIGNED(1, 6));
        WAIT FOR 1 ns;
        ASSERT rd_file = X"2003000C" REPORT "file[1]: " & to_hstring(rd_file) SEVERITY error;
        a <= STD_LOGIC_VECTOR(TO_UNSIGNED(2, 6));
        WAIT FOR 1 ns;
        ASSERT rd_file = X"2067FFF7" REPORT "file[2]: " & to_hstring(rd_file) SEVERITY error;
        a <= STD_LOGIC_VECTOR(TO_UNSIGNED(3, 6));
        WAIT FOR 1 ns;
        ASSERT rd_file = X"DEADBEEF" REPORT "file[3]: " & to_hstring(rd_file) SEVERITY error;
        FOR i IN 4 TO 63 LOOP
            a <= STD_LOGIC_VECTOR(TO_UNSIGNED(i, 6));
            WAIT FOR 1 ns;
            ASSERT rd_file = X"00000000" REPORT "file[" & INTEGER'image(i) & "] should be 0: " & to_hstring(rd_file) SEVERITY error;
        END LOOP;

        REPORT "tb_imem: PASS";
        finish;
    END PROCESS;
END sim;
