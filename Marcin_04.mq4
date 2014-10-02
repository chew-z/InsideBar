//+------------------------------------------------------------------+
//             Copyright © 2012, 2013 chew-z                 |
// v .04 - Marcin stub                                                   |
// 1)  Sygnał aktywny przez określony czas                 |
// 2)                                                                              |
// 3)                                                                              |
// 4)                                                                              |
//+------------------------------------------------------------------+
#property copyright "Marcin_04 © 2012-2014 chew-z"
#include <TradeContext.mq4>
#include <TradeTools\TradeTools5.mqh>
#include <stdlib.mqh>

input int T = 5;               // badana liczba świec pod kątem trendu
input int Expiration = 45;    // On Stop Order Expiration in minutes
input int Bar_size = 10;      // Minimum bar size in pips
input bool With_trend = true; // if true the position is in the trend direction (buy after white candle(s)), if false the position is anti-trend (sell after white candle(s))

input double        Pending = 12; // pullback size in pips - On Stop

int magic_number_1 = 23456789;
int StopLevel;
string AlertText ="";
string  AlertEmailSubject  = "";
string orderComment = "Marcin_04";
static int BarTime;
static int t; //
int contracts = 0;
int     maxContracts       = 2;
double Lots;
double StopLoss, TakeProfit;
int ticketArr[];

//--------------------------
int OnInit()     {
   BarTime = 0;
   ArrayResize(ticketArr, maxContracts, maxContracts);
   for(int i=0; i < maxContracts; i++) //re-initialize table with order tickets
        ticketArr[i] = 0;
   AlertEmailSubject = Symbol() + " Pin-pin 2.0 alert";
   if (Digits == 5 || Digits == 3){    // Adjust for five (5) digit brokers.
      pips2dbl    = Point*10; pips2points = 10;   Digits_pips = 1;
   } else {    pips2dbl    = Point;    pips2points =  1;   Digits_pips = 0; }
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)   {
   Print(__FUNCTION__,"_Deinitalization reason code = ", getDeinitReasonText(reason));
}
//-------------------------
void OnTick()    {
bool isNewBar = NewBar();
double price;
bool  ShortBuy = false, LongBuy = false;
int cnt, check;

if (isNewBar) {
    if(f_OrdersTotal(magic_number_1, ticketArr) < 1) // Gdy nie ma pozycji (bo w domyśle, zostały zamknięte SL lub TP) wyzeruj flagę i czekaj na nowy sygnał
      GlobalVariableSet(StringConcatenate(Symbol(), magic_number_1), 0);
// DISCOVER SIGNALS
   if ( GlobalVariableGet(StringConcatenate(Symbol(), magic_number_1)) == 0 )   { // Only first signal on a bar

      if ( isTrend_H(T, K)  )  {
            if ( With_trend ) LongBuy = true; else ShortBuy = true;
            GlobalVariableSet(StringConcatenate(Symbol(), magic_number_1), 1);
      }
      if ( isTrend_L(T, K) )  {
            if (With_trend) ShortBuy = true; else LongBuy = true;
            GlobalVariableSet(StringConcatenate(Symbol(), magic_number_1), 1);
      }

   }

  }
// EXIT MARKET

// MONEY MANAGEMENT
         Lots =  maxLots;
         cnt = f_OrdersTotal(magic_number_1, ticketArr) + 1;   //how many open lots?
         contracts = f_Money_Management() - cnt;               //how many possible?
// ENTER MARKET CONDITIONS
if( cnt < contracts )   {
      datetime expiration = Time[0] + Expiration * 60;
// check for long position (BUY) possibility
      if(LongBuy == true )      { // pozycja z sygnalu
          StopLoss = NormalizeDouble(Close[1] + (Pending - SL) * pips2dbl, Digits);
          TakeProfit = NormalizeDouble(Close[1] + TP * pips2dbl, Digits);
//--------Transaction
       check = f_SendOrders_OnLimit(OP_BUYSTOP, contracts, price, Lots, StopLoss, TakeProfit, magic_number_1, expiration, orderComment);
//--------
         if(check == 0)         {
              AlertText = "BUY stop order placed : " + Symbol() + ", " + TFToStr(Period())+ " -\r"
               + orderComment + " " + contracts + " order(s) opened. \rPrice = " + DoubleToStr(Ask, 5) + ", L = " + DoubleToStr(L, 5);
         }  else { AlertText = "Error placing BUY limit order : " + ErrorDescription(check) + ". \rPrice = " + DoubleToStr(Ask, 5) + ", L = " + DoubleToStr(L, 5); }
         f_SendAlerts(AlertText);
      }
// check for short position (SELL) possibility
      if(ShortBuy == true )      { // pozycja z sygnalu
            StopLoss = NormalizeDouble(Close[1] + (SL - Pending) *pips2dbl, Digits);
            TakeProfit = NormalizeDouble(Close[1] - TP*pips2dbl, Digits);
//--------Transaction
       check = f_SendOrders_OnLimit(OP_SELLSTOP, contracts, price, Lots, StopLoss, TakeProfit, magic_number_1, expiration, orderComment);
//--------
         if(check == 0)         {
               AlertText = "SELL stop order placed : " + Symbol() + ", " + TFToStr(Period())+ " -\r"
               + orderComment + " " + contracts + " order(s) opened. \rPrice = " + DoubleToStr(Bid, 5) + ", H = " + DoubleToStr(H, 5);
         }  else { AlertText = "Error placing SELL limit order : " + ErrorDescription(check) + ". \rPrice = " + DoubleToStr(Bid, 5) + ", H = " + DoubleToStr(H, 5); }
         f_SendAlerts(AlertText);
      }
 }

} // exit OnTick()


bool isTrend_H(int T1, int K1) { // w zakresie T1 świec powinno być K1 świec wzrostowych
int k = 0;
      for(int i=T1; i > 0; i--) {
          if(Close[i] - Open[i] > Bar_size * pips2dbl)
            k++;
      }
      if (k >= K1)
        return(true);
return(false);
}

bool isTrend_L(int T1, int K1) { // w zakresie T1 powinno być K1 świec spadkowych
int k = 0;
      for(int i=T1; i > 0; i--) {
          if(Open[i] - Close[i] > Bar_size * pips2dbl)
            k++;
      }
      if (k >= K1)
        return(true);
return(false);
}
