--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : signext.vhd
-- Description: This file defines a sign extender component named 'signext'.
-- The sign extender is used to extend the sign bit of a 16-bit input to a
-- 32-bit output.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Entity declaration of signext (sign extender)
ENTITY signext IS
    PORT (
        data_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- 16-bit input
        data_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) -- 32-bit sign-extended output
    );
END signext;

-- Architecture of signext
ARCHITECTURE behave OF signext IS
BEGIN
    -- Sign extension process
    data_out <= X"0000" & data_in WHEN data_in(15) = '0' ELSE
        X"ffff" & data_in;
    -- If the most significant bit (MSB) of 'data_in' is '0', pad with '0's (positive number).
    -- If the MSB is '1', pad with '1's (negative number, sign extension).
END behave;