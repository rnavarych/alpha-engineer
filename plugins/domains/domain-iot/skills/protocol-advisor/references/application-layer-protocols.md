# Application-Layer Protocol Comparison

## When to load
Load when selecting between MQTT, CoAP, AMQP, and HTTP for an IoT use case, or when comparing protocols against specific device constraints and delivery requirements.

## MQTT (Message Queuing Telemetry Transport)
- **Transport**: TCP (port 1883, TLS on 8883), WebSocket for browser clients
- **Pattern**: Publish-subscribe with broker
- **Strengths**: Low overhead (2-byte minimum header), bidirectional, retained messages, LWT, mature ecosystem
- **Best for**: Telemetry ingestion, device-to-cloud and cloud-to-device messaging, event-driven architectures
- **Limitations**: Requires persistent TCP connection, broker is a central dependency

## CoAP (Constrained Application Protocol)
- **Transport**: UDP (port 5683, DTLS on 5684)
- **Pattern**: Request-response (REST-like: GET, PUT, POST, DELETE)
- **Strengths**: Very low overhead, designed for constrained devices (8-bit MCUs, 10KB RAM), multicast support, observable resources
- **Best for**: Constrained devices with limited memory, battery-powered sensors, LAN discovery
- **Limitations**: UDP means no guaranteed delivery (application must handle), less mature tooling than MQTT

## AMQP (Advanced Message Queuing Protocol)
- **Transport**: TCP (port 5672, TLS on 5671)
- **Pattern**: Queue-based with exchanges and routing
- **Strengths**: Rich routing (direct, topic, fanout, headers), message acknowledgment, transactions, high reliability
- **Best for**: Enterprise integration, backend service communication, scenarios requiring message ordering guarantees
- **Limitations**: Higher overhead, complex for constrained devices, overkill for simple telemetry

## HTTP/REST
- **Transport**: TCP (port 80/443)
- **Pattern**: Request-response
- **Strengths**: Universal, well-understood, extensive tooling, firewall-friendly
- **Best for**: Device configuration APIs, firmware download, infrequent data reporting
- **Limitations**: High overhead per request (headers), no server-initiated push (requires polling or WebSocket), not suitable for high-frequency telemetry

## Selection Decision Matrix

| Criterion | MQTT | CoAP | AMQP | HTTP |
|-----------|------|------|------|------|
| Device RAM < 32KB | Fair | Best | Poor | Poor |
| Battery life critical | Good | Best | Poor | Poor |
| Bidirectional messaging | Best | Fair | Good | Poor |
| Reliable delivery | Good (QoS) | Fair | Best | Good |
| Firewall traversal | Good | Fair | Fair | Best |
| Message throughput | Best | Good | Good | Fair |
| Ecosystem maturity | Best | Fair | Good | Best |
