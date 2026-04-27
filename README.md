# Proyecto: CajaFácil - POS Premium para Pequeños Negocios

## 🎯 Objetivo
Sistema de punto de venta (POS) robusto, optimizado para dispositivos móviles, diseñado para la gestión de inventario, ventas en tiempo real, control de turnos y análisis financiero.

---

## 🏗️ Radiografía de Arquitectura

### 1. Persistencia de Datos (Base de Verdad)
*   **Motor:** [Hive](https://pub.dev/packages/hive) (Base de datos NoSQL local).
*   **Gestión de Estados:** [Riverpod](https://pub.dev/packages/flutter_riverpod).
*   **Inmutabilidad Financiera:** Las ventas (`Sale`) guardan un *snapshot* (precio y costo) del momento exacto del cobro. Esto es **crítico** para la integridad de los reportes, ya que protege la utilidad real ante cambios futuros en los precios del catálogo.
*   **TypeIDs (Hive):**
    *   0: Product, 1: Sale, 2: SoldProduct, 3: BusinessConfig, 4: Expense, 5: CostEntry, 6: PriceEntry, 7: Supplier, 8: SupplierPurchase.

### 2. Flujo Crítico: La "Caja"
*   **Seguridad:** El flujo de cobro está blindado contra clics dobles mediante variables de estado (`_isProcessingPayment`).
*   **Alta Rápida:** Si un producto escaneado no existe, el sistema pausa la venta, precarga el código en el formulario de registro y permite volver al flujo de venta sin pérdida de contexto.
*   **Escáner:** Unificado mediante `mobile_scanner`. Se usa el mismo componente para inventario y para la venta.

### 3. Sistema Visual (UX/UI)
*   **ProductImageWidget:** Widget centralizado para carga de imágenes. Soporta `assets`, `http` (red) y `File` (local). Incluye `errorBuilder` que hace fallback a `LucideIcons.package` si la ruta falla.
*   **Consistencia:** El mismo widget se usa en:
    *   **Caja:** Grid de productos.
    *   **Dashboard:** Productos estrella/escasez.
    *   **Inventario:** Ficha Técnica.

### 4. Demo y Simulación
*   **Sembrado:** El `DemoDataSeeder` asegura 20 productos constantes y ventas simuladas que reflejan una realidad comercial (~$2,500 MXN/día, 8 tickets diarios, multi-producto).
*   **Regla de oro:** No modificar la estructura de los 20 productos demo para mantener la coherencia de las gráficas.

---

## 🛠️ Procedimiento de Mantenimiento

### 1. Actualización en Celular
1. El código se sube a `main` en GitHub.
2. **GitHub Actions** compila el `.apk`.
3. Descargar el APK desde la pestaña "Actions" del repositorio.
4. **Instalación:** Al instalar el nuevo APK, el sistema pedirá "Actualizar". Al aceptar, **se conservan los datos de Hive** (ventas e inventario).

### 2. Normas de Seguridad
*   **Blindaje:** Nunca comprometer la atomicidad de la venta.
*   **Consistencia:** Cualquier mejora visual DEBE pasar por el `ProductImageWidget`.

---

## 🚩 Notas Técnicas para el Desarrollador
*   **AppColors:** Siempre utilizar `AppColors` definido en `core/theme/app_theme.dart` para mantener la identidad visual premium.
*   **Límites de Scroll:** En pantallas con listas densas (Inventario), usar estructuras `Column` con `Expanded` + `ListView` para evitar conflictos de gestos de scroll.
*   **Depuración:** Si una imagen falla, verificar siempre en `pubspec.yaml` que el asset esté declarado y que el nombre de archivo coincida exactamente con la extensión (.jfif vs .jpeg).
