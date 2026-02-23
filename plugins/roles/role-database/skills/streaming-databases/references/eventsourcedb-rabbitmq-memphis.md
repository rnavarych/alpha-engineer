# EventStoreDB, RabbitMQ Streams, and Memphis

## When to load
Load when implementing event sourcing with EventStoreDB (append, read, projections), RabbitMQ Streams (append-only log, super streams), or Memphis (modern Kafka alternative with dead-letter stations).

## EventStoreDB: Event Sourcing and Projections

```csharp
// Append events to a stream
var client = new EventStoreClient(EventStoreClientSettings.Create("esdb://localhost:2113?tls=false"));

var orderCreated = new OrderCreated(orderId, customerId, items, total);
var eventData = new EventData(
    Uuid.NewUuid(),
    "OrderCreated",
    JsonSerializer.SerializeToUtf8Bytes(orderCreated)
);

await client.AppendToStreamAsync(
    $"order-{orderId}",
    StreamState.NoStream,  // optimistic concurrency check
    new[] { eventData }
);

// Read stream to rebuild aggregate state
var events = client.ReadStreamAsync(Direction.Forwards, $"order-{orderId}", StreamPosition.Start);
var order = new Order();
await foreach (var resolved in events) {
    order.Apply(resolved.Event);
}

// Catch-up subscription (all historical events, then live)
await client.SubscribeToAllAsync(
    FromAll.Start,
    async (subscription, resolved, ct) => {
        await projectionHandler.Handle(resolved.Event);
    },
    filterOptions: new SubscriptionFilterOptions(EventTypeFilter.ExcludeSystemEvents())
);
```

```javascript
// Built-in projection: aggregate order totals per customer
fromStream('$ce-order')
    .when({
        $init: () => ({ customers: {} }),
        OrderCreated: (state, event) => {
            const cid = event.body.customerId;
            if (!state.customers[cid]) state.customers[cid] = { total: 0, count: 0 };
            state.customers[cid].total += event.body.amount;
            state.customers[cid].count += 1;
        }
    });
```

## RabbitMQ Streams

```bash
rabbitmq-plugins enable rabbitmq_stream

rabbitmqctl declare_stream --vhost / orders \
  --max-length-bytes 10GB \
  --max-age 7D \
  --max-segment-size 500MB
```

```java
Environment environment = Environment.builder().host("rabbitmq").port(5552).build();

Producer producer = environment.producerBuilder().stream("orders").build();

// Consumer with offset tracking
Consumer consumer = environment.consumerBuilder()
    .stream("orders")
    .name("order-processor")  // enables offset tracking
    .autoTrackingStrategy().builder()
    .messageHandler((context, message) -> {
        processOrder(new String(message.getBodyAsBinary()));
    })
    .build();

// Super streams: partitioned streams for horizontal scaling
environment.streamCreator().name("orders").superStream().partitions(12).creator().create();
```

## Memphis

```bash
# Create station (topic equivalent)
memphis station create orders \
  --retention-type=messages \
  --retention-value=1000000 \
  --storage-type=disk \
  --replicas=3

# Schemaverse: enforce schema on station
memphis schema create order-schema \
  --type=json \
  --schema-path=./order.schema.json

memphis schema attach order-schema --station=orders
```

```python
from memphis import Memphis

memphis = Memphis()
await memphis.connect(host="localhost", username="root", password="memphis")

producer = await memphis.producer(station_name="orders", producer_name="order-service")
await producer.produce({"order_id": "123", "amount": 99.99})

# Consumer with dead-letter station (automatic poison message handling)
consumer = await memphis.consumer(
    station_name="orders",
    consumer_name="order-processor",
    consumer_group="processors",
    max_msg_deliveries=5  # after 5 failures -> dead-letter station
)
```
