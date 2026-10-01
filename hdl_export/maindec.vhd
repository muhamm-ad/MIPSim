--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : maindec.vhd
-- Description: Main decoder for the MIPS processor. This component generates
--              control signals based on the opcode of the instruction.
--              Don't-care control bits are driven to '0' so that no undefined
--              value ever reaches the datapath in simulation.
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
        aluop : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END ENTITY maindec;

ARCHITECTURE struct OF maindec IS
    -- controls = regdst & alusrc & memwrite & memtoreg & regwrite & aluop(2:0)
    SIGNAL controls : STD_LOGIC_VECTOR(7 DOWNTO 0);
BEGIN
    PROCESS (op)
    BEGIN
        CASE op IS
            WHEN "000000" => controls <= ("10001" & "011"); -- R-type (add, sub, etc.)
            WHEN "100011" => controls <= ("01011" & "000"); -- lw
            WHEN "101011" => controls <= ("01100" & "000"); -- sw
            WHEN "001000" => controls <= ("01001" & "000"); -- addi
            WHEN "001001" => controls <= ("01001" & "000"); -- addiu
                -- TODO : andi, ori (need zero extension), beq, bne, j

            WHEN OTHERS => controls <= "00000000"; -- illegal op
        END CASE;
    END PROCESS;

    regdst <= controls(7);
    alusrc <= controls(6);
    memwrite <= controls(5);
    memtoreg <= controls(4);
    regwrite <= controls(3);
    aluop <= controls(2 DOWNTO 0);
END ARCHITECTURE struct;
