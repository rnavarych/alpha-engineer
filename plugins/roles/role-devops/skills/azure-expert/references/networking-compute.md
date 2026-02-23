# Azure Networking and Compute

## When to load
Load when designing VNet hub-and-spoke topology, configuring NSGs, load balancers, AKS clusters,
Container Apps, App Service, Azure Functions, or messaging with Service Bus and Event Grid/Hubs.

## Networking (Virtual Network)

### VNet Architecture
- Design VNets with dedicated address spaces per environment. Use **hub-and-spoke topology**: a central hub VNet for shared services (firewall, VPN/ExpressRoute, DNS, monitoring) peered to spoke VNets per workload.
- Use **Azure Virtual WAN** for large-scale multi-region hub-and-spoke with managed routing, SD-WAN integration, and Azure Firewall or NVA in virtual hubs.
- Segment VNets into subnets by tier: Application Gateway/WAF subnet, application subnet, database subnet, private endpoint subnet, AKS subnet.
- Enable **subnet delegation** for PaaS services that inject into VNets (AKS, App Service Environment, Azure SQL Managed Instance, NetApp Files).
- Use **Private Endpoints** for PaaS services (Azure SQL, Cosmos DB, Storage, Key Vault, ACR, Service Bus) — traffic stays within the VNet, off the public internet.
- Use **Azure Private DNS Zones** linked to VNets for automatic DNS resolution of private endpoint FQDNs.

### Azure Firewall and NSGs
- Use **Network Security Groups (NSGs)** for subnet and NIC-level traffic filtering. Use **Application Security Groups (ASGs)** to group VMs by role and reference ASGs in NSG rules instead of IP addresses.
- Use **Azure Firewall Premium** (IDPS, TLS inspection, URL filtering) in the hub for centralized egress control and east-west traffic inspection across spokes.
- Enable **NSG Flow Logs** to Log Analytics for traffic analysis and compliance auditing.
- Use **Azure DDoS Protection Standard** on production VNets. Standard provides adaptive tuning per resource, attack telemetry, and SLA guarantees.

### Load Balancing
- **Azure Application Gateway (WAF v2)**: regional Layer 7 LB with WAF, SSL offload, URL-based routing, session affinity, autoscaling. Use for web workloads requiring WAF.
- **Azure Front Door (Premium)**: global anycast Layer 7 LB with WAF, CDN, origin health probing, and Rules Engine for traffic manipulation. Use for multi-region global web applications.
- **Azure Load Balancer (Standard)**: Layer 4 TCP/UDP, zonal HA, backend pools with VMs or VMSS. Use for non-HTTP workloads or as an internal LB.
- **Azure Traffic Manager**: DNS-based global traffic routing with geographic, performance, weighted, and priority routing methods. Use for multi-region failover and latency-based routing.
- Use **Application Gateway Ingress Controller (AGIC)** for AKS to provision Application Gateway from Kubernetes Ingress resources.

## Compute

### AKS (Azure Kubernetes Service)
- Use **Azure CNI** for production AKS clusters: pods get VNet IPs, enabling direct NSG control, private endpoint access, and Azure-native networking.
- Use **Azure CNI Overlay** for large clusters where IP exhaustion is a concern — pods use an overlay network with VNet IPs only on nodes.
- Enable **AKS Workload Identity** (OIDC + Azure AD federation) for pod-level Azure API access without secrets.
- Use **AKS node pools**: system node pool for critical kube-system components, user node pools for application workloads. Use dedicated node pools for GPU/specialized hardware.
- Enable **Cluster Autoscaler** on node pools and **KEDA** for event-driven pod scaling.
- Use **Azure Linux** (CBL-Mariner) or **Ubuntu** node images. Enable **auto-upgrade channels** (`patch` or `node-image`) for security patches.
- Enable **Defender for Containers** for runtime threat detection, image vulnerability assessment, and Kubernetes audit log analysis.
- Use **Azure Policy for AKS** (OPA Gatekeeper integration) to enforce pod security standards.
- Enable **AKS private cluster** for production — API server not exposed on public internet.
- Use **NAP (Node Auto-Provisioning)** (Karpenter-based, preview) for dynamic optimal node provisioning in AKS.

### Azure Container Apps
- Use **Container Apps** for serverless container workloads with event-driven scaling (KEDA built-in), without managing Kubernetes.
- Deploy Container Apps in a **Container Apps Environment** backed by a managed Kubernetes cluster. Use VNet-integrated environments for private networking.
- Use **Dapr** sidecar integration in Container Apps for service-to-service communication, state management, and pub/sub abstraction.
- Use **Container Apps Jobs** for batch and scheduled workloads. **Event-driven jobs** for processing queues or event streams.

### App Service and Azure Functions
- Use **App Service Environments (ASE v3)** for private, isolated App Service with VNet integration and no shared infrastructure.
- Use **VNet Integration** on App Service to route outbound traffic through VNets for accessing private resources.
- Use **Premium Plan** for Azure Functions requiring VNet integration, longer execution times, and no cold starts.
- Use **Azure Functions Flex Consumption** (per-execution billing + VNet support) for the best of serverless economics with enterprise networking.
- Enable **Managed Identity** on all App Service and Functions apps for Azure service authentication.

## Messaging and Events

### Service Bus
- Use **Service Bus queues** for point-to-point reliable messaging. Use **topics and subscriptions** for fan-out pub/sub patterns.
- Use **Premium tier** for VNet integration, private endpoints, message sessions, and large message support.
- Enable **message sessions** for ordered, stateful processing where all messages for a logical entity must be processed by the same consumer.
- Configure **Dead Letter Queues** (built-in) for messages that exceed `MaxDeliveryCount` or expire via TTL.
- Use **Service Bus Managed Identity** access — no connection strings in application config.

### Event Grid and Event Hubs
- **Event Grid**: event routing from Azure services to handlers (Functions, Logic Apps, Service Bus, webhooks). Use for low-latency reactive event processing.
- **Event Hubs**: high-throughput event streaming (Kafka-compatible). Use for log ingestion, telemetry pipelines, real-time analytics, and large-scale event streams.
- Use **Event Hubs Capture** to automatically archive raw event stream data to Blob Storage or Data Lake for replay and analysis.
- Use **Event Hubs with Kafka protocol** for existing Kafka applications without code changes.
