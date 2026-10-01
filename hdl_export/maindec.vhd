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
--   jump     unconditional jump (j)
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
        extop : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        aluop : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END ENTITY maindec;

ARCHITECTURE struct OF maindec IS
    -- controls = regdst & alusrc & memwrite & memtoreg & regwrite
    --          & branch & bne & jump & extop(1:0) & aluop(2:0)
    SIGNAL controls : STD_LOGIC_VECTOR(12 DOWNTO 0);
BEGIN
    PROCESS (op)
    BEGIN
        CASE op IS
            WHEN "000000" => controls <= ("10001" & "000" & "00" & "011"); -- R-type (add, sub, etc.)
            WHEN "100011" => controls <= ("01011" & "000" & "00" & "000"); -- lw
            WHEN "101011" => controls <= ("01100" & "000" & "00" & "000"); -- sw
            WHEN "001000" => controls <= ("01001" & "000" & "00" & "000"); -- addi
            WHEN "001001" => controls <= ("01001" & "000" & "00" & "000"); -- addiu
            WHEN "001100" => controls <= ("01001" & "000" & "01" & "001"); -- andi (zero-extended imm)
            WHEN "001101" => controls <= ("01001" & "000" & "01" & "100"); -- ori  (zero-extended imm)
            WHEN "001110" => controls <= ("01001" & "000" & "01" & "111"); -- xori (zero-extended imm)
            WHEN "001010" => controls <= ("01001" & "000" & "00" & "101"); -- slti
            WHEN "001011" => controls <= ("01001" & "000" & "00" & "110"); -- sltiu
            WHEN "001111" => controls <= ("01001" & "000" & "10" & "000"); -- lui (0 + imm << 16)
            WHEN "000100" => controls <= ("00000" & "100" & "00" & "010"); -- beq
            WHEN "000101" => controls <= ("00000" & "110" & "00" & "010"); -- bne
            WHEN "000010" => controls <= ("00000" & "001" & "00" & "000"); -- j

            WHEN OTHERS => controls <= (OTHERS => '0'); -- illegal op
        END CASE;
    END PROCESS;

    regdst <= controls(12);
    alusrc <= controls(11);
    memwrite <= controls(10);
    memtoreg <= controls(9);
    regwrite <= controls(8);
    branch <= controls(7);
    bne <= controls(6);
    jump <= controls(5);
    extop <= controls(4 DOWNTO 3);
    aluop <= controls(2 DOWNTO 0);
END ARCHITECTURE struct;
