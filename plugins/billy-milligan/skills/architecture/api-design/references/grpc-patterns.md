# gRPC Patterns

## When to load
Load when designing gRPC services, protobuf schemas, or choosing between gRPC and REST.

## Patterns ✅

### Protobuf schema design
```protobuf
syntax = "proto3";
package orders.v1;

service OrderService {
  rpc CreateOrder(CreateOrderRequest) returns (CreateOrderResponse);
  rpc GetOrder(GetOrderRequest) returns (Order);
  rpc ListOrders(ListOrdersRequest) returns (ListOrdersResponse);
  rpc StreamOrderUpdates(StreamOrdersRequest) returns (stream OrderUpdate); // Server streaming
}

message CreateOrderRequest {
  string customer_id = 1;
  repeated OrderItem items = 2;
  string idempotency_key = 3;
}

message ListOrdersRequest {
  int32 page_size = 1;     // Max 100
  string page_token = 2;   // Opaque cursor
  OrderFilter filter = 3;
}

message ListOrdersResponse {
  repeated Order orders = 1;
  string next_page_token = 2;
}
```
Rules: use `string` for IDs (not int), `repeated` for arrays, `optional` for nullable fields, never reuse field numbers.

### Streaming patterns
- **Unary**: request → response (like REST)
- **Server streaming**: request → stream of responses (live feeds, long lists)
- **Client streaming**: stream of requests → response (file upload, telemetry)
- **Bidirectional**: stream ↔ stream (chat, real-time collaboration)

### Deadlines and timeouts
```go
ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
defer cancel()
resp, err := client.GetOrder(ctx, &GetOrderRequest{Id: "ord_123"})
// Always set deadlines — without them, RPCs can hang forever
```

### Error model
```go
// Use standard gRPC status codes
import "google.golang.org/grpc/codes"
import "google.golang.org/grpc/status"

return nil, status.Errorf(codes.NotFound, "order %s not found", id)
return nil, status.Errorf(codes.InvalidArgument, "customer_id is required")
return nil, status.Errorf(codes.FailedPrecondition, "order already shipped")
```

## Decision criteria
| Factor | REST | gRPC |
|--------|------|------|
| Browser clients | REST ✓ | Needs grpc-web proxy |
| Service-to-service | Either | gRPC ✓ (faster, typed) |
| Streaming | WebSocket/SSE | gRPC ✓ (native) |
| Schema enforcement | OpenAPI (optional) | Protobuf ✓ (mandatory) |
| Latency-sensitive | ~1-5ms overhead | ~0.1-0.5ms overhead |
| Human debugging | curl ✓ | grpcurl (harder) |

## Quick reference
```
Proto style: snake_case fields, PascalCase messages, lowercase package
Field numbers: never reuse, never change type
Deadlines: always set (5s default for sync, 30s for heavy ops)
Health check: implement grpc.health.v1.Health service
Load balancing: client-side (pick_first, round_robin) or L7 proxy (Envoy)
```
