library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package WasmFpgaDebugPackage is

    constant MAX_STATE_HIGH_IDX : natural  := 7;
    constant MAX_STRING_HIGH_IDX : natural := 127;

    type byte_array is array (natural range<>) of std_logic_vector(7 downto 0);

    constant stateIdle : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(0,MAX_STATE_HIGH_IDX+1);
    constant stateExit : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(1,MAX_STATE_HIGH_IDX+1);
    constant stateError : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(255,MAX_STATE_HIGH_IDX+1);

    constant WASMFPGAUART_ADR_BLK_BASE_UartBlk : std_logic_vector(23 downto 0) := x"000000";
    constant WASMFPGAUART_ADR_TxDataReg : std_logic_vector(23 downto 0) := std_logic_vector(x"000008" + unsigned(WASMFPGAUART_ADR_BLK_BASE_UartBlk));
    constant WASMFPGAUART_ADR_RxDataReg : std_logic_vector(23 downto 0) := std_logic_vector(x"00000C" + unsigned(WASMFPGAUART_ADR_BLK_BASE_UartBlk));

    constant WASMFPGAUART_ADR_ControlReg : std_logic_vector(23 downto 0) := std_logic_vector(x"000000" + unsigned(WASMFPGAUART_ADR_BLK_BASE_UartBlk));
    constant WASMFPGAUART_VAL_TxDoRun : std_logic := '1';
    constant WASMFPGAUART_VAL_RxDoRun : std_logic := '1';

    constant WASMFPGAUART_ADR_StatusReg : std_logic_vector(23 downto 0) := std_logic_vector(x"000004" + unsigned(WASMFPGAUART_ADR_BLK_BASE_UartBlk));
    constant WASMFPGAUART_VAL_TxIsNotBusy : std_logic := '0';
    constant WASMFPGAUART_VAL_RxDataIsPresent : std_logic := '1';

    -- WASM DEBUG HEADER
    constant WASMFPGAENGINEDEBUG_ADR_BLK_BASE_EngineBlk : std_logic_vector(23 downto 0) := x"000000";
    constant WASMFPGAENGINEDEBUG_ADR_StatusReg : std_logic_vector(23 downto 0) := std_logic_vector(x"000000" + unsigned(WASMFPGAENGINEDEBUG_ADR_BLK_BASE_EngineBlk));

    -- UTILITIES
    function my_min(a: integer; b: integer) return integer;

    function strcmp(s1: byte_array; s2: byte_array) return std_logic;

    function to_byte_array(s: string) return byte_array;

    procedure print (constant value : in string;
                     signal state : inout unsigned(MAX_STATE_HIGH_IDX downto 0);
                     signal count : inout natural range 0 to MAX_STRING_HIGH_IDX;
                     signal Uart_Adr : out std_logic_vector(23 downto 0);
                     signal Uart_Sel : out std_logic_vector(3 downto 0);
                     signal Uart_DatIn: in std_logic_vector(31 downto 0);
                     signal Uart_We : out std_logic;
                     signal Uart_Stb : out std_logic;
                     signal Uart_Cyc : out std_logic_vector(0 downto 0);
                     signal Uart_DatOut : out std_logic_vector(31 downto 0);
                     signal Uart_Ack : in std_logic);

    procedure printc (constant value : in std_logic_vector(7 downto 0);
                      signal state : inout unsigned(MAX_STATE_HIGH_IDX downto 0);
                      signal Uart_Adr : out std_logic_vector(23 downto 0);
                      signal Uart_Sel : out std_logic_vector(3 downto 0);
                      signal Uart_DatIn: in std_logic_vector(31 downto 0);
                      signal Uart_We : out std_logic;
                      signal Uart_Stb : out std_logic;
                      signal Uart_Cyc : out std_logic_vector(0 downto 0);
                      signal Uart_DatOut : out std_logic_vector(31 downto 0);
                      signal Uart_Ack : in std_logic);

    procedure print_int32 (constant text : in string;
                           signal value : in std_logic_vector(31 downto 0);
                           signal state : inout unsigned(MAX_STATE_HIGH_IDX downto 0);
                           signal count : inout integer range 0 to MAX_STRING_HIGH_IDX;
                           signal Uart_Adr : out std_logic_vector(23 downto 0);
                           signal Uart_Sel : out std_logic_vector(3 downto 0);
                           signal Uart_DatIn: in std_logic_vector(31 downto 0);
                           signal Uart_We : out std_logic;
                           signal Uart_Stb : out std_logic;
                           signal Uart_Cyc : out std_logic_vector(0 downto 0);
                           signal Uart_DatOut : out std_logic_vector(31 downto 0);
                           signal Uart_Ack : in std_logic);

