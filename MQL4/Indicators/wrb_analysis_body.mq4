//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                  Huxley WRB Body.mq4                                      |
//|                                                                                           |
//+-------------------------------------------------------------------------------------------+
#property copyright "Copyright � 2014 Huxley"
#property link      "email:   huxley.source@gmail.com"
#include <wrb_analysis.mqh>
#include <hxl_utils.mqh>


//+-------------------------------------------------------------------------------------------+
//| Indicator Global Inputs                                                                   |
//+-------------------------------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 C'245,146,86'
#property indicator_color2 C'126,59,73'
#property indicator_color3 C'252,165,88'
#property indicator_color4 C'177,83,103'
#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 1
#property indicator_width4 1

#define  _name "hxl_wrb"
#define  short_name "Huxley WRB Body"

//Global External Inputs

extern int   look_back = 2048;
extern bool  draw_wrb = true;
extern bool  draw_wrb_hg = true;
extern color bull_wrb_body = C'245,146,86';
extern color bear_wrb_body = C'126,59,73';
extern color bull_wrb_hg_body = C'252,165,88';
extern color bear_wrb_hg_body = C'177,83,103';
extern int bar_width = 1;

//Misc
MqlRates candle[];
int pip_mult_tab[]={1,10,1,10,1,10,100,1000};
string symbol;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";

double body_wrb_open[], body_wrb_close[], body_wrb_hg_open[], body_wrb_hg_close[];
//+-------------------------------------------------------------------------------------------+
//| Custom indicator initialization function                                                  |
//+-------------------------------------------------------------------------------------------+
int OnInit() {
    symbol = Symbol();
    tf = Period();
    digits = MarketInfo(symbol, MODE_DIGITS);
    multiplier = pip_mult_tab[digits];
    point = MarketInfo(symbol, MODE_POINT) * multiplier;
    spread = MarketInfo(symbol, MODE_SPREAD) * multiplier;
    tickvalue = MarketInfo(symbol, MODE_TICKVALUE) * multiplier;
    if (multiplier > 1) {
        pip_description = " points";
    }
    ArrayCopyRates(candle, symbol, tf);
    IndicatorShortName(short_name);
    SetIndexBuffer(0, body_wrb_close);
    SetIndexStyle(0, DRAW_HISTOGRAM, 0, bar_width, bull_wrb_body);
    SetIndexLabel(0, "WRB");
    SetIndexBuffer(1, body_wrb_open);
    SetIndexStyle(1, DRAW_HISTOGRAM, 0, bar_width, bear_wrb_body);
    SetIndexLabel(1, "WRB");
    SetIndexBuffer(2, body_wrb_hg_close);
    SetIndexStyle(2, DRAW_HISTOGRAM, 0, bar_width, bull_wrb_hg_body);
    SetIndexLabel(2, "WRB HG");
    SetIndexBuffer(3, body_wrb_hg_open);
    SetIndexStyle(3, DRAW_HISTOGRAM, 0, bar_width, bear_wrb_hg_body);
    SetIndexLabel(3, "WRB HG");

    return (0);
}

//+-------------------------------------------------------------------------------------------+
//| Custom indicator deinitialization function                                                |
//+-------------------------------------------------------------------------------------------+
int OnDeinit() {
    return (0);
}

//+-------------------------------------------------------------------------------------------+
//| Custom indicator iteration function                                                       |
//+-------------------------------------------------------------------------------------------+
int OnCalculate (const int rates_total,      // size of input time series
                 const int prev_calculated,  // bars handled in previous call
                 const datetime& time[],     // Time
                 const double& open[],       // Open
                 const double& high[],       // High
                 const double& low[],        // Low
                 const double& close[],      // Close
                 const long& tick_volume[],  // Tick Volume
                 const long& volume[],       // Real Volume
                 const int& spread[]) {      // Spread

    int i, limit, counted_bars;
    if (!new_bar(symbol, tf)) {
        return (0);
    }
    counted_bars = prev_calculated;
    if(counted_bars > 0) {
        counted_bars--;
    }
    limit = MathMin(rates_total - counted_bars, look_back);
    for (i = 1; i < rates_total; i++) {
        if (draw_wrb == true) {
            if (_wrb(candle, i, rates_total) != 0) {
                body_wrb_open[i] = open[i];
                body_wrb_close[i] = close[i];
            }
        }
        if (draw_wrb_hg == true) {
            if (_wrb_hg(candle, i, rates_total) != 0) {
                body_wrb_hg_open[i] = open[i];
                body_wrb_hg_close[i] = close[i];
            }
        }
    }
    return (0);
}
//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+

