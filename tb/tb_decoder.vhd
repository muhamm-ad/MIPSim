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
    SIGNAL m_branch, m_bne, m_jump : STD_LOGIC;
    SIGNAL m_extop : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL m_aluop : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- full decoder
    SIGNAL regdst, alusrc, memwrite, memtoreg, regwrite : STD_LOGIC;
    SIGNAL branch, bne, jump : STD_LOGIC;
    SIGNAL extop : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL alucontrol : STD_LOGIC_VECTOR(3 DOWNTO 0);
BEGIN
    mdec : ENTITY work.maindec
        PORT MAP(
            op => op, regdst => m_regdst, alusrc => m_alusrc, memwrite => m_memwrite,
            memtoreg => m_memtoreg, regwrite => m_regwrite, branch => m_branch, bne => m_bne,
            jump => m_jump, extop => m_extop, aluop => m_aluop);

    dec : ENTITY work.decoder
        PORT MAP(
            op => op, funct => funct, regdst => regdst, alusrc => alusrc, memwrite => memwrite,
            memtoreg => memtoreg, regwrite => regwrite, branch => branch, bne => bne,
            jump => jump, extop => extop, alucontrol => alucontrol);

    PROCESS
        VARIABLE n_checks : INTEGER := 0;

        -- want = regdst & alusrc & memwrite & memtoreg & regwrite & branch & bne & jump & extop(1:0)
        PROCEDURE expect(opcode : STD_LOGIC_VECTOR(5 DOWNTO 0); f : STD_LOGIC_VECTOR(5 DOWNTO 0);
        want : STD_LOGIC_VECTOR(9 DOWNTO 0); want_aluop : STD_LOGIC_VECTOR(2 DOWNTO 0);
        want_ctl : STD_LOGIC_VECTOR(3 DOWNTO 0); name : STRING) IS
            VARIABLE got : STD_LOGIC_VECTOR(9 DOWNTO 0);
        BEGIN
            op <= opcode;
            funct <= f;
            WAIT FOR 1 ns;
            got := m_regdst & m_alusrc & m_memwrite & m_memtoreg & m_regwrite & m_branch & m_bne & m_jump & m_extop;
            ASSERT got = want
            REPORT name & ": maindec regdst/alusrc/memwrite/memtoreg/regwrite/branch/bne/jump/extop expected "
                & to_string(want) & " got " & to_string(got) SEVERITY error;
            ASSERT m_aluop = want_aluop
            REPORT name & ": maindec aluop expected " & to_string(want_aluop) & " got " & to_string(m_aluop)
                SEVERITY error;
            got := regdst & alusrc & memwrite & memtoreg & regwrite & branch & bne & jump & extop;
            ASSERT got = want
            REPORT name & ": decoder controls expected " & to_string(want) & " got " & to_string(got)
                SEVERITY error;
            ASSERT alucontrol = want_ctl
            REPORT name & ": decoder alucontrol expected " & to_string(want_ctl) & " got " & to_string(alucontrol)
                SEVERITY error;
            n_checks := n_checks + 1;
        END PROCEDURE;
    BEGIN
        --        op        funct     RD AS MW MR RW BR BN J EX  aluop  alu_ctl
        expect("000000", "100000", "1000100000", "011", "0010", "add");
        expect("000000", "100001", "1000100000", "011", "0010", "addu");
        expect("000000", "100010", "1000100000", "011", "0110", "sub");
        expect("000000", "100011", "1000100000", "011", "0110", "subu");
        expect("000000", "100100", "1000100000", "011", "0000", "and");
        expect("000000", "100101", "1000100000", "011", "0001", "or");
        expect("000000", "100110", "1000100000", "011", "1001", "xor");
        expect("000000", "100111", "1000100000", "011", "0011", "nor");
        expect("000000", "101010", "1000100000", "011", "0111", "slt");
        expect("000000", "101011", "1000100000", "011", "1000", "sltu");
        expect("000000", "000000", "1000100000", "011", "1010", "sll (and nop)");
        expect("000000", "000010", "1000100000", "011", "1011", "srl");
        expect("000000", "000011", "1000100000", "011", "1100", "sra");
        expect("100011", "000000", "0101100000", "000", "0010", "lw");
        expect("101011", "000000", "0110000000", "000", "0010", "sw");
        expect("001000", "000000", "0100100000", "000", "0010", "addi");
        expect("001001", "000000", "0100100000", "000", "0010", "addiu");
        expect("001100", "000000", "0100100001", "001", "0000", "andi (zero-extended)");
        expect("001101", "000000", "0100100001", "100", "0001", "ori (zero-extended)");
        expect("001110", "000000", "0100100001", "111", "1001", "xori (zero-extended)");
        expect("001010", "000000", "0100100000", "101", "0111", "slti");
        expect("001011", "000000", "0100100000", "110", "1000", "sltiu");
        expect("001111", "000000", "0100100010", "000", "0010", "lui (upper half word)");
        expect("000100", "000000", "0000010000", "010", "0110", "beq");
        expect("000101", "000000", "0000011000", "010", "0110", "bne");
        expect("000010", "000000", "0000000100", "000", "0010", "j");
        -- Illegal opcode: nothing may be written, neither registers nor memory, no branch/jump
        expect("111111", "000000", "0000000000", "000", "0010", "illegal opcode");
        expect("010101", "100000", "0000000000", "000", "0010", "illegal opcode");

        REPORT "tb_decoder: PASS (" & INTEGER'image(n_checks) & " checks)";
        finish;
    END PROCESS;
END sim;