end package;

package body WasmFpgaDebugPackage is

  function my_min(a: integer; b: integer)
    return integer is
  begin
    if a < b then
      return a;
    else
      return b;
    end if;
  end function;

  function strcmp(s1: byte_array; s2: byte_array)
    return std_logic
  is
    variable min: integer;
    variable v1, v2: std_logic_vector(7 downto 0);
  begin
    min := my_min(s1'length, s2'length);
    for i in 0 to min-1 loop
      v1 := s1(i);
      v2 := s2(i);
	  if v1 /= v2 then
	    return '0';
	  end if;
	end loop;
	return '1';
  end function;

  function to_byte_array(s: string)
    return byte_array
  is
    variable r : byte_array(s'length - 1 downto 0);
  begin
    for i in 1 to s'high loop
      r(i - 1) := std_logic_vector(to_unsigned(character'pos(s(i)), 8));
    end loop;
    return r;
  end function;

   procedure print (constant value : in string;
                      signal state : inout unsigned(MAX_STATE_HIGH_IDX downto 0);
                      signal count : inout integer range 0 to MAX_STRING_HIGH_IDX;
                      signal Uart_Adr : out std_logic_vector(23 downto 0);
                      signal Uart_Sel : out std_logic_vector(3 downto 0);
                      signal Uart_DatIn: in std_logic_vector(31 downto 0);
                      signal Uart_We : out std_logic;
                      signal Uart_Stb : out std_logic;
                      signal Uart_Cyc : out std_logic_vector(0 downto 0);
                      signal Uart_DatOut : out std_logic_vector(31 downto 0);
                      signal Uart_Ack : in std_logic) is
       constant stateTransmit0 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(2,MAX_STATE_HIGH_IDX+1);
       constant stateTransmit1 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(5,MAX_STATE_HIGH_IDX+1);
       constant stateTransmit2 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(3,MAX_STATE_HIGH_IDX+1);
       constant stateTransmit3 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(6,MAX_STATE_HIGH_IDX+1);
       constant stateTransmit4 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(7,MAX_STATE_HIGH_IDX+1);
       constant stateTransmit5 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(8,MAX_STATE_HIGH_IDX+1);
       constant stateTransmit6 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(9,MAX_STATE_HIGH_IDX+1);
   begin
       case state is
           when stateIdle =>
               count <= 1;
               state <= stateTransmit0;
           when stateTransmit0 =>
                Uart_Cyc <= "1";
                Uart_Stb <= '1';
                Uart_Sel <= (others => '1');
                Uart_We <= '1';
                Uart_Adr <= WASMFPGAUART_ADR_TxDataReg;
                Uart_DatOut <= std_logic_vector(to_unsigned(character'pos(value(count)), Uart_DatOut'LENGTH));
                state <= stateTransmit1;
           when stateTransmit1 =>
                if ( Uart_Ack = '1' ) then
                    Uart_Cyc <= (others => '0');
                    Uart_Stb <= '0';
                    Uart_Adr <= (others => '0');
                    Uart_Sel <= (others => '0');
                    Uart_We <= '0';
                    state <= stateTransmit2;
                end if;
           when stateTransmit2 =>
                Uart_Cyc <= "1";
                Uart_Stb <= '1';
                Uart_Sel <= (others => '1');
                Uart_We <= '1';
                Uart_Adr <= WASMFPGAUART_ADR_ControlReg;
                Uart_DatOut <= (31 downto 1 => '0') & WASMFPGAUART_VAL_TxDoRun;
                state <= stateTransmit3;
           when stateTransmit3 =>
                if ( Uart_Ack = '1' ) then
                    Uart_Cyc <= (others => '0');
                    Uart_Stb <= '0';
                    Uart_Adr <= (others => '0');
                    Uart_Sel <= (others => '0');
                    Uart_We <= '0';
                    state <= stateTransmit4;
                end if;
           when stateTransmit4 =>
                Uart_Cyc <= "1";
                Uart_Stb <= '1';
                Uart_Sel <= (others => '1');
                Uart_We <= '1';
                Uart_Adr <= WASMFPGAUART_ADR_StatusReg;
                state <= stateTransmit5;
           when stateTransmit5 =>
                if ( Uart_Ack = '1' ) then
                    Uart_Cyc <= "0";
                    Uart_Stb <= '0';
                    Uart_Adr <= (others => '0');
                    Uart_Sel <= (others => '0');
                    Uart_We <= '0';
                    if (Uart_DatIn(0) = WASMFPGAUART_VAL_TxIsNotBusy) then
                        state <= stateTransmit6;
                    else
                        state <= stateTransmit4;
                    end if;
                end if;
           when stateTransmit6 =>
               if (count = value'LENGTH) then
                   state <= stateExit;
               else
                   count <= count + 1;
                   state <= stateTransmit0;
               end if;
           when stateExit =>
                state <= stateExit;
           when others =>
               state  <= stateError;
       end case;
	end;

   procedure printc (constant value : in std_logic_vector(7 downto 0);
                     signal state : inout unsigned(MAX_STATE_HIGH_IDX downto 0);
                     signal Uart_Adr : out std_logic_vector(23 downto 0);
                     signal Uart_Sel : out std_logic_vector(3 downto 0);
                     signal Uart_DatIn: in std_logic_vector(31 downto 0);
                     signal Uart_We : out std_logic;
                     signal Uart_Stb : out std_logic;
                     signal Uart_Cyc : out std_logic_vector(0 downto 0);
                     signal Uart_DatOut : out std_logic_vector(31 downto 0);
                     signal Uart_Ack : in std_logic) is
       constant stateTransmit0 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(2,MAX_STATE_HIGH_IDX+1);
       constant stateTransmit1 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(5,MAX_STATE_HIGH_IDX+1);
       constant stateTransmit2 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(3,MAX_STATE_HIGH_IDX+1);
       constant stateTransmit3 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(6,MAX_STATE_HIGH_IDX+1);
       constant stateTransmit4 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(7,MAX_STATE_HIGH_IDX+1);
       constant stateTransmit5 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(8,MAX_STATE_HIGH_IDX+1);
       constant stateTransmit6 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(9,MAX_STATE_HIGH_IDX+1);
   begin
       case state is
           when stateIdle =>
                Uart_Cyc <= "1";
                Uart_Stb <= '1';
                Uart_Sel <= (others => '1');
                Uart_We <= '1';
                Uart_Adr <= WASMFPGAUART_ADR_TxDataReg;
                Uart_DatOut <= (31 downto 8 => '0') & value;
                state <= stateTransmit0;
           when stateTransmit0 =>
                if ( Uart_Ack = '1' ) then
                    Uart_Cyc <= (others => '0');
                    Uart_Stb <= '0';
                    Uart_Adr <= (others => '0');
                    Uart_Sel <= (others => '0');
                    Uart_We <= '0';
                    state <= stateTransmit1;
                end if;
           when stateTransmit1 =>
                Uart_Cyc <= "1";
                Uart_Stb <= '1';
                Uart_Sel <= (others => '1');
                Uart_We <= '1';
                Uart_Adr <= WASMFPGAUART_ADR_ControlReg;
                Uart_DatOut <= (31 downto 1 => '0') & WASMFPGAUART_VAL_TxDoRun;
                state <= stateTransmit2;
           when stateTransmit2 =>
                if ( Uart_Ack = '1' ) then
                    Uart_Cyc <= (others => '0');
                    Uart_Stb <= '0';
                    Uart_Adr <= (others => '0');
                    Uart_Sel <= (others => '0');
                    Uart_We <= '0';
                    state <= stateTransmit3;
                end if;
           when stateTransmit3 =>
                Uart_Cyc <= "1";
                Uart_Stb <= '1';
                Uart_Sel <= (others => '1');
                Uart_We <= '1';
                Uart_Adr <= WASMFPGAUART_ADR_StatusReg;
                state <= stateTransmit4;
           when stateTransmit4 =>
                if ( Uart_Ack = '1' ) then
                    Uart_Cyc <= "0";
                    Uart_Stb <= '0';
                    Uart_Adr <= (others => '0');
                    Uart_Sel <= (others => '0');
                    Uart_We <= '0';
                    if (Uart_DatIn(0) = WASMFPGAUART_VAL_TxIsNotBusy) then
                        state <= stateExit;
                    else
                        state <= stateTransmit3;
                    end if;
                end if;
           when stateExit =>
                state <= stateExit;
           when others =>
               state  <= stateError;
       end case;
	end;

   procedure print_int32 (constant text : in string;
                          signal value : in std_logic_vector(31 downto 0);
                          signal state : inout unsigned(MAX_STATE_HIGH_IDX downto 0);
                          signal count : inout integer range 0 to MAX_STRING_HIGH_IDX;
                          signal Uart_Adr : out std_logic_vector(23 downto 0);
                          signal Uart_Sel : out std_logic_vector(3 downto 0);
                          signal Uart_DatIn: in std_logic_vector(31 downto 0);
                          signal Uart_We : out std_logic;
                          signal Uart_Stb : out std_logic;
                          signal Uart_Cyc : out std_logic_vector(0 downto 0);
                          signal Uart_DatOut : out std_logic_vector(31 downto 0);
                          signal Uart_Ack : in std_logic) is
       constant stateTransmit0 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(2,MAX_STATE_HIGH_IDX+1);
       constant stateTransmit1 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(3,MAX_STATE_HIGH_IDX+1);
       constant stateTransmit2 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(4,MAX_STATE_HIGH_IDX+1);
       constant stateTransmit3 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(5,MAX_STATE_HIGH_IDX+1);
       constant stateTransmit4 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(6,MAX_STATE_HIGH_IDX+1);
       constant stateTransmit5 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(7,MAX_STATE_HIGH_IDX+1);
       constant stateTransmit6 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(8,MAX_STATE_HIGH_IDX+1);
       constant stateTransmitValue0 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(9,MAX_STATE_HIGH_IDX+1);
       constant stateTransmitValue1 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(10,MAX_STATE_HIGH_IDX+1);
       constant stateTransmitValue2 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(11,MAX_STATE_HIGH_IDX+1);
       constant stateTransmitValue3 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(12,MAX_STATE_HIGH_IDX+1);
       constant stateTransmitValue4 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(13,MAX_STATE_HIGH_IDX+1);
       constant stateTransmitValue5 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(14,MAX_STATE_HIGH_IDX+1);
       constant stateTransmitValue6 : unsigned(MAX_STATE_HIGH_IDX downto 0) := to_unsigned(15,MAX_STATE_HIGH_IDX+1);
   begin
       case state is
           when stateIdle =>
               count <= 1;
               state <= stateTransmit0;
           when stateTransmit0 =>
                Uart_Cyc <= "1";
                Uart_Stb <= '1';
                Uart_Sel <= (others => '1');
                Uart_We <= '1';
                Uart_Adr <= WASMFPGAUART_ADR_TxDataReg;
                Uart_DatOut <= std_logic_vector(to_unsigned(character'pos(text(count)), Uart_DatOut'LENGTH));
                state <= stateTransmit1;
           when stateTransmit1 =>
                if ( Uart_Ack = '1' ) then
                    Uart_Cyc <= (others => '0');
                    Uart_Stb <= '0';
                    Uart_Adr <= (others => '0');
                    Uart_Sel <= (others => '0');
                    Uart_We <= '0';
                    state <= stateTransmit2;
                end if;
           when stateTransmit2 =>
                Uart_Cyc <= "1";
                Uart_Stb <= '1';
                Uart_Sel <= (others => '1');
                Uart_We <= '1';
                Uart_Adr <= WASMFPGAUART_ADR_ControlReg;
                Uart_DatOut <= (31 downto 1 => '0') & WASMFPGAUART_VAL_TxDoRun;
                state <= stateTransmit3;
           when stateTransmit3 =>
                if ( Uart_Ack = '1' ) then
                    Uart_Cyc <= (others => '0');
                    Uart_Stb <= '0';
                    Uart_Adr <= (others => '0');
                    Uart_Sel <= (others => '0');
                    Uart_We <= '0';
                    state <= stateTransmit4;
                end if;
           when stateTransmit4 =>
                Uart_Cyc <= "1";
                Uart_Stb <= '1';
                Uart_Sel <= (others => '1');
                Uart_We <= '1';
                Uart_Adr <= WASMFPGAUART_ADR_StatusReg;
                state <= stateTransmit5;
           when stateTransmit5 =>
                if ( Uart_Ack = '1' ) then
                    Uart_Cyc <= "0";
                    Uart_Stb <= '0';
                    Uart_Adr <= (others => '0');
                    Uart_Sel <= (others => '0');
                    Uart_We <= '0';
                    if (Uart_DatIn(0) = WASMFPGAUART_VAL_TxIsNotBusy) then
                        state <= stateTransmit6;
                    else
                        state <= stateTransmit4;
                    end if;
                end if;
           when stateTransmit6 =>
               if (count = text'LENGTH) then
                   count <= 7;
                   state <= stateTransmitValue0;
               else
                   count <= count + 1;
                   state <= stateTransmit0;
               end if;
           when stateTransmitValue0 =>
                Uart_Cyc <= "1";
                Uart_Stb <= '1';
                Uart_Sel <= (others => '1');
                Uart_We <= '1';
                Uart_Adr <= WASMFPGAUART_ADR_TxDataReg;
                if( unsigned(value(count * 4 + 3 downto count * 4)) < to_unsigned(10, value'LENGTH) ) then
                    Uart_DatOut <= std_logic_vector(unsigned(value(count * 4 + 3 downto count * 4)) + to_unsigned(48, Uart_DatOut'LENGTH));
                else
                    Uart_DatOut <= std_logic_vector(unsigned(value(count * 4 + 3 downto count * 4)) + to_unsigned(55, Uart_DatOut'LENGTH));
                end if;
                state <= stateTransmitValue1;
           when stateTransmitValue1 =>
                if ( Uart_Ack = '1' ) then
                    Uart_Cyc <= (others => '0');
                    Uart_Stb <= '0';
                    Uart_Adr <= (others => '0');
                    Uart_Sel <= (others => '0');
                    Uart_We <= '0';
                    state <= stateTransmitValue2;
                end if;
           when stateTransmitValue2 =>
                Uart_Cyc <= "1";
                Uart_Stb <= '1';
                Uart_Sel <= (others => '1');
                Uart_We <= '1';
                Uart_Adr <= WASMFPGAUART_ADR_ControlReg;
                Uart_DatOut <= (31 downto 1 => '0') & WASMFPGAUART_VAL_TxDoRun;
                state <= stateTransmitValue3;
           when stateTransmitValue3 =>
                if ( Uart_Ack = '1' ) then
                    Uart_Cyc <= (others => '0');
                    Uart_Stb <= '0';
                    Uart_Adr <= (others => '0');
                    Uart_Sel <= (others => '0');
                    Uart_We <= '0';
                    state <= stateTransmitValue4;
                end if;
           when stateTransmitValue4 =>
                Uart_Cyc <= "1";
                Uart_Stb <= '1';
                Uart_Sel <= (others => '1');
                Uart_We <= '1';
                Uart_Adr <= WASMFPGAUART_ADR_StatusReg;
                state <= stateTransmitValue5;
           when stateTransmitValue5 =>
                if ( Uart_Ack = '1' ) then
                    Uart_Cyc <= "0";
                    Uart_Stb <= '0';
                    Uart_Adr <= (others => '0');
                    Uart_Sel <= (others => '0');
                    Uart_We <= '0';
                    if (Uart_DatIn(0) = WASMFPGAUART_VAL_TxIsNotBusy) then
                        state <= stateTransmitValue6;
                    else
                        state <= stateTransmitValue4;
                    end if;
                end if;
           when stateTransmitValue6 =>
                if (count = 0) then
                    state <= stateExit;
                else
                    count <= count - 1;
                    state <= stateTransmitValue0;
                end if;
           when stateExit =>
                state <= stateExit;
           when others =>
               state  <= stateError;
       end case;
	end;

end package body;
