--------------------------------------------------------------------------------
-- Testbench : flopr (resettable flip-flop, asynchronous active-high reset)
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE STD.ENV.ALL;

ENTITY tb_flopr IS
END tb_flopr;

ARCHITECTURE sim OF tb_flopr IS
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL reset : STD_LOGIC := '0';
    SIGNAL d, q : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
BEGIN
    dut : ENTITY work.flopr GENERIC MAP(DATA_WIDTH => 32) PORT MAP(clk => clk, reset => reset, d => d, q => q);

    PROCESS
    BEGIN
        -- Asynchronous reset: q is cleared without any clock edge
        reset <= '1';
        d <= X"FFFFFFFF";
        WAIT FOR 1 ns;
        ASSERT q = X"00000000" REPORT "async reset: got " & to_hstring(q) SEVERITY error;

        -- A rising edge while reset is asserted must not load d
        clk <= '1';
        WAIT FOR 1 ns;
        clk <= '0';
        WAIT FOR 1 ns;
        ASSERT q = X"00000000" REPORT "edge during reset: got " & to_hstring(q) SEVERITY error;

        -- Release reset: still holds until a rising edge
        reset <= '0';
        WAIT FOR 1 ns;
        ASSERT q = X"00000000" REPORT "hold after reset release: got " & to_hstring(q) SEVERITY error;

        -- Loads d on the rising edge only
        d <= X"12345678";
        WAIT FOR 1 ns;
        ASSERT q = X"00000000" REPORT "q changed before the edge: got " & to_hstring(q) SEVERITY error;
        clk <= '1';
        WAIT FOR 1 ns;
        ASSERT q = X"12345678" REPORT "load on rising edge: got " & to_hstring(q) SEVERITY error;

        -- Falling edge and d changes do not affect q
        clk <= '0';
        d <= X"AAAAAAAA";
        WAIT FOR 1 ns;
        ASSERT q = X"12345678" REPORT "falling edge / d change: got " & to_hstring(q) SEVERITY error;

        -- Next rising edge loads the new value
        clk <= '1';
        WAIT FOR 1 ns;
        ASSERT q = X"AAAAAAAA" REPORT "second load: got " & to_hstring(q) SEVERITY error;

        -- Reset in the middle of operation clears asynchronously (clock high)
        reset <= '1';
        WAIT FOR 1 ns;
        ASSERT q = X"00000000" REPORT "mid-run async reset: got " & to_hstring(q) SEVERITY error;

        REPORT "tb_flopr: PASS";
        finish;
    END PROCESS;
END sim;
