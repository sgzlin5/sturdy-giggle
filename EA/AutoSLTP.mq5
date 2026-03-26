//+------------------------------------------------------------------+
//|  AutoSLTP.mq5                                                    |
//|  手动下单后自动设置止盈(TP)和止损(SL)                            |
//|  仅作用于手动下单（Magic = 0），强制覆盖已有 SL/TP               |
//+------------------------------------------------------------------+
#property copyright   "TradFi"
#property version     "1.00"
#property strict

#include <Trade\Trade.mqh>

//--- 输入参数
input group "== 止损 / 止盈设置 =="
input int InpStopLoss   = 300;   // 止损点数（Points），0 = 不设置
input int InpTakeProfit = 500;   // 止盈点数（Points），0 = 不设置

//--- 全局对象
CTrade g_trade;

//+------------------------------------------------------------------+
//| EA 初始化                                                         |
//+------------------------------------------------------------------+
int OnInit()
{
   if(InpStopLoss < 0 || InpTakeProfit < 0)
   {
      Alert("AutoSLTP: SL 和 TP 不能为负数，请检查参数。");
      return INIT_PARAMETERS_INCORRECT;
   }

   if(InpStopLoss == 0 && InpTakeProfit == 0)
      Print("AutoSLTP [警告]: SL 和 TP 均为 0，EA 将不做任何操作。");

   g_trade.SetExpertMagicNumber(0);   // 以 Magic=0 的身份修改仓位
   Print("AutoSLTP 已启动 | SL=", InpStopLoss, " pts | TP=", InpTakeProfit, " pts");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Tick — 无需操作                                                   |
//+------------------------------------------------------------------+
void OnTick() {}

//+------------------------------------------------------------------+
//| 交易事件回调：监听新开仓成交                                       |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest     &request,
                        const MqlTradeResult      &result)
{
   //--- 只处理「成交入场」事件
   if(trans.type   != TRADE_TRANSACTION_DEAL_ADD) return;
   if(trans.deal_type == DEAL_TYPE_BALANCE)        return;   // 排除入金/出金

   //--- 获取成交信息
   ulong dealTicket = trans.deal;
   if(!HistoryDealSelect(dealTicket)) return;

   //--- 只处理开仓方向（DEAL_ENTRY_IN）
   ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
   if(entry != DEAL_ENTRY_IN) return;

   //--- 找到对应仓位
   ulong positionId = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
   if(!PositionSelectByTicket(positionId)) return;

   //--- 仅处理手动下单（Magic = 0）
   long magic = PositionGetInteger(POSITION_MAGIC);
   if(magic != 0) return;

   //--- 计算 SL / TP
   string symbol    = PositionGetString(POSITION_SYMBOL);
   double point     = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   double newSL = 0.0;
   double newTP = 0.0;

   if(posType == POSITION_TYPE_BUY)
   {
      newSL = (InpStopLoss   > 0) ? NormalizeDouble(openPrice - InpStopLoss   * point, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) : 0.0;
      newTP = (InpTakeProfit > 0) ? NormalizeDouble(openPrice + InpTakeProfit * point, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) : 0.0;
   }
   else if(posType == POSITION_TYPE_SELL)
   {
      newSL = (InpStopLoss   > 0) ? NormalizeDouble(openPrice + InpStopLoss   * point, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) : 0.0;
      newTP = (InpTakeProfit > 0) ? NormalizeDouble(openPrice - InpTakeProfit * point, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) : 0.0;
   }
   else
   {
      return;   // 未知仓位类型
   }

   //--- 修改仓位（强制覆盖 SL/TP）
   bool ok = g_trade.PositionModify(positionId, newSL, newTP);

   if(ok)
      PrintFormat("AutoSLTP [成功] #%I64u %s %s | 开仓=%.5f | SL=%.5f | TP=%.5f",
                  positionId,
                  symbol,
                  (posType == POSITION_TYPE_BUY) ? "BUY" : "SELL",
                  openPrice, newSL, newTP);
   else
      PrintFormat("AutoSLTP [失败] #%I64u %s | 错误=%d | %s",
                  positionId, symbol,
                  g_trade.ResultRetcode(),
                  g_trade.ResultRetcodeDescription());
}
//+------------------------------------------------------------------+
