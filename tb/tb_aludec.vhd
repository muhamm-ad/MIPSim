--------------------------------------------------------------------------------
-- Testbench : aludec
-- Checks the (ALUop, funct) -> ALU control table of Docs/Supported_Instruction.md
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.ENV.ALL;

ENTITY tb_aludec IS
END tb_aludec;

ARCHITECTURE sim OF tb_aludec IS
    SIGNAL aluop : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
    SIGNAL funct : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000000";
    SIGNAL alucontrol : STD_LOGIC_VECTOR(3 DOWNTO 0);
BEGIN
    dut : ENTITY work.aludec PORT MAP(funct => funct, aluop => aluop, alucontrol => alucontrol);

    PROCESS
        VARIABLE n_checks : INTEGER := 0;

        PROCEDURE expect(op : STD_LOGIC_VECTOR(2 DOWNTO 0); f : STD_LOGIC_VECTOR(5 DOWNTO 0);
        want : STD_LOGIC_VECTOR(3 DOWNTO 0); name : STRING) IS
        BEGIN
            aluop <= op;
            funct <= f;
            WAIT FOR 1 ns;
            ASSERT alucontrol = want
            REPORT name & ": aluop=" & to_string(op) & " funct=" & to_string(f)
                & " expected " & to_string(want) & " got " & to_string(alucontrol)
                SEVERITY error;
            n_checks := n_checks + 1;
        END PROCEDURE;
    BEGIN
        -- ALUop selects the operation directly (funct is a don't-care)
        FOR f IN 0 TO 63 LOOP
            expect("000", STD_LOGIC_VECTOR(TO_UNSIGNED(f, 6)), "0010", "aluop add");
            expect("001", STD_LOGIC_VECTOR(TO_UNSIGNED(f, 6)), "0000", "aluop and");
            expect("010", STD_LOGIC_VECTOR(TO_UNSIGNED(f, 6)), "0110", "aluop sub");
            expect("100", STD_LOGIC_VECTOR(TO_UNSIGNED(f, 6)), "0001", "aluop or");
            expect("101", STD_LOGIC_VECTOR(TO_UNSIGNED(f, 6)), "0111", "aluop slt");
            expect("110", STD_LOGIC_VECTOR(TO_UNSIGNED(f, 6)), "----", "aluop unused");
            expect("111", STD_LOGIC_VECTOR(TO_UNSIGNED(f, 6)), "----", "aluop unused");
        END LOOP;

        -- R-type: ALUop 011, decoded from funct
        expect("011", "100000", "0010", "add");
        expect("011", "100001", "0010", "addu");
        expect("011", "100010", "0110", "sub");
        expect("011", "100011", "0110", "subu");
        expect("011", "100100", "0000", "and");
        expect("011", "100101", "0001", "or");
        expect("011", "100111", "0011", "nor");
        expect("011", "101010", "0111", "slt");
        expect("011", "111111", "----", "undefined funct");
        expect("011", "000001", "----", "undefined funct");

        REPORT "tb_aludec: PASS (" & INTEGER'image(n_checks) & " checks)";
        finish;
    END PROCESS;
END sim;
