--------------------------------------------------------------------------------
-- Testbench : maindec + decoder
-- Checks the control signals of every supported opcode against the table in
-- Docs/Supported_Instruction.md, both on the main decoder alone and through the
-- full 'decoder' (main decoder + ALU decoder).
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE STD.ENV.ALL;

ENTITY tb_decoder IS
END tb_decoder;

ARCHITECTURE sim OF tb_decoder IS
    SIGNAL op, funct : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0');

    -- main decoder alone
    SIGNAL m_regdst, m_alusrc, m_memwrite, m_memtoreg, m_regwrite : STD_LOGIC;
    SIGNAL m_branch, m_bne, m_jump, m_link : STD_LOGIC;
    SIGNAL m_extop : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL m_aluop : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- full decoder
    SIGNAL regdst, alusrc, memwrite, memtoreg, regwrite : STD_LOGIC;
    SIGNAL branch, bne, jump, jr, link : STD_LOGIC;
    SIGNAL extop : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL alucontrol : STD_LOGIC_VECTOR(3 DOWNTO 0);
BEGIN
    mdec : ENTITY work.maindec
        PORT MAP(
            op => op, regdst => m_regdst, alusrc => m_alusrc, memwrite => m_memwrite,
            memtoreg => m_memtoreg, regwrite => m_regwrite, branch => m_branch, bne => m_bne,
            jump => m_jump, link => m_link, extop => m_extop, aluop => m_aluop);

    dec : ENTITY work.decoder
        PORT MAP(
            op => op, funct => funct, regdst => regdst, alusrc => alusrc, memwrite => memwrite,
            memtoreg => memtoreg, regwrite => regwrite, branch => branch, bne => bne,
            jump => jump, jr => jr, link => link, extop => extop, alucontrol => alucontrol);

    PROCESS
        VARIABLE n_checks : INTEGER := 0;

        -- want = regdst & alusrc & memwrite & memtoreg & regwrite & branch & bne & jump & link & jr & extop(1:0)
        -- (the main decoder has no jr output and sees jr as a plain R-type, regwrite = 1)
        PROCEDURE expect(opcode : STD_LOGIC_VECTOR(5 DOWNTO 0); f : STD_LOGIC_VECTOR(5 DOWNTO 0);
        want : STD_LOGIC_VECTOR(11 DOWNTO 0); want_aluop : STD_LOGIC_VECTOR(2 DOWNTO 0);
        want_ctl : STD_LOGIC_VECTOR(3 DOWNTO 0); name : STRING) IS
            VARIABLE got, want_main : STD_LOGIC_VECTOR(11 DOWNTO 0);
        BEGIN
            op <= opcode;
            funct <= f;
            WAIT FOR 1 ns;
            want_main := want;
            IF want(2) = '1' THEN -- jr
                want_main(2) := '0';
                want_main(7) := '1';
            END IF;
            got := m_regdst & m_alusrc & m_memwrite & m_memtoreg & m_regwrite & m_branch & m_bne & m_jump
                & m_link & '0' & m_extop;
            ASSERT got = want_main
            REPORT name & ": maindec regdst/alusrc/memwrite/memtoreg/regwrite/branch/bne/jump/link/-/extop expected "
                & to_string(want_main) & " got " & to_string(got) SEVERITY error;
            ASSERT m_aluop = want_aluop
            REPORT name & ": maindec aluop expected " & to_string(want_aluop) & " got " & to_string(m_aluop)
                SEVERITY error;
            got := regdst & alusrc & memwrite & memtoreg & regwrite & branch & bne & jump & link & jr & extop;
            ASSERT got = want
            REPORT name & ": decoder controls expected " & to_string(want) & " got " & to_string(got)
                SEVERITY error;
            ASSERT alucontrol = want_ctl
            REPORT name & ": decoder alucontrol expected " & to_string(want_ctl) & " got " & to_string(alucontrol)
                SEVERITY error;
            n_checks := n_checks + 1;
        END PROCEDURE;
    BEGIN
        --        op        funct     RD AS MW MR RW BR BN J LK JR EX  aluop  alu_ctl
        expect("000000", "100000", "100010000000", "011", "0010", "add");
        expect("000000", "100001", "100010000000", "011", "0010", "addu");
        expect("000000", "100010", "100010000000", "011", "0110", "sub");
        expect("000000", "100011", "100010000000", "011", "0110", "subu");
        expect("000000", "100100", "100010000000", "011", "0000", "and");
        expect("000000", "100101", "100010000000", "011", "0001", "or");
        expect("000000", "100110", "100010000000", "011", "1001", "xor");
        expect("000000", "100111", "100010000000", "011", "0011", "nor");
        expect("000000", "101010", "100010000000", "011", "0111", "slt");
        expect("000000", "101011", "100010000000", "011", "1000", "sltu");
        expect("000000", "000000", "100010000000", "011", "1010", "sll (and nop)");
        expect("000000", "000010", "100010000000", "011", "1011", "srl");
        expect("000000", "000011", "100010000000", "011", "1100", "sra");
        expect("100011", "000000", "010110000000", "000", "0010", "lw");
        expect("101011", "000000", "011000000000", "000", "0010", "sw");
        expect("001000", "000000", "010010000000", "000", "0010", "addi");
        expect("001001", "000000", "010010000000", "000", "0010", "addiu");
        expect("001100", "000000", "010010000001", "001", "0000", "andi (zero-extended)");
        expect("001101", "000000", "010010000001", "100", "0001", "ori (zero-extended)");
        expect("001110", "000000", "010010000001", "111", "1001", "xori (zero-extended)");
        expect("001010", "000000", "010010000000", "101", "0111", "slti");
        expect("001011", "000000", "010010000000", "110", "1000", "sltiu");
        expect("001111", "000000", "010010000010", "000", "0010", "lui (upper half word)");
        expect("000100", "000000", "000001000000", "010", "0110", "beq");
        expect("000101", "000000", "000001100000", "010", "0110", "bne");
        expect("000010", "000000", "000000010000", "000", "0010", "j");
        expect("000011", "000000", "000010011000", "000", "0010", "jal (link, jump, writes $31)");
        expect("000000", "001000", "100000000100", "011", "----", "jr (R-type, but no register write)");
        -- Illegal opcode: nothing may be written, neither registers nor memory, no branch/jump
        expect("111111", "000000", "000000000000", "000", "0010", "illegal opcode");
        expect("010101", "100000", "000000000000", "000", "0010", "illegal opcode");

        REPORT "tb_decoder: PASS (" & INTEGER'image(n_checks) & " checks)";
        finish;
    END PROCESS;
END sim;
