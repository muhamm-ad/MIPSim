--------------------------------------------------------------------------------
-- Testbench : mux
-- Checks the packing convention (input 0 = least significant bits) for several
-- widths / input counts, and the behaviour of an out-of-range select.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.ENV.ALL;

ENTITY tb_mux IS
END tb_mux;

ARCHITECTURE sim OF tb_mux IS
    -- 2 x 4-bit
    SIGNAL d2 : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"A5"; -- input1 = A, input0 = 5
    SIGNAL s2 : STD_LOGIC_VECTOR(0 DOWNTO 0) := "0";
    SIGNAL y2 : STD_LOGIC_VECTOR(3 DOWNTO 0);
    -- 4 x 8-bit
    SIGNAL d4 : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"44332211";
    SIGNAL s4 : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
    SIGNAL y4 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    -- 3 x 2-bit (select value 3 is out of range)
    SIGNAL d3 : STD_LOGIC_VECTOR(5 DOWNTO 0) := "100111"; -- in2=10 in1=01 in0=11
    SIGNAL s3 : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
    SIGNAL y3 : STD_LOGIC_VECTOR(1 DOWNTO 0);
    -- 2 x 1-bit
    SIGNAL d1 : STD_LOGIC_VECTOR(1 DOWNTO 0) := "10";
    SIGNAL s1 : STD_LOGIC_VECTOR(0 DOWNTO 0) := "0";
    SIGNAL y1 : STD_LOGIC_VECTOR(0 DOWNTO 0);
BEGIN
    m2 : ENTITY work.mux GENERIC MAP(DATA_WIDTH => 4, N_INPUTS => 2) PORT MAP(data_in => d2, sel => s2, data_out => y2);
    m4 : ENTITY work.mux GENERIC MAP(DATA_WIDTH => 8, N_INPUTS => 4) PORT MAP(data_in => d4, sel => s4, data_out => y4);
    m3 : ENTITY work.mux GENERIC MAP(DATA_WIDTH => 2, N_INPUTS => 3) PORT MAP(data_in => d3, sel => s3, data_out => y3);
    m1 : ENTITY work.mux GENERIC MAP(DATA_WIDTH => 1, N_INPUTS => 2) PORT MAP(data_in => d1, sel => s1, data_out => y1);

    PROCESS
    BEGIN
        -- 2 x 4-bit: sel=0 -> low nibble, sel=1 -> high nibble
        s2 <= "0";
        WAIT FOR 1 ns;
        ASSERT y2 = X"5" REPORT "m2 sel=0: got " & to_hstring(y2) SEVERITY error;
        s2 <= "1";
        WAIT FOR 1 ns;
        ASSERT y2 = X"A" REPORT "m2 sel=1: got " & to_hstring(y2) SEVERITY error;
        d2 <= X"3C";
        WAIT FOR 1 ns;
        ASSERT y2 = X"3" REPORT "m2 data change while sel=1: got " & to_hstring(y2) SEVERITY error;

        -- 4 x 8-bit
        FOR i IN 0 TO 3 LOOP
            s4 <= STD_LOGIC_VECTOR(TO_UNSIGNED(i, 2));
            WAIT FOR 1 ns;
            ASSERT y4 = STD_LOGIC_VECTOR(TO_UNSIGNED((i + 1) * 17, 8))
            REPORT "m4 sel=" & INTEGER'image(i) & ": got " & to_hstring(y4) SEVERITY error;
        END LOOP;

        -- 3 x 2-bit
        s3 <= "00";
        WAIT FOR 1 ns;
        ASSERT y3 = "11" REPORT "m3 sel=0: got " & to_string(y3) SEVERITY error;
        s3 <= "01";
        WAIT FOR 1 ns;
        ASSERT y3 = "01" REPORT "m3 sel=1: got " & to_string(y3) SEVERITY error;
        s3 <= "10";
        WAIT FOR 1 ns;
        ASSERT y3 = "10" REPORT "m3 sel=2: got " & to_string(y3) SEVERITY error;
        s3 <= "11";
        WAIT FOR 1 ns;
        ASSERT y3 = "XX" REPORT "m3 sel=3 (out of range) must be undefined, got " & to_string(y3) SEVERITY error;

        -- 2 x 1-bit (the instance shape used for regdst / alusrc / memtoreg)
        s1 <= "0";
        WAIT FOR 1 ns;
        ASSERT y1 = "0" REPORT "m1 sel=0: got " & to_string(y1) SEVERITY error;
        s1 <= "1";
        WAIT FOR 1 ns;
        ASSERT y1 = "1" REPORT "m1 sel=1: got " & to_string(y1) SEVERITY error;

        REPORT "tb_mux: PASS";
        finish;
    END PROCESS;
END sim;
