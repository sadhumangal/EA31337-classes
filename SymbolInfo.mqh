//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2018, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
   This file is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Properties.
#property strict

// Prevents processing this includes file for the second time.
#ifndef SYMBOLINFO_MQH
#define SYMBOLINFO_MQH

// Forward declaration.
class SymbolInfo;
class Terminal;

// Includes.
#include "Terminal.mqh"

/**
 * Class to provide symbol information.
 */
class SymbolInfo : public Terminal {

  protected:

    // Variables.
    string symbol;             // Current symbol pair.
    MqlTick last_tick;         // Stores the latest prices of the symbol.
    MqlTick tick_data[];       // Stores saved ticks.
    double pip_size;           // Value of pip size.
    uint symbol_digits;        // Count of digits after decimal point in the symbol price.
    //uint pts_per_pip;          // Number of points per pip.
    double volume_precision;

  public:

    /**
     * Implements class constructor with a parameter.
     */
    SymbolInfo(string _symbol = NULL, Log *_log = NULL) :
      symbol(_symbol == NULL ? _Symbol : _symbol),
      pip_size(GetPipSize()),
      symbol_digits(GetDigits()),
      Terminal(_log)
      {
        this.last_tick = GetTick();
      }

    ~SymbolInfo() {
    }

    /* Getters */

    /**
     * Get current symbol pair used by the class.
     */
    string GetSymbol() {
      return this.symbol;
    }

    /**
     * Get the symbol pair from the current chart.
     */
    string GetChartSymbol() {
      return _Symbol;
    }

    /**
     * Updates and gets the latest tick prices.
     *
     * @docs MQL4 https://docs.mql4.com/constants/structures/mqltick
     * @docs MQL5 https://www.mql5.com/en/docs/constants/structures/mqltick
     */
    static MqlTick GetTick(string _symbol) {
      MqlTick _last_tick;
      if (!SymbolInfoTick(_symbol, _last_tick)) {
        PrintFormat("Error: %s(): %s", __FUNCTION__, "Cannot return current prices!");
      }
      return _last_tick;
    }
    MqlTick GetTick() {
      if (!SymbolInfoTick(this.symbol, this.last_tick)) {
        Logger().Error("Cannot return current prices!", __FUNCTION__);
      }
      return this.last_tick;
    }

    /**
     * Gets the last tick prices (without updating).
     */
    MqlTick GetLastTick() {
      return this.last_tick;
    }

    /**
     * The latest known seller's price (ask price) for the current symbol.
     * The RefreshRates() function must be used to update.
     *
     * @see http://docs.mql4.com/predefined/ask
     */
    double Ask() {
      return this.GetTick().ask;

      // @todo?
      // Overriding Ask variable to become a function call.
      // #ifdef __MQL5__ #define Ask Market::Ask() #endif // @fixme 
    }

    /**
     * Updates and gets the latest ask price (best buy offer).
     */
    static double GetAsk(string _symbol) {
      return SymbolInfoDouble(_symbol, SYMBOL_ASK);
    }
    double GetAsk() {
      return this.GetAsk(symbol);
    }

    /**
     * Gets the last ask price (without updating).
     */
    double GetLastAsk() {
      return this.last_tick.ask;
    }

    /**
     * The latest known buyer's price (offer price, bid price) of the current symbol.
     * The RefreshRates() function must be used to update.
     *
     * @see http://docs.mql4.com/predefined/bid
     */
    double Bid() {
      return this.GetTick().bid;

      // @todo?
      // Overriding Bid variable to become a function call.
      // #ifdef __MQL5__ #define Bid Market::Bid() #endif // @fixme
    }

    /**
     * Updates and gets the latest bid price (best sell offer).
     */
    static double GetBid(string _symbol) {
      return SymbolInfoDouble(_symbol, SYMBOL_BID);
    }
    double GetBid() {
      return this.GetBid(symbol);
    }

    /**
     * Gets the last bid price (without updating).
     */
    double GetLastBid() {
      return this.last_tick.bid;
    }

    /**
     * Get the last volume for the current last price.
     *
     * @see: https://www.mql5.com/en/docs/constants/environment_state/marketinfoconstants
     */
    static ulong GetVolume(string _symbol) {
      return GetTick(_symbol).volume;
    }
    ulong GetVolume() {
      return this.GetTick(this.symbol).volume;
    }

