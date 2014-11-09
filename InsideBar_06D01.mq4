//+------------------------------------------------------------------+
//             Copyright © 2012, 2013, 2014 chew-z                   |
// v .06D01 - InsideBar setup stub                                   |
// 1) searches for Daily Inside Bars pattern within last K days      |
// 2) this subversion exits at end of the day (beginning of next day)|
// 3) logic exactly? as in Python                                    |
//+------------------------------------------------------------------+
#property copyright "InsideBar_06D01 © 2012-2014 chew-z"
#include <TradeContext.mq4>
#include <TradeTools\TradeTools5.mqh>
#include <stdlib.mqh>

int magic_number_1 = 32547798;
string AlertText ="";
string  AlertEmailSubject  = "";
string orderComment = "InsideBar_06D01";
int contracts = 0;

int StopLevel;
static int BarTime;
static int t; //
int ticketArr[], ticketArrLimit[];

//--------------------------
int OnInit()     {
   BarTime = 0;
   ArrayResize(ticketArr, maxContracts, maxContracts);
   ArrayResize(ticketArrLimit, maxContracts, maxContracts);
   for(int i=0; i < maxContracts; i++) //re-initialize table with order tickets
        ticketArr[i] = 0;
   for(i=0; i < maxContracts; i++) //re-initialize an array with limit order tickets
      ticketArrLimit[i] = 0;
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
bool isNewDay = NewDay2();
double price;
bool  ShortBuy = false, LongBuy = false;
int cnt, cntLimit, check;

  if ( isNewDay ) {
   Print( "New Day. Server time = " + TimeHour( TimeCurrent() ) + ": Local time = "
              + TimeHour( TimeLocal() )+ ": Bar Time = " + TimeHour(Time[0])+ ": " );
   Print( "Time offset = "+ f_TimeOffset() );
   cnt = f_OrdersTotal(magic_number_1, ticketArr); //-1 = no active orders
   while ( cnt >= 0) {                              //Print ("Ticket #", ticketArr[k]);
      if(OrderSelect(ticketArr[cnt], SELECT_BY_TICKET, MODE_TRADES) )   {
// First EXIT MARKET [on next day Open, suboptimal]
         if(OrderType() == OP_BUY || OrderType() == OP_SELL )   {
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

   for(int i=0; i < maxContracts; i++) //re-initialize an array with order tickets
      ticketArr[i] = 0;
   for(i=0; i < maxContracts; i++) //re-initialize an array with limit order tickets
      ticketArrLimit[i] = 0;
   int MotherBar = MotherBarD(K);
   L = Low[1];
   H = High[1];

// DISCOVER SIGNALS
    if (MotherBar > 1 && isInsideBarD(MotherBar) && BarSizeD(1) > minBar*pips2dbl)
      LongBuy = True;
    if (MotherBar > 1 && isInsideBarD(MotherBar) && BarSizeD(1) > minBar*pips2dbl)
      ShortBuy = True;
// MONEY MANAGEMENT
   double Lots =  maxLots;
   cnt = f_OrdersTotal(magic_number_1, ticketArr) + 1;   //how many open lots?
   cntLimit = f_LimitOrders(magic_number_1, ticketArrLimit); //are there already limit orders placed? [in case of restart]
   contracts = f_Money_Management() - cnt;               //how many possible?
   double TakeProfit, StopLoss;
// Next ENTER MARKET
    if( cnt < maxContracts && cntLimit < 0 )   { //if we are able to place new orders...
      //datetime expiration = StrToTime( (End_Hour-1)+":55" );   
      /* if NewDay occurs at 23 local time gives time in the past  and fails during order placement */
      datetime expiration = Time[0] + (End_Hour-1)*3600 + 55*60; /* this will work only for D1 and
      still is tricky as Time[] will shift from 00:00 to 23:00 */
      Print("expiration = " + TimeToStr(expiration));
// check for long position (BUY) possibility
      if(LongBuy == true )      { // pozycja z sygnalu
         price = NormalizeDouble(H, Digits);
         StopLoss = NormalizeDouble(L, Digits);
         TakeProfit = NormalizeDouble(0.0, Digits);
   //--------Transaction        //Print (StopLoss," - ", price, " - ", TakeProfit);
         if (price > Ask) {
            check = f_SendOrders_OnLimit(OP_BUYSTOP, contracts, price, Lots, StopLoss, TakeProfit, magic_number_1, expiration, orderComment);
   //--------
            if(check == 0)         {
                  AlertText = "BUY stop order placed : " + Symbol() + ", " + TFToStr(Period())+ " -\r"
                   + orderComment + " " + contracts + " order(s) opened. \rPrice = " + DoubleToStr(Ask, 5) + ", L = " + DoubleToStr(L, 5);
             }  else { AlertText = "Error placing BUY stop order : " + ErrorDescription(check) + ". \rPrice = " + DoubleToStr(Ask, 5) + ", L = " + DoubleToStr(L, 5); }
            f_SendAlerts(AlertText);
          }
      }
// check for short position (SELL) possibility
      if(ShortBuy == true )      { // pozycja z sygnalu
         price = NormalizeDouble(L, Digits);
         StopLoss = NormalizeDouble(H, Digits);
         TakeProfit = NormalizeDouble(0.0, Digits);
   //--------Transaction        //Print (TakeProfit, " - ", price, " - ", StopLoss);
         if(price < Bid) {
            check = f_SendOrders_OnLimit(OP_SELLSTOP, contracts, price, Lots, StopLoss, TakeProfit, magic_number_1, expiration, orderComment);
   //--------
            if(check == 0)         {
                   AlertText = "SELL stop order placed : " + Symbol() + ", " + TFToStr(Period())+ " -\r"
                   + orderComment + " " + contracts + " order(s) opened. \rPrice = " + DoubleToStr(Bid, 5) + ", H = " + DoubleToStr(H, 5);
             }  else { AlertText = "Error placing SELL stop order : " + ErrorDescription(check) + ". \rPrice = " + DoubleToStr(Bid, 5) + ", H = " + DoubleToStr(H, 5); }
            f_SendAlerts(AlertText);
         }
      }
    }

  } // if isNewDay

} // exit OnTick()


