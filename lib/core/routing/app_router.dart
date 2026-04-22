import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/main_scaffold.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/inventory/screens/inventory_screen.dart';
import '../../features/inventory/screens/product_form_screen.dart';
import '../../features/sales/screens/sales_screen.dart';
import '../../features/admin/screens/admin_panel_screen.dart';
import '../../features/admin/screens/sales_history_screen.dart';
import '../../features/suppliers/screens/supplier_list_screen.dart';
import '../../features/promotions/screens/promotions_screen.dart';
import '../../data/models/product.dart';

// Claves globales para navegación
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorDashboardKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _shellNavigatorSalesKey = GlobalKey<NavigatorState>(debugLabel: 'sales');
final _shellNavigatorInventoryKey = GlobalKey<NavigatorState>(debugLabel: 'inventory');
final _shellNavigatorSuppliersKey = GlobalKey<NavigatorState>(debugLabel: 'suppliers');
final _shellNavigatorAdminKey = GlobalKey<NavigatorState>(debugLabel: 'admin');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    navigatorKey: _rootNavigatorKey,
    routes: [
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      // Navegación Principal con Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Pestaña: Resumen (Dashboard)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboardKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Pestaña: Caja (Sales)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSalesKey,
            routes: [
              GoRoute(
                path: '/sales',
                builder: (context, state) => const SalesScreen(),
              ),
            ],
          ),
          // Pestaña: Inventario
          StatefulShellBranch(
            navigatorKey: _shellNavigatorInventoryKey,
            routes: [
              GoRoute(
                path: '/inventory',
                builder: (context, state) => const InventoryScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ProductFormScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final product = state.extra as Product?;
                      return ProductFormScreen(productToEdit: product);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Pestaña: Proveedores (NUEVA)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSuppliersKey,
            routes: [
              GoRoute(
                path: '/suppliers',
                builder: (context, state) => const SupplierListScreen(),
              ),
            ],
          ),
          // Pestaña: La Verdad (Admin/Analítica)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorAdminKey,
            routes: [
              GoRoute(
                path: '/admin',
                builder: (context, state) => const AdminPanelScreen(),
                routes: [
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const SalesHistoryScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/promotions',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PromotionsScreen(),
      ),
    ],
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      if (!authState.isAuthenticated) return isLoggingIn ? null : '/login';
      if (isLoggingIn) return '/dashboard';
      if (state.matchedLocation == '/admin' && authState.role != UserRole.dueno) return '/dashboard';
      return null;
    },
  );
});
