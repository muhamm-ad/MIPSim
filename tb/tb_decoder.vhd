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
    SIGNAL m_branch, m_bne, m_jump, m_zeroext : STD_LOGIC;
    SIGNAL m_aluop : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- full decoder
    SIGNAL regdst, alusrc, memwrite, memtoreg, regwrite : STD_LOGIC;
    SIGNAL branch, bne, jump, zeroext : STD_LOGIC;
    SIGNAL alucontrol : STD_LOGIC_VECTOR(3 DOWNTO 0);
BEGIN
    mdec : ENTITY work.maindec
        PORT MAP(
            op => op, regdst => m_regdst, alusrc => m_alusrc, memwrite => m_memwrite,
            memtoreg => m_memtoreg, regwrite => m_regwrite, branch => m_branch, bne => m_bne,
            jump => m_jump, zeroext => m_zeroext, aluop => m_aluop);

    dec : ENTITY work.decoder
        PORT MAP(
            op => op, funct => funct, regdst => regdst, alusrc => alusrc, memwrite => memwrite,
            memtoreg => memtoreg, regwrite => regwrite, branch => branch, bne => bne,
            jump => jump, zeroext => zeroext, alucontrol => alucontrol);

    PROCESS
        VARIABLE n_checks : INTEGER := 0;

        -- want = regdst & alusrc & memwrite & memtoreg & regwrite & branch & bne & jump & zeroext
        PROCEDURE expect(opcode : STD_LOGIC_VECTOR(5 DOWNTO 0); f : STD_LOGIC_VECTOR(5 DOWNTO 0);
        want : STD_LOGIC_VECTOR(8 DOWNTO 0); want_aluop : STD_LOGIC_VECTOR(2 DOWNTO 0);
        want_ctl : STD_LOGIC_VECTOR(3 DOWNTO 0); name : STRING) IS
            VARIABLE got : STD_LOGIC_VECTOR(8 DOWNTO 0);
        BEGIN
            op <= opcode;
            funct <= f;
            WAIT FOR 1 ns;
            got := m_regdst & m_alusrc & m_memwrite & m_memtoreg & m_regwrite & m_branch & m_bne & m_jump & m_zeroext;
            ASSERT got = want
            REPORT name & ": maindec regdst/alusrc/memwrite/memtoreg/regwrite/branch/bne/jump/zeroext expected "
                & to_string(want) & " got " & to_string(got) SEVERITY error;
            ASSERT m_aluop = want_aluop
            REPORT name & ": maindec aluop expected " & to_string(want_aluop) & " got " & to_string(m_aluop)
                SEVERITY error;
            got := regdst & alusrc & memwrite & memtoreg & regwrite & branch & bne & jump & zeroext;
            ASSERT got = want
            REPORT name & ": decoder controls expected " & to_string(want) & " got " & to_string(got)
                SEVERITY error;
            ASSERT alucontrol = want_ctl
            REPORT name & ": decoder alucontrol expected " & to_string(want_ctl) & " got " & to_string(alucontrol)
                SEVERITY error;
            n_checks := n_checks + 1;
        END PROCEDURE;
    BEGIN
        --        op        funct     RD AS MW MR RW BR BN J ZE  aluop  alu_ctl
        expect("000000", "100000", "100010000", "011", "0010", "add");
        expect("000000", "100001", "100010000", "011", "0010", "addu");
        expect("000000", "100010", "100010000", "011", "0110", "sub");
        expect("000000", "100011", "100010000", "011", "0110", "subu");
        expect("000000", "100100", "100010000", "011", "0000", "and");
        expect("000000", "100101", "100010000", "011", "0001", "or");
        expect("000000", "100111", "100010000", "011", "0011", "nor");
        expect("000000", "101010", "100010000", "011", "0111", "slt");
        expect("100011", "000000", "010110000", "000", "0010", "lw");
        expect("101011", "000000", "011000000", "000", "0010", "sw");
        expect("001000", "000000", "010010000", "000", "0010", "addi");
        expect("001001", "000000", "010010000", "000", "0010", "addiu");
        expect("001100", "000000", "010010001", "001", "0000", "andi (zero-extended)");
        expect("001101", "000000", "010010001", "100", "0001", "ori (zero-extended)");
        expect("001010", "000000", "010010000", "101", "0111", "slti");
        expect("000100", "000000", "000001000", "010", "0110", "beq");
        expect("000101", "000000", "000001100", "010", "0110", "bne");
        expect("000010", "000000", "000000010", "000", "0010", "j");
        -- Illegal opcode: nothing may be written, neither registers nor memory, no branch/jump
        expect("111111", "000000", "000000000", "000", "0010", "illegal opcode");
        expect("010101", "100000", "000000000", "000", "0010", "illegal opcode");

        REPORT "tb_decoder: PASS (" & INTEGER'image(n_checks) & " checks)";
        finish;
    END PROCESS;
END sim;
