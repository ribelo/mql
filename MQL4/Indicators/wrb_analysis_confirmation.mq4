//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                              Huxley WRB Confirmation.mq4                                  |
//|                                                                                           |
//+-------------------------------------------------------------------------------------------+
#property copyright "Copyright � 2014 Huxley"
#property link      "email:   huxley.source@gmail.com"
#include <wrb_analysis.mqh>
#include <hxl_utils.mqh>
#include <hanover --- function header (np).mqh>
#include <hanover --- extensible functions (np).mqh>


//+-------------------------------------------------------------------------------------------+
//| Indicator Global Inputs                                                                   |
//+-------------------------------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 C'205,138,108'
#property indicator_color2 C'151,125,130'
#property indicator_color3 C'252,165,88'
#property indicator_color4 C'177,83,103'
#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 1
#property indicator_width4 1


#define  _name "hxl_wrb_conf"
#define  short_name "Huxley WRB Confirmation"

//Global External Inputs

extern int look_back = 512;
extern int contraction_size = 16;
extern int refresh_candles = 16;
extern bool pattern_a = true;
extern bool pattern_b = true;
extern bool pattern_c = true;
extern bool pattern_d = true;
extern bool pattern_e = true;
extern bool pattern_h1 = true;
extern bool pattern_h2 = true;
extern bool pattern_h3 = false;
extern bool pattern_h4 = false;
extern color conf_bull_body = C'252,165,88';
extern color conf_bear_body = C'177,83,103';
extern color contraction_bull_body = C'205,138,108';
extern color contraction_bear_body = C'151,125,130';
extern color text_color = C'56,47,50';
extern bool make_text = false;
extern bool send_notification = false;
extern double label_offset_percent = 1.0;
extern int font_size = 8;
extern string font_name = "Cantarell";
extern int bar_width = 1;

//Misc
double candle[][6];
int pip_mult_tab[] = {1, 10, 1, 10, 1, 10, 100, 1000};
string symbol, global_name;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";

double conf_body_open[], conf_body_close[];
double contraction_body_open[], contraction_body_close[];

int last_conf_a, last_conf_b, last_conf_c, last_conf_d, last_conf_e;
int last_conf_f, last_conf_g, last_conf_h1, last_conf_h2, last_conf_h3, last_conf_h4;
//+-------------------------------------------------------------------------------------------+
//| Custom indicator initialization function                                                  |
//+-------------------------------------------------------------------------------------------+
int init() {
    symbol = Symbol();
    tf = Period();
    digits = MarketInfo(symbol, MODE_DIGITS);
    multiplier = pip_mult_tab[digits];
    point = MarketInfo(symbol, MODE_POINT) * multiplier;
    spread = MarketInfo(symbol, MODE_SPREAD) * multiplier;
    tickvalue = MarketInfo(symbol, MODE_TICKVALUE) * multiplier;
    global_name = StringLower(_name + "_" + ReduceCcy(symbol) + "_" + TFToStr(tf));
    if (multiplier > 1) {
        pip_description = " points";
    }
    ArrayCopyRates(candle, symbol, tf);
    IndicatorShortName(short_name);
    SetIndexBuffer(0, contraction_body_close);
    SetIndexStyle(0, DRAW_HISTOGRAM, 0, bar_width, contraction_bull_body);
    SetIndexLabel(0, "WRB Contraction");
    SetIndexBuffer(1, contraction_body_open);
    SetIndexStyle(1, DRAW_HISTOGRAM, 0, bar_width, contraction_bear_body);
    SetIndexLabel(1, "WRB Contraction");
    SetIndexBuffer(2, conf_body_close);
    SetIndexStyle(2, DRAW_HISTOGRAM, 0, bar_width, conf_bull_body);
    SetIndexLabel(2, "WRB Confirmation");
    SetIndexBuffer(3, conf_body_open);
    SetIndexStyle(3, DRAW_HISTOGRAM, 0, bar_width, conf_bear_body);
    SetIndexLabel(3, "WRB Confirmation");

    if (!GlobalVariableCheck(global_name)) {
        GlobalVariableSet(global_name, 0);
    }
    return (0);
}

//+-------------------------------------------------------------------------------------------+
//| Custom indicator deinitialization function                                                |
//+-------------------------------------------------------------------------------------------+
int deinit() {
    for (int i = ObjectsTotal(OBJ_TEXT) - 1; i >= 0; i--) {
        string name = ObjectName(i);
        int length = StringLen(_name);
        if (StringFind(name, _name) != -1) {
            ObjectDelete(name);
        }
    }
    return (0);
}

