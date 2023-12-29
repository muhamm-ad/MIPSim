--------------------------------------------------------------------------------
-- Project : MIPS Processor
-- File    : datapath.vhd
-- Description: This file defines the MIPS processor datapath entity 'datapath'.
-- It integrates various components such as the program counter (PC), registers,
-- ALU, and multiplexers to execute instructions. The datapath handles data flow
-- and control signals to perform arithmetic and logical operations as per MIPS
-- instruction set architecture.
-- TODO add jump, and other instruction-specific behaviors.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

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
        alucontrol : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
        aluresult : BUFFER STD_LOGIC_VECTOR (31 DOWNTO 0);
        readdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        memtoreg : IN STD_LOGIC
        zero : OUT STD_LOGIC;
    );
END;

ARCHITECTURE struct OF datapath IS

    SIGNAL pcnext : STD_LOGIC_VECTOR (31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL writereg : STD_LOGIC_VECTOR (4 DOWNTO 0);
    SIGNAL result : STD_LOGIC_VECTOR (31 DOWNTO 0);
    SIGNAL signimm : STD_LOGIC_VECTOR (31 DOWNTO 0);
    SIGNAL srca, srcb : STD_LOGIC_VECTOR (31 DOWNTO 0);

BEGIN
    -- Next PC logic
    -- Update PC with the next value on the rising edge of the clock
    pcflopr : ENTITY work.flopr
        GENERIC MAP(DATA_WIDTH => 32)
        PORT MAP(clk => clk, reset => reset, d => pcnext, q => pc);
    pcadder : ENTITY work.adder
        GENERIC MAP(VECTOR_SIZE => 32)
        PORT MAP(v1 => X"00000004", v2 => pc, vecr => pcnext);

    -- Register logic
    -- Read from registers or write data to a register
    regis : ENTITY work.reg
        PORT MAP(
            clk => clk,
            we3 => regwrite,
            a1 => instr(25 DOWNTO 21),
            a2 => instr(20 DOWNTO 16),
            wa3 => writereg,
            wd3 => result,
            rd1 => srca,
            rd2 => writedata
        );
    -- Multiplexer for write register selection
    wrmux : ENTITY work.mux
        GENERIC MAP(DATA_WIDTH => 5, N_INPUTS => 2)
        PORT MAP(
            data_in => (instr(20 DOWNTO 16) & instr(15 DOWNTO 11)),
            select_ => regdst,
            data_out => writereg
        );
    resmux : ENTITY work.mux
        GENERIC MAP(DATA_WIDTH => 32, N_INPUTS => 2)
        PORT MAP(
            data_in => (aluresult & readdata),
            select_ => memtoreg,
            data_out => result
        );
    -- Sign extension unit
    -- Extends a 16-bit immediate to 32 bits
    se : ENTITY work.signext PORT MAP(data_in => instr(15 DOWNTO 0), data_out => signimm);

    -- ALU control logic
    -- Determines the ALU operation based on the control signals
    srcbmux : ENTITY work.mux
        GENERIC MAP(DATA_WIDTH => 32, N_INPUTS => 2)
        PORT MAP(
            data_in => (writedata & signimm),
            select_ => alusrc,
            data_out => srcb
        );
    mainalu : ENTITY work.alu
        GENERIC MAP(DATA_WIDTH => 32)
        PORT MAP(
            srca => srca,
            srcb => srcb,
            aluctl => alucontrol,
            zero => zero,
            aluout => aluresult
        );
END struct;