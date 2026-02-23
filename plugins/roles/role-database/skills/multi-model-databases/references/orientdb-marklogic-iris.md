# OrientDB, MarkLogic, and InterSystems IRIS

## When to load
Load when working with OrientDB (document-graph SQL hybrid), MarkLogic (enterprise content + semantic/SPARQL), or InterSystems IRIS (healthcare, HL7/FHIR, ObjectScript multi-model).

## OrientDB

```sql
-- Create class with inheritance (like table + polymorphism)
CREATE CLASS Order EXTENDS V;
CREATE PROPERTY Order.customerId STRING (MANDATORY TRUE);
CREATE PROPERTY Order.amount DECIMAL (MANDATORY TRUE);
CREATE PROPERTY Order.status STRING (DEFAULT 'pending');

-- Create edge class
CREATE CLASS PlacedOrder EXTENDS E;

-- Insert document
INSERT INTO Order SET customerId = 'alice', amount = 99.99, status = 'pending';

-- Create graph edge
CREATE EDGE PlacedOrder FROM (SELECT FROM Customer WHERE name = 'Alice')
    TO (SELECT FROM Order WHERE customerId = 'alice');

-- Graph traversal with SQL
SELECT expand(out('PlacedOrder')) FROM Customer WHERE name = 'Alice';
SELECT shortestPath(#12:0, #14:5, 'BOTH');
```

**Use OrientDB when**: document-graph hybrid needed with SQL-like syntax, distributed multi-master deployment.

## MarkLogic

```xquery
(: Insert JSON document with permissions and collections :)
xdmp:document-insert("/orders/order-123.json",
    object-node {
        "orderId": "order-123",
        "customer": "alice",
        "amount": 99.99,
        "status": "pending"
    },
    map:map()
        => map:with("permissions", (xdmp:permission("readers", "read")))
        => map:with("collections", ("orders", "pending-orders"))
)

(: Full-text search with relevance ranking :)
cts:search(
    fn:collection("orders"),
    cts:and-query((
        cts:json-property-range-query("amount", ">", 50),
        cts:json-property-word-query("notes", "urgent delivery")
    ))
)

(: SPARQL query — RDF triples stored alongside documents :)
sem:sparql('PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  SELECT ?name ?email WHERE { ?person foaf:name ?name . ?person foaf:mbox ?email . }')

(: Optic API: relational-style joins on document collections :)
op:from-view("orders", "orders")
    => op:join-inner(
        op:from-view("customers", "customers"),
        op:on(op:view-col("orders", "customerId"), op:view-col("customers", "id"))
    )
    => op:where(op:gt(op:view-col("orders", "amount"), 100))
    => op:result()
```

**Use MarkLogic when**: enterprise content management, document + full-text + semantic (RDF/SPARQL) in one system.

## InterSystems IRIS

```objectscript
// Multi-model: ObjectScript + SQL + Document + Interoperability
Class MyApp.Order Extends %Persistent {
    Property OrderId As %String [ Required ];
    Property Customer As MyApp.Customer;
    Property Amount As %Numeric(SCALE = 2);
    Property Status As %String [ InitialExpression = "pending" ];
    Property Items As list Of MyApp.OrderItem;

    Index StatusIdx On Status;

    ClassMethod GetPendingOrders() As %Status {
        &sql(DECLARE C1 CURSOR FOR
             SELECT OrderId, Amount FROM MyApp.Order WHERE Status = 'pending')
        &sql(OPEN C1)
        While (1) {
            &sql(FETCH C1 INTO :orderId, :amount)
            If SQLCODE '= 0 Quit
            Write orderId, ": $", amount, !
        }
        &sql(CLOSE C1)
        Quit $$$OK
    }
}

// Document store
Set doc = {"orderId": "123", "amount": 99.99}
Do ##class(%DocDB.Database).%CreateDatabase("orders")
Set db = ##class(%DocDB.Database).%GetDatabase("orders")
Do db.%SaveDocument(doc)
```

**Use InterSystems IRIS when**: healthcare interoperability (HL7/FHIR), FHIR R4 server, mixed relational + document workloads.

## Design Pattern Summary

| Database | Primary Pattern | Key Differentiator |
|----------|----------------|-------------------|
| ArangoDB | Document + Graph | AQL unified language |
| SurrealDB | Document + Graph | LIVE SELECT, built-in auth |
| FaunaDB | Document-Relational | Global distributed ACID |
| Cosmos DB | Multi-API | 5 consistency levels |
| OrientDB | Document + Graph | SQL-like, multi-master |
| MarkLogic | Document + Semantic | Content + SPARQL |
| IRIS | Relational + Document | Healthcare, HL7/FHIR |
