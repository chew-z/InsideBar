//+------------------------------------------------------------------+
//             Copyright Â© 2012, 2013, 2014, 2015 chew-z            |
// v .06D04 - InsideBar setup stub                                   |
// 1) searches for Daily Inside Bars pattern within last K days      |
// 2)                                                                |
// 3)                                                                |
//+------------------------------------------------------------------+
#property copyright "InsideBar_06D04 © 2012-2015 chew-z"
#include <TradeContext.mq4>
#include <TradeTools\TradeTools5.mqh>
#include <stdlib.mqh>

extern int MaxRisk = 200; //Maximum risk in pips

int magic_number_1 = 32547799;
string orderComment = "InsideBar_06D04";
int contracts = 0;

int StopLevel;
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
            pips2dbl    = Point*10; pips2points = 10;   Digits_pips = 1; dbl2pips = 0.1/Point;
     } else {    pips2dbl    = Point;    pips2points =  1;   Digits_pips = 0; dbl2pips = 1.0/Point; }

     // .. and after all this
    Print("Lot size ", MarketInfo(Symbol(), MODE_LOTSIZE), " Lot step ", MarketInfo(Symbol(), MODE_LOTSTEP));
    Print("Min lot ", MarketInfo(Symbol(), MODE_MINLOT), " Max lot ", MarketInfo(Symbol(), MODE_MAXLOT));

     if( !IsConnected() )
                Sleep( 5000 );  //wait 5s for establishing connection to trading server
                //Sleep() is automatically passed during testing

     return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)   {
     Print(__FUNCTION__,"_Deinitalization reason code = ", getDeinitReasonText(reason));
}
//-------------------------
void OnTick()    {
bool isNewBar = NewBar();
bool isNewDay = NewDay2();
double price, Risk, RiskPLN;
bool  ShortBuy = false, LongBuy = false;
int cnt, cntLimit, check;

    if ( isNewDay ) {
         Print( "New Day. Server time = " + TimeHour( TimeCurrent() ) + ":" + TimeMinute( TimeCurrent() )
            + " Local time = " + TimeHour( TimeLocal() ) + ":" + TimeMinute( TimeLocal() )
            + " Bar Time = " + TimeHour(Time[0])+ ": " );
         Print( "Time offset = "+ f_TimeOffset() );

         for(int i=0; i < maxContracts; i++) //re-initialize an array with order tickets
                ticketArr[i] = 0;
         for(i=0; i < maxContracts; i++)    //re-initialize an array with limit order tickets
                ticketArrLimit[i] = 0;

        double spread = Ask - Bid;
// DISCOVER SIGNALS
        int MotherBar = MotherBarD(K);
        Print("MotherBar: ", MotherBar);
        int InsideBar = InsideBarD(MotherBar);
        Print("InsideBar: ", InsideBar);
        L = NormalizeDouble(Low[InsideBar], Digits); // - spread
        H = NormalizeDouble(High[InsideBar] + spread, Digits);
        Risk = (H-L)*dbl2pips;
        if (IsTesting())
            RiskPLN = Risk; // During testing MarketInfo( "PAIR", MODE_ASK) is always 0;
        else
            RiskPLN = Risk * pipsValuePLN(Symbol());
        if ( MotherBar > 1 && InsideBar > 0 && isBarSignificant(InsideBar) ) {
            LongBuy = True;
            ShortBuy = True;
        }
// MONEY MANAGEMENT
         double Lots =  maxLots;
         //all this is a bit too complex 0, -1, etc.
         cnt = f_OrdersTotal(magic_number_1, ticketArr) + 1;   //how many open lots?
         cntLimit = f_LimitOrders(magic_number_1, ticketArrLimit); //are there already limit orders placed? [in case of restart]
         contracts = f_Money_Management() - cnt;               //how many possible?
         double TakeProfit, StopLoss;
// ENTER MARKET CONDITIONS
        if( cnt < maxContracts && cntLimit < 0 )   { //if we are able to place new orders...
            /* datetime expiration = StrToTime( (End_Hour-1)+":55" ); if NewDay occurs at 23 local time
            gives time in the past  and fails during order placement */
            datetime expiration = Time[0] + (End_Hour-1)*3600 + 55*60; /*this will work only for D1 and
            still is tricky as Time[] will shift from 00:00 to 23:00 resulting in earlier expiration */
            Print("expiration = " + TimeToStr(expiration));
// check for long position (BUY) possibility
            if(LongBuy == true )      { // pozycja z sygnalu
                 price = NormalizeDouble(H, Digits);
                 if (Risk < MaxRisk)  {
                    StopLoss = NormalizeDouble(L, Digits);
                    } else {
                    StopLoss = NormalizeDouble(H - MaxRisk * pips2dbl, Digits);
                    }
                 TakeProfit = NormalizeDouble(0.0, Digits);
 //--------Transaction        //Print (StopLoss," - ", price, " - ", TakeProfit);
                 if (price > Ask) {
                        check = f_SendOrders_OnLimit(OP_BUYSTOP, contracts, price, Lots, StopLoss, TakeProfit, magic_number_1, expiration, orderComment);
 //--------
                    if(check == 0)         {
                                AlertText = "BUY stop order placed : " + Symbol() + ", " + TFToStr(Period())+ " -\r"
                                 + orderComment + " " + contracts + " order(s) opened. \rPrice = " + DoubleToStr(Ask, 5) + ",\rRisk = " + DoubleToStr(Risk, 0) + " (PLN " + DoubleToStr(RiskPLN, 0) + ")";
                     }  else { AlertText = "Error placing BUY stop order : " + ErrorDescription(check) + ". \rPrice = " + DoubleToStr(Ask, 5) + ", L = " + DoubleToStr(L, 5); }
                    f_SendAlerts(AlertText);
                }
            }
// check for short position (SELL) possibility
            if(ShortBuy == true )      { // pozycja z sygnalu
                 price = NormalizeDouble(L, Digits);
                 if (Risk < MaxRisk) {
                    StopLoss = NormalizeDouble(H, Digits);
                    } else {
                    StopLoss = NormalizeDouble(L + MaxRisk * pips2dbl, Digits);
                    }
                 TakeProfit = NormalizeDouble(0.0, Digits);
 //--------Transaction        //Print (TakeProfit, " - ", price, " - ", StopLoss);
                 if(price < Bid) {
                        check = f_SendOrders_OnLimit(OP_SELLSTOP, contracts, price, Lots, StopLoss, TakeProfit, magic_number_1, expiration, orderComment);
     //--------
                        if(check == 0)         {
                                     AlertText = "SELL stop order placed : " + Symbol() + ", " + TFToStr(Period())+ " -\r"
                                     + orderComment + " " + contracts + " order(s) opened. \rPrice = " + DoubleToStr(Bid, 5) + ",\rRisk = " + DoubleToStr(Risk, 0) + " (PLN " + DoubleToStr(RiskPLN, 0) + ")";
                         }  else { AlertText = "Error placing SELL stop order : " + ErrorDescription(check) + ". \rPrice = " + DoubleToStr(Bid, 5) + ", H = " + DoubleToStr(H, 5); }
                        f_SendAlerts(AlertText);
                 }
            }
        }

    } // if isNewDay

} // exit OnTick()


