--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : mips.vhd
-- Description: Single-cycle MIPS processor core (without memories). It wires the
-- control decoder to the datapath and resolves conditional branches:
--   pcsrc = branch AND (zero XOR bne)
-- i.e. beq is taken when the ALU result is zero, bne when it is not.
-- Instruction and data memories are external (see top.vhd).
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Entity declaration of mips (processor core)
ENTITY mips IS
    PORT (
        clk, reset : IN STD_LOGIC;
        pc : BUFFER STD_LOGIC_VECTOR(31 DOWNTO 0); -- Address of the current instruction
        instr : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- Current instruction
        memwrite : OUT STD_LOGIC; -- Data memory write enable
        aluout : BUFFER STD_LOGIC_VECTOR(31 DOWNTO 0); -- Data memory address
        writedata : BUFFER STD_LOGIC_VECTOR(31 DOWNTO 0); -- Data memory write data
        readdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0) -- Data memory read data
    );
END;

ARCHITECTURE struct OF mips IS
    SIGNAL memtoreg, alusrc, regdst, regwrite : STD_LOGIC;
    SIGNAL branch, bne, jump, jr, link : STD_LOGIC;
    SIGNAL extop : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL zero, pcsrc : STD_LOGIC;
    SIGNAL alucontrol : STD_LOGIC_VECTOR(3 DOWNTO 0);
BEGIN
    dec : ENTITY work.decoder
        PORT MAP(
            op => instr(31 DOWNTO 26),
            funct => instr(5 DOWNTO 0),
            regdst => regdst,
            alusrc => alusrc,
            memwrite => memwrite,
            memtoreg => memtoreg,
            regwrite => regwrite,
            branch => branch,
            bne => bne,
            jump => jump,
            jr => jr,
            link => link,
            extop => extop,
            alucontrol => alucontrol
        );

    pcsrc <= branch AND (zero XOR bne);

    dp : ENTITY work.datapath
        PORT MAP(
            clk => clk,
            reset => reset,
            pc => pc,
            instr => instr,
            regdst => regdst,
            regwrite => regwrite,
            writedata => writedata,
            alusrc => alusrc,
            extop => extop,
            alucontrol => alucontrol,
            aluresult => aluout,
            readdata => readdata,
            memtoreg => memtoreg,
            pcsrc => pcsrc,
            jump => jump,
            jr => jr,
            link => link,
            zero => zero
        );
END struct;
