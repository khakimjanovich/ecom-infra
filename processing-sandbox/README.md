# Processing sandbox

A WireMock stand-in for the Uzcard (SVGate, JSON-RPC) and Humo (Payment Server SOAP + middleware REST) test environments, so the whole system runs on a laptop.

| Path | Speaks |
|---|---|
| `/uzcard/api/jsonrpc` | SVGate JSON-RPC: `cards.new.otp`, `cards.new.verify`, `trans.pay.purpose`, `trans.reverse`, `trans.ext`, `get.bin.list` |
| `/humo/PaymentServer` | SOAP `urn:PaymentServer`: `Payment` (hold, then confirm), `CancelRequest`, `GetPayment` |
| `/humo-middleware/...` | `/v1/send/sms`, `/v1/send/code`, `/v2/pm/bins` |

## Test cards

| Card | Expiry | SMS code | Outcome |
|---|---|---|---|
| 8600 1402 3456 7890 | 2812 | 111111 | approved |
| 8600 1402 0000 0082 | 2812 | 111111 | declined: insufficient funds |
| 8600 1402 0000 0033 | 2812 | 111111 | declined: expired card |
| 8600 1402 0000 0009 | 2812 | 111111 | no answer (timeout) |
| 9860 0901 0119 1238 | 2804 | 660130 | approved |
| 9860 0901 0119 0032 | 2804 | 660130 | declined: insufficient funds |
| 9860 0901 0119 0073 | 2804 | 660130 | declined: expired card |
| 9860 0901 0119 0099 | 2804 | 660130 | no answer (timeout) |

Any other SMS code is refused. The ecom card module's integration tests use a copy of these mappings.
