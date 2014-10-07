//+------------------------------------------------------------------+
//             Copyright © 2012, 2013, 2014 chew-z                   |
// v .05 - InsideBar setup stub                                      |
// 1) searches for Daily Inside Bars pattern within last K days      |
// 2) exits at end of the day                                        |
// 3) logic exactly? as in Python                                    |
//+------------------------------------------------------------------+
#property copyright "InsideBar_05 © 2012-2014 chew-z"
#include <TradeContext.mq4>
#include <TradeTools\TradeTools5.mqh>
#include <stdlib.mqh>

input int End_Hour = 22;
int magic_number_1 = 32547698;
string AlertText ="";
string  AlertEmailSubject  = "";
string orderComment = "InsideBar_05";
int contracts = 0;

int StopLevel;
static int BarTime;
static int t; //
double Lots;
double StopLoss, TakeProfit;
int ticketArr[];

//--------------------------
int OnInit()     {
   BarTime = 0;
   ArrayResize(ticketArr, maxContracts, maxContracts);
   for(int i=0; i < maxContracts; i++) //re-initialize table with order tickets
        ticketArr[i] = 0;
   AlertEmailSubject = Symbol() + " " + orderComment + " alert";
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
    if (MotherBar > 1 && isInsideBar(MotherBar))
      LongBuy = True;
    if (MotherBar > 1 && isInsideBar(MotherBar))
      ShortBuy = True;
// MONEY MANAGEMENT
   Lots =  maxLots;
   cnt = f_OrdersTotal(magic_number_1, ticketArr) + 1;   //how many open lots?
   contracts = f_Money_Management() - cnt;               //how many possible?
// ENTER MARKET CONDITIONS
    if( cnt < maxContracts )   { //if we are able to open new lots...
      datetime expiration = StrToTime( End_Hour+":55" );
// check for long position (BUY) possibility
      if(LongBuy == true )      { // pozycja z sygnalu
         price = NormalizeDouble(H + 1*pips2dbl, Digits);
         StopLoss = NormalizeDouble(L, Digits);
         TakeProfit = NormalizeDouble(0.0, Digits);
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
         TakeProfit = NormalizeDouble(0.0, Digits);
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
  if (isNewBar) {
   cnt = f_OrdersTotal(magic_number_1, ticketArr); //-1 = no active orders
   while (cnt >= 0) {                              //Print ("Ticket #", ticketArr[k]);
      if(OrderSelect(ticketArr[cnt], SELECT_BY_TICKET, MODE_TRADES) )   {
// EXIT MARKET [time exit]
         if( (OrderType() == OP_BUY || OrderType() == OP_SELL) && TimeHour(Time[0]) == End_Hour )   {
                  RefreshRates();
                  if(TradeIsBusy() < 0) // Trade Busy semaphore
                     break;
                  check = OrderClose(OrderTicket(),OrderLots(), Bid, 5, Violet);
                  TradeIsNotBusy();
                  f_SendAlerts(orderComment + " trade exit attempted.\rResult = " + ErrorDescription(GetLastError()) + ". \rPrice = " + DoubleToStr(Ask, 5));
         }
       }//if OrderSelect
      cnt--;
      } //end while
  } // if NewBar

} // exit OnTick()

////////////////////////////////////////////////////////////////////////////
int MotherBar(int K) { //find largest bar within last K bars
int MoBar = K;
  for(int i=K; i > 1; i--)
    if (BarSize(i) < BarSize(i-1))
      MoBar = i-1;

return (MoBar);
}

bool isInsideBar(int k) { // is largest (k) bar completely overshadowing inside bar?
  if (iLow(NULL, PERIOD_D1, k) < iLow(NULL, PERIOD_D1, 1)
    && iHigh(NULL, PERIOD_D1, k) > iHigh(NULL, PERIOD_D1, 1))
    return true;

return false;
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
