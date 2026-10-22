# Processing sandbox

A WireMock stand-in for the Uzcard (its SV-Gate JSON-RPC API) and Humo (Payment Server SOAP + middleware REST) test environments, so the whole system runs on a laptop.

| Path | Speaks |
|---|---|
| `/uzcard/api/jsonrpc` | Uzcard JSON-RPC: `cards.new.otp`, `cards.new.verify`, `cards.remove.token`, `trans.pay.purpose`, `trans.reverse`, `trans.reverse.partial`, `trans.ext`, `get.bin.list`, `terminal.add/check/get/remove`, `report.sum/short/detail` |
| `/humo/PaymentServer` | SOAP `urn:PaymentServer`, every operation of HUMOPAYMENT.pdf: `Request` (P2P; SOAP_TOCARD_2 credit), `Payment` (SOAP_DMS hold, then confirm with the same or a changed amount; P2P confirm; SOAP_RECO reconciliation), `CancelRequest`, `ReturnPayment`, `GetPayment` |
| `/humo-middleware/...` | every method of HUMOMIDDLEWARE.pdf (`/v2/mb/*`, `/v3/iiacs/card`, `/v3/iiacs/card2`, `/cs/v1/*`, `/v1/ws/transaction-history`, `/v2/pm/*`), plus `/v1/send/sms`, `/v1/send/code` |
| `/merchant/webhooks` | a merchant's webhook endpoint: answers 200; WireMock's request journal (`/__admin/requests`) shows what arrived |

## Test cards

| Card | Expiry | SMS code | Outcome |
|---|---|---|---|
| 8600 1402 3456 7890 | 2812 | 111111 | approved |
| 8600 1402 0000 0082 | 2812 | 111111 | declined: insufficient funds |
| 8600 1402 0000 0033 | 2812 | 111111 | declined: expired card |
| 8600 1402 0000 0009 | 2812 | 111111 | no answer (timeout) |
| 8600 1402 0000 0013 | 2812 | 111111 | binding refused: the card is blocked (card status 12); a debit by its token: error -205 |
| 8600 1402 0000 0017 | 2812 | 111111 | error -301 "check trans.ext later", then found approved by `trans.ext` |
| 9860 0901 0119 1238 | 2804 | 660130 | approved |
| 9860 0901 0119 0032 | 2804 | 660130 | declined: insufficient funds |
| 9860 0901 0119 0073 | 2804 | 660130 | declined: expired card |
| 9860 0901 0119 0099 | 2804 | 660130 | no answer (timeout) |

Any other SMS code is refused. Uzcard lookups (`trans.ext`) by an ext starting `never-` find nothing, by one starting `reversed-` find a debit given back; terminal `00000000` is one Uzcard doesn't have. Humo status lookups (`GetPayment`) by a paymentRef starting `active-` find a hold, by one starting `notfound-` find nothing (HTTP 202 with no body, as the real Payment Server answers), by one starting `unknown-` answer a SOAP fault; card record lookups (`/v3/iiacs/card`) answer only with `mb_flag` 1; card 9860 0901 0119 0073's card record is blocked (209). Each adapter's integration tests in ecom use a copy of its file.

The Humo stubs answer in the shape of the PDFs' own examples (each names its section and page in `metadata.pdf`) and only when every field the PDF marks mandatory is there. A P2P confirmation is told from a SOAP_DMS one by a paymentRef starting `P2P`.
