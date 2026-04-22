# Estado del Proyecto - CajaFácil (tienda-3)

## Última Actualización: 16 de Abril, 2026

### Infraestructura de Navegación
- Implementado `StatefulShellRoute` en `app_router.dart`.
- Barra de navegación persistente con 5 pestañas: Resumen, Caja, Inventario, Proveedores, La Verdad (Admin).
- Los navegadores de cada pestaña son independientes para evitar interferencias (especialmente en búsquedas).

### Módulo de Ventas (Caja)
- **Seguridad:** Flujo de cobro blindado contra clics dobles y pérdida de contexto.
- **UX:** El `GridView` de productos tiene un `bottom padding` de 120dp para evitar ser tapado por la barra de cobro.
- **Tickets:** Visualización garantizada de ticket tras el cobro con cálculo de cambio basado en monto recibido.
- **Inmutabilidad:** Las ventas guardan un snapshot de precios/costos del momento.

### Gestión de Inventario (BI)
- **Kardex:** Historial de costos (compras) y precios (ventas) por producto.
- **Matemática Financiera:** Implementado el Costo Promedio Ponderado en la función `restock`.
- **Calculadora de Margen:** Al surtir, se muestra el margen proyectado (%) antes de guardar.
- **Ficha Técnica:** Acceso al detalle profundo tocando el nombre del producto en la tabla.

### Módulo Proveedores (Cero Papeles)
- Registro de proveedores con contacto y teléfono.
- Registro de compras con fecha editable y monto.
- **Digitalización:** Soporte para múltiples fotos de tickets/notas físicas por cada compra.
- Visualización de fotos en pantalla completa (Kardex de Notas).

### Datos y Persistencia (Hive)
- TypeIDs utilizados: 
  - 0: Product
  - 1: Sale
  - 2: SoldProduct
  - 3: BusinessConfig
  - 4: Expense
  - 5: CostEntry
  - 6: PriceEntry
  - 7: Supplier
  - 8: SupplierPurchase
- Localización en español (`intl`) configurada e inicializada en `main.dart`.
---
*Instrucción para próxima sesión: El proyecto está en un Checkpoint Estable (21 Abr). No realizar cambios estructurales en el flujo de caja. Siguiente paso: Generación de APK y validación final de fotos en dispositivo físico.*
---