    /**
     * Gets the last volume for the current price (without updating).
     */
    ulong GetLastVolume() {
      return this.last_tick.volume;
    }

    /**
     * Get summary volume of current session deals.
     *
     * @see: https://www.mql5.com/en/docs/constants/environment_state/marketinfoconstants
     */
    static double GetSessionVolume(string _symbol) {
      return SymbolInfoDouble(_symbol, SYMBOL_SESSION_VOLUME);
    }
    double GetSessionVolume() {
      return this.GetSessionVolume(this.symbol);
    }

    /**
     * Get current open price depending on the operation type.
     *
     * @param:
     *   op_type int Order operation type of the order.
     * @return
     *   Current open price.
     */
    static double GetOpenOffer(string _symbol, ENUM_ORDER_TYPE _cmd = NULL) {
      if (_cmd == NULL) _cmd = (ENUM_ORDER_TYPE) OrderGetInteger(ORDER_TYPE); // Same as: OrderType();
      // Use the right open price at opening of a market order. For example:
      // When selling, only the latest Bid prices can be used.
      // When buying, only the latest Ask prices can be used.
      return _cmd == ORDER_TYPE_BUY ? GetAsk(_symbol) : GetBid(_symbol);
    }
    double GetOpenOffer(ENUM_ORDER_TYPE _cmd) {
      return GetOpenOffer(symbol, _cmd);
    }

    /**
     * Get current close price depending on the operation type.
     *
     * @param:
     *   op_type int Order operation type of the order.
     * @return
     * Current close price.
     */
    static double GetCloseOffer(string _symbol, ENUM_ORDER_TYPE _cmd = NULL) {
      if (_cmd == NULL) _cmd = (ENUM_ORDER_TYPE) OrderGetInteger(ORDER_TYPE); // Same as: OrderType();
      return _cmd == ORDER_TYPE_BUY ? GetBid(_symbol) : GetAsk(_symbol);
    }
    double GetCloseOffer(ENUM_ORDER_TYPE _cmd = NULL) {
      return GetCloseOffer(symbol, _cmd);
    }

    /**
     * Get the point size in the quote currency.
     *
     * The smallest digit of price quote.
     * A change of 1 in the least significant digit of the price.
     * You may also use Point predefined variable for the current symbol.
     */
    double GetPointSize() {
      return SymbolInfoDouble(symbol, SYMBOL_POINT); // Same as: MarketInfo(symbol, MODE_POINT);
    }
    static double GetPointSize(string _symbol) {
      return SymbolInfoDouble(_symbol, SYMBOL_POINT); // Same as: MarketInfo(symbol, MODE_POINT);
    }

    /**
     * Return a pip size.
     *
     * In most cases, a pip is equal to 1/100 (.01%) of the quote currency.
     */
    static double GetPipSize(string _symbol) {
      // @todo: This code may fail at Gold and Silver (https://www.mql5.com/en/forum/135345#515262).
      return GetDigits(_symbol) % 2 == 0 ? GetPointSize(_symbol) : GetPointSize(_symbol) * 10;
    }
    double GetPipSize() {
      return GetPipSize(symbol);
    }

    /**
     * Get a tick size in the price value.
     *
     * It is the smallest movement in the price quoted by the broker,
     * which could be several points.
     * In currencies it is equivalent to point size, in metals they are not.
     */
    static double GetTickSize(string _symbol) {
      // Note: In currencies a tick is always a point, but not for other markets.
      return SymbolInfoDouble(_symbol, SYMBOL_TRADE_TICK_SIZE);
    }
    double GetTickSize() {
      return GetTickSize(symbol);
    }

    /**
     * Get a tick size in points.
     *
     * It is a minimal price change in points.
     * In currencies it is equivalent to point size, in metals they are not.
     */
    double GetTradeTickSize() {
      return SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    }

    /**
     * Get a tick value in the deposit currency.
     *
     * @return
     * Returns the number of base currency units for one pip of movement.
     */
    static double GetTickValue(string _symbol) {
      return SymbolInfoDouble(_symbol, SYMBOL_TRADE_TICK_VALUE); // Same as: MarketInfo(symbol, MODE_TICKVALUE);
    }
    double GetTickValue() {
      double _value = GetTickValue(symbol);
      _value = _value > 0 ? _value : GetTickValueProfit(symbol);
      return _value > 0 ? _value : 1;
    }

