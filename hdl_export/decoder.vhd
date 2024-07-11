--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : decoder.vhd
-- Description: Single cycle control decoder.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY decoder IS
	PORT (
		op : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		funct : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		regdst : OUT STD_LOGIC;
		alusrc : OUT STD_LOGIC;
		memwrite : OUT STD_LOGIC;
		memtoreg : OUT STD_LOGIC;
		regwrite : OUT STD_LOGIC;
		alucontrol : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END ENTITY decoder;

ARCHITECTURE struct OF decoder IS
	SIGNAL aluop_sig : STD_LOGIC_VECTOR(1 DOWNTO 0);
BEGIN
	mdec : ENTITY work.maindec
		PORT MAP(
			op => op,
			memtoreg => memtoreg,
			memwrite => memwrite,
			alusrc => alusrc,
			regdst => regdst,
			regwrite => regwrite,
			aluop => aluop_sig
		);

	adec : ENTITY work.aludec
		PORT MAP(
			aluop => aluop_sig,
			funct => funct,
			aluctrl => alucontrol
		);
END ARCHITECTURE struct;