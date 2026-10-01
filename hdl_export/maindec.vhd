--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : maindec.vhd
-- Description: Main decoder for the MIPS processor. This component generates
--              control signals based on the opcode of the instruction.
--              Don't-care control bits are driven to '0' so that no undefined
--              value ever reaches the datapath in simulation.
--
-- Control signals:
--   regdst   destination register: 0 = rt (I-type), 1 = rd (R-type)
--   alusrc   ALU operand B:        0 = register,    1 = immediate
--   memwrite write data memory
--   memtoreg register write data:  0 = ALU result,  1 = memory data
--   regwrite write the register file
--   branch   instruction is a conditional branch (beq / bne)
--   bne      branch is taken when the ALU result is NOT zero (bne), else zero (beq)
--   jump     unconditional jump (j, jal)
--   link     write PC+4 into $ra ($31) (jal); the register file input and the
--            destination register are overridden in the datapath
--   extop    immediate extension: 00 = sign-extended, 01 = zero-extended
--            (andi, ori, xori), 10 = placed in the upper half word (lui)
--   aluop    see aludec
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY maindec IS
    PORT (
        op : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        regdst : OUT STD_LOGIC;
        alusrc : OUT STD_LOGIC;
        memwrite : OUT STD_LOGIC;
        memtoreg : OUT STD_LOGIC;
        regwrite : OUT STD_LOGIC;
        branch : OUT STD_LOGIC;
        bne : OUT STD_LOGIC;
        jump : OUT STD_LOGIC;
        link : OUT STD_LOGIC;
        extop : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        aluop : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END ENTITY maindec;

ARCHITECTURE struct OF maindec IS
    -- controls = regdst & alusrc & memwrite & memtoreg & regwrite
    --          & branch & bne & jump & link & extop(1:0) & aluop(2:0)
    SIGNAL controls : STD_LOGIC_VECTOR(13 DOWNTO 0);
BEGIN
    PROCESS (op)
    BEGIN
        CASE op IS
            WHEN "000000" => controls <= ("10001" & "000" & "0" & "00" & "011"); -- R-type (add, sub, etc.)
            WHEN "100011" => controls <= ("01011" & "000" & "0" & "00" & "000"); -- lw
            WHEN "101011" => controls <= ("01100" & "000" & "0" & "00" & "000"); -- sw
            WHEN "001000" => controls <= ("01001" & "000" & "0" & "00" & "000"); -- addi
            WHEN "001001" => controls <= ("01001" & "000" & "0" & "00" & "000"); -- addiu
            WHEN "001100" => controls <= ("01001" & "000" & "0" & "01" & "001"); -- andi (zero-extended imm)
            WHEN "001101" => controls <= ("01001" & "000" & "0" & "01" & "100"); -- ori  (zero-extended imm)
            WHEN "001110" => controls <= ("01001" & "000" & "0" & "01" & "111"); -- xori (zero-extended imm)
            WHEN "001010" => controls <= ("01001" & "000" & "0" & "00" & "101"); -- slti
            WHEN "001011" => controls <= ("01001" & "000" & "0" & "00" & "110"); -- sltiu
            WHEN "001111" => controls <= ("01001" & "000" & "0" & "10" & "000"); -- lui (0 + imm << 16)
            WHEN "000100" => controls <= ("00000" & "100" & "0" & "00" & "010"); -- beq
            WHEN "000101" => controls <= ("00000" & "110" & "0" & "00" & "010"); -- bne
            WHEN "000010" => controls <= ("00000" & "001" & "0" & "00" & "000"); -- j
            WHEN "000011" => controls <= ("00001" & "001" & "1" & "00" & "000"); -- jal ($31 = PC+4, jump)

            WHEN OTHERS => controls <= (OTHERS => '0'); -- illegal op
        END CASE;
    END PROCESS;

    regdst <= controls(13);
    alusrc <= controls(12);
    memwrite <= controls(11);
    memtoreg <= controls(10);
    regwrite <= controls(9);
    branch <= controls(8);
    bne <= controls(7);
    jump <= controls(6);
    link <= controls(5);
    extop <= controls(4 DOWNTO 3);
    aluop <= controls(2 DOWNTO 0);
END ARCHITECTURE struct;
