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
    -- Sign extender takes a 16-bit input and extends it to a 32-bit output
    PORT (
        a : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- 16-bit input
        y : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) -- 32-bit sign-extended output
    );
END signext;

-- Architecture of signext
ARCHITECTURE behave OF signext IS
BEGIN
    -- Sign extension process
    y <= X"0000" & a WHEN a(15) = '0' ELSE X"ffff" & a;
    -- If the most significant bit (MSB) of 'a' is '0', pad with '0's (positive number).
    -- If the MSB is '1', pad with '1's (negative number, sign extension).
END behave;