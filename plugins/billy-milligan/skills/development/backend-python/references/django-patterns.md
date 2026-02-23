# Django Patterns

## Models with Best Practices

```python
from django.db import models
from django.utils import timezone
import uuid

class BaseModel(models.Model):
    """Abstract base — timestamp fields on every model."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True
        ordering = ['-created_at']

class Order(BaseModel):
    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        PROCESSING = 'processing', 'Processing'
        COMPLETED = 'completed', 'Completed'
        CANCELLED = 'cancelled', 'Cancelled'

    user = models.ForeignKey('auth.User', on_delete=models.CASCADE, related_name='orders')
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING, db_index=True)
    total = models.DecimalField(max_digits=10, decimal_places=2)
    notes = models.TextField(blank=True, default='')

    class Meta(BaseModel.Meta):
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['status', '-created_at']),
        ]

    def __str__(self) -> str:
        return f"Order {self.id} ({self.status})"

    @property
    def is_cancellable(self) -> bool:
        return self.status in (self.Status.PENDING, self.Status.PROCESSING)
```

## Django REST Framework Serializers

```python
from rest_framework import serializers, viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response

class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    item_count = serializers.IntegerField(source='items.count', read_only=True)

    class Meta:
        model = Order
        fields = ['id', 'user', 'status', 'total', 'items', 'item_count', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']

class OrderCreateSerializer(serializers.Serializer):
    items = OrderItemCreateSerializer(many=True, min_length=1)
    notes = serializers.CharField(max_length=500, required=False, default='')

    def validate_items(self, items):
        product_ids = [i['product_id'] for i in items]
        if len(product_ids) != len(set(product_ids)):
            raise serializers.ValidationError("Duplicate products")
        return items

class OrderViewSet(viewsets.ModelViewSet):
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Order.objects.filter(user=self.request.user).select_related('user').prefetch_related('items')

    def get_serializer_class(self):
        if self.action == 'create':
            return OrderCreateSerializer
        return OrderSerializer

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        order = self.get_object()
        if not order.is_cancellable:
            return Response({'error': 'Order cannot be cancelled'}, status=status.HTTP_400_BAD_REQUEST)
        order.status = Order.Status.CANCELLED
        order.save(update_fields=['status', 'updated_at'])
        return Response(OrderSerializer(order).data)
```

## Signals

```python
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver

@receiver(post_save, sender=Order)
def order_created_handler(sender, instance, created, **kwargs):
    if created:
        send_order_confirmation.delay(str(instance.id))  # Celery task

@receiver(pre_save, sender=Order)
def order_status_change(sender, instance, **kwargs):
    if instance.pk:
        try:
            old = Order.objects.get(pk=instance.pk)
            if old.status != instance.status:
                AuditLog.objects.create(
                    entity_type='order',
                    entity_id=str(instance.pk),
                    action=f'status_changed:{old.status}->{instance.status}',
                )
        except Order.DoesNotExist:
            pass
# Caution: signals are implicit — prefer explicit service layer for complex logic
```

## Migrations

```python
# Generate migration
# python manage.py makemigrations

# Zero-downtime: expand-then-contract
# Step 1: Add new column with default (expand)
class Migration(migrations.Migration):
    operations = [
        migrations.AddField(
            model_name='order',
            name='shipping_method',
            field=models.CharField(max_length=20, default='standard'),
        ),
    ]

# Step 2: Backfill data (data migration)
def backfill_shipping(apps, schema_editor):
    Order = apps.get_model('orders', 'Order')
    Order.objects.filter(total__gte=100).update(shipping_method='express')

class Migration(migrations.Migration):
    operations = [
        migrations.RunPython(backfill_shipping, migrations.RunPython.noop),
    ]

# Step 3: Remove old column or add constraint (contract) — after deploy
```

## Admin Customization

```python
from django.contrib import admin

@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'status', 'total', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['user__email', 'id']
    readonly_fields = ['id', 'created_at', 'updated_at']
    date_hierarchy = 'created_at'

    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user')
```

## Anti-Patterns
- N+1 queries — always use `select_related` (FK) and `prefetch_related` (M2M/reverse FK)
- Complex logic in signals — hard to debug, test, and trace; use service layer
- Missing `update_fields` in `save()` — updates all columns, causes race conditions
- Migrations without `RunPython.noop` reverse — blocks rollback

## Quick Reference
```
Models: UUIDField PK, TextChoices for enums, abstract BaseModel
DRF: separate read/create serializers, select_related in get_queryset
Signals: post_save/pre_save — keep simple, prefer explicit service calls
Migrations: makemigrations, expand-contract for zero-downtime
Admin: list_display, list_filter, search_fields, select_related
N+1: select_related (FK), prefetch_related (reverse FK / M2M)
```
