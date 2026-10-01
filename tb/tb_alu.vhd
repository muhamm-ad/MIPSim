--------------------------------------------------------------------------------
-- Testbench : alu
-- Directed corner cases + pseudo-random vectors checked against a reference.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.ENV.ALL;

ENTITY tb_alu IS
END tb_alu;

ARCHITECTURE sim OF tb_alu IS
    SIGNAL a, b, y : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL sh : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000";
    SIGNAL ctl : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000";
    SIGNAL zero : STD_LOGIC;

    -- Reference model (independent from the DUT's coding style: the shifts are
    -- done one bit at a time)
    FUNCTION ref(x, z : STD_LOGIC_VECTOR(31 DOWNTO 0); n : INTEGER; op : STD_LOGIC_VECTOR(3 DOWNTO 0))
        RETURN STD_LOGIC_VECTOR IS
        VARIABLE r : STD_LOGIC_VECTOR(31 DOWNTO 0);
    BEGIN
        CASE op IS
            WHEN "0000" => r := x AND z;
            WHEN "0001" => r := x OR z;
            WHEN "0010" => r := STD_LOGIC_VECTOR(signed(x) + signed(z));
            WHEN "0011" => r := NOT (x OR z);
            WHEN "0100" => r := x AND NOT z;
            WHEN "0101" => r := x OR NOT z;
            WHEN "0110" => r := STD_LOGIC_VECTOR(signed(x) - signed(z));
            WHEN "0111" =>
                IF signed(x) < signed(z) THEN
                    r := X"00000001";
                ELSE
                    r := X"00000000";
                END IF;
            WHEN "1000" =>
                IF unsigned(x) < unsigned(z) THEN
                    r := X"00000001";
                ELSE
                    r := X"00000000";
                END IF;
            WHEN "1001" => r := x XOR z;
            WHEN "1010" => -- SLL of z
                r := z;
                FOR i IN 1 TO n LOOP
                    r := r(30 DOWNTO 0) & '0';
                END LOOP;
            WHEN "1011" => -- SRL of z
                r := z;
                FOR i IN 1 TO n LOOP
                    r := '0' & r(31 DOWNTO 1);
                END LOOP;
            WHEN "1100" => -- SRA of z
                r := z;
                FOR i IN 1 TO n LOOP
                    r := r(31) & r(31 DOWNTO 1);
                END LOOP;
            WHEN OTHERS => r := (OTHERS => '1');
        END CASE;
        RETURN r;
    END FUNCTION;
