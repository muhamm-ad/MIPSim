--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : aludec.vhd
-- Description: This file defines an ALU control decoder component named 'aludec'.
-- It decodes the ALU operation code (ALUop, produced by the main decoder) and the
-- function field (funct) of R-type instructions into the 4-bit control signal of
-- the ALU. The 4-bit control allows for an extended operation set.
--
-- ALUop encoding (see docs/supported-instructions.md):
--   000 add  (lw, sw, addi, addiu, lui)   100 or   (ori)
--   001 and  (andi)                       101 slt  (slti)
--   010 sub  (beq, bne)                   110 sltu (sltiu)
--   011 check funct (R-type)              111 xor  (xori)
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Entity declaration of aludec (ALU control decoder)
ENTITY aludec IS
    PORT (
        funct : IN STD_LOGIC_VECTOR(5 DOWNTO 0); -- Function field from the instruction
        aluop : IN STD_LOGIC_VECTOR(2 DOWNTO 0); -- ALU operation code
        alucontrol : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) -- 4-bit Control signal for ALU operations
    );
END aludec;

-- Architecture of aludec
ARCHITECTURE behave OF aludec IS
BEGIN
    -- Process to decode ALU operations
    PROCESS (aluop, funct) BEGIN
        CASE aluop IS
            WHEN "000" => alucontrol <= "0010"; -- Add operation
            WHEN "001" => alucontrol <= "0000"; -- And operation
            WHEN "010" => alucontrol <= "0110"; -- Subtract operation
            WHEN "011" =>
                -- Decoding based on the function field for R-type instructions
                CASE funct IS
                    WHEN "000000" => alucontrol <= "1010"; -- sll (all-zero word = sll $0,$0,0 = nop)
                    WHEN "000010" => alucontrol <= "1011"; -- srl
                    WHEN "000011" => alucontrol <= "1100"; -- sra
                    WHEN "100000" => alucontrol <= "0010"; -- add
                    WHEN "100001" => alucontrol <= "0010"; -- addu
                    WHEN "100010" => alucontrol <= "0110"; -- sub
                    WHEN "100011" => alucontrol <= "0110"; -- subu
                    WHEN "100100" => alucontrol <= "0000"; -- and
                    WHEN "100101" => alucontrol <= "0001"; -- or
                    WHEN "100110" => alucontrol <= "1001"; -- xor
                    WHEN "100111" => alucontrol <= "0011"; -- nor
                    WHEN "101010" => alucontrol <= "0111"; -- slt
                    WHEN "101011" => alucontrol <= "1000"; -- sltu
                    WHEN OTHERS => alucontrol <= "----"; -- Undefined operations
                END CASE;
            WHEN "100" => alucontrol <= "0001"; -- Or operation
            WHEN "101" => alucontrol <= "0111"; -- Set less than operation
            WHEN "110" => alucontrol <= "1000"; -- Set less than unsigned operation
            WHEN "111" => alucontrol <= "1001"; -- Xor operation
            WHEN OTHERS => alucontrol <= "----"; -- Undefined ALUop
        END CASE;
    END PROCESS;
END behave;
