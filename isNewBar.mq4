if( isNewBar ) {
     cnt = f_OrdersTotal(magic_number_1, ticketArr); //-1 = no active orders
     while (cnt >= 0) {                              //Print ("Ticket #", ticketArr[k]);
        if(OrderSelect(ticketArr[cnt], SELECT_BY_TICKET, MODE_TRADES) )   {
  // MODIFY ORDERS [if position in profit zone don't close, just trail SL agresivly]
           if(OrderType()== OP_BUY && (Ask - OrderOpenPrice()) > SL * pips2dbl ) {
              RefreshRates();
              StopLoss = NormalizeDouble(Ask - SL*pips2dbl, Digits);
              TakeProfit = OrderTakeProfit();
              if ( StopLoss > OrderStopLoss() + 5*pips2dbl ) {
                    if(TradeIsBusy() < 0) // Trade Busy semaphore
                       break;
                    check = OrderModify(OrderTicket(),OrderOpenPrice(), StopLoss, TakeProfit, 0, Gold);
                    TradeIsNotBusy();
                    AlertText = orderComment + " " + Symbol() + " BUY order modification attempted.\rResult = " + ErrorDescription(GetLastError()) + ". \rPrice = " + DoubleToStr(Ask, 5) + ", H = " + DoubleToStr(H, 5);
                    f_SendAlerts(AlertText);
              }
           }
           if(OrderType()==OP_SELL && (OrderOpenPrice()- Bid) > SL * pips2dbl ) {
              RefreshRates();
              StopLoss = NormalizeDouble(Bid + SL*pips2dbl, Digits);
              TakeProfit = OrderTakeProfit();
              if ( StopLoss < OrderStopLoss() + 5*pips2dbl )  {
                    if(TradeIsBusy() < 0) // Trade Busy semaphore
                       break;
                    check = OrderModify(OrderTicket(),OrderOpenPrice(), StopLoss, TakeProfit, 0, Gold);
                    TradeIsNotBusy();
                    AlertText = orderComment + " " + Symbol() + " SELL order modification attempted.\rResult = " + ErrorDescription(GetLastError()) + ". \rPrice = " + DoubleToStr(Bid, 5) + ", L = " + DoubleToStr(L, 5);
                    f_SendAlerts(AlertText);
              }
           }
         }//if OrderSelect
        cnt--;
        } //end while
      }//if NewBar
