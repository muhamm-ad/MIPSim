--------------------------------------------------------------------------------
-- Testbench : signext (exhaustive: all 65536 input values)
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.ENV.ALL;

ENTITY tb_signext IS
END tb_signext;

ARCHITECTURE sim OF tb_signext IS
    SIGNAL din : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL dout : STD_LOGIC_VECTOR(31 DOWNTO 0);
BEGIN
    dut : ENTITY work.signext PORT MAP(data_in => din, data_out => dout);

    PROCESS
    BEGIN
        FOR i IN 0 TO 65535 LOOP
            din <= STD_LOGIC_VECTOR(TO_UNSIGNED(i, 16));
            WAIT FOR 1 ns;
            ASSERT dout = STD_LOGIC_VECTOR(RESIZE(signed(din), 32))
            REPORT "signext " & to_hstring(din) & " -> " & to_hstring(dout) SEVERITY error;
        END LOOP;

        -- A few explicit values, for readability of the spec
        din <= X"7FFF";
        WAIT FOR 1 ns;
        ASSERT dout = X"00007FFF" REPORT "max positive" SEVERITY error;
        din <= X"8000";
        WAIT FOR 1 ns;
        ASSERT dout = X"FFFF8000" REPORT "min negative" SEVERITY error;
        din <= X"FFF7"; -- -9
        WAIT FOR 1 ns;
        ASSERT dout = X"FFFFFFF7" REPORT "-9" SEVERITY error;

        REPORT "tb_signext: PASS (65536 values)";
        finish;
    END PROCESS;
END sim;
