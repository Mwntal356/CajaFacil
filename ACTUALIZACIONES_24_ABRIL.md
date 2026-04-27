# Bitácora de Actualizaciones - CajaFácil (Post-Checkpoint 24 Abril)

## Fecha: 24 de Abril, 2026

### 1. Módulo de Ventas (Scanner Continuo)
- **Cambio:** Se refactorizó `ContinuousScannerView` para evitar el cierre automático tras la detección de un producto.
- **Detalles:** 
  - Se eliminó el `Navigator.pop` al detectar.
  - Implementado un sistema de `lastCode` con "cooldown" de 1 segundo para evitar escaneos repetidos accidentales.
  - Se añadió feedback visual mediante `SnackBar` al añadir productos.
  - El escáner ahora permanece abierto permitiendo sesiones de venta completas sin interrupción.

### 2. Optimización de UI/UX (Responsividad)
- **Caja (SalesScreen):** Se envolvió el `GridView` de productos en un `InteractiveViewer` para permitir gestos de zoom (pinch-to-zoom), mejorando la accesibilidad en pantallas móviles pequeñas.
- **Inventario (InventoryScreen):** Se envolvió el `ListView` en un `SingleChildScrollView` para garantizar el desplazamiento vertical fluido en cualquier orientación, eliminando bloqueos de layout.

### 3. Identidad de Marca (Branding)
- **Nuevo Logo:** Se creó el componente `CajaFacilLogo` (Widget escalable basado en código) para asegurar nitidez y profesionalismo.
- **Integración:** Sustituido el logo genérico/texto por `CajaFacilLogo` en `LoginScreen` y Dashboard.
- **Infraestructura:** Creada la estructura de directorios en `assets/logo/` para la gestión de iconos de la aplicación.
