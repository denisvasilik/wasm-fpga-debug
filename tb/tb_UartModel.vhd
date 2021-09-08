library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity tb_UartModel is
    port (
        Clk : in std_logic;
        Rst : in std_logic;
        Uart_Adr : in std_logic_vector(23 downto 0);
        Uart_Sel : in std_logic_vector(3 downto 0);
        Uart_DatIn: in std_logic_vector(31 downto 0);
        Uart_We : in std_logic;
        Uart_Stb : in std_logic;
        Uart_Cyc : in std_logic_vector(0 downto 0);
        Uart_DatOut : out std_logic_vector(31 downto 0);
        Uart_Ack : out std_logic
    );
end tb_UartModel;

architecture Behavioral of tb_UartModel is

    signal State : std_logic_vector(7 downto 0);

    type byte_array is array (0 to 7) of std_logic_vector(0 to 7);

    signal RxBuffer : byte_array;
    signal RxBufferPosition : integer range 0 to 7;

    signal UartBlk_Unoccupied_Ack : std_logic;
    signal UartRxRun : std_logic;
    signal UartTxRun : std_logic;
    signal WRegPulse_ControlReg : std_logic;
    signal UartRxDataPresent : std_logic;
    signal UartRxBusy : std_logic;
    signal UartTxBusy : std_logic;
    signal TxDataByte : std_logic_vector(7 downto 0);
    signal RxDataByte : std_logic_vector(7 downto 0);

begin

    UartWishboneSlave : process (Clk, Rst) is
      constant StateIdle0 : std_logic_vector(7 downto 0) := x"00";
      constant StateSend0 : std_logic_vector(7 downto 0) := x"01";
      constant StateReceive0 : std_logic_vector(7 downto 0) := x"02";
    begin
        if (Rst = '1') then
            UartRxBusy <= '0';
            RxDataByte <= (others => '0');
            UartTxBusy <= '0';
            UartRxDataPresent <= '1';
            RxBuffer <= (x"73", x"74", x"61", x"74", x"75", x"73", x"0D", x"0A");
            RxBufferPosition <= 0;
            State <= StateIdle0;
        elsif rising_edge(Clk) then
            if (State = StateIdle0) then
              UartRxBusy <= '0';
              UartTxBusy <= '0';
              if (WRegPulse_ControlReg = '1' and UartTxRun = '1') then
                UartTxBusy <= '1';
                State <= StateSend0;
              elsif (WRegPulse_ControlReg = '1' and UartRxRun = '1') then
                UartRxBusy <= '1';
                State <= StateReceive0;
              end if;
            elsif (State = StateSend0) then
                State <= StateIdle0;
            elsif (State = StateReceive0) then
                if (RxBufferPosition = 7) then
                    UartRxDataPresent <= '0';
                end if;
                RxDataByte <= RxBuffer(RxBufferPosition);
                RxBufferPosition <= RxBufferPosition + 1;
                State <= StateIdle0;
            end if;
        end if;
    end process;

    UartBlk_WasmFpgaUart_i : entity work.UartBlk_WasmFpgaUart
      port map (
        Clk => Clk,
        Rst => Rst,
        Adr => Uart_Adr,
        Sel => Uart_Sel,
        DatIn => Uart_DatIn,
        We => Uart_We,
        Stb => Uart_Stb,
        Cyc => Uart_Cyc,
        UartBlk_DatOut => Uart_DatOut,
        UartBlk_Ack => Uart_Ack,
        UartBlk_Unoccupied_Ack => UartBlk_Unoccupied_Ack,
        UartRxRun => UartRxRun,
        UartTxRun => UartTxRun,
        WRegPulse_ControlReg => WRegPulse_ControlReg,
        UartRxDataPresent => UartRxDataPresent,
        UartRxBusy => UartRxBusy,
        UartTxBusy => UartTxBusy,
        TxDataByte => TxDataByte,
        RxDataByte => RxDataByte
      );

end Behavioral;
