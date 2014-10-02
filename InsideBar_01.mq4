//+------------------------------------------------------------------+
//             Copyright © 2012, 2013, 2014 chew-z                   |
// v .01 - InsideBar setup stub                                      |
// 1) searches for Daily Inside Bars pattern within last K days      |
// 2) places stop orders for both - follow through and reversal?     |
// 3) good exit, time exit and lazy trailing SL ?                    |
//+------------------------------------------------------------------+
#property copyright "InsideBar_01 © 2012-2014 chew-z"
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
int     maxContracts       = 10;
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
bool isNewDay = NewDay();
double price;
bool  ShortBuy = false, LongBuy = false;
int cnt, check;

  if ( isNewDay ) {
   for(int i=0; i < maxContracts; i++) //re-initialize an array with order tickets
      ticketArr[i] = 0;

   int MotherBar = MotherBar(K);
   L = iLow(NULL, PERIOD_D1, MotherBar);
   H = iHigh(NULL, PERIOD_D1, MotherBar);
  // DISCOVER SIGNALS
    if (MotherBar > 1) {
      LongBuy = True;
      ShortBuy = True;
    }
// MONEY MANAGEMENT
         Lots =  maxLots;
         cnt = f_OrdersTotal(magic_number_1, ticketArr) + 1;   //how many open lots?
         contracts = f_Money_Management() - cnt;               //how many possible?
// ENTER MARKET CONDITIONS
if( cnt < maxContracts )   { //if we are able to open new lots...
  contracts = 1;
  datetime expiration = StrToTime( "23:55" );
// check for long position (BUY) possibility
      if(LongBuy == true )      { // pozycja z sygnalu
         price = NormalizeDouble(H + 1*pips2dbl, Digits);
         StopLoss = NormalizeDouble(L, Digits);
         TakeProfit = NormalizeDouble(H + BodySize(MotherBar), Digits);
   //--------Transaction        //Print (StopLoss," - ", price, " - ", TakeProfit);
         if (price > Ask)
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
         price = NormalizeDouble(L - 1*pips2dbl, Digits);
         StopLoss = NormalizeDouble(H, Digits);
         TakeProfit = NormalizeDouble(L - BodySize(MotherBar), Digits);
   //--------Transaction        //Print (TakeProfit, " - ", price, " - ", StopLoss);
         if(price < Bid)
            check = f_SendOrders_OnLimit(OP_SELLSTOP, contracts, price, Lots, StopLoss, TakeProfit, magic_number_1, expiration, orderComment);
   //--------
         if(check == 0)         {
               AlertText = "SELL stop order placed : " + Symbol() + ", " + TFToStr(Period())+ " -\r"
               + orderComment + " " + contracts + " order(s) opened. \rPrice = " + DoubleToStr(Bid, 5) + ", H = " + DoubleToStr(H, 5);
         }  else { AlertText = "Error placing SELL stop order : " + ErrorDescription(check) + ". \rPrice = " + DoubleToStr(Bid, 5) + ", H = " + DoubleToStr(H, 5); }
         f_SendAlerts(AlertText);
      }
    }
  } // if isNewDay

} // exit OnTick()


int MotherBar(int K) {
int MoBar = K;
  for(int i=K; i > 1; i--)
    if (BarSize(i) < BarSize(i-1))
      inBar = i-1;

return (MoBar);
}

double BarSize(int i) {
    double l = iLow(NULL, PERIOD_D1, i);
    double h = iHigh(NULL, PERIOD_D1, i);

return (h-l);
}

double BodySize(int i) {
    double c = iClose(NULL, PERIOD_D1, i);
    double o = iOpen(NULL, PERIOD_D1, i);

return MathAbs(c-o);
}
