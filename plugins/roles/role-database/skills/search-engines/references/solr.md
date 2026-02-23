# Apache Solr

## When to load
Load when working with SolrCloud architecture, schema design, custom analyzers, faceted search, streaming expressions, or data import from SQL databases.

## SolrCloud Architecture

```bash
# Components: Collections (logical index), Shards (partitions), Replicas (NRT/TLOG/PULL), ZooKeeper (coordination)

bin/solr start -c -z zk1:2181,zk2:2181,zk3:2181

bin/solr create_collection -c products -shards 3 -replicationFactor 2 -p 8983

# Upload configset
bin/solr zk upconfig -z localhost:2181 -n products_config -d /path/to/configset

# Collection API
curl "http://localhost:8983/solr/admin/collections?action=CREATE&name=products&numShards=3&replicationFactor=2&collection.configName=products_config"
```

## Schema Design and Analyzers

```xml
<!-- managed-schema (schemaless) or schema.xml (classic) -->
<schema name="products" version="1.6">
    <field name="id" type="string" indexed="true" stored="true" required="true"/>
    <field name="name" type="text_en" indexed="true" stored="true"/>
    <field name="description" type="text_en" indexed="true" stored="true"/>
    <field name="category" type="string" indexed="true" stored="true" docValues="true"/>
    <field name="price" type="pdouble" indexed="true" stored="true" docValues="true"/>
    <field name="tags" type="strings" indexed="true" stored="true" docValues="true"/>
    <field name="location" type="location" indexed="true" stored="true"/>
    <field name="_text_" type="text_general" indexed="true" stored="false" multiValued="true"/>

    <!-- Custom analyzer for product search -->
    <fieldType name="text_product" class="solr.TextField">
        <analyzer type="index">
            <tokenizer class="solr.StandardTokenizerFactory"/>
            <filter class="solr.LowerCaseFilterFactory"/>
            <filter class="solr.StopFilterFactory" words="stopwords.txt"/>
            <filter class="solr.SynonymGraphFilterFactory" synonyms="synonyms.txt" expand="true"/>
            <filter class="solr.FlattenGraphFilterFactory"/>
            <filter class="solr.EdgeNGramFilterFactory" minGramSize="2" maxGramSize="15"/>
        </analyzer>
        <analyzer type="query">
            <tokenizer class="solr.StandardTokenizerFactory"/>
            <filter class="solr.LowerCaseFilterFactory"/>
            <filter class="solr.StopFilterFactory" words="stopwords.txt"/>
            <filter class="solr.SynonymGraphFilterFactory" synonyms="synonyms.txt"/>
        </analyzer>
    </fieldType>

    <!-- Phonetic matching for names -->
    <fieldType name="phonetic" class="solr.TextField">
        <analyzer>
            <tokenizer class="solr.StandardTokenizerFactory"/>
            <filter class="solr.DoubleMetaphoneFilterFactory" inject="false"/>
        </analyzer>
    </fieldType>

    <!-- Copy fields for catch-all search -->
    <copyField source="name" dest="_text_"/>
    <copyField source="description" dest="_text_"/>
</schema>
```

## Faceted Search and Streaming

```bash
# Faceted search query
curl "http://localhost:8983/solr/products/select" -d '
{
    "query": "wireless headphones",
    "filter": ["price:[50 TO 300]", "in_stock:true"],
    "facet": {
        "categories": { "type": "terms", "field": "category", "limit": 10 },
        "price_ranges": { "type": "range", "field": "price", "start": 0, "end": 1000, "gap": 100 },
        "brands": { "type": "terms", "field": "brand", "limit": 20, "sort": "count desc" },
        "avg_rating": { "type": "func", "func": "avg(rating)" }
    },
    "sort": "score desc, popularity desc",
    "rows": 20
}'

# Streaming expressions (analytical queries)
curl "http://localhost:8983/solr/products/stream" -d '
    expr=rollup(
        search(products, q="*:*", fl="category,price", sort="category asc", qt="/export"),
        over="category",
        sum(price),
        count(*)
    )
'
```