    /**
     * Get a calculated tick price for a profitable position.
     *
     * @return
     * Returns the number of base currency units for one pip of movement.
     */
    static double GetTickValueProfit(string _symbol) {
      // Not supported in MQL4.
      return SymbolInfoDouble(_symbol, SYMBOL_TRADE_TICK_VALUE_PROFIT); // Same as: MarketInfo(symbol, SYMBOL_TRADE_TICK_VALUE_PROFIT);
    }
    double GetTickValueProfit() {
      return GetTickValueProfit(symbol);
    }

    /**
     * Get a calculated tick price for a losing position.
     *
     * @return
     * Returns the number of base currency units for one pip of movement.
     */
    static double GetTickValueLoss(string _symbol) {
      // Not supported in MQL4.
      return SymbolInfoDouble(_symbol, SYMBOL_TRADE_TICK_VALUE_LOSS); // Same as: MarketInfo(symbol, SYMBOL_TRADE_TICK_VALUE_LOSS);
    }
    double GetTickValueLoss() {
      return GetTickValueLoss(symbol);
    }

    /**
     * Get count of digits after decimal point for the symbol price.
     *
     * For the current symbol, it is stored in the predefined variable Digits.
     *
     */
    static uint GetDigits(string _symbol) {
      return (uint) SymbolInfoInteger(_symbol, SYMBOL_DIGITS); // Same as: MarketInfo(symbol, MODE_DIGITS);
    }
    uint GetDigits() {
      return GetDigits(symbol);
    }

    /**
     * Get current spread in points.
     *
     * @param
     *   symbol string (optional)
     *   Currency pair symbol.
     *
     * @return
     *   Return symbol trade spread level in points.
     */
    static uint GetSpread(string _symbol) {
      return (uint) SymbolInfoInteger(_symbol, SYMBOL_SPREAD);
    }
    uint GetSpread() {
      return GetSpread(symbol);
    }

    /**
     * Get real spread based on the ask and bid price (in points).
     */
    static uint GetRealSpread(string _symbol) {
      return (uint) round((GetAsk(_symbol) - GetBid(_symbol)) * pow(10, GetDigits(_symbol)));
    }

    /**
     * Minimal indention in points from the current close price to place Stop orders.
     *
     * This is due that at placing of a pending order, the open price cannot be too close to the market.
     * The minimal distance of the pending price from the current market one in points can be obtained
     * using the MarketInfo() function with the MODE_STOPLEVEL parameter.
     * Related error messages:
     *   Error 130 (ERR_INVALID_STOPS) happens In case of false open price of a pending order.
     *   Error 145 (ERR_TRADE_MODIFY_DENIED) happens when modification of order was too close to market.
     *
     *
     * @param
     *   symbol string (optional)
     *   Currency pair symbol.
     *
     * @return
     *   Returns the minimal permissible distance value in points for StopLoss/TakeProfit.
     *   A zero value means either absence of any restrictions on the minimal distance.
     *
     * @see: https://book.mql4.com/appendix/limits
     */
    long GetTradeStopsLevel() {
      return SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
    }
    static long GetTradeStopsLevel(string _symbol) {
      return SymbolInfoInteger(_symbol, SYMBOL_TRADE_STOPS_LEVEL);
    }

