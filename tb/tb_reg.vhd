--------------------------------------------------------------------------------
-- Testbench : reg (3-port register file)
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.ENV.ALL;

ENTITY tb_reg IS
END tb_reg;

ARCHITECTURE sim OF tb_reg IS
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL we3 : STD_LOGIC := '0';
    SIGNAL a1, a2, a3 : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
    SIGNAL wd3, rd1, rd2 : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

    FUNCTION reg_addr(i : INTEGER) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        RETURN STD_LOGIC_VECTOR(TO_UNSIGNED(i, 5));
    END FUNCTION;
BEGIN
    clk <= NOT clk AFTER 5 ns; -- rising edges at 5, 15, 25 ... ns

    dut : ENTITY work.reg
        PORT MAP(clk => clk, we3 => we3, a1 => a1, a2 => a2, a3 => a3, wd3 => wd3, rd1 => rd1, rd2 => rd2);

    PROCESS
        PROCEDURE write_reg(i : INTEGER; v : STD_LOGIC_VECTOR(31 DOWNTO 0)) IS
        BEGIN
            a3 <= reg_addr(i);
            wd3 <= v;
            we3 <= '1';
            WAIT UNTIL rising_edge(clk);
            WAIT FOR 1 ns;
            we3 <= '0';
        END PROCEDURE;
    BEGIN
        -- Align on a clock edge so stimuli change 1 ns after it
        WAIT UNTIL rising_edge(clk);
        WAIT FOR 1 ns;

        -- Registers are cleared at start-up (no 'U' / 'X' leaking into the datapath)
        FOR i IN 0 TO 31 LOOP
            a1 <= reg_addr(i);
            WAIT FOR 1 ns;
            ASSERT rd1 = X"00000000" REPORT "reg " & INTEGER'image(i) & " not cleared: " & to_hstring(rd1) SEVERITY error;
        END LOOP;

        -- Basic write / read on both ports
        write_reg(5, X"DEADBEEF");
        a1 <= reg_addr(5);
        a2 <= reg_addr(5);
        WAIT FOR 1 ns;
        ASSERT rd1 = X"DEADBEEF" REPORT "rd1 after write: " & to_hstring(rd1) SEVERITY error;
        ASSERT rd2 = X"DEADBEEF" REPORT "rd2 after write: " & to_hstring(rd2) SEVERITY error;

        -- The two read ports are independent
        write_reg(6, X"CAFEF00D");
        a1 <= reg_addr(5);
        a2 <= reg_addr(6);
        WAIT FOR 1 ns;
        ASSERT rd1 = X"DEADBEEF" REPORT "rd1 independent: " & to_hstring(rd1) SEVERITY error;
        ASSERT rd2 = X"CAFEF00D" REPORT "rd2 independent: " & to_hstring(rd2) SEVERITY error;

        -- $0 is hard-wired to zero even after a write
        write_reg(0, X"12345678");
        a1 <= reg_addr(0);
        a2 <= reg_addr(0);
        WAIT FOR 1 ns;
        ASSERT rd1 = X"00000000" REPORT "$0 on rd1: " & to_hstring(rd1) SEVERITY error;
        ASSERT rd2 = X"00000000" REPORT "$0 on rd2: " & to_hstring(rd2) SEVERITY error;

        -- No write without write enable
        a3 <= reg_addr(7);
        wd3 <= X"FFFFFFFF";
        we3 <= '0';
        WAIT UNTIL rising_edge(clk);
        WAIT FOR 1 ns;
        a1 <= reg_addr(7);
        WAIT FOR 1 ns;
        ASSERT rd1 = X"00000000" REPORT "write with we3=0 modified $7: " & to_hstring(rd1) SEVERITY error;

        -- Write is synchronous: the old value is visible until the clock edge
        write_reg(8, X"11111111");
        a1 <= reg_addr(8);
        a3 <= reg_addr(8);
        wd3 <= X"22222222";
        we3 <= '1';
        WAIT FOR 1 ns;
        ASSERT rd1 = X"11111111" REPORT "write must not be combinational: " & to_hstring(rd1) SEVERITY error;
        WAIT UNTIL rising_edge(clk);
        WAIT FOR 1 ns;
        we3 <= '0';
        ASSERT rd1 = X"22222222" REPORT "value after edge: " & to_hstring(rd1) SEVERITY error;

        -- Fill every register with a distinct value and read everything back
        FOR i IN 1 TO 31 LOOP
            write_reg(i, STD_LOGIC_VECTOR(TO_UNSIGNED(i * 1000 + 7, 32)));
        END LOOP;
        FOR i IN 1 TO 31 LOOP
            a1 <= reg_addr(i);
            a2 <= reg_addr(32 - i);
            WAIT FOR 1 ns;
            ASSERT rd1 = STD_LOGIC_VECTOR(TO_UNSIGNED(i * 1000 + 7, 32))
            REPORT "readback rd1 reg " & INTEGER'image(i) & ": " & to_hstring(rd1) SEVERITY error;
            ASSERT rd2 = STD_LOGIC_VECTOR(TO_UNSIGNED((32 - i) * 1000 + 7, 32))
            REPORT "readback rd2 reg " & INTEGER'image(32 - i) & ": " & to_hstring(rd2) SEVERITY error;
        END LOOP;

        REPORT "tb_reg: PASS";
        finish;
    END PROCESS;
END sim;