BEGIN
    dut : ENTITY work.alu
        GENERIC MAP(DATA_WIDTH => 32)
        PORT MAP(srca => a, srcb => b, shamt => sh, aluctl => ctl, zero => zero, aluout => y);

    PROCESS
        VARIABLE rnd : UNSIGNED(31 DOWNTO 0) := X"1badc0de";
        VARIABLE n_checks : INTEGER := 0;

        PROCEDURE expect(op : STD_LOGIC_VECTOR(3 DOWNTO 0);
        x, z, want : STD_LOGIC_VECTOR(31 DOWNTO 0); name : STRING; amount : INTEGER := 0) IS
            VARIABLE want_zero : STD_LOGIC;
        BEGIN
            ctl <= op;
            a <= x;
            b <= z;
            sh <= STD_LOGIC_VECTOR(TO_UNSIGNED(amount, 5));
            WAIT FOR 1 ns;
            ASSERT y = want
            REPORT name & ": a=" & to_hstring(x) & " b=" & to_hstring(z) & " shamt=" & INTEGER'image(amount)
                & " op=" & to_string(op) & " expected " & to_hstring(want) & " got " & to_hstring(y)
                SEVERITY error;
            IF unsigned(want) = 0 THEN
                want_zero := '1';
            ELSE
                want_zero := '0';
            END IF;
            ASSERT zero = want_zero
            REPORT name & ": zero flag expected " & STD_LOGIC'image(want_zero) & " got " & STD_LOGIC'image(zero)
                SEVERITY error;
            n_checks := n_checks + 1;
        END PROCEDURE;
    BEGIN
        -- Directed vectors -----------------------------------------------------
        expect("0000", X"F0F0F0F0", X"FF00FF00", X"F000F000", "and");
        expect("0001", X"F0F0F0F0", X"0F0F0F00", X"FFFFFFF0", "or");
        expect("0010", X"00000005", X"00000007", X"0000000C", "add");
        expect("0010", X"FFFFFFFF", X"00000001", X"00000000", "add wraps to zero");
        expect("0010", X"7FFFFFFF", X"00000001", X"80000000", "add overflow wraps");
        expect("0011", X"00000000", X"00000000", X"FFFFFFFF", "nor");
        expect("0011", X"F0F0F0F0", X"0F0F0F0F", X"00000000", "nor to zero");
        expect("0100", X"FFFFFFFF", X"0000FFFF", X"FFFF0000", "a and not b");
        expect("0101", X"00000000", X"FFFF0000", X"0000FFFF", "a or not b");
        expect("0110", X"0000000A", X"00000003", X"00000007", "sub");
        expect("0110", X"00000003", X"00000003", X"00000000", "sub equal -> zero");
        expect("0110", X"00000000", X"00000001", X"FFFFFFFF", "sub underflow");
        expect("0111", X"00000001", X"00000002", X"00000001", "slt 1<2");
        expect("0111", X"00000002", X"00000001", X"00000000", "slt 2<1");
        expect("0111", X"00000003", X"00000003", X"00000000", "slt equal");
        expect("0111", X"FFFFFFFF", X"00000000", X"00000001", "slt -1<0 (signed)");
        expect("0111", X"00000000", X"FFFFFFFF", X"00000000", "slt 0<-1");
        -- A - B overflows here: the sign of the difference is wrong, slt must not be
        expect("0111", X"80000000", X"7FFFFFFF", X"00000001", "slt min<max (overflowing diff)");
        expect("0111", X"7FFFFFFF", X"80000000", X"00000000", "slt max<min (overflowing diff)");

        -- SLTU: the same operands as the signed cases give the opposite answer
        expect("1000", X"00000001", X"00000002", X"00000001", "sltu 1<2");
        expect("1000", X"00000001", X"FFFFFFFF", X"00000001", "sltu 1<0xFFFFFFFF (unsigned)");
        expect("1000", X"FFFFFFFF", X"00000001", X"00000000", "sltu 0xFFFFFFFF<1");
        expect("1000", X"FFFFFFFF", X"00000000", X"00000000", "sltu 0xFFFFFFFF<0");
        expect("1000", X"00000000", X"FFFFFFFF", X"00000001", "sltu 0<0xFFFFFFFF");
        expect("1000", X"80000000", X"7FFFFFFF", X"00000000", "sltu 0x80000000<0x7FFFFFFF");
        expect("1000", X"00000005", X"00000005", X"00000000", "sltu equal");

        -- XOR
        expect("1001", X"F0F0F0F0", X"FF00FF00", X"0FF00FF0", "xor");
        expect("1001", X"12345678", X"12345678", X"00000000", "xor with itself -> zero");
        expect("1001", X"12345678", X"00000000", X"12345678", "xor with zero");

        -- Shifts operate on B by 'shamt'; A must be ignored
        expect("1010", X"DEADBEEF", X"00000001", X"00000002", "sll 1<<1", 1);
        expect("1010", X"DEADBEEF", X"00000001", X"80000000", "sll 1<<31", 31);
        expect("1010", X"DEADBEEF", X"12345678", X"12345678", "sll by 0", 0);
        expect("1010", X"DEADBEEF", X"FFFFFFFF", X"FFFFFFF0", "sll 0xFFFFFFFF<<4", 4);
        expect("1010", X"00000000", X"80000000", X"00000000", "sll shifts out all bits -> zero flag", 1);
        expect("1011", X"DEADBEEF", X"80000000", X"00000001", "srl 0x80000000>>31", 31);
        expect("1011", X"DEADBEEF", X"FFFFFFFF", X"0FFFFFFF", "srl 0xFFFFFFFF>>4 (zero fill)", 4);
        expect("1011", X"DEADBEEF", X"12345678", X"12345678", "srl by 0", 0);
        expect("1100", X"DEADBEEF", X"80000000", X"FFFFFFFF", "sra 0x80000000>>31 (sign fill)", 31);
        expect("1100", X"DEADBEEF", X"F0000000", X"FF000000", "sra 0xF0000000>>4", 4);
        expect("1100", X"DEADBEEF", X"7FFFFFFF", X"00000000", "sra 0x7FFFFFFF>>31", 31);
        expect("1100", X"DEADBEEF", X"7FFFFFF0", X"07FFFFFF", "sra positive >>4", 4);

        expect("1101", X"12345678", X"9ABCDEF0", X"FFFFFFFF", "undefined op 1101");
        expect("1111", X"12345678", X"9ABCDEF0", X"FFFFFFFF", "undefined op 1111");

        -- Pseudo-random vectors over every defined operation -------------------
        FOR i IN 0 TO 1999 LOOP
            rnd := RESIZE(rnd * TO_UNSIGNED(1664525, 32), 32) + TO_UNSIGNED(1013904223, 32);
            a <= STD_LOGIC_VECTOR(rnd);
            rnd := RESIZE(rnd * TO_UNSIGNED(1664525, 32), 32) + TO_UNSIGNED(1013904223, 32);
            b <= STD_LOGIC_VECTOR(rnd);
            FOR op IN 0 TO 12 LOOP
                expect(STD_LOGIC_VECTOR(TO_UNSIGNED(op, 4)), a, b,
                ref(a, b, i MOD 32, STD_LOGIC_VECTOR(TO_UNSIGNED(op, 4))), "random", i MOD 32);
            END LOOP;
        END LOOP;

        REPORT "tb_alu: PASS (" & INTEGER'image(n_checks) & " checks)";
        finish;
    END PROCESS;
END sim;
