--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : datapath.vhd
-- Description: This file defines the MIPS processor datapath entity 'datapath'.
-- It integrates various components such as the program counter (PC), registers,
-- ALU, and multiplexers to execute instructions. The datapath handles data flow
-- and control signals to perform arithmetic and logical operations as per MIPS
-- instruction set architecture.
--
-- Next-PC logic:
--   pcplus4  = pc + 4
--   pcbranch = pcplus4 + (SignExtImm << 2)               (taken when pcsrc = 1)
--   pcjump   = pcplus4[31:28] & instr[25:0] & "00"       (taken when jump = 1)
--   pcnext   = jump ? pcjump : (pcsrc ? pcbranch : pcplus4)
-- 'pcsrc' (branch decision) is computed by the controller from 'zero'.
-- TODO add jal / jr and other instruction-specific behaviors.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Entity declaration of datapath (MIPS datapath)
ENTITY datapath IS
    PORT (
        clk, reset : IN STD_LOGIC;
        pc : BUFFER STD_LOGIC_VECTOR (31 DOWNTO 0);
        instr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        regdst : IN STD_LOGIC;
        regwrite : IN STD_LOGIC;
        writedata : BUFFER STD_LOGIC_VECTOR (31 DOWNTO 0);
        alusrc : IN STD_LOGIC;
        extop : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        alucontrol : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
        aluresult : BUFFER STD_LOGIC_VECTOR (31 DOWNTO 0);
        readdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        memtoreg : IN STD_LOGIC;
        pcsrc : IN STD_LOGIC;
        jump : IN STD_LOGIC;
        zero : OUT STD_LOGIC
    );
END;

ARCHITECTURE struct OF datapath IS

    SIGNAL pcnext, pcnextbr : STD_LOGIC_VECTOR (31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL pcplus4, pcbranch, pcjump : STD_LOGIC_VECTOR (31 DOWNTO 0);
    SIGNAL writereg : STD_LOGIC_VECTOR (4 DOWNTO 0);
    SIGNAL result : STD_LOGIC_VECTOR (31 DOWNTO 0);
    SIGNAL signimm, zeroimm, upperimm, extimm, signimmsh : STD_LOGIC_VECTOR (31 DOWNTO 0);
    SIGNAL srca, srcb : STD_LOGIC_VECTOR (31 DOWNTO 0);

BEGIN
    -- Next PC logic
    -- Update PC with the next value on the rising edge of the clock
    pcflopr : ENTITY work.flopr
        GENERIC MAP(DATA_WIDTH => 32)
        PORT MAP(clk => clk, reset => reset, d => pcnext, q => pc);
    pcadder : ENTITY work.adder
        GENERIC MAP(VECTOR_SIZE => 32)
        PORT MAP(v1 => X"00000004", v2 => pc, vr => pcplus4);

    -- Branch target: PC+4 + (offset << 2)
    signimmsh <= signimm(29 DOWNTO 0) & "00";
    pcbradd : ENTITY work.adder
        GENERIC MAP(VECTOR_SIZE => 32)
        PORT MAP(v1 => signimmsh, v2 => pcplus4, vr => pcbranch);
    pcbrmux : ENTITY work.mux
        GENERIC MAP(DATA_WIDTH => 32, N_INPUTS => 2)
        PORT MAP(
            data_in => (pcbranch & pcplus4), -- (branch target & PC+4)
            sel(0) => pcsrc,
            data_out => pcnextbr
        );

    -- Jump target: upper 4 bits of PC+4, 26-bit address field, two zero bits
    pcjump <= pcplus4(31 DOWNTO 28) & instr(25 DOWNTO 0) & "00";
    pcmux : ENTITY work.mux
        GENERIC MAP(DATA_WIDTH => 32, N_INPUTS => 2)
        PORT MAP(
            data_in => (pcjump & pcnextbr), -- (jump target & PC+4 / branch target)
            sel(0) => jump,
            data_out => pcnext
        );

    -- Register logic
    -- Read from registers or write data to a register
    regis : ENTITY work.reg
        PORT MAP(
            clk => clk,
            we3 => regwrite,
            a1 => instr(25 DOWNTO 21),
            a2 => instr(20 DOWNTO 16),
            a3 => writereg,
            wd3 => result,
            rd1 => srca,
            rd2 => writedata
        );
    -- Multiplexer for write register selection
    wrmux : ENTITY work.mux
        GENERIC MAP(DATA_WIDTH => 5, N_INPUTS => 2)
        PORT MAP(
            data_in => (instr(15 DOWNTO 11) & instr(20 DOWNTO 16)), -- (rd & rt)
            sel(0) => regdst,
            data_out => writereg
        );
    resmux : ENTITY work.mux
        GENERIC MAP(DATA_WIDTH => 32, N_INPUTS => 2)
        PORT MAP(
            data_in => (readdata & aluresult), -- (memory data & ALU result)
            sel(0) => memtoreg,
            data_out => result
        );
    -- Immediate extension unit
    -- Builds the 32-bit immediate from the 16-bit field, selected by extop:
    --   00 sign-extended (addi, lw, sw, slti, ...)   01 zero-extended (andi, ori, xori)
    --   10 upper half word (lui)
    se : ENTITY work.signext PORT MAP(data_in => instr(15 DOWNTO 0), data_out => signimm);
    zeroimm <= X"0000" & instr(15 DOWNTO 0);
    upperimm <= instr(15 DOWNTO 0) & X"0000";
    immmux : ENTITY work.mux
        GENERIC MAP(DATA_WIDTH => 32, N_INPUTS => 3)
        PORT MAP(
            data_in => (upperimm & zeroimm & signimm), -- (upper & zero-extended & sign-extended)
            sel => extop,
            data_out => extimm
        );

    -- ALU control logic
    -- Determines the ALU operation based on the control signals
    srcbmux : ENTITY work.mux
        GENERIC MAP(DATA_WIDTH => 32, N_INPUTS => 2)
        PORT MAP(
            data_in => (extimm & writedata), -- (immediate & register)
            sel(0) => alusrc,
            data_out => srcb
        );
    mainalu : ENTITY work.alu
        GENERIC MAP(DATA_WIDTH => 32)
        PORT MAP(
            srca => srca,
            srcb => srcb,
            shamt => instr(10 DOWNTO 6),
            aluctl => alucontrol,
            zero => zero,
            aluout => aluresult
        );
END struct;
