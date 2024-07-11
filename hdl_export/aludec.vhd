--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : aludec.vhd
-- Description: This file defines an ALU control decoder component named 'aludec'.
-- It decodes ALU operation codes (ALUop) and function field (funct) from instructions
-- to generate 4-bit control signals for the ALU. An additional 'neg' signal is
-- provided to indicate special cases such as negative operations. The 4-bit control
-- allows for extended operation set or more complex control schemes.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Entity declaration of aludec (ALU control decoder)
ENTITY aludec IS
    PORT (
        funct : IN STD_LOGIC_VECTOR(5 DOWNTO 0); -- Function field from the instruction
        aluop : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- ALU operation code
        alucontrol : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- 4-bit Control signal for ALU operations
        neg : OUT STD_LOGIC := '0' -- Flag to indicate special cases like negative operations
    );
END aludec;

-- Architecture of aludec
ARCHITECTURE behave OF aludec IS
BEGIN
    -- Process to decode ALU operations
    PROCESS (aluop, funct) BEGIN
        neg <= '0'; -- Default neg signal is '0'
        CASE aluop IS
            WHEN "00" => alucontrol <= "0010"; -- Add operation
            WHEN "01" => alucontrol <= "0110"; -- Subtract operation
            WHEN "10" =>
                -- Decoding based on the function field for R-type instructions
                CASE funct IS
                    WHEN "100000" => alucontrol <= "0010"; -- Add
                    WHEN "100010" => alucontrol <= "0110"; -- Subtract
                    WHEN "100100" => alucontrol <= "0000"; -- And
                    WHEN "100101" => alucontrol <= "0001"; -- Or
                    WHEN "101010" => alucontrol <= "0111"; -- SLT
                    WHEN "111111" => alucontrol <= "0010"; -- Special operation
                        neg <= '1';
                    WHEN OTHERS => alucontrol <= "----"; -- Undefined operations
                END CASE;
            WHEN OTHERS => alucontrol <= "----"; -- Undefined ALUop
        END CASE;
    END PROCESS;
END behave;