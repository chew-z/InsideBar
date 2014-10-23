//+------------------------------------------------------------------+
//             Copyright © 2012, 2013, 2014 chew-z                   |
// v .06 - InsideBar setup stub                                      |
// 1) searches for Daily Inside Bars pattern within last K days      |
// 2) exits at end of the day                                        |
// 3) logic exactly? as in Python                                    |
//+------------------------------------------------------------------+
#property copyright "InsideBar_06 © 2012-2014 chew-z"
#include <TradeContext.mq4>
#include <TradeTools\TradeTools5.mqh>
#include <stdlib.mqh>

int magic_number_1 = 32547698;
string AlertText ="";
string  AlertEmailSubject  = "";
string orderComment = "InsideBar_06";
int contracts = 0;

int StopLevel;
static int BarTime;
static int t; //
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
   int iDay = iBarShift(NULL, PERIOD_D1, Time[0], false);
   L = iLow(NULL, PERIOD_D1, iDay+1);
   H = iHigh(NULL, PERIOD_D1, iDay+1);
  // DISCOVER SIGNALS
    if (MotherBar > 1 && isInsideBar(MotherBar) && BarSize(1) > minBar*pips2dbl)
      LongBuy = True;
    if (MotherBar > 1 && isInsideBar(MotherBar) && BarSize(1) > minBar*pips2dbl)
      ShortBuy = True;
// MONEY MANAGEMENT
   double Lots =  maxLots;
   cnt = f_OrdersTotal(magic_number_1, ticketArr) + 1;   //how many open lots?
   contracts = f_Money_Management() - cnt;               //how many possible?
   double TakeProfit, StopLoss;
// ENTER MARKET CONDITIONS
    if( cnt < maxContracts )   { //if we are able to open new lots...
      datetime expiration = StrToTime( (End_Hour-1)+":55" );
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
         }  else { AlertText = "Error placing BUY stop order : " + ErrorDescription(check) + ". \rPrice = " + DoubleToStr(Ask, 5) + ", L = " + DoubleToStr(L, 5); }
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
   while ( cnt >= 0) {                              //Print ("Ticket #", ticketArr[k]);
      if(OrderSelect(ticketArr[cnt], SELECT_BY_TICKET, MODE_TRADES) )   {
// EXIT MARKET [time exit]
         if(TimeHour(Time[0]) == End_Hour && (OrderType() == OP_BUY || OrderType() == OP_SELL) )   {
                  if(TradeIsBusy() < 0) // Trade Busy semaphore
                     break;
                  RefreshRates();
                  if (OrderType()==OP_SELL) price = Ask;
                  if (OrderType()==OP_BUY)  price = Bid;
                  check = OrderClose(OrderTicket(), OrderLots(), price, 5, Violet);
                  TradeIsNotBusy();
                  f_SendAlerts(orderComment + " trade exit attempted.\rResult = " + ErrorDescription(GetLastError()) + ". \rPrice = " + DoubleToStr(Ask, 5));
         }
       }//if OrderSelect
      cnt--;
      } //end while
  } // if NewBar

} // exit OnTick()


