--------------------------------------------------------------------------------
-- Testbench : adder (32-bit instance used for PC+4, exhaustive 8-bit instance)
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.ENV.ALL;

ENTITY tb_adder IS
END tb_adder;

ARCHITECTURE sim OF tb_adder IS
    SIGNAL a32, b32, r32 : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL a8, b8, r8 : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
BEGIN
    add32 : ENTITY work.adder GENERIC MAP(VECTOR_SIZE => 32) PORT MAP(v1 => a32, v2 => b32, vr => r32);
    add8 : ENTITY work.adder GENERIC MAP(VECTOR_SIZE => 8) PORT MAP(v1 => a8, v2 => b8, vr => r8);

    PROCESS
        VARIABLE rnd : UNSIGNED(31 DOWNTO 0) := X"0badf00d";

        PROCEDURE expect32(x, z, want : STD_LOGIC_VECTOR(31 DOWNTO 0)) IS
        BEGIN
            a32 <= x;
            b32 <= z;
            WAIT FOR 1 ns;
            ASSERT r32 = want
            REPORT "add32 " & to_hstring(x) & " + " & to_hstring(z) & " = " & to_hstring(r32) & ", expected " & to_hstring(want)
                SEVERITY error;
        END PROCEDURE;
    BEGIN
        -- PC + 4 cases
        expect32(X"00000000", X"00000004", X"00000004");
        expect32(X"00000010", X"00000004", X"00000014");
        expect32(X"0000FFFC", X"00000004", X"00010000");
        expect32(X"FFFFFFFC", X"00000004", X"00000000"); -- wraps

        -- Random 32-bit vectors
        FOR i IN 0 TO 999 LOOP
            rnd := RESIZE(rnd * TO_UNSIGNED(1664525, 32), 32) + TO_UNSIGNED(1013904223, 32);
            a32 <= STD_LOGIC_VECTOR(rnd);
            rnd := RESIZE(rnd * TO_UNSIGNED(1664525, 32), 32) + TO_UNSIGNED(1013904223, 32);
            expect32(a32, STD_LOGIC_VECTOR(rnd), STD_LOGIC_VECTOR(unsigned(a32) + rnd));
        END LOOP;

        -- Exhaustive 8-bit
        FOR i IN 0 TO 255 LOOP
            FOR j IN 0 TO 255 LOOP
                a8 <= STD_LOGIC_VECTOR(TO_UNSIGNED(i, 8));
                b8 <= STD_LOGIC_VECTOR(TO_UNSIGNED(j, 8));
                WAIT FOR 1 ns;
                ASSERT r8 = STD_LOGIC_VECTOR(TO_UNSIGNED((i + j) MOD 256, 8))
                REPORT "add8 " & INTEGER'image(i) & " + " & INTEGER'image(j) & " = " & to_hstring(r8) SEVERITY error;
            END LOOP;
        END LOOP;

        REPORT "tb_adder: PASS";
        finish;
    END PROCESS;
END sim;
