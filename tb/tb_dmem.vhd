--------------------------------------------------------------------------------
-- Testbench : dmem (64-word data memory, byte addressing of aligned words)
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.ENV.ALL;

ENTITY tb_dmem IS
END tb_dmem;

ARCHITECTURE sim OF tb_dmem IS
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL we : STD_LOGIC := '0';
    SIGNAL a, wd, rd : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

    FUNCTION addr(i : INTEGER) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        RETURN STD_LOGIC_VECTOR(TO_UNSIGNED(i, 32));
    END FUNCTION;
BEGIN
    clk <= NOT clk AFTER 5 ns; -- rising edges at 5, 15, 25 ... ns

    dut : ENTITY work.dmem GENERIC MAP(MEM_SIZE => 64) PORT MAP(clk => clk, we => we, a => a, wd => wd, rd => rd);

    PROCESS
        PROCEDURE write_word(byte_addr : INTEGER; v : STD_LOGIC_VECTOR(31 DOWNTO 0)) IS
        BEGIN
            a <= addr(byte_addr);
            wd <= v;
            we <= '1';
            WAIT UNTIL rising_edge(clk);
            WAIT FOR 1 ns;
            we <= '0';
        END PROCEDURE;

        PROCEDURE expect_read(byte_addr : INTEGER; want : STD_LOGIC_VECTOR(31 DOWNTO 0); name : STRING) IS
        BEGIN
            a <= addr(byte_addr);
            WAIT FOR 1 ns;
            ASSERT rd = want
            REPORT name & ": read @" & INTEGER'image(byte_addr) & " expected " & to_hstring(want) & " got " & to_hstring(rd)
                SEVERITY error;
        END PROCEDURE;
    BEGIN
        WAIT UNTIL rising_edge(clk);
        WAIT FOR 1 ns;

        -- Memory starts cleared
        expect_read(0, X"00000000", "initial");
        expect_read(252, X"00000000", "initial last word");

        -- Word writes at consecutive word addresses (byte addresses 0, 4, 8, ...)
        write_word(0, X"11111111");
        write_word(4, X"22222222");
        write_word(252, X"EEEEEEEE"); -- last word (index 63)
        expect_read(0, X"11111111", "word 0");
        expect_read(4, X"22222222", "word 1");
        expect_read(8, X"00000000", "word 2 untouched");
        expect_read(252, X"EEEEEEEE", "word 63");

        -- The two low address bits are ignored (aligned word access)
        expect_read(5, X"22222222", "alias @5");
        expect_read(6, X"22222222", "alias @6");
        expect_read(7, X"22222222", "alias @7");
        write_word(9, X"33333333"); -- same word as byte address 8
        expect_read(8, X"33333333", "word 2 via @9");

        -- The read is combinational, the write is synchronous
        a <= addr(12);
        wd <= X"44444444";
        we <= '1';
        WAIT FOR 1 ns;
        ASSERT rd = X"00000000" REPORT "write must not be combinational: " & to_hstring(rd) SEVERITY error;
        WAIT UNTIL rising_edge(clk);
        WAIT FOR 1 ns;
        we <= '0';
        ASSERT rd = X"44444444" REPORT "value after edge: " & to_hstring(rd) SEVERITY error;

        -- No write when we = 0
        a <= addr(16);
        wd <= X"55555555";
        we <= '0';
        WAIT UNTIL rising_edge(clk);
        WAIT FOR 1 ns;
        expect_read(16, X"00000000", "we=0 must not write");

        -- Out of range: reads give zero, writes are ignored (and corrupt nothing)
        write_word(256, X"DEADBEEF"); -- word 64, first one out of range
        expect_read(256, X"00000000", "out of range read");
        write_word(16#7FFFFFF0#, X"DEADBEEF");
        expect_read(16#7FFFFFF0#, X"00000000", "far out of range read");
        expect_read(0, X"11111111", "word 0 intact after OOB write");
        expect_read(252, X"EEEEEEEE", "word 63 intact after OOB write");

        REPORT "tb_dmem: PASS";
        finish;
    END PROCESS;
END sim;
