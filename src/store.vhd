-- execute I and R type instructions

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.common.all;

entity store is
    port (reset : in  std_logic;
          clk   : in  std_logic;
			 y : out word);
end store;

architecture behavioral of store is

signal alu_func : alu_func_t := ALU_NONE;
signal alu_A : word := x"00000000";
signal alu_B : word := x"00000000";
signal alu_out : word := x"00000000";
signal reg_B : word := x"00000000";
signal imm : word := x"00000000";
signal imm_rd : word := x"00000000";
signal ir : word := x"00000000";
signal dmem_out : word := x"00000000";
signal rf_wdata : word := x"00000000";
signal dmem_w : word := x"00000000";

-- instruction fields
signal opcode : opcode_t;
signal funct3 : std_logic_vector(2 downto 0);
signal funct7 : std_logic_vector(6 downto 0);
signal rs1 : std_logic_vector(4 downto 0);
signal rs2 : std_logic_vector(4 downto 0);
signal rd : std_logic_vector(4 downto 0);
signal pc : unsigned(word'range) := x"00000000";
signal mema : std_logic_vector(5 downto 0);
signal memwa : std_logic_vector(5 downto 0);



-- control signals
signal regwrite : std_logic;
signal wbsel : std_logic;
signal memwrite : std_logic;
signal op2sel : std_logic_vector(1 downto 0);

component alu is
port (alu_func : in  alu_func_t;
		op1      : in  word;
		op2      : in  word;
		result   : out word);
end component alu;

component imem is 
port(    
	addr : in std_logic_vector(3 downto 0);
	dout : out word);
end component imem;

component dmem is
port (reset : in  std_logic;
      clk   : in  std_logic;
      raddr : in  std_logic_vector(5 downto 0);
      dout  : out word;
      waddr : in  std_logic_vector(5 downto 0);
      din : in  word;
      we    : in  std_logic);
end component dmem;

component regfile is
port (reset : in  std_logic;
      clk   : in  std_logic;
      addra : in  std_logic_vector(4 downto 0);
      addrb : in  std_logic_vector(4 downto 0);
      rega  : out word;
      regb  : out word;
      addrw : in  std_logic_vector(4 downto 0);
      dataw : in  word;
      we    : in  std_logic);
end component regfile;

begin
    
	 alu0: alu port map(
		alu_func => alu_func,
            op1 => alu_A,
            op2 => alu_B,
			result => alu_out);
		  
	imem0: imem port map(    
        	addr => std_logic_vector(pc(3 downto 0)),
        	dout => ir);

	-- Lab 4: instantiate dmem here

	rf0: regfile port map(
	reset => reset,
		clk => clk,
        addra => rs1,
        addrb => rs2,
		rega => alu_A,
		regb => reg_B,
		addrw => rd,
		dataw => rf_wdata,
		we => regwrite);
		
	mem0: dmem  port map(
	       reset => reset,
          clk   => clk,
          raddr => mema,
          dout  => dmem_out,
          waddr => memwa,
          din   => dmem_w,
          we    => memwrite);

	alu_B <= reg_B when op2sel = "00" else 
			imm when op2sel = "01" else
			imm_rd;
    rf_wdata <= alu_out when wbsel = '0' else reg_B;
    
		  
	-- instruction fields
	imm(31 downto 12) <= (others => ir(31));
	imm(11 downto 0) <= ir(31 downto 20);
	imm_rd(31 downto 12) <= (others => funct7(6));
	imm_rd(11 downto 5) <= funct7;
	imm_rd(4 downto 0) <= rd;
    rs1 <= ir(19 downto 15);
    rs2 <= ir(24 downto 20);
	rd <= ir(11 downto 7);
	funct3 <= ir(14 downto 12);
	funct7 <= ir(31 downto 25);
	opcode <= ir(6 downto 0);
 

	
	
   decode_proc : process (funct7, funct3, opcode, clk) is
	begin

		
	   regwrite <= '0';
		op2sel <= "00";
		memwrite <= '0';
		wbsel <= '0';
		case opcode is
			when OP_ITYPE =>
				regwrite <= '1';
				op2sel <= "01";
				case (funct3) is
                    when "000" => alu_func <= ALU_ADD;
                    when "001" => alu_func <= ALU_SLL;
                    when "010" => alu_func <= ALU_SLT;
                    when "011" => alu_func <= ALU_SLTU;
                    when "100" => alu_func <= ALU_XOR;
                    when "110" => alu_func <= ALU_OR;
                    when "111" => alu_func <= ALU_AND;
                    when "101" =>
                        if (ir(30) = '1') then
                            alu_func <= ALU_SRA;
                        else
                            alu_func <= ALU_SRL;
                        end if;

                    when others => null;
                end case;

			when OP_STORE => 
			      
					memwrite <= '1';
					op2sel <= "10";
					alu_func <= ALU_ADD;
					memwa <= alu_out(5 downto 0);
					dmem_w <= reg_B;
				-- put control for store instruction here

			when others => null;
		end case;
    end process;

	y <= alu_out;
	
	acc: process(reset, clk) 
	begin 
		if (reset = '1') then 
			pc <= (others => '0');
		elsif rising_edge(clk) then 
			pc <= pc + 1;
		end if; 
	end process; 
end architecture;
