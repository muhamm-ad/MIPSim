--------------------------------------------------------------------------------
-- Testbench : datapath
-- Drives the datapath with hand-encoded instructions and the control word the
-- decoder would produce, one instruction per clock cycle (the memory is faked:
-- 'readdata' is supplied by the testbench). Exercises R-type, addi (negative
-- immediate), sw (address + store data), lw (memory -> register), the zero flag,
-- register write enable, zero-extended immediates, PC+4, branch and jump targets
-- and the asynchronous reset.
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
    SIGNAL pcsrc, jump : STD_LOGIC := '0';
    SIGNAL extop : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
    SIGNAL alucontrol : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0010";

    CONSTANT ALU_AND : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000";
    CONSTANT ALU_OR : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0001";
    CONSTANT ALU_ADD : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0010";
    CONSTANT ALU_SUB : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0110";
    CONSTANT ALU_SLTU : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1000";
    CONSTANT ALU_SLL : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1010";
    CONSTANT ALU_SRL : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1011";
    CONSTANT ALU_SRA : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1100";

    CONSTANT EXT_SIGN : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
    CONSTANT EXT_ZERO : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";
    CONSTANT EXT_UPPER : STD_LOGIC_VECTOR(1 DOWNTO 0) := "10";

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
            alusrc => alusrc, extop => extop, alucontrol => alucontrol, aluresult => aluresult,
            readdata => readdata, memtoreg => memtoreg, pcsrc => pcsrc, jump => jump, zero => zero);

    PROCESS
        VARIABLE n : INTEGER := 0; -- number of instructions executed
        VARIABLE exp_pc : INTEGER := 0; -- address the PC must hold before the next instruction

        -- Execute one instruction: apply instr + control word, check the
        -- combinational results, then let the clock edge commit the write-back
        -- and check the new PC (PC+4 unless next_pc is given).
        PROCEDURE exec(i : STD_LOGIC_VECTOR(31 DOWNTO 0); name : STRING;
        rd, rw, asrc, m2r : STD_LOGIC; ctl : STD_LOGIC_VECTOR(3 DOWNTO 0);
        mem_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
        want_alu : STD_LOGIC_VECTOR(31 DOWNTO 0);
        ext : STD_LOGIC_VECTOR(1 DOWNTO 0) := EXT_SIGN; psrc : STD_LOGIC := '0'; jmp : STD_LOGIC := '0';
        next_pc : INTEGER := - 1) IS
        BEGIN
            ASSERT pc = w(exp_pc) REPORT name & ": pc expected " & to_hstring(w(exp_pc)) & " got " & to_hstring(pc) SEVERITY error;
            instr <= i;
            regdst <= rd;
            regwrite <= rw;
            alusrc <= asrc;
            memtoreg <= m2r;
            alucontrol <= ctl;
            readdata <= mem_data;
            extop <= ext;
            pcsrc <= psrc;
            jump <= jmp;
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
            IF next_pc < 0 THEN
                exp_pc := exp_pc + 4;
            ELSE
                exp_pc := next_pc;
            END IF;
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

        -- Zero-extended immediates (zeroext = 1): ori 0xFFFF gives 0x0000FFFF, not 0xFFFFFFFF
        exec(X"340BFFFF", "ori  $11,$0,FFFF", '0', '1', '1', '0', ALU_OR, X"00000000", X"0000FFFF", ext => EXT_ZERO);
        exec(X"316C00FF", "andi $12,$11,00FF", '0', '1', '1', '0', ALU_AND, X"00000000", X"000000FF", ext => EXT_ZERO);
        -- The same immediate is sign-extended when extop = 00
        exec(X"340BFFFF", "ori  (sign-ext)  ", '0', '1', '1', '0', ALU_OR, X"00000000", X"FFFFFFFF", ext => EXT_SIGN);

        -- lui: the immediate goes to the upper half word (extop = 10), rs = $0
        exec(X"3C0C1234", "lui  $12,0x1234", '0', '1', '1', '0', ALU_ADD, X"00000000", X"12340000", ext => EXT_UPPER);
        exec(X"3C0DFFFF", "lui  $13,0xFFFF", '0', '1', '1', '0', ALU_ADD, X"00000000", X"FFFF0000", ext => EXT_UPPER);

        -- Shifts take B ($rt) and the shamt field (instruction bits 10:6); $2 = 5, $11 = 0xFFFFFFFF
        exec(X"00027100", "sll  $14,$2,4  ", '1', '1', '0', '0', ALU_SLL, X"00000000", w(80));
        exec(X"000B7A02", "srl  $15,$11,8 ", '1', '1', '0', '0', ALU_SRL, X"00000000", X"00FFFFFF");
        exec(X"000BC203", "sra  $24,$11,8 ", '1', '1', '0', '0', ALU_SRA, X"00000000", X"FFFFFFFF");
        -- sltu $25,$0,$11 : 0 < 0xFFFFFFFF unsigned
        exec(X"000BC82B", "sltu $25,$0,$11", '1', '1', '0', '0', ALU_SLTU, X"00000000", w(1));

        -- Branch taken (pcsrc = 1): target = (pc + 4) + (offset << 2)
        exec(X"10000003", "beq  $0,$0,+3  ", '0', '0', '0', '0', ALU_SUB, X"00000000", w(0),
        psrc => '1', next_pc => exp_pc + 4 + 12);
        exec(X"1000FFFE", "beq  $0,$0,-2  ", '0', '0', '0', '0', ALU_SUB, X"00000000", w(0),
        psrc => '1', next_pc => exp_pc + 4 - 8);
        -- Branch not taken (pcsrc = 0): falls through to PC + 4
        exec(X"10000003", "beq  (not taken)", '0', '0', '0', '0', ALU_SUB, X"00000000", w(0));

        -- Jump: target = PC+4[31:28] & address & "00"  (address field 0x40 -> byte address 0x100)
        exec(X"08000040", "j    0x100     ", '0', '0', '0', '0', ALU_ADD, X"00000000", w(0),
        jmp => '1', next_pc => 16#100#);
        exec(X"20020001", "addi $2,$0,1   ", '0', '1', '1', '0', ALU_ADD, X"00000000", w(1)); -- executes at 0x100

        -- Asynchronous reset in the middle of the run brings the PC back to 0
        reset <= '1';
        WAIT FOR 1 ns;
        ASSERT pc = X"00000000" REPORT "pc after mid-run reset: " & to_hstring(pc) SEVERITY error;

        REPORT "tb_datapath: PASS (" & INTEGER'image(n) & " instructions)";
        finish;
    END PROCESS;
END sim;
