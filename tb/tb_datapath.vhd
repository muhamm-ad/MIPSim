--------------------------------------------------------------------------------
-- Testbench : datapath
-- Drives the datapath with hand-encoded instructions and the control word the
-- decoder would produce, one instruction per clock cycle (the memory is faked:
-- 'readdata' is supplied by the testbench). Exercises R-type, addi (negative
-- immediate), sw (address + store data), lw (memory -> register), the zero flag,
-- register write enable, PC+4 and the asynchronous reset.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.ENV.ALL;

ENTITY tb_datapath IS
END tb_datapath;

ARCHITECTURE sim OF tb_datapath IS
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL reset : STD_LOGIC := '1';
    SIGNAL pc, instr, writedata, aluresult, readdata : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL regdst, regwrite, alusrc, memtoreg, zero : STD_LOGIC := '0';
    SIGNAL alucontrol : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0010";

    CONSTANT ALU_ADD : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0010";
    CONSTANT ALU_SUB : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0110";

    FUNCTION w(i : INTEGER) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        RETURN STD_LOGIC_VECTOR(TO_SIGNED(i, 32));
    END FUNCTION;
BEGIN
    clk <= NOT clk AFTER 5 ns; -- rising edges at 5, 15, 25 ... ns

    dut : ENTITY work.datapath
        PORT MAP(
            clk => clk, reset => reset, pc => pc, instr => instr,
            regdst => regdst, regwrite => regwrite, writedata => writedata,
            alusrc => alusrc, alucontrol => alucontrol, aluresult => aluresult,
            readdata => readdata, memtoreg => memtoreg, zero => zero);

    PROCESS
        VARIABLE n : INTEGER := 0; -- number of instructions executed

        -- Execute one instruction: apply instr + control word, check the
        -- combinational results, then let the clock edge commit the write-back.
        PROCEDURE exec(i : STD_LOGIC_VECTOR(31 DOWNTO 0); name : STRING;
        rd, rw, asrc, m2r : STD_LOGIC; ctl : STD_LOGIC_VECTOR(3 DOWNTO 0);
        mem_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
        want_alu : STD_LOGIC_VECTOR(31 DOWNTO 0)) IS
        BEGIN
            ASSERT pc = w(4 * n) REPORT name & ": pc expected " & to_hstring(w(4 * n)) & " got " & to_hstring(pc) SEVERITY error;
            instr <= i;
            regdst <= rd;
            regwrite <= rw;
            alusrc <= asrc;
            memtoreg <= m2r;
            alucontrol <= ctl;
            readdata <= mem_data;
            WAIT FOR 2 ns;
            ASSERT aluresult = want_alu
            REPORT name & ": aluresult expected " & to_hstring(want_alu) & " got " & to_hstring(aluresult) SEVERITY error;
            IF unsigned(want_alu) = 0 THEN
                ASSERT zero = '1' REPORT name & ": zero flag should be set" SEVERITY error;
            ELSE
                ASSERT zero = '0' REPORT name & ": zero flag should be clear" SEVERITY error;
            END IF;
            WAIT UNTIL rising_edge(clk);
            WAIT FOR 1 ns;
            n := n + 1;
        END PROCEDURE;
    BEGIN
        -- Reset: asynchronous, PC is 0 and stays there until released
        reset <= '1';
        WAIT FOR 7 ns; -- spans the first rising edge (5 ns)
        ASSERT pc = X"00000000" REPORT "pc during reset: " & to_hstring(pc) SEVERITY error;
        reset <= '0';
        WAIT FOR 1 ns;
        -- (now at 8 ns; the next rising edge is at 15 ns)

        --   instruction     name             RD RW AS M2R  alu ctl   readdata   expected ALU
        exec(X"20020005", "addi $2,$0,5   ", '0', '1', '1', '0', ALU_ADD, X"00000000", w(5));
        exec(X"2003000C", "addi $3,$0,12  ", '0', '1', '1', '0', ALU_ADD, X"00000000", w(12));
        -- R-type: destination is rd (regdst = 1), operands from registers (alusrc = 0)
        exec(X"00432020", "add  $4,$2,$3  ", '1', '1', '0', '0', ALU_ADD, X"00000000", w(17));
        -- sw: aluresult is the address (8), writedata is the register to store ($4 = 17), no write-back
        exec(X"AC040008", "sw   $4,8($0)  ", '0', '0', '1', '0', ALU_ADD, X"00000000", w(8));
        ASSERT writedata = w(17) REPORT "sw: writedata expected 17 got " & to_hstring(writedata) SEVERITY error;
        -- (the sw above must not have clobbered $4: checked by the `sub $10` below)
        -- lw: memory data (17, supplied by the testbench) is written to rt ($5)
        exec(X"8C050008", "lw   $5,8($0)  ", '0', '1', '1', '1', ALU_ADD, w(17), w(8));
        -- $5 must hold the *memory* value (17), not the ALU result (8): 17 - 5 = 12
        exec(X"00A23022", "sub  $6,$5,$2  ", '1', '1', '0', '0', ALU_SUB, X"00000000", w(12));
        -- zero flag
        exec(X"00423822", "sub  $7,$2,$2  ", '1', '1', '0', '0', ALU_SUB, X"00000000", w(0));
        -- negative immediate is sign-extended: 12 + (-9) = 3
        exec(X"2068FFF7", "addi $8,$3,-9  ", '0', '1', '1', '0', ALU_ADD, X"00000000", w(3));
        -- $8 was written through the rt path
        exec(X"01004822", "sub  $9,$8,$0  ", '1', '1', '0', '0', ALU_SUB, X"00000000", w(3));
        -- sw did not write $4 (regwrite = 0)
        exec(X"00805022", "sub  $10,$4,$0 ", '1', '1', '0', '0', ALU_SUB, X"00000000", w(17));
        -- a write to $0 never shows up on a read of $0
        exec(X"20000063", "addi $0,$0,99  ", '0', '1', '1', '0', ALU_ADD, X"00000000", w(99));
        -- ($0 - $2 = -5 only if $0 reads as 0; it would be 94 if the write had stuck)
        exec(X"00021822", "sub  $3,$0,$2  ", '1', '1', '0', '0', ALU_SUB, X"00000000", w(-5));

        -- Asynchronous reset in the middle of the run brings the PC back to 0
        reset <= '1';
        WAIT FOR 1 ns;
        ASSERT pc = X"00000000" REPORT "pc after mid-run reset: " & to_hstring(pc) SEVERITY error;

        REPORT "tb_datapath: PASS (" & INTEGER'image(n) & " instructions)";
        finish;
    END PROCESS;
END sim;
