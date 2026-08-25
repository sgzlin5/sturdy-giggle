# sturdy-giggle

MT5 自定义指标与 EA 脚本库，配合 [TradFi](https://github.com/yourname/TradFi) Web 交易看板使用，保持统一的视觉风格与交易逻辑。

---

## 目录结构

```
sturdy-giggle/
├── Indictor/          # 自定义指标（.mq5）
│   ├── TradFi_MACD.mq5
│   └── TradFi_ZigZag.mq5
├── EA/                # 智能交易系统（.mq5）
│   └── AutoSLTP.mq5
└── README.md
```

---

## 安装方法

1. 打开 MetaTrader 5，点击菜单 **文件 → 打开数据文件夹**
2. 将对应文件复制到 MQL5 目录下：
   - 指标：将 `Indictor/` 下的 `.mq5` 文件复制到 `MQL5/Indicators/`
   - EA：将 `EA/` 下的 `.mq5` 文件复制到 `MQL5/Experts/`
3. 在 MetaEditor（F4）中打开对应文件，按 **F7** 编译
4. 回到 MT5：
   - 指标：在「导航」面板 → 指标 → 自定义 中找到对应指标，拖拽到图表
   - EA：在「导航」面板 → 智能交易系统 中找到对应 EA，拖拽到图表（需开启「允许算法交易」）

---

## 指标列表

### TradFi_MACD

> `Indictor/TradFi_MACD.mq5`

与 TradFi Web 看板完全一致的 MACD 指标，包含能量强弱颜色区分。在**独立子窗口**中显示。

#### 效果预览

| 元素 | 颜色 | 说明 |
|---|---|---|
| MACD 线 | ![#58a6ff](https://placehold.co/12x12/58a6ff/58a6ff.png) `#58a6ff` 蓝色 | 快线 EMA − 慢线 EMA |
| 信号线 | ![#f0883e](https://placehold.co/12x12/f0883e/f0883e.png) `#f0883e` 橙色 | MACD 的 EMA |
| 能量柱（涨强） | ![#26a641](https://placehold.co/12x12/26a641/26a641.png) `#26a641` 鲜绿 | 正值且能量增强 |
| 能量柱（跌强） | ![#f85149](https://placehold.co/12x12/f85149/f85149.png) `#f85149` 鲜红 | 负值且能量增强 |
| 能量柱（涨弱） | ![#1a5c2c](https://placehold.co/12x12/1a5c2c/1a5c2c.png) `#1a5c2c` 暗绿 | 正值但能量减弱 |
| 能量柱（跌弱） | ![#833130](https://placehold.co/12x12/833130/833130.png) `#833130` 暗红 | 负值但能量减弱 |

> **能量减弱判断**：当前柱的绝对值 < 前一柱的绝对值时，颜色切换为弱色（原色与暗背景 `#0d1117` 各 50% 混合），与 Web 端 `alpha 50%` 效果一致。

#### 输入参数

| 参数 | 默认值 | 说明 |
|---|---|---|
| `InpFastEMA` | `12` | 快线 EMA 周期 |
| `InpSlowEMA` | `26` | 慢线 EMA 周期 |
| `InpSignalEMA` | `9` | 信号线 EMA 周期 |
| `InpPrice` | `PRICE_CLOSE` | 价格类型（`ENUM_APPLIED_PRICE`） |

#### 技术细节

- **窗口**：独立子窗口（`indicator_separate_window`）
- **缓冲区**：4 个（MACD 线、信号线、柱值、颜色索引）
- **绘图序列**：3 个（MACD 线 `DRAW_LINE`、信号线 `DRAW_LINE`、能量柱 `DRAW_COLOR_HISTOGRAM`）
- **颜色索引**：`DRAW_COLOR_HISTOGRAM` + 4 色索引，单一绘图通道实现强弱配色（0=涨强 / 1=跌强 / 2=涨弱 / 3=跌弱）
- **EMA 计算**：通过 `iMA` 句柄复制快/慢线；Signal 以前 `InpSignalEMA` 根 MACD 的简单均值作为 EMA 种子，与 TradFi Web 端算法一致
- **小数位**：`INDICATOR_DIGITS = _Digits + 1`

### TradFi_ZigZag

> `Indictor/TradFi_ZigZag.mq5`

ZigZag 折线指标，基于 Depth / Deviation / Backstep 三参数识别价格转折点并连线。在**主图表窗口**中显示。

#### 效果预览

| 元素 | 颜色 | 说明 |
|---|---|---|
| ZigZag 折线 | ![#39c5cf](https://placehold.co/12x12/39c5cf/39c5cf.png) `#39c5cf` 青色 | 分段连线（`DRAW_SECTION`），宽 2 |

#### 输入参数

| 参数 | 默认值 | 说明 |
|---|---|---|
| `InpDepth` | `12` | 两侧搜索窗口（局部极值检测范围） |
| `InpDeviation` | `5` | 转折确认的最小点数偏差 |
| `InpBackstep` | `3` | 相邻转折点间的最少 bar 间隔 |

#### 技术细节

- **窗口**：主图表窗口（`indicator_chart_window`）
- **缓冲区**：3 个（主折线 `INDICATOR_DATA` + 2 个隐藏极值标记 `INDICATOR_CALCULATIONS`）
- **绘图类型**：`DRAW_SECTION`，空值使用 `EMPTY_VALUE`（≈1.79e308），避免与价格 0.0 冲突；仅在确认的转折点写入真实价格，`DRAW_SECTION` 自动跳过空值连接相邻有效点
- **两阶段算法**：
  1. **Phase 1 — 对称窗口极值检测**：对每根 bar `i`，检查 `high[i]` 是否为 `[i-Depth, i+Depth]` 中心窗口的最大值、`low[i]` 是否为最小值，标记到辅助缓冲区
  2. **Phase 2 — 状态机确认转折点**：三态状态机（0=初始 / -1=等高确认 / +1=等低确认），同时满足方向反转、Deviation 偏差、Backstep 间隔才确认转折并写入主缓冲区
- **计算策略**：每次 tick 全量重算，无状态残留
- **参数校验**：`OnInit` 中对三参数做合法性检查，非法参数返回 `INIT_PARAMETERS_INCORRECT`

---

## EA 列表

### AutoSLTP

> `EA/AutoSLTP.mq5`

手动下单后自动设置止盈（TP）和止损（SL）的辅助 EA。**仅作用于手动下单（Magic = 0）**，并**强制覆盖**已有 SL/TP。

#### 输入参数

| 参数 | 默认值 | 说明 |
|---|---|---|
| `InpStopLoss` | `300` | 止损点数（Points），`0` = 不设置 |
| `InpTakeProfit` | `500` | 止盈点数（Points），`0` = 不设置 |

#### 工作流程

1. 监听 `OnTradeTransaction` 中的**成交入场事件**（`TRADE_TRANSACTION_DEAL_ADD`），过滤掉出入金（`DEAL_TYPE_BALANCE`）和非开仓成交（`DEAL_ENTRY_IN`）
2. 通过 `DEAL_POSITION_ID` 找到对应仓位，仅处理 **Magic = 0** 的手动单
3. 按开仓价 ± 点数计算 SL/TP（BUY：SL = 开仓价 − SL×point，TP = 开仓价 + TP×point；SELL 相反），以 `SYMBOL_DIGITS` 精度归一化
4. 调用 `PositionModify` 修改仓位，成功/失败均输出日志（含开仓价、SL/TP 与错误码）

#### 注意事项

- 请在图表上挂载该 EA 后**再做手动下单**，EA 只响应挂载期间发生的成交事件
- SL/TP 均设为 `0` 时 EA 不执行任何操作（`OnInit` 会打印警告）
- 负数参数会在 `OnInit` 中被拒绝（`INIT_PARAMETERS_INCORRECT`）

---

## 开发规范

- 所有文件使用 **UTF-8** 编码
- 指标文件放入 `Indictor/` 目录，EA 文件放入 `EA/` 目录
- 颜色规范遵循 TradFi 主题色板：

  | 用途 | Hex | MQL5 |
  |---|---|---|
  | 主蓝 | `#58a6ff` | `C'88,166,255'` |
  | 信号橙 | `#f0883e` | `C'240,136,62'` |
  | 涨绿 | `#26a641` | `C'38,166,65'` |
  | 跌红 | `#f85149` | `C'248,81,73'` |
  | 深背景 | `#0d1117` | `C'13,17,23'` |
  | ZigZag 青 | `#39c5cf` | `C'57,197,207'` |

---

## License

MIT
