# Dropshipping, 3PL, and Demand Forecasting

## When to load
Load when evaluating dropshipping vs. 3PL fulfillment models, integrating third-party logistics providers, or building demand forecasting and replenishment automation.

## Dropshipping

### Model
- Merchant lists products without holding inventory; supplier ships directly to customer.
- No upfront inventory investment — lower risk, lower margin.
- Merchant handles storefront, marketing, customer service; supplier handles fulfillment.

### Integration
- **Supplier catalogs**: import product data via CSV, API, or platforms (Oberlo, Spocket, Modalyst, DSers).
- **Order routing**: on order placement, automatically forward to supplier for fulfillment.
- **Inventory sync**: sync supplier stock levels to prevent selling out-of-stock items (real-time API or periodic feed).
- **Tracking passthrough**: receive tracking from supplier; forward to customer.
- **Pricing**: apply markup to supplier cost; auto-update when supplier prices change.

### Platforms
- **DSers / CJ Dropshipping**: AliExpress-based with order automation.
- **Spocket**: curated US/EU suppliers, faster shipping (3-7 days vs. AliExpress 15-30).
- **Modalyst**: branded dropshipping with independent brands.
- **Printful / Printify**: print-on-demand for custom apparel, accessories, home goods.

### Challenges
- Shipping time expectations, quality control limits, branding constraints, complex returns.
- Margin pressure — differentiate via branding, content, and customer experience.

## 3PL (Third-Party Logistics)

### Providers
- **ShipBob**: distributed fulfillment centers, 2-day shipping, real-time analytics. Shopify/BigCommerce/WooCommerce integrations.
- **Flexport**: global freight forwarding, customs, warehousing, last-mile. Strong for international supply chain.
- **ShipMonk**: DTC brands, custom packaging, subscription box fulfillment, Amazon FBA prep.
- **Red Stag Fulfillment**: heavy, oversized, and high-value items.
- **Amazon FBA**: Amazon warehouse network; Prime shipping eligibility.

### Integration Patterns
- **Order push**: send confirmed orders to 3PL; receive shipment confirmation with tracking.
- **Inventory feed**: daily or real-time inventory snapshots from 3PL warehouses.
- **Inbound ASN**: create inbound shipment with expected SKUs/quantities; 3PL confirms receipt.
- **Returns processing**: 3PL inspects, updates inventory or quarantines, reports back.
- **Billing reconciliation**: storage, pick/pack, shipping, value-added services.
- **SLA monitoring**: track fulfillment speed, accuracy, and damage rates per 3PL.

### 3PL vs. In-House
- 3PL pros: no warehouse lease, scalable capacity, geographic distribution, carrier discounts.
- 3PL cons: less branding control, per-order fees erode margins, complex returns.
- In-house pros: quality control, custom packaging, faster process iteration.
- In-house cons: capital investment, limited reach, capacity constraints during peaks.
- Hybrid: own warehouse for core, 3PL for overflow or geographic expansion.

## Demand Forecasting

### Methods
- **Moving average**: simple or weighted over N periods (30/90-day rolling).
- **Exponential smoothing**: Holt-Winters for trend + seasonality.
- **ARIMA/SARIMA**: autoregressive models for stationary/seasonal series.
- **Machine learning**: XGBoost, LightGBM, LSTM, Transformer for complex patterns.
- **Causal models**: incorporate marketing spend, weather, competitor pricing, economic indicators.

### Inputs
- Historical daily/weekly unit sales per SKU per location.
- Promotional calendar, seasonal patterns, market trends, new product launches.
- Lead times with variability buffer; external data (weather, event calendars).

### Outputs
- **Demand plan**: projected unit sales per SKU per period.
- **Replenishment plan**: PO quantities and timing based on demand, lead time, safety stock.
- **Safety stock**: Z-score × standard deviation of demand during lead time.
- **Reorder point**: (average daily demand × lead time) + safety stock.
- **EOQ**: Economic Order Quantity = √(2 × demand × ordering cost / holding cost).

### Tools
- **Inventory Planner (Sage)**: Shopify/BigCommerce app for forecasting and replenishment.
- **Amazon Forecast**: AWS ML service for time series.
- **Prophet (Meta)**: open-source library with seasonality and holiday effects.
- **Custom**: Python (scikit-learn, statsmodels, PyTorch) + data warehouse.
