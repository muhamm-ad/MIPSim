--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : decoder.vhd
-- Description: Single cycle control decoder.
--              Main decoder (opcode -> control signals) + ALU decoder
--              (ALUop, funct -> ALU control).
--              'jr' (R-type, funct 001000) is recognised here since it depends on
--              the funct field; it cancels the register write of the R-type class.
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
		branch : OUT STD_LOGIC;
		bne : OUT STD_LOGIC;
		jump : OUT STD_LOGIC;
		jr : OUT STD_LOGIC;
		link : OUT STD_LOGIC;
		extop : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		alucontrol : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END ENTITY decoder;

ARCHITECTURE struct OF decoder IS
	SIGNAL aluop_sig : STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL regwrite_main, jr_sig : STD_LOGIC;
BEGIN
	mdec : ENTITY work.maindec
		PORT MAP(
			op => op,
			memtoreg => memtoreg,
			memwrite => memwrite,
			alusrc => alusrc,
			regdst => regdst,
			regwrite => regwrite_main,
			branch => branch,
			bne => bne,
			jump => jump,
			link => link,
			extop => extop,
			aluop => aluop_sig
		);

	-- jr rs: R-type with funct = 001000. It must not write the register file.
	jr_sig <= '1' WHEN op = "000000" AND funct = "001000" ELSE
		'0';
	jr <= jr_sig;
	regwrite <= regwrite_main AND NOT jr_sig;

	adec : ENTITY work.aludec
		PORT MAP(
			aluop => aluop_sig,
			funct => funct,
			alucontrol => alucontrol
		);
END ARCHITECTURE struct;
