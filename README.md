# sturdy-giggle

MT5 自定义指标与 EA 脚本库，配合 [TradFi](https://github.com/yourname/TradFi) Web 交易看板使用，保持统一的视觉风格与交易逻辑。

---

## 目录结构

```
sturdy-giggle/
├── Indictor/          # 自定义指标（.mq5）
│   └── TradFi_MACD.mq5
└── README.md
```

---

## 安装方法

1. 打开 MetaTrader 5，点击菜单 **文件 → 打开数据文件夹**
2. 将 `Indictor/` 目录下的 `.mq5` 文件复制到：
   ```
   MQL5/Indicators/
   ```
3. 在 MetaEditor（F4）中打开对应文件，按 **F7** 编译
4. 回到 MT5 图表，在「导航」面板 → 指标 → 自定义 中找到对应指标，拖拽到图表即可

---

## 指标列表

### TradFi_MACD

> `Indictor/TradFi_MACD.mq5`

与 TradFi Web 看板完全一致的 MACD 指标，包含能量强弱颜色区分。

#### 效果预览

| 元素 | 颜色 | 说明 |
|---|---|---|
| MACD 线 | ![#58a6ff](https://placehold.co/12x12/58a6ff/58a6ff.png) `#58a6ff` 蓝色 | 快线 EMA − 慢线 EMA |
| 信号线 | ![#f0883e](https://placehold.co/12x12/f0883e/f0883e.png) `#f0883e` 橙色 | MACD 的 EMA |
| 能量柱（涨强） | ![#26a641](https://placehold.co/12x12/26a641/26a641.png) `#26a641` 鲜绿 | 正值且能量增强 |
| 能量柱（涨弱） | ![#1a5c2c](https://placehold.co/12x12/1a5c2c/1a5c2c.png) `#1a5c2c` 暗绿 | 正值但能量减弱 |
| 能量柱（跌强） | ![#f85149](https://placehold.co/12x12/f85149/f85149.png) `#f85149` 鲜红 | 负值且能量增强 |
| 能量柱（跌弱） | ![#833130](https://placehold.co/12x12/833130/833130.png) `#833130` 暗红 | 负值但能量减弱 |

> **能量减弱判断**：当前柱的绝对值 < 前一柱的绝对值时，颜色切换为弱色（原色与暗背景 `#0d1117` 各 50% 混合），与 Web 端 `alpha 50%` 效果一致。

#### 输入参数

| 参数 | 默认值 | 说明 |
|---|---|---|
| `InpFastEMA` | `12` | 快线 EMA 周期 |
| `InpSlowEMA` | `26` | 慢线 EMA 周期 |
| `InpSignalEMA` | `9` | 信号线 EMA 周期 |
| `InpPrice` | `PRICE_CLOSE` | 价格类型 |

#### 技术细节

- **缓冲区**：4 个（MACD 线、信号线、柱值、颜色索引）
- **颜色索引**：使用 `DRAW_COLOR_HISTOGRAM` + 4 色索引，单一绘图通道实现强弱配色
- **Signal 初始化**：以前 `InpSignalEMA` 根 MACD 的简单均值作为 EMA 种子，与 TradFi Web 端算法一致

---

## 开发规范

- 所有文件使用 **UTF-8** 编码
- 指标文件放入 `Indictor/` 目录，EA 文件（待添加）放入 `EA/` 目录
- 颜色规范遵循 TradFi 主题色板：

  | 用途 | Hex | MQL5 |
  |---|---|---|
  | 主蓝 | `#58a6ff` | `C'88,166,255'` |
  | 信号橙 | `#f0883e` | `C'240,136,62'` |
  | 涨绿 | `#26a641` | `C'38,166,65'` |
  | 跌红 | `#f85149` | `C'248,81,73'` |
  | 深背景 | `#0d1117` | `C'13,17,23'` |

---

## License

MIT