//+-------------------------------------------------------------------------------------------+
//| Custom indicator iteration function                                                       |
//+-------------------------------------------------------------------------------------------+
int start() {
    int i, j, limit, counted_bars, r[4];
    double text_price;
    string text_name, time_str;
    if (!_new_bar(symbol, tf)) {
        return (0);
    }
    counted_bars = IndicatorCounted();
    if(counted_bars > 0) {
        counted_bars--;
        counted_bars -= refresh_candles;
    }
    limit = MathMin(iBars(symbol, tf) - counted_bars, look_back);
    for (i = iBars(symbol, tf); i >= 0; i--) {
        if (pattern_a == true) {
            if (_conf_a(candle, i, iBars(symbol, tf), r) != 0) {
                conf_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                conf_body_close[r[0]] = iClose(symbol, tf, r[0]);
                for (j = 1; j <= r[1] - r[0]; j++) {
                    conf_body_open[r[0] + j] = iOpen(symbol, tf, r[0] + j);
                    conf_body_close[r[0] + j] = iClose(symbol, tf, r[0] + j);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "A", Time[r[0] + 1], text_price, font_size, text_color) ;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "A", Time[r[0] + 1], text_price,  font_size, text_color) ;
                    }
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > GlobalVariableGet(global_name)) {
                        GlobalVariableSet(global_name, iTime(symbol, tf, r[0]));
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Confirmation A at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Confirmation A at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
        if (pattern_b == true) {
            if (_conf_b(candle, i, iBars(symbol, tf), r) != 0) {
                conf_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                conf_body_close[r[0]] = iClose(symbol, tf, r[0]);
                for (j = 1; j <= r[1] - r[0]; j++) {
                    conf_body_open[r[0] + j] = iOpen(symbol, tf, r[0] + j);
                    conf_body_close[r[0] + j] = iClose(symbol, tf, r[0] + j);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "B", Time[r[0] + 1], text_price, font_size, text_color) ;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "B", Time[r[0] + 1], text_price,  font_size, text_color) ;
                    }
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > GlobalVariableGet(global_name)) {
                        GlobalVariableSet(global_name, iTime(symbol, tf, r[0]));
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Confirmation B at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Confirmation B at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
        if (pattern_c == true) {
            if (_conf_c(candle, i, iBars(symbol, tf), r) != 0) {
                conf_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                conf_body_close[r[0]] = iClose(symbol, tf, r[0]);
                for (j = 1; j <= r[1] - r[0]; j++) {
                    conf_body_open[r[0] + j] = iOpen(symbol, tf, r[0] + j);
                    conf_body_close[r[0] + j] = iClose(symbol, tf, r[0] + j);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "C", Time[r[0] + 1], text_price, font_size, text_color) ;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "C", Time[r[0] + 1], text_price,  font_size, text_color) ;
                    }
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > GlobalVariableGet(global_name)) {
                        GlobalVariableSet(global_name, iTime(symbol, tf, r[0]));
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Confirmation C at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Confirmation C at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
        if (pattern_d == true) {
            if (_conf_d(candle, i, iBars(symbol, tf), r) != 0) {
                conf_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                conf_body_close[r[0]] = iClose(symbol, tf, r[0]);
                for (j = 1; j <= r[1] - r[0]; j++) {
                    conf_body_open[r[0] + j] = iOpen(symbol, tf, r[0] + j);
                    conf_body_close[r[0] + j] = iClose(symbol, tf, r[0] + j);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "D", Time[r[0] + 1], text_price, font_size, text_color) ;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "D", Time[r[0] + 1], text_price,  font_size, text_color) ;
                    }
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > GlobalVariableGet(global_name)) {
                        GlobalVariableSet(global_name, iTime(symbol, tf, r[0]));
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Confirmation D at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Confirmation D at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
        if (pattern_e == true) {
            if (_conf_e(candle, i, iBars(symbol, tf), r) != 0) {
                conf_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                conf_body_close[r[0]] = iClose(symbol, tf, r[0]);
                for (j = 1; j <= r[1] - r[0]; j++) {
                    conf_body_open[r[0] + j] = iOpen(symbol, tf, r[0] + j);
                    conf_body_close[r[0] + j] = iClose(symbol, tf, r[0] + j);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "E", Time[r[0] + 1], text_price, font_size, text_color) ;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "E", Time[r[0] + 1], text_price,  font_size, text_color) ;
                    }
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > GlobalVariableGet(global_name)) {
                        GlobalVariableSet(global_name, iTime(symbol, tf, r[0]));
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Confirmation E at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Confirmation E at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
        if (pattern_h1 == true) {
            if (_conf_h1(candle, i, iBars(symbol, tf), contraction_size, r) != 0) {
                conf_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                conf_body_close[r[0]] = iClose(symbol, tf, r[0]);
                conf_body_open[r[1]] = iOpen(symbol, tf, r[1]);
                conf_body_close[r[1]] = iClose(symbol, tf, r[1]);
                for (j = 1; j < r[1] - r[0]; j++) {
                    contraction_body_open[r[0] + j] = iOpen(symbol, tf, r[0] + j);
                    contraction_body_close[r[0] + j] = iClose(symbol, tf, r[0] + j);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                        make_text(text_name, "H1", Time[r[0] + (r[1] - r[0]) / 2], text_price, font_size, text_color) ;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                        make_text(text_name, "H1", Time[r[0] + (r[1] - r[0]) / 2], text_price,  font_size, text_color) ;
                    }
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > GlobalVariableGet(global_name)) {
                        GlobalVariableSet(global_name, iTime(symbol, tf, r[0]));
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Confirmation H1 at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Confirmation H1 at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
        if (pattern_h2 == true) {
            if (_conf_h2(candle, i, iBars(symbol, tf), contraction_size, r) != 0) {
                conf_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                conf_body_close[r[0]] = iClose(symbol, tf, r[0]);
                conf_body_open[r[1]] = iOpen(symbol, tf, r[1]);
                conf_body_close[r[1]] = iClose(symbol, tf, r[1]);
                for (j = 1; j < r[1] - r[0]; j++) {
                    contraction_body_open[r[0] + j] = iOpen(symbol, tf, r[0] + j);
                    contraction_body_close[r[0] + j] = iClose(symbol, tf, r[0] + j);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                        make_text(text_name, "H2", Time[r[0] + (r[1] - r[0]) / 2], text_price, font_size, text_color) ;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                        make_text(text_name, "H2", Time[r[0] + (r[1] - r[0]) / 2], text_price,  font_size, text_color) ;
                    }
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > GlobalVariableGet(global_name)) {
                        GlobalVariableSet(global_name, iTime(symbol, tf, r[0]));
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Confirmation H2 at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Confirmation H2 at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
        if (pattern_h3 == true) {
            if (_conf_h3(candle, i, iBars(symbol, tf), contraction_size, r) != 0) {
                conf_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                conf_body_close[r[0]] = iClose(symbol, tf, r[0]);
                conf_body_open[r[1]] = iOpen(symbol, tf, r[1]);
                conf_body_close[r[1]] = iClose(symbol, tf, r[1]);
                for (j = 1; j < r[1] - r[0]; j++) {
                    contraction_body_open[r[0] + j] = iOpen(symbol, tf, r[0] + j);
                    contraction_body_close[r[0] + j] = iClose(symbol, tf, r[0] + j);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                        make_text(text_name, "H3", Time[r[0] + (r[1] - r[0]) / 2], text_price, font_size, text_color) ;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                        make_text(text_name, "H3", Time[r[0] + (r[1] - r[0]) / 2], text_price,  font_size, text_color) ;
                    }
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > GlobalVariableGet(global_name)) {
                        GlobalVariableSet(global_name, iTime(symbol, tf, r[0]));
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Confirmation H3 at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Confirmation H3 at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
        if (pattern_h4 == true) {
            if (_conf_h4(candle, i, iBars(symbol, tf), contraction_size, r) != 0) {
                conf_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                conf_body_close[r[0]] = iClose(symbol, tf, r[0]);
                conf_body_open[r[1]] = iOpen(symbol, tf, r[1]);
                conf_body_close[r[1]] = iClose(symbol, tf, r[1]);
                for (j = 1; j < r[1] - r[0]; j++) {
                    contraction_body_open[r[0] + j] = iOpen(symbol, tf, r[0] + j);
                    contraction_body_close[r[0] + j] = iClose(symbol, tf, r[0] + j);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                        make_text(text_name, "H4", Time[r[0] + (r[1] - r[0]) / 2], text_price, font_size, text_color) ;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                        make_text(text_name, "H4", Time[r[0] + (r[1] - r[0]) / 2], text_price,  font_size, text_color) ;
                    }
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > GlobalVariableGet(global_name)) {
                        GlobalVariableSet(global_name, iTime(symbol, tf, r[0]));
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Confirmation H4 at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Confirmation H4 at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }

    }
    return (0);
}
//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+
