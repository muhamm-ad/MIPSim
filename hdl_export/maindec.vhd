--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : maindec.vhd
-- Description: Main decoder for the MIPS processor. This component generates 
--              control signals based on the opcode of the instruction.
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
        aluop : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
    );
END ENTITY maindec;

ARCHITECTURE struct OF maindec IS
    SIGNAL controls : STD_LOGIC_VECTOR(6 DOWNTO 0);
BEGIN
    PROCESS (op)
    BEGIN
        CASE op IS
            WHEN X"00" => controls <= ("10001" & "11"); -- R-type (add, sub, etc.)
            WHEN X"23" => controls <= ("01011" & "00"); -- lw
            WHEN X"2B" => controls <= ("-11-0" & "00"); -- sw
                -- TODO : complete

            WHEN OTHERS => controls <= "0000000"; -- illegal op
        END CASE;
    END PROCESS;

    regdst <= controls(6);
    alusrc <= controls(5);
    memwrite <= controls(4);
    memtoreg <= controls(3);
    regwrite <= controls(2);
    aluop <= controls(1 DOWNTO 0);
END ARCHITECTURE struct;