    /**
     * Get a contract lot size in the base currency.
     */
    double GetTradeContractSize() {
      return SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE); // Same as: MarketInfo(symbol, MODE_LOTSIZE);
    }
    static double GetTradeContractSize(string _symbol) {
      return SymbolInfoDouble(_symbol, SYMBOL_TRADE_CONTRACT_SIZE); // Same as: MarketInfo(symbol, MODE_LOTSIZE);
    }

    /**
     * Minimum permitted amount of a lot/volume for a deal.
     */
    static double GetVolumeMin(string _symbol) {
      return SymbolInfoDouble(_symbol, SYMBOL_VOLUME_MIN); // Same as: MarketInfo(symbol, MODE_MINLOT);
    }
    double GetVolumeMin() {
      return GetVolumeMin(symbol);
    }

    /**
     * Maximum permitted amount of a lot/volume for a deal.
     */
    static double GetVolumeMax(string _symbol) {
      return SymbolInfoDouble(_symbol, SYMBOL_VOLUME_MAX); // Same as: MarketInfo(symbol, MODE_MAXLOT);
    }
    double GetVolumeMax() {
      return GetVolumeMax(symbol);
    }

    /**
     * Get a lot/volume step for a deal.
     *
     * Minimal volume change step for deal execution
     */
    static double GetVolumeStep(string _symbol) {
      return SymbolInfoDouble(_symbol, SYMBOL_VOLUME_STEP); // Same as: MarketInfo(symbol, MODE_LOTSTEP);
    }
    double GetVolumeStep() {
      return GetVolumeStep(symbol);
    }

    /**
     * Order freeze level in points.
     *
     * Freeze level is a value that determines the price band,
     * within which the order is considered as 'frozen' (prohibited to change).
     *
     * If the execution price lies within the range defined by the freeze level,
     * the order cannot be modified, cancelled or closed.
     * The possibility of deleting a pending order is regulated by the FreezeLevel.
     *
     * @see: https://book.mql4.com/appendix/limits
     */
    uint GetFreezeLevel() {
      return (uint) SymbolInfoInteger(symbol, SYMBOL_TRADE_FREEZE_LEVEL); // Same as: MarketInfo(symbol, MODE_FREEZELEVEL);
    }
    static uint GetFreezeLevel(string _symbol) {
      return (uint) SymbolInfoInteger(_symbol, SYMBOL_TRADE_FREEZE_LEVEL); // Same as: MarketInfo(symbol, MODE_FREEZELEVEL);
    }

    /**
     * Initial margin (a security deposit) requirements for 1 lot.
     *
     * Initial margin means the amount in the margin currency required for opening a position with the volume of one lot.
     * It is used for checking a client's assets when he or she enters the market.
     */
    double GetMarginInit() {
      return SymbolInfoDouble(symbol, SYMBOL_MARGIN_INITIAL); // Same as: MarketInfo(symbol, MODE_MARGININIT);
    }

    /**
     * Maintenance margin charged from one lot.
     *
     * If it is set, it sets the margin amount in the margin currency of the symbol, charged from one lot.
     * It is used for checking a client's assets when his/her account state changes.
     * If the maintenance margin is equal to 0, the initial margin is used.
     */
    double GetMarginMaintenance() {
      return SymbolInfoDouble(symbol, SYMBOL_MARGIN_MAINTENANCE); // Same as: MarketInfo(symbol, SYMBOL_MARGIN_MAINTENANCE);
    }

    /* Tick storage */

    /**
     * Appends a new tick to an array.
     */
    bool SaveTick(MqlTick &_tick) {
      static int _index = 0;
      if (_index++ >= ArraySize(this.tick_data) - 1) {
        if (ArrayResize(this.tick_data, _index + 100, 1000) < 0) {
          logger.Error(StringFormat("Cannot resize array (size: %d)!", _index), __FUNCTION__);
          return false;
        }
      }
      this.tick_data[_index] = this.GetTick();
      return true;
    }

    /**
     * Empties the tick array.
     */
    bool ResetTicks() {
      return ArrayResize(this.tick_data, 0, 100) != -1;
    }

    /* Setters */

    /**
     * Sets the tick based on the given prices.
     */
    void SetTick(MqlTick &_tick) {
      this.last_tick = _tick;
    }

    /* Other methods */

    /**
     * Returns symbol information.
     */
    string ToString() {
      MqlTick _tick = GetTick();
      return StringFormat(
       "Symbol: %s, Ask/Bid: %g/%g, Price/Session Volume: %d/%g, Point size: %g, Pip size: %g, " +
       "Tick size: %g (%g pts), Tick value: %g (%g/%g), " +
       "Digits: %d, Spread: %d pts, Trade stops level: %d, " +
       "Trade contract size: %g, Min lot: %g, Max lot: %g, Lot step: %g, Freeze level: %d, Margin initial (maintenance): %g (%g)",
       GetSymbol(), _tick.ask, _tick.bid, _tick.volume, GetSessionVolume(), GetPointSize(), GetPipSize(),
       GetTickSize(), GetTradeTickSize(), GetTickValue(), GetTickValueProfit(), GetTickValueLoss(),
       GetDigits(), GetSpread(), GetTradeStopsLevel(),
       GetTradeContractSize(), GetVolumeMin(), GetVolumeMax(), GetVolumeStep(), GetFreezeLevel(), GetMarginInit(), GetMarginMaintenance()
      );
    }

};
#endif // SYMBOLINFO_MQH